# Google Drive backup deployment setup

The app code stores up to five versioned ZIP snapshots in Google Drive's
private `appDataFolder`. The folder is hidden from the normal Drive UI and is
accessible only to this OAuth application.

## Google Cloud

1. Enable the **Google Drive API** in the OAuth project used by the mobile app.
2. Configure the OAuth consent screen and request the
   `https://www.googleapis.com/auth/drive.appdata` scope.
3. For Android, create OAuth clients for package `app.nextlevel` for every
   signing certificate that can ship the app: local debug, release, and Google
   Play App Signing SHA-1 fingerprints.
4. For iOS, configure an iOS OAuth client for bundle ID `app.nextlevel`.

Current local Android signing fingerprint. Debug and release builds use the
same release keystore:

- Debug/profile SHA-1: `58:DF:E8:66:42:69:5D:BF:A2:B7:64:F6:7B:A4:67:E5:2A:91:5A:C5`
- Release SHA-1: `58:DF:E8:66:42:69:5D:BF:A2:B7:64:F6:7B:A4:67:E5:2A:91:5A:C5`

Verify them whenever a signing key changes:

```powershell
cd android
.\gradlew.bat :app:signingReport
```

Create a separate Android OAuth client for each SHA-1, always using package
`app.nextlevel`. A Play-distributed build is re-signed by Google, so also add
the **App signing key certificate** SHA-1 shown in Play Console under
**Setup > App integrity**. All clients must belong to the same Google Cloud
project in which the Drive API and consent screen are configured.

`ApiException: 10` / `DEVELOPER_ERROR` means the installed APK's package and
signing certificate do not match any Android OAuth client. It is not a network
or Drive API error. After adding the correct OAuth client, allow time for the
credential to propagate, uninstall the old app (or clear its data), reinstall,
and sign in again.

The Android implementation does not require Firebase or
`google-services.json`. Google Play Services matches the package name and
signing certificate to the Android OAuth client.

## iOS client ID

The existing Apple client ID is the default in `BackupService`. To replace it:

1. Build with
   `--dart-define=GOOGLE_APPLE_CLIENT_ID=<client-id>.apps.googleusercontent.com`.
2. Replace the matching reversed client ID under `CFBundleURLSchemes` in
   `ios/Runner/Info.plist`.

iOS background refresh is opportunistic: the operating system, rather than the
app, decides the exact execution time. The app requests one run per day.

## Release verification

Before publishing each signed build, verify on a physical device that:

- connecting Drive shows the expected Google account and consent screen;
- “Back Up Now” creates a snapshot and reports its size;
- a second installation using the same OAuth project/account can list it;
- restore recovers tasks, routines, preferences, progress, and attachments;
- automatic backup records an attempt after the OS runs the scheduled job.
