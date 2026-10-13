# NextLevel privacy and store release checklist

## Current data behavior

- Tasks, routines, logs, notes, projects and local analytics are stored on the device.
- Local analytics records page-view event names and timestamps only. It does not send data to a third party.
- Google Drive backup/sync is opt-in and uses the private `appDataFolder` scope.
- Alarm, notification and file permissions are requested only when the related feature needs them.

## Privacy policy updates

The published policy should explicitly state:

1. Which task/profile data is stored locally.
2. That optional Google Drive backup uploads an encrypted-transport snapshot to the user's private Drive app-data area.
3. That local page analytics stays on-device unless a future remote analytics provider is enabled with consent.
4. How users can export, delete and restore their data.
5. Contact information and the policy's last-updated date.

## Google Play Data safety

- Declare Google Drive backup as optional user-initiated/opt-in cloud storage.
- Do not declare local-only analytics as data shared with third parties.
- Recheck notification, exact alarm and full-screen intent declarations before every release.
- Explain the core alarm/timer use case if Play Console requests exact-alarm justification.
- Upload an Android App Bundle (`.aab`). Google Play does not accept a Windows desktop package.

## Windows release

- Build with `flutter build windows --release`.
- Publish the Windows package through the Microsoft Store, GitHub Releases, or a direct installer.
- Google Play Games on PC distributes compatible Android builds; it does not distribute the Flutter Windows binary.
