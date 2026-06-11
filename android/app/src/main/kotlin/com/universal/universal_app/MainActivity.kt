package com.universal.universal_app

import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.universal.universal_app/apk_installer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "installApk" -> {
                        val filePath = call.argument<String>("filePath")
                        if (filePath != null) {
                            val success = installApk(filePath)
                            result.success(success)
                        } else {
                            result.error("INVALID_ARGUMENT", "filePath is required", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun installApk(filePath: String): Boolean {
        return try {
            val file = File(filePath)
            if (!file.exists()) {
                return false
            }

            val intent = Intent(Intent.ACTION_VIEW)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                // Android 7+ — use FileProvider for content:// URI
                val authority = "${applicationContext.packageName}.fileprovider"
                val uri = FileProvider.getUriForFile(applicationContext, authority, file)
                intent.setDataAndType(uri, "application/vnd.android.package-archive")
                intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            } else {
                // Android 6 and below — use file:// URI directly
                val uri = Uri.fromFile(file)
                intent.setDataAndType(uri, "application/vnd.android.package-archive")
            }

            startActivity(intent)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
}
