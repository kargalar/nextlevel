# NextLevel privacy and Google Play update

Checked on 2026-08-01.

## Current mismatch

The published privacy policy (effective 2025-10-18) says that the app is
entirely offline, does not require internet access, and never transfers data.
That is no longer accurate because NextLevel now offers optional Google Drive
backup/restore and Google sign-in. The in-app page-view analytics remains local
to the device and is not sent to the developer or an analytics provider.

Update the hosted policy before releasing this version. At minimum, describe:

- Tasks, routines, logs, traits, store data, notes, projects, settings and
  attachments are stored locally by default.
- If the user connects Google Drive, the app uploads encrypted-in-transit ZIP
  snapshots to the user's private Google Drive `appDataFolder` and can download
  them for restore. The app retains up to five snapshots.
- Google sign-in provides the selected account identity to establish the Drive
  session. The developer does not run a separate account server for this flow.
- Automatic backup is optional and can be disabled; Drive can be disconnected,
  and individual cloud snapshots can be deleted from the app.
- Page-view analytics is stored only on the device, capped at 500 events, can be
  reviewed and cleared in Settings, and is not transmitted to the developer.
- Notification and exact-alarm permissions are used only for task and timer
  reminders. Attachment access is used only for files the user selects.
- Include the effective date, retention/deletion behavior, security limits,
  contact address, and links to Google's privacy terms for Drive/sign-in.

## Play Console checklist

- Replace the Play Console privacy-policy URL with the direct policy page:
  `https://kargalar.github.io/nextlevel_privacy2/privacy-policy/`.
- Re-review Data safety for optional Google Drive backup and Google sign-in.
  Google Play's official guidance has a narrow exception for a user choosing to
  upload directly to their own cloud account when the developer does not collect
  or access that data. Automatic backups after opt-in make an accurate, cautious
  disclosure especially important; save the final determination with release
  records.
- Do not declare remote analytics for this build: no remote analytics SDK is
  included and page events remain on-device.
- Confirm the app is not enrolled in Families unless the policy and app meet all
  Families requirements; the current public policy's “all ages” wording is not a
  substitute for a target-audience declaration.
- Review the exact-alarm permission declaration. This build uses
  `SCHEDULE_EXACT_ALARM` with a runtime user grant and no longer declares the
  restricted `USE_EXACT_ALARM` permission.

This document is an engineering checklist, not legal advice.
