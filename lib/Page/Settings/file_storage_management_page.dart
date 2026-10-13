// ignore_for_file: unused_element

import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:get/get_navigation/src/routes/transitions_type.dart';

import 'package:next_level/General/app_colors.dart';
import 'package:next_level/General/accessible.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';

import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Service/file_storage_service.dart';
import 'package:next_level/Service/hive_service.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/logging_service.dart';

import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Page/Home/Add Task/add_task_page.dart';

import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/trait_provider.dart';
import 'package:next_level/Provider/store_provider.dart';
import 'package:next_level/Provider/user_provider.dart';
import 'package:next_level/Page/Task%20Detail%20Page/view_model/task_progress_view_model.dart';

class FileStorageManagementPage extends StatefulWidget {
  const FileStorageManagementPage({super.key});

  @override
  State<FileStorageManagementPage> createState() => _FileStorageManagementPageState();
}

class _FileStorageManagementPageState extends State<FileStorageManagementPage> {
  final _fileStorageService = FileStorageService.instance;
  List<Map<String, dynamic>> attachmentFilesWithDetails = [];
  Map<String, dynamic> storageStats = {};
  bool isLoading = true;

  // sorting
  String _sortBy = 'name';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadAttachmentFiles();
  }

  Future<void> _loadAttachmentFiles() async {
    setState(() => isLoading = true);
    try {
      final filesWithDetails = await _fileStorageService.getAttachmentFilesWithDetails();
      final stats = await _fileStorageService.getStorageStats();
      attachmentFilesWithDetails = filesWithDetails;
      storageStats = stats;
      _sortFiles();
    } catch (e) {
      LogService.error('Error loading attachment files: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _downloadAllFiles() async {
    if (attachmentFilesWithDetails.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text(LocaleKeys.DownloadAllFiles.tr()),
        content: Text('Download all ${attachmentFilesWithDetails.length} files?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(LocaleKeys.Cancel.tr())),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text('Download', style: TextStyle(color: AppColors.main))),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        final ok = await _fileStorageService.downloadAllFiles();
        if (!mounted) return;
        Helper().getMessage(
          message: ok ? 'All files downloaded' : 'Some files failed',
          status: ok ? StatusEnum.SUCCESS : StatusEnum.WARNING,
        );
      } catch (e) {
        if (!mounted) return;
        Helper().getMessage(message: 'Error', status: StatusEnum.WARNING);
      }
    }
  }

  Future<void> _downloadSingleFile(File file) async {
    final fileName = path.basename(file.path);
    final size = await file.length();
    final confirmed = await showDialog<bool>(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Download'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File: $fileName'),
            Text('Size: ${_fileStorageService.formatFileSize(size)}'),
            const SizedBox(height: 8),
            const Text('Download this file?'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(LocaleKeys.Cancel.tr())),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text('Download', style: TextStyle(color: AppColors.main))),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        final ok = await _fileStorageService.downloadFile(file, null);
        if (!mounted) return;
        Helper().getMessage(
          message: ok ? 'Downloaded' : 'Failed',
          status: ok ? StatusEnum.SUCCESS : StatusEnum.WARNING,
        );
      } catch (e) {
        if (!mounted) return;
        Helper().getMessage(message: 'Error', status: StatusEnum.WARNING);
      }
    }
  }

  Future<void> _clearAllFiles() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Clear All Files'),
        content: const Text('Are you sure you want to delete all attachment files? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(LocaleKeys.Cancel.tr())),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(LocaleKeys.Delete.tr(), style: const TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        final ok = await _fileStorageService.deleteAllAttachments();
        if (ok) await _loadAttachmentFiles();
        if (!mounted) return;
        Helper().getMessage(
          message: ok ? 'Cleared' : 'Failed',
          status: ok ? StatusEnum.SUCCESS : StatusEnum.WARNING,
        );
      } catch (e) {
        if (!mounted) return;
        Helper().getMessage(message: 'Error', status: StatusEnum.WARNING);
      }
    }
  }

  Future<void> _deleteFile(File file) async {
    try {
      await file.delete();
      await _loadAttachmentFiles();
      if (!mounted) return;
      Helper().getMessage(message: 'Deleted');
    } catch (e) {
      if (!mounted) return;
      Helper().getMessage(message: 'Error', status: StatusEnum.WARNING);
    }
  }

  void _showFilePreview(String filePath) {
    if (!_isImageFile(filePath)) return;
    showDialog(
      context: context,
      builder: (c) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(path.basename(filePath)),
              leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(c)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.download_rounded),
                  onPressed: () {
                    Navigator.pop(c);
                    _downloadSingleFile(File(filePath));
                  },
                ),
              ],
            ),
            Flexible(
              child: Image.file(
                File(filePath),
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(ext)) return Icons.image_rounded;
    if (ext == '.pdf') return Icons.picture_as_pdf_rounded;
    if (ext == '.doc' || ext == '.docx') return Icons.description_rounded;
    if (ext == '.xls' || ext == '.xlsx') return Icons.table_chart_rounded;
    if (ext == '.txt') return Icons.text_snippet_rounded;
    if (['.zip', '.rar', '.7z'].contains(ext)) return Icons.archive_rounded;
    return Icons.insert_drive_file_rounded;
  }

  bool _isImageFile(String filePath) => ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(path.extension(filePath).toLowerCase());

  void _sortFiles() {
    attachmentFilesWithDetails.sort((a, b) {
      final fileA = a['file'] as File;
      final fileB = b['file'] as File;
      final metaA = a['metadata'] as Map<String, dynamic>;
      final metaB = b['metadata'] as Map<String, dynamic>;
      int cmp = 0;
      switch (_sortBy) {
        case 'name':
          cmp = path.basename(fileA.path).toLowerCase().compareTo(path.basename(fileB.path).toLowerCase());
          break;
        case 'size':
          cmp = (metaA['size'] as int).compareTo(metaB['size'] as int);
          break;
        case 'date':
          cmp = (metaA['modified'] as DateTime).compareTo(metaB['modified'] as DateTime);
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });
  }

  void _changeSortBy(String sortBy) {
    setState(() {
      if (_sortBy == sortBy) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = sortBy;
        _sortAscending = true;
      }
      _sortFiles();
    });
  }

  void _navigateToTask(TaskModel task) {
    NavigatorService().goTo(
      AddTaskPage(editTask: task),
      transition: Transition.size,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.DataManagement.tr()),
        leading: InkWell(
          borderRadius: AppColors.borderRadiusAll,
          onTap: () => NavigatorService().back(),
          child: const Icon(Icons.arrow_back_ios),
        ),
        // File management actions commented out for now
        // actions: [
        //   if (attachmentFilesWithDetails.isNotEmpty) ...[
        //     PopupMenuButton<String>(
        //       icon: Icon(Icons.sort_rounded, color: AppColors.main),
        //       tooltip: 'Sort Files',
        //       onSelected: _changeSortBy,
        //       itemBuilder: (context) => [
        //         _sortMenuItem('name', Icons.text_fields_rounded, 'Sort by Name'),
        //         _sortMenuItem('size', Icons.data_usage_rounded, 'Sort by Size'),
        //         _sortMenuItem('date', Icons.schedule_rounded, 'Sort by Date'),
        //       ],
        //     ),
        //     IconButton(onPressed: _downloadAllFiles, icon: const Icon(Icons.download_rounded), tooltip: 'Download All Files'),
        //     IconButton(onPressed: _clearAllFiles, icon: const Icon(Icons.delete_sweep_rounded), tooltip: 'Clear All Files'),
        //   ],
        //   IconButton(onPressed: _loadAttachmentFiles, icon: const Icon(Icons.refresh_rounded), tooltip: 'Refresh'),
        // ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _dataManagementActions(),
                // File management UI commented out for now
                // _storageSummaryCard(),
                // Expanded(
                //   child: attachmentFilesWithDetails.isEmpty
                //       ? _emptyFiles()
                //       : ListView.builder(
                //           padding: const EdgeInsets.symmetric(horizontal: 16),
                //           itemCount: attachmentFilesWithDetails.length,
                //           itemBuilder: (context, index) {
                //             final data = attachmentFilesWithDetails[index];
                //             final file = data['file'] as File;
                //             final meta = data['metadata'] as Map<String, dynamic>;
                //             final task = data['task'] as TaskModel?;
                //             final fileName = path.basename(file.path);
                //             final isImage = _isImageFile(file.path);
                //             final fileSize = meta['size'] as int;
                //             final modified = meta['modified'] as DateTime;
                //             return Container(
                //               margin: const EdgeInsets.only(bottom: 8),
                //               decoration: BoxDecoration(
                //                 color: AppColors.background,
                //                 borderRadius: BorderRadius.circular(8),
                //                 border: Border.all(color: AppColors.text.withValues(alpha: 0.1), width: 1),
                //               ),
                //               child: ListTile(
                //                 leading: Container(
                //                   width: 40,
                //                   height: 40,
                //                   decoration: BoxDecoration(
                //                     color: AppColors.main.withValues(alpha: 0.1),
                //                     borderRadius: BorderRadius.circular(8),
                //                   ),
                //                   child: isImage && File(file.path).existsSync()
                //                       ? ClipRRect(
                //                           borderRadius: BorderRadius.circular(8),
                //                           child: Image.file(
                //                             File(file.path),
                //                             width: 40,
                //                             height: 40,
                //                             fit: BoxFit.cover,
                //                             errorBuilder: (c, e, s) => Icon(Icons.broken_image_rounded, color: AppColors.main, size: 20),
                //                           ),
                //                         )
                //                       : Icon(_getFileIcon(file.path), color: AppColors.main, size: 20),
                //                 ),
                //                 title: Text(
                //                   fileName,
                //                   maxLines: 2,
                //                   overflow: TextOverflow.ellipsis,
                //                   style: TextStyle(
                //                     color: AppColors.text,
                //                     fontSize: 14,
                //                     fontWeight: FontWeight.w500,
                //                   ),
                //                 ),
                //                 subtitle: Column(
                //                   crossAxisAlignment: CrossAxisAlignment.start,
                //                   children: [
                //                     Text(
                //                       _fileStorageService.formatFileSize(fileSize),
                //                       style: TextStyle(color: AppColors.text.withValues(alpha: 0.6), fontSize: 12),
                //                     ),
                //                     Text(
                //                       DateFormat('MMM dd, yyyy HH:mm').format(modified),
                //                       style: TextStyle(color: AppColors.text.withValues(alpha: 0.5), fontSize: 11),
                //                     ),
                //                     if (task != null)
                //                       Text(
                //                         'From: ${task.title}',
                //                         maxLines: 1,
                //                         overflow: TextOverflow.ellipsis,
                //                         style: TextStyle(
                //                           color: AppColors.main.withValues(alpha: 0.8),
                //                           fontSize: 11,
                //                           fontWeight: FontWeight.w500,
                //                         ),
                //                       ),
                //                   ],
                //                 ),
                //                 trailing: Row(
                //                   mainAxisSize: MainAxisSize.min,
                //                   children: [
                //                     if (task != null)
                //                       IconButton(
                //                         onPressed: () => _navigateToTask(task),
                //                         icon: Icon(Icons.task_rounded, color: AppColors.main, size: 20),
                //                         tooltip: 'Go to Task',
                //                       ),
                //                     IconButton(
                //                       onPressed: () => _downloadSingleFile(file),
                //                       icon: Icon(Icons.download_rounded, color: AppColors.main, size: 20),
                //                       tooltip: 'Download',
                //                     ),
                //                     IconButton(
                //                       onPressed: () => _deleteFile(file),
                //                       icon: const Icon(Icons.delete_rounded, color: AppColors.red, size: 20),
                //                       tooltip: 'Delete',
                //                     ),
                //                   ],
                //                 ),
                //                 onTap: isImage ? () => _showFilePreview(file.path) : () => _downloadSingleFile(file),
                //               ),
                //             ); // end item Container
                //           },
                //         ),
                // ),
              ],
            ),
    );
  }

  Widget _dataManagementActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        children: [
          // First Row: Export & Import
          Row(
            children: [
              Expanded(
                child: _dataActionButton(
                  icon: Icons.upload_file,
                  label: LocaleKeys.ExportData.tr(),
                  color: AppColors.green,
                  onTap: () async => HiveService().exportData(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dataActionButton(
                  icon: Icons.download,
                  label: LocaleKeys.ImportData.tr(),
                  color: AppColors.blue,
                  onTap: () async => HiveService().importData(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Second Row: Reset Routine & Reset Store
          Row(
            children: [
              Expanded(
                child: _dataActionButton(
                  icon: Icons.refresh,
                  label: LocaleKeys.ResetRoutineProgress.tr(),
                  color: AppColors.orange,
                  onTap: () {
                    Helper().getDialog(
                      withTimer: true,
                      message: LocaleKeys.ResetRoutineProgressWarning.tr(),
                      onAccept: () async => HiveService().resetAllRoutineProgress(),
                      acceptButtonText: LocaleKeys.Yes.tr(),
                      title: 'Confirm',
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dataActionButton(
                  icon: Icons.history_rounded,
                  label: 'Reset Store Progress',
                  color: AppColors.purple,
                  onTap: () {
                    Helper().getDialog(
                      withTimer: true,
                      message: 'Reset all store item purchase history? This action cannot be undone.',
                      onAccept: () async {
                        try {
                          await UserProvider().resetCredit();

                          final storeProvider = StoreProvider();

                          // Reset all store items' progress to their initial values
                          for (final item in storeProvider.storeItemList) {
                            // Reset counter items
                            if (item.type == TaskTypeEnum.COUNTER) {
                              item.currentCount = 0;
                            }
                            // Reset timer items
                            else if (item.type == TaskTypeEnum.TIMER) {
                              item.currentDuration = Duration.zero;
                              // Also stop timer if it's active
                              if (item.isTimerActive == true) {
                                item.isTimerActive = false;
                              }
                            }

                            await HiveService().updateItem(item);
                            await TaskProgressViewModel.clearStoreItemLogs(item.id);
                          }

                          // Update the provider to reflect changes in UI
                          storeProvider.setStateItems();

                          LogService.debug('✅ Store progress reset');
                          Helper().getMessage(message: LocaleKeys.ResetStoreProgressSuccess.tr());
                        } catch (e) {
                          LogService.error('❌ Error resetting store progress: $e');
                          Helper().getMessage(message: "Error: $e");
                        }
                      },
                      acceptButtonText: LocaleKeys.Yes.tr(),
                      title: 'Confirm',
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Third Row: Delete All Data
          Row(
            children: [
              Expanded(
                child: _dataActionButton(
                  icon: Icons.delete_forever,
                  label: LocaleKeys.DeleteAllData.tr(),
                  color: AppColors.red,
                  onTap: () {
                    Helper().getDialog(
                      withTimer: true,
                      message: LocaleKeys.DeleteAllDataWarning.tr(),
                      onAccept: () async {
                        await HiveService().deleteAllData();
                        TaskProvider().taskList = [];
                        TaskProvider().routineList = [];
                        TraitProvider().traitList = [];
                        StoreProvider().storeItemList = [];
                        loginUser = null;
                      },
                      acceptButtonText: LocaleKeys.Yes.tr(),
                      title: 'Confirm',
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _storageSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.storage_rounded, color: AppColors.main, size: 24),
              const SizedBox(width: 8),
              Text(
                LocaleKeys.StorageSummary.tr(),
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LocaleKeys.TotalFiles.tr(),
                    style: TextStyle(color: AppColors.text.withAlpha(179), fontSize: 12),
                  ),
                  Text(
                    '${storageStats['totalFiles'] ?? 0}',
                    style: TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    LocaleKeys.TotalSize.tr(),
                    style: TextStyle(color: AppColors.text.withAlpha(179), fontSize: 12),
                  ),
                  Text(
                    _fileStorageService.formatFileSize(storageStats['totalSize'] ?? 0),
                    style: TextStyle(color: AppColors.main, fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildFileTypeCard(LocaleKeys.Images.tr(), storageStats['imageCount'] ?? 0, Icons.image_rounded, Colors.blue),
              _buildFileTypeCard(LocaleKeys.Documents.tr(), storageStats['documentCount'] ?? 0, Icons.description_rounded, Colors.orange),
              _buildFileTypeCard(LocaleKeys.Others.tr(), storageStats['otherCount'] ?? 0, Icons.insert_drive_file_rounded, Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyFiles() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_rounded, size: 64, color: AppColors.text.withAlpha(77)),
          const SizedBox(height: 16),
          Text(
            LocaleKeys.NoAttachmentFilesFound.tr(),
            style: TextStyle(color: AppColors.text.withAlpha(153), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildFileTypeCard(String title, int count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              title,
              style: TextStyle(color: AppColors.text.withValues(alpha: 0.7), fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _sortMenuItem(String value, IconData icon, String text) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: _sortBy == value ? AppColors.main : AppColors.text.withValues(alpha: 0.6)),
          const SizedBox(width: 8),
          Text(text),
          if (_sortBy == value) ...[
            const Spacer(),
            Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 16, color: AppColors.main),
          ],
        ],
      ),
    );
  }

  Widget _dataActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
