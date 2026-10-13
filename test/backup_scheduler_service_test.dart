import 'package:flutter_test/flutter_test.dart';
import 'package:next_level/Service/backup_scheduler_service.dart';

void main() {
  group('BackupFrequency', () {
    test('uses daily for missing and unknown stored values', () {
      expect(
        BackupFrequency.fromPreference(null),
        BackupFrequency.daily,
      );
      expect(
        BackupFrequency.fromPreference('unsupported'),
        BackupFrequency.daily,
      );
    });

    test('maps stored values to their scheduling intervals', () {
      expect(
        BackupFrequency.fromPreference('daily').interval,
        const Duration(days: 1),
      );
      expect(
        BackupFrequency.fromPreference('weekly').interval,
        const Duration(days: 7),
      );
      expect(
        BackupFrequency.fromPreference('monthly').interval,
        const Duration(days: 30),
      );
    });
  });

  group('automaticBackupStartupWarning', () {
    test('reports the session error when automatic backup is enabled', () {
      final warning = automaticBackupStartupWarning(
        enabled: true,
        signedIn: false,
        lastError: 'OAuth session expired',
      );

      expect(warning, contains('OAuth session expired'));
    });

    test('does not warn when backup is disabled or the session is active', () {
      expect(
        automaticBackupStartupWarning(
          enabled: false,
          signedIn: false,
          lastError: 'OAuth session expired',
        ),
        isNull,
      );
      expect(
        automaticBackupStartupWarning(
          enabled: true,
          signedIn: true,
          lastError: null,
        ),
        isNull,
      );
    });
  });

  group('automatic backup scheduling helpers', () {
    test('recognizes periodic and immediate worker task names', () {
      expect(isAutomaticBackupTask(BackupSchedulerService.taskName), isTrue);
      expect(
        isAutomaticBackupTask(BackupSchedulerService.immediateTaskName),
        isTrue,
      );
      expect(isAutomaticBackupTask('unrelated'), isFalse);
    });

    test('catch-up backup is due only after the selected interval', () {
      final now = DateTime.utc(2026, 8, 1, 12);

      expect(
        isAutomaticBackupDue(
          lastSuccess: null,
          now: now,
          frequency: BackupFrequency.daily,
        ),
        isTrue,
      );
      expect(
        isAutomaticBackupDue(
          lastSuccess: now.subtract(const Duration(hours: 23)),
          now: now,
          frequency: BackupFrequency.daily,
        ),
        isFalse,
      );
      expect(
        isAutomaticBackupDue(
          lastSuccess: now.subtract(const Duration(hours: 25)),
          now: now,
          frequency: BackupFrequency.daily,
        ),
        isTrue,
      );
    });
  });
}
