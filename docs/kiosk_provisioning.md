# Kiosk / Lockdown Options for PST Devices

This document explains three approaches to lock a device to your PDT app (`UniTrack`) and how to provision a fleet (~300+ devices). Choose the method that fits your operational constraints.

---

## 1) Recommended: Device Owner (MDM / Zero-touch / QR provisioning)

Overview
- Device Owner mode gives your app (or an MDM) full control: set lock-task packages, disable home/recents, block status bar, disable factory reset, and more. This is the secure, scalable approach for unattended kiosks.

Provisioning options (production)
- Android Zero-touch (OEM-managed): best for large fleets. Devices purchased through supported resellers can be enrolled automatically into an EMM/MDM.
- Android Enterprise (EMM / Managed Google Play): enroll devices via EMM console (QR/Token/Offline enrollment flows).
- OEM specific: Samsung Knox, Zebra StageNow, SOTI, Scalefusion, etc. These vendors provide guided provisioning and deeper OEM controls.

Testing / manual (single-device) using `adb` (developer-friendly, **requires factory reset**):
1. Build and install APK on a factory-reset device.
2. On the device (or via ADB) set the device owner:

```bash
adb install -r app-release.apk
adb shell dpm set-device-owner com.your.package/.MyDeviceAdminReceiver
```

Notes
- `set-device-owner` only works on devices with no accounts and which were factory-reset.
- For large fleets, use an MDM/EMM provider — they can push the app, set policies, and manage devices remotely.

On the device (app code)
- When your app is device owner it can call DevicePolicyManager APIs to call `setLockTaskPackages(...)` and `startLockTask()` to enter kiosk mode.

Security & limitations
- Device-owner provides strongest control; some OEMs add extra managed features. Power button behavior cannot always be fully suppressed (depends on hardware). Use MDM for fine-grained control.

---

## 2) Developer / small-batch ADB provisioning (not for 300+ without tooling)

Use case: QA or small lab where you can factory-reset devices and run commands.

Steps (factory-reset device required):
1. Enable USB debugging on the device.
2. Install the app:

```bash
adb install -r app-release.apk
```

3. Set device owner (one command, requires factory-reset):

```bash
adb shell dpm set-device-owner com.your.package/.MyDeviceAdminReceiver
```
```

4. Verify: your app should now be the device owner (DevicePolicyManager.isDeviceOwnerApp returns true). App can now call `setLockTaskPackages(...)` and `startLockTask()`.

Caveats:
- Not automated across hundreds of devices; not suitable for large deployments.
- Some device models and Android versions vary in behavior.

---

## 3) Fallback: Default-launcher (no MDM/ADB required)

Overview
- Make the app available as a Home/Launcher and instruct the provisioning person to select your app as the default Home app. This does NOT require device-owner nor factory-reset.
- This is the only practical no-MDM option for many devices, but it is less secure: users can still open quick-settings, notifications, and may change the default launcher from Settings.

How it works (implemented in this repo)
- The app includes an intent-filter for `CATEGORY_HOME` so Android lists it as a launcher.
- When chosen as the default Home app, the device returns to your app when Home is pressed.
- To exit the kiosk (admin flow) scan the `EXIT` barcode which should trigger the app to open the system Home selection settings.

Admin exit flow (what we implement)
- The app exposes a method channel `app.kiosk/mode` with `openHomeSettings()` and `isDefaultLauncher()`.
- When the superuser scans the barcode `EXIT` the app should call `openHomeSettings()` which launches the system Home app selection screen. From there the admin can choose another launcher or change defaults.

Limitations
- Not secure: power menu, notifications, long-press UI, and some OEM features let users escape or disrupt the kiosk.
- Not centrally manageable: requires manual steps per device (or scripted via ADB if available).

---

## Recommended deployment for 300+ devices

1. Procure devices that support Android Zero-touch or OEM enrollment (Zebra, Samsung Knox, etc.).
2. Choose an EMM/MDM provider (Android Management API, Microsoft Intune, VMware Workspace ONE, SOTI, Scalefusion, 42Gears, etc.).
3. Configure the MDM policy:
   - Install your app as a required application (Managed Play or pushed APK).
   - Set it as Kiosk/Lock Task package, disable status bar and notifications as needed.
   - Configure Wi-Fi, time zone, and other network settings.
4. Test provisioning on a small batch, then scale using reseller zero-touch or EMM bulk enrollment.

---

## Quick reference commands

- Install APK (local):
```bash
adb install -r app-release.apk
```

- Set device owner (factory-reset device only):
```bash
adb shell dpm set-device-owner com.your.package/.MyDeviceAdminReceiver
```

- Open Home settings (from app): uses `android.settings.HOME_SETTINGS` intent, implemented in `MainActivity`.

---

## Files changed / added for fallback launcher

- `android/app/src/main/AndroidManifest.xml` — added `CATEGORY_HOME` intent-filter.
- `android/app/src/main/kotlin/com/universal/universal_app/MainActivity.kt` — added `app.kiosk/mode` MethodChannel with `openHomeSettings()` and `isDefaultLauncher()`.
- `lib/core/services/kiosk_service.dart` — Flutter wrapper for the MethodChannel.

---

If you want, I can:
- Add a simple admin PIN flow that unlocks additional actions when the `EXIT` barcode is scanned, or
- Implement the Device Owner native code path (DeviceAdminReceiver, setLockTaskPackages) and a provisioning README describing exact MDM steps.

Tell me which you'd prefer next.
