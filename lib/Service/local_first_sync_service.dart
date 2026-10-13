import 'dart:async';

import 'package:next_level/Service/backup_scheduler_service.dart';
import 'package:next_level/Service/backup_service.dart';
import 'package:next_level/Service/data_mutation_notifier.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Debounced local-first synchronization using the existing private Drive
/// snapshot transport. Local writes always complete first; remote backup never
/// blocks the feature that produced the mutation.
class LocalFirstSyncService {
  static const Duration minimumSyncInterval = Duration(minutes: 5);
  static const Duration retryInterval = Duration(minutes: 15);
  static const String dirtyPreference = 'local_first_sync_dirty';
  static const String lastSyncPreference = 'local_first_sync_last_success';
  static const String lastErrorPreference = 'local_first_sync_last_error';

  static final LocalFirstSyncService _instance =
      LocalFirstSyncService._internal();
  factory LocalFirstSyncService() => _instance;
  LocalFirstSyncService._internal();

  StreamSubscription<String>? _subscription;
  Timer? _debounce;
  bool _syncing = false;

  Future<void> initialize() async {
    if (!BackupService.isSupported || _subscription != null) return;

    _subscription = DataMutationNotifier().changes.listen((entity) {
      _markDirtyAndSchedule(entity);
    });

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(dirtyPreference) == true) {
      _schedule(const Duration(seconds: 5));
    }
  }

  Future<void> _markDirtyAndSchedule(String entity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(dirtyPreference, true);
    LogService.debug('Local-first sync marked dirty by $entity');
    _schedule(const Duration(seconds: 20));
  }

  void _schedule(Duration delay) {
    _debounce?.cancel();
    _debounce = Timer(delay, syncNow);
  }

  Future<bool> syncNow() async {
    if (_syncing || !BackupService.isSupported) return false;

    final prefs = await SharedPreferences.getInstance();
    final enabled =
        prefs.getBool(BackupSchedulerService.enabledPreference) ?? false;
    if (!enabled || prefs.getBool(dirtyPreference) != true) return false;

    final lastSyncRaw = prefs.getString(lastSyncPreference);
    final lastSync =
        lastSyncRaw == null ? null : DateTime.tryParse(lastSyncRaw)?.toLocal();
    if (lastSync != null) {
      final elapsed = DateTime.now().difference(lastSync);
      if (elapsed < minimumSyncInterval) {
        _schedule(minimumSyncInterval - elapsed);
        return false;
      }
    }

    _syncing = true;
    try {
      final account = await BackupService().initialize();
      if (account == null) {
        await prefs.setString(
          lastErrorPreference,
          BackupService().lastError ?? 'Google Drive session is unavailable.',
        );
        _schedule(retryInterval);
        return false;
      }

      final wifiOnly =
          prefs.getBool(BackupSchedulerService.wifiOnlyPreference) ?? true;
      final result = await BackupService().backupData(
        wifiOnly: wifiOnly,
        interactiveSignIn: false,
      );

      if (result.isSuccess) {
        await prefs.setBool(dirtyPreference, false);
        await prefs.setString(
          lastSyncPreference,
          DateTime.now().toUtc().toIso8601String(),
        );
        await prefs.remove(lastErrorPreference);
        return true;
      }

      await prefs.setString(
        lastErrorPreference,
        result.message ?? result.status.name,
      );
      _schedule(retryInterval);
      return false;
    } catch (error, stackTrace) {
      await prefs.setString(lastErrorPreference, error.toString());
      LogService.error('Local-first sync failed: $error\n$stackTrace');
      _schedule(retryInterval);
      return false;
    } finally {
      _syncing = false;
    }
  }
}
