import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Model/note_model.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Provider/notes_provider.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/logging_service.dart';

/// Not ekleme ve düzenleme sayfası
class AddEditNotePage extends StatefulWidget {
  final NoteModel? note;

  const AddEditNotePage({super.key, this.note});

  @override
  State<AddEditNotePage> createState() => _AddEditNotePageState();
}

class _AddEditNotePageState extends State<AddEditNotePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  CategoryModel? _selectedCategory;
  late bool _isPinned;
  bool _isSaving = false;

  bool get isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');

    // Initialize state
    _isPinned = widget.note?.isPinned ?? false;

    // Kategoriyi yükle
    if (widget.note?.categoryId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = Provider.of<NotesProvider>(context, listen: false);
        _selectedCategory = provider.getCategoryById(widget.note!.categoryId);
        if (mounted) setState(() {});
      });
    }

    LogService.debug('🔧 AddEditNotePage: Initialized ${isEditing ? "edit" : "add"} mode');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isEditing ? LocaleKeys.EditNote.tr() : LocaleKeys.NewNote.tr(),
          style: TextStyle(color: AppColors.text),
        ),
        backgroundColor: AppColors.background,
        iconTheme: IconThemeData(color: AppColors.text),
        actions: [
          if (isEditing)
            IconButton(
              icon: Icon(
                _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: _isPinned ? AppColors.yellow : AppColors.text,
              ),
              onPressed: () {
                setState(() {
                  _isPinned = !_isPinned;
                });
              },
              tooltip: _isPinned ? LocaleKeys.Unpin.tr() : LocaleKeys.Pin.tr(),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildNoteFields(),
            const SizedBox(height: 20),
            _buildCategorySelector(),
            const SizedBox(height: 24),
            _buildSaveButton(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  /// Başlık ve içerik alanları (tek container'da - task'lardaki gibi)
  Widget _buildNoteFields() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.panelBackground2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _titleController,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
            decoration: InputDecoration(
              hintText: LocaleKeys.Title.tr(),
              hintStyle: const TextStyle(color: AppColors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return LocaleKeys.TitleRequired.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Divider(color: AppColors.panelBackground2, height: 1),
          const SizedBox(height: 12),
          TextFormField(
            controller: _contentController,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.text,
            ),
            decoration: InputDecoration(
              hintText: LocaleKeys.ContentOptional.tr(),
              hintStyle: const TextStyle(color: AppColors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            maxLines: 10,
            minLines: 5,
          ),
        ],
      ),
    );
  }

  /// Kategori seçici (altta, kompakt)
  Widget _buildCategorySelector() {
    return Consumer<NotesProvider>(
      builder: (context, provider, child) {
        if (provider.categories.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${LocaleKeys.Category.tr()} (${LocaleKeys.ContentOptional.tr()})',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildCategoryChip(null, LocaleKeys.NoCategory.tr()),
                ...provider.categories.map((category) {
                  return _buildCategoryChip(category, category.name);
                }),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Kategori chip widget
  Widget _buildCategoryChip(CategoryModel? category, String label) {
    final isSelected = (_selectedCategory?.id == category?.id) || (_selectedCategory == null && category == null);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedCategory = category;
        });
      },
      backgroundColor: AppColors.panelBackground,
      selectedColor: category != null ? category.color.withValues(alpha: 0.3) : AppColors.panelBackground2,
      labelStyle: TextStyle(
        color: AppColors.text,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      checkmarkColor: AppColors.text,
      side: BorderSide(
        color: isSelected ? (category != null ? category.color : AppColors.panelBackground2) : AppColors.panelBackground2,
      ),
    );
  }

  /// Kaydet butonu
  Widget _buildSaveButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveNote,
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedCategory != null ? Color(_selectedCategory!.colorValue) : AppColors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save),
        label: Text(
          _isSaving
              ? LocaleKeys.Saving.tr()
              : isEditing
                  ? LocaleKeys.Update.tr()
                  : LocaleKeys.Save.tr(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final provider = context.read<NotesProvider>();

      bool success;

      if (isEditing) {
        // Mevcut notu güncelle
        LogService.debug('📝 AddEditNotePage: Updating note ${widget.note!.id}');
        final updatedNote = widget.note!.copyWith(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          categoryId: _selectedCategory?.id,
          isPinned: _isPinned,
          updatedAt: DateTime.now(),
        );
        success = await provider.updateNote(updatedNote);
      } else {
        // Yeni not ekle
        LogService.debug('➕ AddEditNotePage: Adding new note');
        success = await provider.addNote(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          categoryId: _selectedCategory?.id,
        );
      }

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        if (success) {
          LogService.debug('✅ AddEditNotePage: Note saved successfully');
          Navigator.pop(context);
          Helper().getMessage(
            message: isEditing ? LocaleKeys.NoteUpdated.tr() : LocaleKeys.NoteAdded.tr(),
            status: StatusEnum.SUCCESS,
          );
        } else {
          LogService.error('❌ AddEditNotePage: Failed to save note');
          Helper().getMessage(
            message: isEditing ? LocaleKeys.NoteUpdateFailed.tr() : LocaleKeys.NoteSaveFailed.tr(),
            status: StatusEnum.WARNING,
          );
        }
      }
    } catch (e) {
      LogService.error('❌ AddEditNotePage: Error saving note: $e');
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        Helper().getMessage(
          message: LocaleKeys.ErrorOccurred.tr(args: [e.toString()]),
          status: StatusEnum.WARNING,
        );
      }
    }
  }
}
