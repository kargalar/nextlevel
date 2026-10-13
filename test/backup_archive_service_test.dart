import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_level/Service/backup_archive_service.dart';
import 'package:path/path.dart' as path;

void main() {
  late Directory sandbox;
  late BackupArchiveService service;

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('nextlevel_backup_test_');
    service = BackupArchiveService();
  });

  tearDown(() async {
    if (await sandbox.exists()) {
      await sandbox.delete(recursive: true);
    }
  });

  test('creates and safely extracts a complete backup archive', () async {
    final source = Directory(path.join(sandbox.path, 'source'));
    final attachments = Directory(path.join(source.path, 'attachments'));
    await attachments.create(recursive: true);
    await File(path.join(source.path, BackupArchiveService.backupJsonFileName))
        .writeAsString('{"_metadata":{"schemaVersion":1}}');
    await File(path.join(attachments.path, 'example.txt'))
        .writeAsString('attachment');

    final zipFile = File(path.join(sandbox.path, 'backup.zip'));
    await service.createZipFromDirectory(
      sourceDirectory: source,
      zipFilePath: zipFile.path,
    );

    final extracted = Directory(path.join(sandbox.path, 'extracted'));
    await service.extractZipSafely(
      zipFile: zipFile,
      destinationDirectory: extracted,
    );

    final jsonFile = await service.findBackupJsonFile(extracted);
    final attachmentDirectory = await service.findAttachmentsDirectory(
      extractedRoot: extracted,
    );
    expect(jsonFile, isNotNull);
    expect(await jsonFile!.readAsString(), contains('schemaVersion'));
    expect(attachmentDirectory, isNotNull);
    expect(
      await File(path.join(attachmentDirectory!.path, 'example.txt'))
          .readAsString(),
      'attachment',
    );
  });

  test('rejects archive entries that escape the destination', () async {
    final archive = Archive()
      ..addFile(ArchiveFile.string('../outside.txt', 'unsafe'));
    final encoded = ZipEncoder().encode(archive);
    final zipFile = File(path.join(sandbox.path, 'malicious.zip'));
    await zipFile.writeAsBytes(encoded);
    final extracted = Directory(path.join(sandbox.path, 'extracted'));

    await expectLater(
      service.extractZipSafely(
        zipFile: zipFile,
        destinationDirectory: extracted,
      ),
      throwsA(isA<FormatException>()),
    );
    expect(File(path.join(sandbox.path, 'outside.txt')).existsSync(), isFalse);
  });
}
