import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:next_level/Service/backup_service.dart';

void main() {
  test('parses Drive metadata used for restore integrity checks', () {
    final modifiedAt = DateTime.utc(2026, 7, 15, 10, 30);
    final file = drive.File()
      ..id = 'backup-id'
      ..name = 'nextlevel_backup_20260715.zip'
      ..modifiedTime = modifiedAt
      ..size = '4096'
      ..appProperties = {
        'sha256': 'abc123',
        'schemaVersion': '1',
      };

    final info = DriveBackupInfo.fromDriveFile(file);

    expect(info.id, 'backup-id');
    expect(info.name, file.name);
    expect(info.modifiedTime, modifiedAt);
    expect(info.size, 4096);
    expect(info.sha256Checksum, 'abc123');
    expect(info.schemaVersion, 1);
  });

  test('reports operation success only for the success status', () {
    expect(
      const BackupOperationResult(BackupOperationStatus.success).isSuccess,
      isTrue,
    );
    expect(
      const BackupOperationResult(BackupOperationStatus.failed).isSuccess,
      isFalse,
    );
  });
}
