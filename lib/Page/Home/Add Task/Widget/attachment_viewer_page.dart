import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/logging_service.dart';

class AttachmentViewerPage extends StatefulWidget {
  final List<String> attachmentPaths;
  final int initialIndex;

  const AttachmentViewerPage({
    super.key,
    required this.attachmentPaths,
    required this.initialIndex,
  });

  @override
  State<AttachmentViewerPage> createState() => _AttachmentViewerPageState();
}

class _AttachmentViewerPageState extends State<AttachmentViewerPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _isImageFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(extension);
  }

  Future<void> _downloadFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        // Downloads klasörüne kopyala
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }

        final fileName = path.basename(filePath);
        final newPath = path.join(downloadsDir.path, 'NextLevel', fileName);

        // NextLevel klasörünü oluştur
        final nextLevelDir = Directory(path.dirname(newPath));
        if (!await nextLevelDir.exists()) {
          await nextLevelDir.create(recursive: true);
        }

        await file.copy(newPath);

        Helper().getMessage(
          message: LocaleKeys.DownloadSuccess.tr(args: [path.basename(filePath)]),
          status: StatusEnum.SUCCESS,
        );
        LogService.debug('Dosya indirildi: $newPath');
      }
    } catch (e) {
      LogService.error('Download error: $e');
      Helper().getMessage(
        message: LocaleKeys.DownloadFailed.tr(),
        status: StatusEnum.WARNING,
      );
    }
  }

  Future<void> _shareFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(filePath)],
          ),
        );
        LogService.debug('File Shared: $filePath');
      }
    } catch (e) {
      LogService.error('Share error: $e');
      Helper().getMessage(
        message: LocaleKeys.ShareFailed.tr(),
        status: StatusEnum.WARNING,
      );
    }
  }

  Future<void> _openFile(String filePath) async {
    LogService.debug('File opening initiated: $filePath');
    try {
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        // If file couldn't be opened, show its location
        Helper().getMessage(
          message: LocaleKeys.FileCannotBeOpenedLocation.tr(args: [path.dirname(filePath)]),
          status: StatusEnum.INFO,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      LogService.error('Open file error: $e');
      Helper().getMessage(
        message: LocaleKeys.FileCannotBeOpenedLocation.tr(args: [path.dirname(filePath)]),
        status: StatusEnum.INFO,
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentFilePath = widget.attachmentPaths[_currentIndex];
    final isImage = _isImageFile(currentFilePath);
    final fileName = path.basename(currentFilePath);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          fileName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // İndirme butonu
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            onPressed: () => _downloadFile(currentFilePath),
            tooltip: LocaleKeys.Download.tr(),
          ),
          // Paylaşma butonu
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: () => _shareFile(currentFilePath),
            tooltip: LocaleKeys.Share.tr(),
          ),
          // Dosya varsa açma butonu
          if (!isImage)
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded, color: Colors.white),
              onPressed: () => _openFile(currentFilePath),
              tooltip: LocaleKeys.Open.tr(),
            ),
        ],
      ),
      body: Column(
        children: [
          // Ana içerik alanı
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: widget.attachmentPaths.length,
              itemBuilder: (context, index) {
                final filePath = widget.attachmentPaths[index];
                final fileIsImage = _isImageFile(filePath);

                if (fileIsImage) {
                  // Görsel için
                  return InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: Center(
                      child: Image.file(
                        File(filePath),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.broken_image_rounded,
                                  color: Colors.white54,
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  LocaleKeys.ImageCouldNotLoad.tr(),
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                } else {
                  // Dosya için
                  return GestureDetector(
                    onTap: () {
                      LogService.debug('File clicked: $filePath');
                      _openFile(filePath);
                    },
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.all(24),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.panelBackground.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.main.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getFileIcon(filePath),
                              color: AppColors.main,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              path.basename(filePath),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              LocaleKeys.TapToOpen.tr(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          ),

          // Alt bilgi çubuğu
          if (widget.attachmentPaths.length > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              color: Colors.black.withValues(alpha: 0.8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_currentIndex + 1} / ${widget.attachmentPaths.length}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String filePath) {
    final extension = path.extension(filePath).toLowerCase();

    if (['.pdf'].contains(extension)) {
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
