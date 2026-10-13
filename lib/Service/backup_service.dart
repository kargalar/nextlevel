import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:next_level/Service/google_auth_client.dart';
import 'package:next_level/Service/hive_service.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BackupOperationStatus {
  success,
  notSupported,
  notSignedIn,
  wifiRequired,
  noBackupFound,
  busy,
  failed,
}

class BackupOperationResult {
  const BackupOperationResult(
    this.status, {
    this.message,
    this.error,
  });

  final BackupOperationStatus status;
  final String? message;
  final Object? error;

  bool get isSuccess => status == BackupOperationStatus.success;
}

class DriveBackupInfo {
  const DriveBackupInfo({
    required this.id,
    required this.name,
    this.modifiedTime,
    this.size,
    this.sha256Checksum,
    this.schemaVersion,
  });

  final String id;
  final String name;
  final DateTime? modifiedTime;
  final int? size;
  final String? sha256Checksum;
  final int? schemaVersion;

  factory DriveBackupInfo.fromDriveFile(drive.File file) {
    final properties = file.appProperties ?? const <String, String?>{};
    return DriveBackupInfo(
      id: file.id!,
      name: file.name ?? 'NextLevel backup',
      modifiedTime: file.modifiedTime,
      size: int.tryParse(file.size ?? ''),
      sha256Checksum: properties['sha256'],
      schemaVersion: int.tryParse(properties['schemaVersion'] ?? ''),
    );
  }
}

class BackupService {
  static final BackupService _instance = BackupService._internal();

  factory BackupService() => _instance;

  BackupService._internal() : _googleSignIn = _createGoogleSignIn();

  static const String backupNamePrefix = 'nextlevel_backup_';
  static const int retainedBackupCount = 5;
  static const String lastSuccessPreference = 'drive_backup_last_success';
  static const String lastRestorePreference = 'drive_backup_last_restore';

  // The legacy Apple OAuth client remains the default for existing builds.
  // It can be replaced without a code change using --dart-define.
  static const String _appleClientId = String.fromEnvironment(
    'GOOGLE_APPLE_CLIENT_ID',
    defaultValue:
        '769104090883-c53kfsm3t0aqd01s1qrophlrv2ljbhbh.apps.googleusercontent.com',
  );

  final GoogleSignIn _googleSignIn;
  GoogleSignInAccount? _currentUser;
  bool _operationInProgress = false;
  String? _lastError;

  static GoogleSignIn _createGoogleSignIn() {
    String? clientId;
    if (!kIsWeb && Platform.isIOS) {
      clientId = _appleClientId;
    }
    return GoogleSignIn(
      clientId: clientId,
      scopes: const [drive.DriveApi.driveAppdataScope],
    );
  }

  static bool get isSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  GoogleSignInAccount? get currentUser =>
      _currentUser ?? _googleSignIn.currentUser;

  String? get lastError => _lastError;

  Future<GoogleSignInAccount?> initialize() async {
    if (!isSupported) return null;
    try {
      _lastError = null;
      _currentUser = _googleSignIn.currentUser;
      _currentUser ??= await _googleSignIn.signInSilently();
      return _currentUser;
    } catch (error, stackTrace) {
      _recordError('Silent Google sign-in failed', error, stackTrace);
      return null;
    }
  }

  Future<GoogleSignInAccount?> signIn() async {
    if (!isSupported) return null;
    try {
      _lastError = null;
      _currentUser = _googleSignIn.currentUser;
      _currentUser ??= await _googleSignIn.signInSilently();
      _currentUser ??= await _googleSignIn.signIn();
      return _currentUser;
    } catch (error, stackTrace) {
      _recordError('Google sign-in failed', error, stackTrace);
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      if (_googleSignIn.currentUser != null || _currentUser != null) {
        await _googleSignIn.disconnect();
      } else {
        await _googleSignIn.signOut();
      }
    } catch (error, stackTrace) {
      _recordError('Google sign-out failed', error, stackTrace);
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // The local account is still cleared below so the UI remains coherent.
      }
    } finally {
      _currentUser = null;
    }
  }

  Future<List<DriveBackupInfo>> listBackups({
    bool interactiveSignIn = false,
  }) async {
    final session = await _openDriveSession(interactive: interactiveSignIn);
    if (session == null) return const [];

    try {
      final backups = await _listBackups(session.api);
      _lastError = null;
      return backups;
    } catch (error, stackTrace) {
      _recordError('Listing Drive backups failed', error, stackTrace);
      return const [];
    } finally {
      session.close();
    }
  }

  Future<DateTime?> getLastBackupTime() async {
    final backups = await listBackups();
    return backups.isEmpty ? null : backups.first.modifiedTime;
  }

  Future<BackupOperationResult> backupData({
    bool wifiOnly = false,
    bool interactiveSignIn = true,
  }) async {
    if (!isSupported) {
      return const BackupOperationResult(
        BackupOperationStatus.notSupported,
        message: 'Google Drive backup is not supported on this platform.',
      );
    }
    if (_operationInProgress) {
      return const BackupOperationResult(
        BackupOperationStatus.busy,
        message: 'Another backup operation is already running.',
      );
    }

    _operationInProgress = true;
    Directory? workingDirectory;
    _DriveSession? session;
    try {
      if (wifiOnly && !await _isOnWifi()) {
        return const BackupOperationResult(
          BackupOperationStatus.wifiRequired,
          message: 'A Wi-Fi connection is required by your backup settings.',
        );
      }

      session = await _openDriveSession(interactive: interactiveSignIn);
      if (session == null) {
        return const BackupOperationResult(
          BackupOperationStatus.notSignedIn,
          message: 'Google Drive is not connected.',
        );
      }

      final temporaryRoot = await getTemporaryDirectory();
      workingDirectory = Directory(
        path.join(
          temporaryRoot.path,
          'nextlevel_drive_backup_${DateTime.now().microsecondsSinceEpoch}',
        ),
      );
      await workingDirectory.create(recursive: true);

      final archiveFile = await HiveService().createBackupArchive(
        outputDirectory: workingDirectory,
      );
      final checksum = await _sha256Of(archiveFile);
      final length = await archiveFile.length();
      final createdAt = DateTime.now().toUtc();

      final remoteMetadata = drive.File()
        ..name = path.basename(archiveFile.path)
        ..mimeType = 'application/zip'
        ..parents = ['appDataFolder']
        ..description = 'NextLevel application data backup'
        ..appProperties = {
          'source': 'nextlevel',
          'schemaVersion': '1',
          'createdAt': createdAt.toIso8601String(),
          'sha256': checksum,
        };

      final media = drive.Media(archiveFile.openRead(), length);
      await session.api.files.create(
        remoteMetadata,
        uploadMedia: media,
        $fields: 'id,name,modifiedTime,size,appProperties',
      );

      await _pruneOldBackups(session.api);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        lastSuccessPreference,
        createdAt.toIso8601String(),
      );
      await prefs.setBool('local_first_sync_dirty', false);
      await prefs.setString(
        'local_first_sync_last_success',
        createdAt.toIso8601String(),
      );
      await prefs.remove('local_first_sync_last_error');
      _lastError = null;
      return const BackupOperationResult(BackupOperationStatus.success);
    } catch (error, stackTrace) {
      _recordError('Google Drive backup failed', error, stackTrace);
      return BackupOperationResult(
        BackupOperationStatus.failed,
        message: 'Backup could not be uploaded to Google Drive.',
        error: error,
      );
    } finally {
      session?.close();
      await _deleteDirectoryQuietly(workingDirectory);
      _operationInProgress = false;
    }
  }

  Future<BackupOperationResult> restoreData({
    DriveBackupInfo? backup,
    bool interactiveSignIn = true,
  }) async {
    if (!isSupported) {
      return const BackupOperationResult(
        BackupOperationStatus.notSupported,
        message: 'Google Drive restore is not supported on this platform.',
      );
    }
    if (_operationInProgress) {
      return const BackupOperationResult(
        BackupOperationStatus.busy,
        message: 'Another backup operation is already running.',
      );
    }

    _operationInProgress = true;
    Directory? workingDirectory;
    _DriveSession? session;
    try {
      session = await _openDriveSession(interactive: interactiveSignIn);
      if (session == null) {
        return const BackupOperationResult(
          BackupOperationStatus.notSignedIn,
          message: 'Google Drive is not connected.',
        );
      }

      final availableBackups = await _listBackups(session.api);
      if (availableBackups.isEmpty) {
        return const BackupOperationResult(
          BackupOperationStatus.noBackupFound,
          message: 'No Google Drive backup was found.',
        );
      }

      final selectedBackup = backup == null
          ? availableBackups.first
          : availableBackups.firstWhere(
              (item) => item.id == backup.id,
              orElse: () => throw const FormatException(
                'The selected Drive backup no longer exists.',
              ),
            );

      final mediaResponse = await session.api.files.get(
        selectedBackup.id,
        downloadOptions: drive.DownloadOptions.fullMedia,
      );
      if (mediaResponse is! drive.Media) {
        throw const FormatException(
            'Google Drive returned invalid backup data.');
      }

      final temporaryRoot = await getTemporaryDirectory();
      workingDirectory = Directory(
        path.join(
          temporaryRoot.path,
          'nextlevel_drive_restore_${DateTime.now().microsecondsSinceEpoch}',
        ),
      );
      await workingDirectory.create(recursive: true);

      final downloadedArchive = File(
        path.join(workingDirectory.path, 'downloaded_backup.zip'),
      );
      final sink = downloadedArchive.openWrite();
      await mediaResponse.stream.pipe(sink);

      final expectedSize = selectedBackup.size;
      if (expectedSize != null &&
          await downloadedArchive.length() != expectedSize) {
        throw const FormatException('The downloaded backup is incomplete.');
      }
      final expectedChecksum = selectedBackup.sha256Checksum;
      if (expectedChecksum != null &&
          expectedChecksum.isNotEmpty &&
          await _sha256Of(downloadedArchive) != expectedChecksum) {
        throw const FormatException(
            'The downloaded backup failed its integrity check.');
      }

      // Keep a local rollback point until the cloud archive is fully restored.
      final safetyArchive = await HiveService().createBackupArchive(
        outputDirectory: workingDirectory,
      );
      try {
        await HiveService().importData(
          archiveFile: downloadedArchive,
          showUi: false,
          restartApp: false,
        );
      } catch (restoreError, restoreStackTrace) {
        LogService.error(
          'Drive restore failed; attempting local rollback: $restoreError\n'
          '$restoreStackTrace',
        );
        try {
          await HiveService().importData(
            archiveFile: safetyArchive,
            showUi: false,
            restartApp: false,
          );
        } catch (rollbackError, rollbackStackTrace) {
          LogService.error(
            'Local rollback also failed: $rollbackError\n$rollbackStackTrace',
          );
        }
        rethrow;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        lastRestorePreference,
        DateTime.now().toUtc().toIso8601String(),
      );
      _lastError = null;
      return const BackupOperationResult(BackupOperationStatus.success);
    } catch (error, stackTrace) {
      _recordError('Google Drive restore failed', error, stackTrace);
      return BackupOperationResult(
        BackupOperationStatus.failed,
        message: 'The Google Drive backup could not be restored.',
        error: error,
      );
    } finally {
      session?.close();
      await _deleteDirectoryQuietly(workingDirectory);
      _operationInProgress = false;
    }
  }

  Future<BackupOperationResult> deleteBackup(DriveBackupInfo backup) async {
    if (_operationInProgress) {
      return const BackupOperationResult(BackupOperationStatus.busy);
    }
    _operationInProgress = true;
    _DriveSession? session;
    try {
      session = await _openDriveSession(interactive: true);
      if (session == null) {
        return const BackupOperationResult(BackupOperationStatus.notSignedIn);
      }
      final backups = await _listBackups(session.api);
      if (!backups.any((item) => item.id == backup.id)) {
        return const BackupOperationResult(BackupOperationStatus.noBackupFound);
      }
      await session.api.files.delete(backup.id);
      return const BackupOperationResult(BackupOperationStatus.success);
    } catch (error, stackTrace) {
      _recordError('Deleting Drive backup failed', error, stackTrace);
      return BackupOperationResult(
        BackupOperationStatus.failed,
        error: error,
      );
    } finally {
      session?.close();
      _operationInProgress = false;
    }
  }

  Future<_DriveSession?> _openDriveSession({required bool interactive}) async {
    if (!isSupported) return null;
    GoogleSignInAccount? user = currentUser;
    user ??= await initialize();
    if (user == null && interactive) {
      user = await signIn();
    }
    if (user == null) return null;

    final headers = await user.authHeaders;
    if (headers.isEmpty) return null;
    final client = GoogleAuthClient(headers);
    return _DriveSession(drive.DriveApi(client), client);
  }

  Future<List<DriveBackupInfo>> _listBackups(drive.DriveApi api) async {
    final files = <drive.File>[];
    String? pageToken;
    do {
      final response = await api.files.list(
        q: "trashed = false and 'appDataFolder' in parents and "
            "name contains '$backupNamePrefix'",
        spaces: 'appDataFolder',
        orderBy: 'modifiedTime desc',
        pageSize: 100,
        pageToken: pageToken,
        $fields: 'nextPageToken,files(id,name,modifiedTime,size,appProperties)',
      );
      files.addAll(response.files ?? const <drive.File>[]);
      pageToken = response.nextPageToken;
    } while (pageToken != null && pageToken.isNotEmpty);

    return files
        .where((file) => file.id != null)
        .map(DriveBackupInfo.fromDriveFile)
        .toList(growable: false);
  }

  Future<void> _pruneOldBackups(drive.DriveApi api) async {
    try {
      final backups = await _listBackups(api);
      for (final oldBackup in backups.skip(retainedBackupCount)) {
        await api.files.delete(oldBackup.id);
      }
    } catch (error, stackTrace) {
      _recordError('Old Drive backup cleanup failed', error, stackTrace);
    }
  }

  Future<bool> _isOnWifi() async {
    final results = await Connectivity().checkConnectivity();
    return results.contains(ConnectivityResult.wifi);
  }

  Future<String> _sha256Of(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  Future<void> _deleteDirectoryQuietly(Directory? directory) async {
    if (directory == null) return;
    try {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    } catch (error, stackTrace) {
      LogService.error(
        'Temporary backup directory cleanup failed: $error\n$stackTrace',
      );
    }
  }

  void _recordError(String context, Object error, StackTrace stackTrace) {
    _lastError = _userFacingError(error);
    LogService.error('$context: $error\n$stackTrace');
  }

  String _userFacingError(Object error) {
    if (error is PlatformException &&
        error.code == 'sign_in_failed' &&
        (error.message?.contains('ApiException: 10') ?? false)) {
      return 'Google OAuth configuration does not match this Android build '
          '(DEVELOPER_ERROR 10). Add the SHA-1 fingerprint of the installed '
          'APK to an Android OAuth client for package app.nextlevel in the '
          'Google Cloud project that has the Drive API enabled.';
    }

    return error.toString();
  }
}

class _DriveSession {
  const _DriveSession(this.api, this.client);

  final drive.DriveApi api;
  final GoogleAuthClient client;

  void close() => client.close();
}
