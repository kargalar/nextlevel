import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Service/backup_service.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

bool _backgroundStorageInitialized = false;

bool isAutomaticBackupTask(String taskName) {
  return taskName == BackupSchedulerService.taskName ||
      taskName == BackupSchedulerService.uniqueTaskName ||
      taskName == BackupSchedulerService.immediateTaskName ||
      taskName == Workmanager.iOSBackgroundTask;
}

bool isAutomaticBackupDue({
  required DateTime? lastSuccess,
  required DateTime now,
  required BackupFrequency frequency,
}) {
  if (lastSuccess == null) return true;
  return now.toUtc().difference(lastSuccess.toUtc()) >= frequency.interval;
}

enum BackupFrequency {
  daily(
    interval: Duration(days: 1),
    label: 'Daily',
    scheduleDescription: 'approximately once per day',
  ),
  weekly(
    interval: Duration(days: 7),
    label: 'Weekly',
    scheduleDescription: 'approximately once per week',
  ),
  monthly(
    interval: Duration(days: 30),
    label: 'Monthly',
    scheduleDescription: 'approximately every 30 days',
  );

  const BackupFrequency({
    required this.interval,
    required this.label,
    required this.scheduleDescription,
  });

  final Duration interval;
  final String label;
  final String scheduleDescription;

  static BackupFrequency fromPreference(String? value) {
    return BackupFrequency.values.firstWhere(
      (frequency) => frequency.name == value,
      orElse: () => BackupFrequency.daily,
    );
  }
}

String? automaticBackupStartupWarning({
  required bool enabled,
  required bool signedIn,
  required String? lastError,
}) {
  if (!enabled || signedIn) return null;

  final detail = lastError?.trim();
  if (detail == null || detail.isEmpty) {
    return 'Google Drive automatic backup session could not be restored. '
        'Reconnect Google Drive.';
  }

  return 'Google Drive automatic backup session could not be restored: $detail';
}

@pragma('vm:entry-point')
void driveBackupCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    if (!isAutomaticBackupTask(taskName)) {
      return true;
    }

    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(BackupSchedulerService.enabledPreference) ?? false)) {
      return true;
    }

    final attemptTime = DateTime.now().toUtc();
    await prefs.setString(
      BackupSchedulerService.lastAttemptPreference,
      attemptTime.toIso8601String(),
    );

    try {
      if (!_backgroundStorageInitialized) {
        await Helper().registerAdapters();
        _backgroundStorageInitialized = true;
      }

      final wifiOnly =
          prefs.getBool(BackupSchedulerService.wifiOnlyPreference) ?? true;
      final result = await BackupService().backupData(
        wifiOnly: wifiOnly,
        interactiveSignIn: false,
      );

      if (result.isSuccess) {
        await prefs.setBool('local_first_sync_dirty', false);
        await prefs.setString(
          'local_first_sync_last_success',
          DateTime.now().toUtc().toIso8601String(),
        );
        await prefs.remove(BackupSchedulerService.lastErrorPreference);
        return true;
      }

      final message = result.message ?? result.status.name;
      await prefs.setString(
        BackupSchedulerService.lastErrorPreference,
        message,
      );

      // Authentication and policy skips need user action, not a tight retry.
      return result.status == BackupOperationStatus.notSignedIn ||
          result.status == BackupOperationStatus.wifiRequired ||
          result.status == BackupOperationStatus.notSupported;
    } catch (error, stackTrace) {
      await prefs.setString(
        BackupSchedulerService.lastErrorPreference,
        error.toString(),
      );
      LogService.error('Automatic Drive backup failed: $error\n$stackTrace');
      return false;
    }
  });
}

class BackupSchedulerService {
  static const String uniqueTaskName = 'app.nextlevel.driveBackup';
  static const String taskName = 'autoBackupTask';
  static const String immediateUniqueTaskName =
      'app.nextlevel.driveBackup.immediate';
  static const String immediateTaskName = 'autoBackupImmediateTask';
  static const String enabledPreference = 'auto_backup_enabled';
  static const String wifiOnlyPreference = 'backup_wifi_only';
  static const String frequencyPreference = 'drive_backup_frequency';
  static const String lastAttemptPreference = 'drive_backup_last_attempt';
  static const String lastErrorPreference = 'drive_backup_last_error';
  static const String _legacyUniqueTaskName = '1';

  static bool _initialized = false;

  static bool get isSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  Future<void> initialize() async {
    if (!isSupported || _initialized) return;
    await Workmanager().initialize(driveBackupCallbackDispatcher);
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(enabledPreference) ?? false;
    final wifiOnly = prefs.getBool(wifiOnlyPreference) ?? true;
    final frequency = BackupFrequency.fromPreference(
      prefs.getString(frequencyPreference),
    );
    await configure(
      enabled: enabled,
      wifiOnly: wifiOnly,
      frequency: frequency,
      persist: false,
    );
  }

  Future<void> configure({
    required bool enabled,
    required bool wifiOnly,
    required BackupFrequency frequency,
    bool persist = true,
  }) async {
    SharedPreferences? prefs;
    bool? previousEnabled;
    bool? previousWifiOnly;
    String? previousFrequency;
    if (persist) {
      prefs = await SharedPreferences.getInstance();
      previousEnabled = prefs.getBool(enabledPreference);
      previousWifiOnly = prefs.getBool(wifiOnlyPreference);
      previousFrequency = prefs.getString(frequencyPreference);
      await prefs.setBool(enabledPreference, enabled);
      await prefs.setBool(wifiOnlyPreference, wifiOnly);
      await prefs.setString(frequencyPreference, frequency.name);
    }
    if (!isSupported) return;

    try {
      if (!_initialized) {
        await Workmanager().initialize(driveBackupCallbackDispatcher);
        _initialized = true;
      }

      // Remove the task identifier used by the unfinished implementation.
      await Workmanager().cancelByUniqueName(_legacyUniqueTaskName);
      if (!enabled) {
        await Workmanager().cancelByUniqueName(uniqueTaskName);
        return;
      }

      final constraints = Constraints(
        networkType: wifiOnly ? NetworkType.unmetered : NetworkType.connected,
        requiresBatteryNotLow: true,
        requiresStorageNotLow: true,
      );

      await Workmanager().registerPeriodicTask(
        uniqueTaskName,
        taskName,
        frequency: frequency.interval,
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 30),
        constraints: constraints,
      );

      // Periodic work is intentionally inexact and may not run for many hours.
      // Queue one immediate catch-up on Android when the latest snapshot is due
      // so enabling automatic backup has an observable result.
      if (Platform.isAndroid) {
        final currentPrefs = prefs ?? await SharedPreferences.getInstance();
        final lastSuccess = DateTime.tryParse(
          currentPrefs.getString(BackupService.lastSuccessPreference) ?? '',
        );
        if (isAutomaticBackupDue(
          lastSuccess: lastSuccess,
          now: DateTime.now(),
          frequency: frequency,
        )) {
          await currentPrefs.setBool('local_first_sync_dirty', true);
          await Workmanager().registerOneOffTask(
            immediateUniqueTaskName,
            immediateTaskName,
            initialDelay: const Duration(seconds: 10),
            existingWorkPolicy: ExistingWorkPolicy.replace,
            backoffPolicy: BackoffPolicy.exponential,
            backoffPolicyDelay: const Duration(minutes: 30),
            constraints: constraints,
          );
        }
      }
    } catch (_) {
      if (persist && prefs != null) {
        if (previousEnabled == null) {
          await prefs.remove(enabledPreference);
        } else {
          await prefs.setBool(enabledPreference, previousEnabled);
        }
        if (previousWifiOnly == null) {
          await prefs.remove(wifiOnlyPreference);
        } else {
          await prefs.setBool(wifiOnlyPreference, previousWifiOnly);
        }
        if (previousFrequency == null) {
          await prefs.remove(frequencyPreference);
        } else {
          await prefs.setString(frequencyPreference, previousFrequency);
        }
      }
      rethrow;
    }
  }
}
