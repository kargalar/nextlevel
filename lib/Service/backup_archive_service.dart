import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;

import 'package:next_level/Service/logging_service.dart';

class BackupArchiveService {
  static const String backupJsonFileName = 'gamify_todo_backup.json';
  static const String attachmentsFolderName = 'attachments';
  static const int _maxArchiveEntries = 10000;
  static const int _maxUncompressedBytes = 2 * 1024 * 1024 * 1024;

  Future<void> createZipFromDirectory({
    required Directory sourceDirectory,
    required String zipFilePath,
  }) async {
    final zipFile = File(zipFilePath);
    if (await zipFile.exists()) {
      await zipFile.delete();
    }

    final encoder = ZipFileEncoder();
    encoder.create(zipFilePath);

    try {
      await for (final entity
          in sourceDirectory.list(recursive: true, followLinks: false)) {
        if (entity is! File) {
          continue;
        }

        if (!await entity.exists()) {
          LogService.error(
              '⚠️ BackupArchiveService: Skipping missing file during zip: ${entity.path}');
          continue;
        }

        final relativePath =
            path.relative(entity.path, from: sourceDirectory.path);
        final archivePath = path.posix.joinAll(path.split(relativePath));

        try {
          await encoder.addFile(entity, archivePath);
        } catch (e) {
          LogService.error(
              '❌ BackupArchiveService: Failed to add file to zip: ${entity.path} - $e');
          if (path.basename(entity.path) == backupJsonFileName) {
            rethrow;
          }
        }
      }
    } finally {
      await encoder.close();
    }

    if (!await zipFile.exists() || await zipFile.length() == 0) {
      throw Exception('Backup archive could not be created.');
    }
  }

  Future<File?> findBackupJsonFile(Directory extractedRoot) async {
    if (!await extractedRoot.exists()) {
      return null;
    }

    await for (final entity
        in extractedRoot.list(recursive: true, followLinks: false)) {
      if (entity is File && path.basename(entity.path) == backupJsonFileName) {
        return entity;
      }
    }

    return null;
  }

  /// Extracts a backup while rejecting path traversal, symbolic links and
  /// unexpectedly large archives before anything is written to disk.
  Future<void> extractZipSafely({
    required File zipFile,
    required Directory destinationDirectory,
  }) async {
    if (!await zipFile.exists()) {
      throw const FileSystemException('Backup archive does not exist.');
    }

    await destinationDirectory.create(recursive: true);
    final input = InputFileStream(zipFile.path);

    try {
      final archive = ZipDecoder().decodeStream(input);
      if (archive.length > _maxArchiveEntries) {
        throw const FormatException('Backup archive contains too many files.');
      }

      var totalSize = 0;
      final destinationRoot = path.canonicalize(destinationDirectory.path);

      for (final entry in archive) {
        final normalizedName = path.normalize(entry.name);
        final destinationPath = path.canonicalize(
          path.join(destinationRoot, normalizedName),
        );

        if (entry.isSymbolicLink ||
            path.isAbsolute(normalizedName) ||
            (!path.isWithin(destinationRoot, destinationPath) &&
                destinationPath != destinationRoot)) {
          throw const FormatException(
              'Backup archive contains an unsafe path.');
        }

        if (entry.isFile) {
          totalSize += entry.size;
          if (totalSize > _maxUncompressedBytes) {
            throw const FormatException('Backup archive is too large.');
          }
        }
      }

      for (final entry in archive) {
        final destinationPath = path.canonicalize(
          path.join(destinationRoot, path.normalize(entry.name)),
        );
        if (entry.isDirectory) {
          await Directory(destinationPath).create(recursive: true);
          continue;
        }

        await File(destinationPath).parent.create(recursive: true);
        final output = OutputFileStream(destinationPath);
        try {
          entry.writeContent(output);
        } finally {
          await output.close();
        }
      }
    } finally {
      await input.close();
    }
  }

  Future<Directory?> findAttachmentsDirectory({
    required Directory extractedRoot,
    Directory? preferredRoot,
  }) async {
    if (preferredRoot != null) {
      final preferredAttachmentsDir =
          Directory(path.join(preferredRoot.path, attachmentsFolderName));
      if (await preferredAttachmentsDir.exists()) {
        return preferredAttachmentsDir;
      }
    }

    if (!await extractedRoot.exists()) {
      return null;
    }

    await for (final entity
        in extractedRoot.list(recursive: true, followLinks: false)) {
      if (entity is Directory &&
          path.basename(entity.path) == attachmentsFolderName) {
        return entity;
      }
    }

    return null;
  }

  Future<Map<String, String>> restoreAttachments({
    required Directory sourceDirectory,
    required Directory destinationDirectory,
  }) async {
    final restoredFiles = <String, String>{};

    if (!await sourceDirectory.exists()) {
      return restoredFiles;
    }

    await destinationDirectory.create(recursive: true);

    await for (final entity
        in sourceDirectory.list(recursive: true, followLinks: false)) {
      if (entity is! File) {
        continue;
      }

      if (!await entity.exists()) {
        LogService.error(
            '⚠️ BackupArchiveService: Attachment disappeared before restore: ${entity.path}');
        continue;
      }

      final fileName = path.basename(entity.path);
      final restoredPath = path.join(destinationDirectory.path, fileName);
      final restoredFile = await entity.copy(restoredPath);
      restoredFiles[fileName] = restoredFile.path;
    }

    return restoredFiles;
  }
}
