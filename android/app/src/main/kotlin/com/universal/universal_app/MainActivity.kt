package com.universal.universal_app

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageInstaller
import android.net.Uri
import android.os.Build
import android.content.pm.PackageManager
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

/**
 * MainActivity exposes a method channel for downloading and installing APK
 * updates from inside the Flutter app.
 *
 * The install path uses the [PackageInstaller] Session API instead of the
 * legacy `ACTION_VIEW` intent. Why this matters for the silent-failure case:
 *
 *  1. ACTION_VIEW only tells us "the installer screen was launched". It can
 *     not tell us whether the user tapped Install, whether the APK was
 *     rejected for a signature mismatch, whether storage failed, or whether
 *     the user cancelled. That is exactly the symptom seen here:
 *     `Installer launch result: true` but the installed version never changes.
 *
 *  2. Session API streams the APK bytes directly into the system installer.
 *     The on-disk location of the APK is no longer the system installer's
 *     concern, so problems like "/Android/data/<pkg>/files is private to the
 *     app on Android 11+ and the installer can't read it" simply disappear.
 *
 *  3. We get a callback with a real [PackageInstaller.STATUS_SUCCESS] /
 *     [PackageInstaller.STATUS_FAILURE_*] code plus a human readable reason,
 *     which we forward to Dart so the UI can show the user what really
 *     happened.
 */
class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.universal.universal_app/apk_installer"
    private val TAG = "ApkInstaller"

    /** Custom action our PendingIntent broadcasts to. */
    private val INSTALL_ACTION = "com.universal.universal_app.INSTALL_RESULT"

    private val REQUEST_INSTALL_PERMISSION = 4631
    private val REQUEST_USER_CONFIRM_INSTALL = 4632

    /** Outstanding "open install-permission settings" call. */
    private var pendingPermissionResult: MethodChannel.Result? = null

    /** Outstanding `installApk` call, completed when the OS reports terminal status. */
    private var pendingInstallResult: MethodChannel.Result? = null

    /** Receiver registered for the lifetime of an in-progress install session. */
    private var installReceiver: BroadcastReceiver? = null

    /** Currently active install session id, or -1 when no install is in flight. */
    private var currentSessionId: Int = -1

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canInstallPackages" -> result.success(canInstallPackages())
                    "requestInstallPermission" -> requestInstallPermission(result)
                    "installApk" -> {
                        val filePath = call.argument<String>("filePath")
                        if (filePath != null) {
                            installApk(filePath, result)
                        } else {
                            result.error(
                                "INVALID_ARGUMENT",
                                "filePath is required",
                                null
                            )
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // Kiosk / launcher helper channel (fallback non-MDM flow)
        val KIOSK_CHANNEL = "app.kiosk/mode"
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, KIOSK_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openHomeSettings" -> {
                        openHomeSettings()
                        result.success(true)
                    }
                    "isDefaultLauncher" -> {
                        result.success(isDefaultLauncher())
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun openHomeSettings() {
        try {
            val intent = Intent(Settings.ACTION_HOME_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open home settings", e)
        }
    }

    private fun isDefaultLauncher(): Boolean {
        val intent = Intent(Intent.ACTION_MAIN)
        intent.addCategory(Intent.CATEGORY_HOME)
        val resolveInfo = packageManager.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY)
        return resolveInfo?.activityInfo?.packageName == packageName
    }

    // ─── "Install unknown apps" permission ───────────────────────────────────

    /** Android 8+ requires explicit "install unknown apps" permission per app. */
    private fun canInstallPackages(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            packageManager.canRequestPackageInstalls()
        } else {
            true
        }
    }

    private fun requestInstallPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            result.success(true); return
        }
        if (canInstallPackages()) {
            result.success(true); return
        }
        try {
            pendingPermissionResult = result
            val intent = Intent(
                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                Uri.parse("package:$packageName")
            )
            startActivityForResult(intent, REQUEST_INSTALL_PERMISSION)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open install-permission settings", e)
            pendingPermissionResult = null
            result.success(false)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            REQUEST_INSTALL_PERMISSION -> {
                val granted = canInstallPackages()
                Log.d(TAG, "Returned from install-permission settings. granted=$granted")
                pendingPermissionResult?.success(granted)
                pendingPermissionResult = null
            }
            REQUEST_USER_CONFIRM_INSTALL -> {
                // The terminal status will arrive via the broadcast receiver.
                // We intentionally do not complete pendingInstallResult here.
                Log.d(TAG, "Returned from user-confirm install. resultCode=$resultCode")
            }
        }
    }

    // ─── PackageInstaller session-based install ──────────────────────────────

    /**
     * Stream [filePath] into a [PackageInstaller] session and commit it. The
     * [result] is held until the OS reports a terminal status via our
     * [installReceiver], at which point we forward the real outcome to Dart.
     *
     * Map fields:
     *   launched           -> Boolean: session was committed (installer engaged)
     *   success            -> Boolean: package install actually completed
     *   permissionRequired -> Boolean: blocked because "install unknown apps" is off
     *   userCancelled      -> Boolean: user dismissed the install confirmation
     *   statusCode         -> Int?: PackageInstaller.STATUS_*
     *   statusMessage      -> String?: raw OS-provided message
     *   error              -> String?: human readable failure reason
     */
    private fun installApk(filePath: String, result: MethodChannel.Result) {
        val file = File(filePath)

        if (!file.exists()) {
            Log.e(TAG, "APK not found: $filePath")
            result.success(buildResult(error = "APK file not found at $filePath"))
            return
        }
        if (file.length() == 0L) {
            Log.e(TAG, "APK is empty: $filePath")
            result.success(buildResult(error = "APK file is empty (0 bytes)"))
            return
        }
        if (!canInstallPackages()) {
            Log.w(TAG, "Install blocked: REQUEST_INSTALL_PACKAGES not granted")
            result.success(
                buildResult(
                    permissionRequired = true,
                    error = "Install unknown apps permission not granted"
                )
            )
            return
        }
        if (pendingInstallResult != null) {
            Log.w(TAG, "An install is already in progress; rejecting duplicate call")
            result.success(buildResult(error = "Install already in progress"))
            return
        }

        Log.d(
            TAG,
            "Starting PackageInstaller session: path=$filePath size=${file.length()}"
        )

        pendingInstallResult = result
        var sessionId = -1
        val packageInstaller = packageManager.packageInstaller

        try {
            registerInstallReceiver()

            val params = PackageInstaller.SessionParams(
                PackageInstaller.SessionParams.MODE_FULL_INSTALL
            )
            params.setAppPackageName(packageName)
            // Always require the user's confirmation. Without
            // INSTALL_PACKAGES (system permission) the OS would ignore us
            // anyway, but being explicit keeps Android 12+ happy.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                params.setRequireUserAction(
                    PackageInstaller.SessionParams.USER_ACTION_REQUIRED
                )
            }

            sessionId = packageInstaller.createSession(params)
            currentSessionId = sessionId

            // Stream APK bytes into the session. file.length() lets the
            // installer pre-allocate and detect short writes.
            packageInstaller.openSession(sessionId).use { session ->
                FileInputStream(file).use { input ->
                    session.openWrite("base.apk", 0, file.length()).use { output ->
                        input.copyTo(output)
                        session.fsync(output)
                    }
                }

                // PendingIntent we'll be called back on with the real status.
                val intent = Intent(INSTALL_ACTION).apply { setPackage(packageName) }
                val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
                val statusReceiver = PendingIntent.getBroadcast(
                    this, sessionId, intent, flags
                )

                Log.d(TAG, "Committing session $sessionId")
                session.commit(statusReceiver.intentSender)
            }
            // Note: pendingInstallResult is NOT completed here. We wait for
            // STATUS_PENDING_USER_ACTION (to show the confirm dialog) and then
            // a terminal STATUS_SUCCESS / STATUS_FAILURE_* in the receiver.
        } catch (e: Exception) {
            Log.e(TAG, "PackageInstaller failure", e)
            if (sessionId != -1) {
                try { packageInstaller.abandonSession(sessionId) } catch (_: Exception) {}
            }
            completeInstallResult(
                buildResult(error = "PackageInstaller failure: ${e.message}")
            )
        }
    }

    private fun registerInstallReceiver() {
        if (installReceiver != null) return
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                if (intent.action != INSTALL_ACTION) return
                val status = intent.getIntExtra(
                    PackageInstaller.EXTRA_STATUS,
                    PackageInstaller.STATUS_FAILURE
                )
                val message = intent.getStringExtra(PackageInstaller.EXTRA_STATUS_MESSAGE)
                Log.d(TAG, "Install broadcast: status=$status message=$message")

                when (status) {
                    PackageInstaller.STATUS_PENDING_USER_ACTION -> {
                        // Not terminal — launch the system confirmation UI.
                        val confirm = extraIntent(intent)
                        if (confirm == null) {
                            completeInstallResult(
                                buildResult(
                                    error = "Install requires user action but no intent provided"
                                )
                            )
                            return
                        }
                        confirm.addFlags(
                            Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        )
                        try {
                            startActivityForResult(confirm, REQUEST_USER_CONFIRM_INSTALL)
                            Log.d(TAG, "Launched user-confirm install dialog")
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to launch install dialog", e)
                            completeInstallResult(
                                buildResult(
                                    error = "Failed to launch install dialog: ${e.message}"
                                )
                            )
                        }
                    }

                    PackageInstaller.STATUS_SUCCESS -> {
                        Log.i(TAG, "Install SUCCESS for session $currentSessionId")
                        completeInstallResult(
                            buildResult(
                                launched = true,
                                success = true,
                                statusCode = status,
                                statusMessage = message
                            )
                        )
                    }

                    else -> {
                        val (cancelled, reason) = describeFailure(status, message)
                        Log.w(TAG, "Install FAILURE status=$status reason=$reason")
                        completeInstallResult(
                            buildResult(
                                launched = true,
                                success = false,
                                userCancelled = cancelled,
                                statusCode = status,
                                statusMessage = message,
                                error = reason
                            )
                        )
                    }
                }
            }
        }

        val filter = IntentFilter(INSTALL_ACTION)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // RECEIVER_NOT_EXPORTED is required on Android 14+ for runtime
            // receivers that don't subscribe to protected system broadcasts.
            registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(receiver, filter)
        }
        installReceiver = receiver
    }

    private fun unregisterInstallReceiver() {
        installReceiver?.let {
            try { unregisterReceiver(it) } catch (_: Exception) { /* already gone */ }
        }
        installReceiver = null
    }

    /**
     * Dispatch the final result back to Dart and tear down per-session state.
     * Safe to call multiple times.
     */
    private fun completeInstallResult(map: Map<String, Any?>) {
        val r = pendingInstallResult ?: return
        pendingInstallResult = null
        currentSessionId = -1
        unregisterInstallReceiver()
        try {
            r.success(map)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to deliver install result to Dart", e)
        }
    }

    override fun onDestroy() {
        unregisterInstallReceiver()
        super.onDestroy()
    }

    /** Map [PackageInstaller.STATUS_FAILURE_*] codes to a friendly explanation. */
    private fun describeFailure(status: Int, message: String?): Pair<Boolean, String> {
        return when (status) {
            PackageInstaller.STATUS_FAILURE_ABORTED ->
                true to "Installation cancelled by user"
            PackageInstaller.STATUS_FAILURE_BLOCKED ->
                false to "Install blocked by device policy or another installer"
            PackageInstaller.STATUS_FAILURE_CONFLICT ->
                false to ("Install conflict — likely a signature mismatch with " +
                        "the currently installed app, or attempted downgrade. " +
                        (message ?: ""))
            PackageInstaller.STATUS_FAILURE_INCOMPATIBLE ->
                false to "APK is incompatible with this device. ${message ?: ""}"
            PackageInstaller.STATUS_FAILURE_INVALID ->
                false to "APK is invalid or corrupt. ${message ?: ""}"
            PackageInstaller.STATUS_FAILURE_STORAGE ->
                false to "Insufficient storage to install the update"
            else ->
                false to (message ?: "Install failed (status $status)")
        }
    }

    @Suppress("DEPRECATION")
    private fun extraIntent(intent: Intent): Intent? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_INTENT, Intent::class.java)
        } else {
            intent.getParcelableExtra(Intent.EXTRA_INTENT)
        }
    }

    private fun buildResult(
        launched: Boolean = false,
        success: Boolean = false,
        permissionRequired: Boolean = false,
        userCancelled: Boolean = false,
        statusCode: Int? = null,
        statusMessage: String? = null,
        error: String? = null
    ): Map<String, Any?> = mapOf(
        "launched" to launched,
        "success" to success,
        "permissionRequired" to permissionRequired,
        "userCancelled" to userCancelled,
        "statusCode" to statusCode,
        "statusMessage" to statusMessage,
        "error" to error
    )
}
