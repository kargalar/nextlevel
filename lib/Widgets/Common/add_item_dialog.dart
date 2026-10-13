import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Widgets/Common/description_editor.dart';
import 'package:next_level/Service/logging_service.dart';

/// Generic dialog for adding/editing items with title and description
/// Can be used for subtasks, notes, projects, etc.
class AddItemDialog extends StatefulWidget {
  /// Dialog title
  final String title;

  /// Icon for the header
  final IconData icon;

  /// Title field configuration
  final String? titleLabel;
  final String? titleHint;
  final bool titleRequired;
  final String? initialTitle;

  /// Description/Content field configuration
  final String? descriptionLabel;
  final String? descriptionHint;
  final bool descriptionRequired;
  final String? initialDescription;
  final int descriptionMaxLines;
  final int descriptionMinLines;

  /// Whether to show cancel button
  final bool showCancelButton;

  /// Validation message for when both fields are empty (if both are optional)
  final String? emptyValidationMessage;

  /// Callback when save is pressed
  final Function(String? title, String? description) onSave;

  /// Whether this is an edit operation (affects behavior)
  final bool isEditing;

  const AddItemDialog({
    super.key,
    required this.title,
    required this.icon,
    this.titleLabel,
    this.titleHint,
    this.titleRequired = false,
    this.initialTitle,
    this.descriptionLabel,
    this.descriptionHint,
    this.descriptionRequired = false,
    this.initialDescription,
    this.descriptionMaxLines = 5,
    this.descriptionMinLines = 2,
    this.showCancelButton = true,
    this.emptyValidationMessage,
    required this.onSave,
    this.isEditing = false,
  });

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();

  bool _forceClose = false;

  bool _hasUnsavedChanges() {
    final currentTitle = _titleController.text;
    final currentDesc = _descriptionController.text;

    final initialTit = widget.initialTitle ?? '';
    final initialDes = widget.initialDescription ?? '';

    return currentTitle != initialTit || currentDesc != initialDes;
  }

  @override
  void initState() {
    super.initState();

    // Populate initial values
    if (widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
    }
    if (widget.initialDescription != null) {
      _descriptionController.text = widget.initialDescription!;
    }

    // Auto-focus the title field if it exists, otherwise description
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.titleLabel != null) {
        _titleFocus.requestFocus();
      } else if (widget.descriptionLabel != null) {
        _descriptionFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocus.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  void _saveItem({bool isAutoSave = false}) {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    // Validation
    if (widget.titleRequired && title.isEmpty) {
      if (!isAutoSave) {
        Helper().getMessage(
          message: widget.titleHint ?? LocaleKeys.NameEmpty.tr(),
          status: StatusEnum.WARNING,
        );
      }
      return;
    }

    if (widget.descriptionRequired && description.isEmpty) {
      if (!isAutoSave) {
        Helper().getMessage(
          message: widget.descriptionHint ?? LocaleKeys.EnterDescription.tr(),
          status: StatusEnum.WARNING,
        );
      }
      return;
    }

    // If both are optional, at least one must be filled
    if (!widget.titleRequired && !widget.descriptionRequired && widget.emptyValidationMessage != null && title.isEmpty && description.isEmpty) {
      if (!isAutoSave) {
        Helper().getMessage(
          message: widget.emptyValidationMessage!,
          status: StatusEnum.WARNING,
        );
      }
      return;
    }

    widget.onSave(
      title.isEmpty ? null : title,
      description.isEmpty ? null : description,
    );

    // If adding new item, clear and keep dialog open
    // If editing, close the dialog (handled by parent)
    if (!widget.isEditing) {
      _titleController.clear();
      _descriptionController.clear();
      if (widget.titleLabel != null) {
        _titleFocus.requestFocus();
      } else if (widget.descriptionLabel != null) {
        _descriptionFocus.requestFocus();
      }
    } else {
      if (!isAutoSave) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _forceClose || widget.isEditing || !_hasUnsavedChanges(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          if (widget.isEditing && !_forceClose) {
            _saveItem(isAutoSave: true);
          }
          return;
        }

        Helper().getDialog(
          title: LocaleKeys.Warning.tr(),
          message: 'Are you sure you want to discard your changes?'.tr(),
          onAccept: () {
            setState(() {
              _forceClose = true;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) Navigator.pop(context);
            });
          },
        );
      },
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          border: const Border(
            top: BorderSide(color: AppColors.dirtyWhite),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.icon,
                      color: AppColors.main,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.maybePop(context),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.close_rounded,
                        color: AppColors.text.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(
                color: AppColors.text.withValues(alpha: 0.1),
                height: 1,
              ),
            ),

            // Input fields container
            Container(
              decoration: BoxDecoration(
                color: AppColors.panelBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.panelBackground2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title field (if configured)
                  if (widget.titleLabel != null) ...[
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: TextField(
                        autofocus: true,
                        controller: _titleController,
                        focusNode: _titleFocus,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                        decoration: InputDecoration(
                          hintText: widget.titleHint ?? widget.titleLabel,
                          hintStyle: const TextStyle(color: AppColors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        textInputAction: widget.descriptionLabel != null ? TextInputAction.next : TextInputAction.done,
                        onSubmitted: widget.descriptionLabel != null ? (_) => _descriptionFocus.requestFocus() : (_) => _saveItem(),
                      ),
                    ),
                    if (widget.descriptionLabel != null) Divider(color: AppColors.panelBackground2, height: 1),
                  ],

                  // Description field (if configured)
                  if (widget.descriptionLabel != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Stack(
                        children: [
                          TextField(
                            controller: _descriptionController,
                            focusNode: _descriptionFocus,
                            textCapitalization: TextCapitalization.sentences,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.text,
                            ),
                            decoration: InputDecoration(
                              hintText: widget.descriptionHint ?? widget.descriptionLabel,
                              hintStyle: const TextStyle(color: AppColors.grey),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            maxLines: widget.descriptionMaxLines,
                            minLines: widget.descriptionMinLines,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.none,
                          ),
                          // Full screen button positioned at top right
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(Icons.fullscreen, size: 18),
                              onPressed: () async {
                                LogService.debug('🔍 AddItemDialog: Opening full screen editor for description');
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DescriptionEditor(
                                      controller: _descriptionController,
                                      onChanged: (value) => setState(() {}),
                                      title: widget.title,
                                    ),
                                  ),
                                );
                                LogService.debug('✅ AddItemDialog: Returned from full screen editor');
                              },
                              tooltip: 'Full Screen',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            if (!widget.isEditing)
              Row(
                children: [
                  // Cancel button (if enabled)
                  if (widget.showCancelButton) ...[
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.maybePop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          LocaleKeys.Cancel.tr(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.text.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Save button
                  Expanded(
                    flex: widget.showCancelButton ? 2 : 1,
                    child: ElevatedButton(
                      onPressed: _saveItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.main,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        LocaleKeys.Save.tr(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
