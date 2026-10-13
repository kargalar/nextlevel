import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/attachment_viewer_page.dart';

class FileAttachmentWidget extends StatelessWidget {
  const FileAttachmentWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final addTaskProvider = context.watch<AddTaskProvider>();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with attachment count and add buttons
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.attach_file_rounded,
                  color: AppColors.main,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Attachments',
                  style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (addTaskProvider.attachmentPaths.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.main.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${addTaskProvider.attachmentPaths.length}',
                      style: TextStyle(
                        color: AppColors.main,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                // Quick action buttons
                Row(
                  children: [
                    // Image picker button
                    InkWell(
                      onTap: () => addTaskProvider.pickImages(),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.main.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.image_rounded,
                          color: AppColors.main,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // File picker button
                    InkWell(
                      onTap: () => addTaskProvider.pickFiles(),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.main.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.folder_rounded,
                          color: AppColors.main,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ), // File list
          if (addTaskProvider.attachmentPaths.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: addTaskProvider.attachmentPaths.asMap().entries.map((entry) {
                  final index = entry.key;
                  final filePath = entry.value;
                  final fileName = path.basename(filePath);
                  final isImage = _isImageFile(filePath);
                  final fileExists = File(filePath).existsSync();

                  if (isImage && fileExists) {
                    // Image preview with larger size
                    return GestureDetector(
                      onTap: () => _showFullScreenImage(context, filePath),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.text.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(filePath),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: AppColors.main.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.broken_image_rounded,
                                      color: AppColors.main,
                                      size: 24,
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Subtle filename overlay (only show on hover/press)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.5),
                                      Colors.transparent,
                                    ],
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(8),
                                    bottomRight: Radius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  fileName.length > 12 ? '${fileName.substring(0, 9)}...' : fileName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 7,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),

                            // Remove button
                            Positioned(
                              top: 2,
                              right: 2,
                              child: InkWell(
                                onTap: () => addTaskProvider.removeAttachment(index),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: AppColors.red.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    // Regular file display or missing file
                    final fileExists = File(filePath).existsSync();

                    return Container(
                      decoration: BoxDecoration(
                        color: fileExists ? AppColors.background : AppColors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: fileExists ? AppColors.text.withValues(alpha: 0.1) : AppColors.red.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // File content
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // File icon
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: fileExists ? AppColors.main.withValues(alpha: 0.1) : AppColors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    fileExists ? _getFileIcon(filePath) : Icons.error_outline_rounded,
                                    color: fileExists ? AppColors.main : AppColors.red,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8), // File name and status
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        fileName,
                                        style: TextStyle(
                                          color: fileExists ? AppColors.text : AppColors.red,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (fileExists) ...[
                                        Text(
                                          _formatFileSize(File(filePath).lengthSync()),
                                          style: TextStyle(
                                            color: AppColors.text.withValues(alpha: 0.6),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ] else ...[
                                        const Text(
                                          'File not found',
                                          style: TextStyle(
                                            color: AppColors.red,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20), // Space for remove button
                              ],
                            ),
                          ),

                          // Remove button
                          Positioned(
                            top: 2,
                            right: 2,
                            child: InkWell(
                              onTap: () => addTaskProvider.removeAttachment(index),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: AppColors.red.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                }).toList(),
              ),
            ),
          ] else ...[
            // Empty state
            Padding(
              padding: const EdgeInsets.all(12),
              child: GestureDetector(
                onTap: () => addTaskProvider.pickFiles(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.main.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.main.withValues(alpha: 0.2),
                      width: 1,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.attach_file_rounded,
                        color: AppColors.main.withValues(alpha: 0.6),
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to add files',
                        style: TextStyle(
                          color: AppColors.main.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imagePath) {
    final addTaskProvider = context.read<AddTaskProvider>();
    final currentIndex = addTaskProvider.attachmentPaths.indexOf(imagePath);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AttachmentViewerPage(
          attachmentPaths: addTaskProvider.attachmentPaths,
          initialIndex: currentIndex >= 0 ? currentIndex : 0,
        ),
      ),
    );
  }

  bool _isImageFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(extension);
  }

  String _formatFileSize(int bytes) {
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

  IconData _getFileIcon(String filePath) {
    final extension = path.extension(filePath).toLowerCase();

    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(extension)) {
      return Icons.image_rounded;
    } else if (['.pdf'].contains(extension)) {
      return Icons.picture_as_pdf_rounded;
    } else if (['.doc', '.docx'].contains(extension)) {
      return Icons.description_rounded;
    } else if (['.xls', '.xlsx'].contains(extension)) {
      return Icons.table_chart_rounded;
    } else if (['.txt'].contains(extension)) {
      return Icons.text_snippet_rounded;
    } else if (['.zip', '.rar', '.7z'].contains(extension)) {
      return Icons.archive_rounded;
    } else {
      return Icons.insert_drive_file_rounded;
    }
  }
}
