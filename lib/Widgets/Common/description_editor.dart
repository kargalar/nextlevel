import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// !!!!!!!!!!!!!!!!!!!!
// ignore: depend_on_referenced_packages
import 'package:linkify/linkify.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Widgets/Common/linkify_text.dart';

/// Reusable description editor component
/// Can be used for tasks, notes, projects, subtasks, etc.
/// Supports auto-save, character count, copy and clear functionality
class DescriptionEditor extends StatefulWidget {
  const DescriptionEditor({
    super.key,
    required this.controller,
    required this.onChanged,
    this.focusNode,
    this.title,
  });

  /// Text controller for the description field
  final TextEditingController controller;

  /// Callback when description text changes (for auto-save)
  final Function(String) onChanged;

  /// Optional focus node for tracking focus state
  final FocusNode? focusNode;

  /// Optional custom title for the app bar
  final String? title;

  @override
  State<DescriptionEditor> createState() => _DescriptionEditorState();
}

class _DescriptionEditorState extends State<DescriptionEditor> {
  bool _showLinkPreview = false;

  @override
  void initState() {
    super.initState();
    // If a focus node is provided, request focus after build
    if (widget.focusNode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.focusNode!.requestFocus();
      });
    }
  }

  List<LinkableElement> _extractLinks(String value) {
    final elements = linkify(
      value,
      options: const LinkifyOptions(
        humanize: false,
        looseUrl: true,
        removeWww: false,
      ),
    );

    return elements.whereType<LinkableElement>().where((link) => link.url.isNotEmpty).toList();
  }

  void _copyDescription() {
    final description = widget.controller.text;
    if (description.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: description));
      if (mounted) {
        Helper().getMessage(
          message: LocaleKeys.CopiedDescription.tr(),
          status: StatusEnum.SUCCESS,
        );
        LogService.debug('✅ Description copied to clipboard');
      }
    } else {
      LogService.debug('⚠️ No description to copy');
    }
  }

  void _clearDescription() {
    if (widget.controller.text.isNotEmpty) {
      // Confirmation dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Clear Description',
            style: TextStyle(color: AppColors.text),
          ),
          content: Text(
            'Are you sure you want to clear the description?',
            style: TextStyle(color: AppColors.text.withValues(alpha: 0.8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                LocaleKeys.Cancel.tr(),
                style: TextStyle(color: AppColors.text.withValues(alpha: 0.7)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                widget.controller.clear();
                widget.onChanged(''); // Trigger auto-save
                setState(() {}); // Update UI
                Navigator.of(context).pop();
                LogService.debug('✅ Description cleared');

                Helper().getMessage(
                  message: 'Description cleared',
                  status: StatusEnum.INFO,
                );
              },
              child: Text(LocaleKeys.Clear.tr()),
            ),
          ],
        ),
      );
    } else {
      LogService.debug('⚠️ No description to clear');
    }
  }

  @override
  Widget build(BuildContext context) {
    final linkElements = _extractLinks(widget.controller.text);
    final linkPreviewText = linkElements.map((link) => link.url).join('\n');

    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          borderRadius: AppColors.borderRadiusAll,
          onTap: () {
            Navigator.of(context).pop();
          },
          child: const Icon(Icons.arrow_back_ios),
        ),
        title: Text(
          widget.title ?? LocaleKeys.Description.tr(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            // Description input area
            Expanded(
              child: Container(
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
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        focusNode: widget.focusNode,
                        autofocus: widget.focusNode == null,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                        decoration: InputDecoration(
                          hintText: LocaleKeys.EnterDescription.tr(),
                          hintStyle: TextStyle(
                            color: AppColors.text.withValues(alpha: 0.4),
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.only(
                            left: 16,
                            top: 10,
                            bottom: 12,
                          ),
                        ),
                        maxLines: null,
                        expands: true,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.none,
                        onChanged: (value) {
                          setState(() {}); // Update UI to reflect changes
                          widget.onChanged(value); // Trigger callback
                        },
                      ),
                    ),
                    if (linkElements.isNotEmpty) ...[
                      Divider(
                        color: AppColors.text.withValues(alpha: 0.08),
                        height: 1,
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.panelBackground.withValues(alpha: 0.4),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                setState(() {
                                  _showLinkPreview = !_showLinkPreview;
                                });
                                LogService.debug(
                                  '🔗 Description link list toggled: ${_showLinkPreview ? "expanded" : "collapsed"}',
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Links (${linkElements.length})',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.text.withValues(alpha: 0.65),
                                      ),
                                    ),
                                    Icon(
                                      _showLinkPreview ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                      size: 18,
                                      color: AppColors.text.withValues(alpha: 0.6),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            AnimatedCrossFade(
                              firstChild: const SizedBox.shrink(),
                              secondChild: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  constraints: const BoxConstraints(maxHeight: 140),
                                  padding: const EdgeInsets.all(6),
                                  color: AppColors.panelBackground.withValues(alpha: 0.5),
                                  child: SingleChildScrollView(
                                    child: LinkifyText(
                                      text: linkPreviewText,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              crossFadeState: _showLinkPreview ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 200),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Character count, copy and clear buttons
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.panelBackground.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Character count
                  Row(
                    children: [
                      Icon(
                        Icons.edit_rounded,
                        size: 14,
                        color: AppColors.text.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Characters: ${widget.controller.text.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.text.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),

                  // Copy and Clear buttons
                  Row(
                    children: [
                      // Clear button
                      GestureDetector(
                        onTap: _clearDescription,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.panelBackground,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.red.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.clear_rounded,
                                size: 16,
                                color: AppColors.red.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                LocaleKeys.Clear.tr(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.red.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Copy button
                      GestureDetector(
                        onTap: _copyDescription,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.panelBackground,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.text.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.copy_rounded,
                                size: 16,
                                color: AppColors.text.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                LocaleKeys.Copy.tr(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.text.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
