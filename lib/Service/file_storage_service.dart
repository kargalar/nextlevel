import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Provider/task_provider.dart';

class FileStorageService {
  static FileStorageService? _instance;
  static FileStorageService get instance => _instance ??= FileStorageService._();

  FileStorageService._();

  Future<Directory> getAttachmentsDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory('${directory.path}/NextLevel/task_attachments');
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }
    return attachmentsDir;
  }

  Future<List<File>> getAllAttachmentFiles() async {
    try {
      final attachmentsDir = await getAttachmentsDirectory();
      if (await attachmentsDir.exists()) {
        return attachmentsDir.listSync().whereType<File>().toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<int> getTotalStorageSize() async {
    try {
      final files = await getAllAttachmentFiles();
      int totalSize = 0;

      for (final file in files) {
        try {
          totalSize += await file.length();
        } catch (e) {
          // Skip files that can't be accessed
        }
      }

      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final files = await getAllAttachmentFiles();
      int totalSize = 0;
      int imageCount = 0;
      int documentCount = 0;
      int otherCount = 0;

      for (final file in files) {
        try {
          final size = await file.length();
          totalSize += size;

          final extension = file.path.toLowerCase();
          if (extension.contains('.jpg') || extension.contains('.jpeg') || extension.contains('.png') || extension.contains('.gif') || extension.contains('.bmp') || extension.contains('.webp')) {
            imageCount++;
          } else if (extension.contains('.pdf') || extension.contains('.doc') || extension.contains('.docx') || extension.contains('.txt') || extension.contains('.xls') || extension.contains('.xlsx')) {
            documentCount++;
          } else {
            otherCount++;
          }
        } catch (e) {
          // Skip files that can't be accessed
        }
      }

      return {
        'totalFiles': files.length,
        'totalSize': totalSize,
        'imageCount': imageCount,
        'documentCount': documentCount,
        'otherCount': otherCount,
      };
    } catch (e) {
      return {
        'totalFiles': 0,
        'totalSize': 0,
        'imageCount': 0,
        'documentCount': 0,
        'otherCount': 0,
      };
    }
  }

  Future<bool> deleteAllAttachments() async {
    try {
      final files = await getAllAttachmentFiles();
      for (final file in files) {
        await file.delete();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> clearAllAttachments() async {
    return await deleteAllAttachments();
  }

  Future<String?> getDownloadsDirectory() async {
    try {
      String basePath;
      if (Platform.isAndroid) {
        basePath = '/storage/emulated/0/Download';
      } else if (Platform.isIOS) {
        final directory = await getApplicationDocumentsDirectory();
        basePath = directory.path;
      } else {
        // For other platforms, use documents directory as fallback
        final directory = await getApplicationDocumentsDirectory();
        basePath = directory.path;
      }

      // Create Next Level folder inside downloads/documents
      final nextLevelPath = '$basePath/Next Level';
      final nextLevelDir = Directory(nextLevelPath);

      if (!await nextLevelDir.exists()) {
        await nextLevelDir.create(recursive: true);
      }

      return nextLevelPath;
    } catch (e) {
      return null;
    }
  }

  Future<bool> downloadFile(File sourceFile, String? customName) async {
    try {
      final downloadsPath = await getDownloadsDirectory();
      if (downloadsPath == null) return false;

      final fileName = customName ?? sourceFile.path.split('/').last;
      final targetPath = '$downloadsPath/$fileName';

      // If file exists, add number suffix
      String finalPath = targetPath;
      int counter = 1;
      while (File(finalPath).existsSync()) {
        final nameWithoutExt = fileName.split('.').first;
        final extension = fileName.contains('.') ? '.${fileName.split('.').last}' : '';
        finalPath = '$downloadsPath/${nameWithoutExt}_$counter$extension';
        counter++;
      }

      await sourceFile.copy(finalPath);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> downloadAllFiles() async {
    try {
      final files = await getAllAttachmentFiles();
      bool allSuccess = true;

      for (final file in files) {
        final success = await downloadFile(file, null);
        if (!success) allSuccess = false;
      }

      return allSuccess;
    } catch (e) {
      return false;
    }
  }

  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Find the task that contains the given file path
  TaskModel? findTaskByFilePath(String filePath) {
    try {
      final allTasks = TaskProvider().taskList;
      for (final task in allTasks) {
        if (task.attachmentPaths != null && task.attachmentPaths!.contains(filePath)) {
          return task;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get file metadata including creation/modification date
  Future<Map<String, dynamic>> getFileMetadata(File file) async {
    try {
      final stat = await file.stat();
      final size = await file.length();

      return {
        'size': size,
        'created': stat.changed,
        'modified': stat.modified,
        'accessed': stat.accessed,
      };
    } catch (e) {
      return {
        'size': 0,
        'created': DateTime.now(),
        'modified': DateTime.now(),
        'accessed': DateTime.now(),
      };
    }
  }

  /// Get all attachment files with their associated tasks and metadata
  Future<List<Map<String, dynamic>>> getAttachmentFilesWithDetails() async {
    try {
      final files = await getAllAttachmentFiles();
      final List<Map<String, dynamic>> filesWithDetails = [];

      for (final file in files) {
        final metadata = await getFileMetadata(file);
        final associatedTask = findTaskByFilePath(file.path);

        filesWithDetails.add({
          'file': file,
          'metadata': metadata,
          'task': associatedTask,
        });
      }

      return filesWithDetails;
    } catch (e) {
      return [];
    }
  }
}
