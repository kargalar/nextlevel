# NextLevel

NextLevel helps you turn goals into repeatable routines with tasks, reminders, focus timers, streaks, notes, and progress insights.

## Features

- Create one-time tasks, recurring routines, and reusable templates.
- Track progress with timers, streaks, analytics, and a customizable home screen.
- Organize notes and projects alongside your tasks.
- Schedule alarms and reminders, including Android home-screen widgets.
- Back up and restore your data with Google Drive.
- Use voice input and choose its recognition language independently from the English app interface.

## Download

Get the latest Android APK from [GitHub Releases](https://github.com/kargalar/nextlevel/releases/latest). Install the APK manually on Android, or build the app from source.

## Build

Requirements: Flutter, the Android SDK, and a configured Android toolchain.

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Google Drive backup setup is documented in [docs/google_drive_backup_setup.md](docs/google_drive_backup_setup.md). Firebase configuration values in the Android app are public client configuration; never place service-account credentials or private keys in the app.

## License

NextLevel is licensed under the GNU General Public License v3.0. See [LICENSE](LICENSE).
