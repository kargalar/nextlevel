import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/General/category_icons.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Provider/category_provider.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Widgets/Common/color_picker_row.dart';
import 'package:next_level/Widgets/Common/icon_picker_grid.dart';
import 'package:provider/provider.dart';

class CreateCategoryBottomSheet extends StatefulWidget {
  final CategoryModel? categoryModel;
  final CategoryType? initialCategoryType;

  const CreateCategoryBottomSheet({
    super.key,
    this.categoryModel,
    this.initialCategoryType,
  });

  @override
  State<CreateCategoryBottomSheet> createState() => _CreateCategoryBottomSheetState();
}

class _CreateCategoryBottomSheetState extends State<CreateCategoryBottomSheet> {
  final TextEditingController _titleController = TextEditingController();
  Color _selectedColor = AppColors.main;
  CategoryType _selectedCategoryType = CategoryType.task;
  IconData _selectedIcon = Icons.category;

  bool get _isEditing => widget.categoryModel != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleController.text = widget.categoryModel!.title;
      _selectedColor = widget.categoryModel!.color;
      _selectedCategoryType = widget.categoryModel!.categoryType;
      if (widget.categoryModel!.iconCodePoint != null) {
        _selectedIcon = CategoryIcons.getIconByCodePoint(widget.categoryModel!.iconCodePoint!) ?? Icons.category;
      }
    } else if (widget.initialCategoryType != null) {
      _selectedCategoryType = widget.initialCategoryType!;
      LogService.debug('🎨 CreateCategoryBottomSheet: Initial category type set to: $_selectedCategoryType');
    } else {
      LogService.debug('⚠️ CreateCategoryBottomSheet: No initial category type provided, using default: $_selectedCategoryType');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: bottomInset + 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(
            color: _selectedColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: _selectedColor.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHandle(),
            const SizedBox(height: 12),
            _buildHeader(),
            const SizedBox(height: 20),
            _buildNameField(),
            const SizedBox(height: 24),
            _buildSectionLabel(LocaleKeys.SelectColor.tr()),
            const SizedBox(height: 10),
            ColorPickerRow(
              selectedColor: _selectedColor,
              onColorSelected: (color) => setState(() => _selectedColor = color),
            ),
            const SizedBox(height: 24),
            _buildSectionLabel(LocaleKeys.SelectIcon.tr()),
            const SizedBox(height: 10),
            IconPickerGrid(
              selectedIcon: _selectedIcon,
              accentColor: _selectedColor,
              onIconSelected: (icon) => setState(() => _selectedIcon = icon),
            ),
            const SizedBox(height: 28),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.text.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Animated color preview with icon
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _selectedColor.withValues(alpha: 0.3),
                _selectedColor.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selectedColor.withValues(alpha: 0.4),
            ),
          ),
          child: Icon(
            _selectedIcon,
            color: _selectedColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _isEditing ? LocaleKeys.EditCategory.tr() : LocaleKeys.CreateCategory.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ),
        if (_isEditing) _buildDeleteButton(),
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.text.withValues(alpha: 0.5),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: _titleController,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: LocaleKeys.CategoryName.tr(),
        hintStyle: TextStyle(
          color: AppColors.text.withValues(alpha: 0.3),
        ),
        filled: true,
        fillColor: AppColors.panelBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.panelBackground2.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _selectedColor.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _confirmDelete,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: AppColors.red,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Cancel
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: AppColors.panelBackground2.withValues(alpha: 0.6),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              LocaleKeys.Cancel.tr(),
              style: TextStyle(
                color: AppColors.text.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Save
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _saveCategory,
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              LocaleKeys.Save.tr(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocaleKeys.Delete.tr()),
        content: Text(LocaleKeys.DeleteCategoryConfirmation.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocaleKeys.Cancel.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              LogService.debug('🗑️ CreateCategoryBottomSheet: Deleting category ${widget.categoryModel!.id}');
              await context.read<CategoryProvider>().deleteCategory(widget.categoryModel!);
              LogService.debug('✅ CreateCategoryBottomSheet: Category deleted, closing bottom sheet');
              if (context.mounted) {
                Navigator.pop(context, true);
              }
            },
            child: Text(
              LocaleKeys.Delete.tr(),
              style: const TextStyle(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCategory() async {
    if (_titleController.text.trim().isEmpty) {
      Helper().getMessage(
        message: LocaleKeys.CategoryNameEmpty.tr(),
        status: StatusEnum.WARNING,
      );
      return;
    }

    final categoryProvider = context.read<CategoryProvider>();

    if (!_isEditing) {
      final newCategory = CategoryModel(
        id: '',
        title: _titleController.text.trim(),
        colorValue: _selectedColor.toARGB32(),
        iconCodePoint: _selectedIcon.codePoint,
        categoryType: _selectedCategoryType,
      );
      LogService.debug('🆕 CreateCategoryBottomSheet: Creating new category: ${newCategory.title}, type: ${newCategory.categoryType}');

      try {
        await categoryProvider.addCategory(newCategory);
        LogService.debug('✅ CreateCategoryBottomSheet: Category added to provider');
      } catch (e) {
        LogService.error('❌ CreateCategoryBottomSheet: Error adding category: $e');
        if (mounted) {
          Helper().getMessage(
            message: LocaleKeys.CategoryCreateFailed.tr(args: [e.toString()]),
            status: StatusEnum.ERROR,
          );
        }
        return;
      }

      if (mounted) {
        final addTaskProvider = Provider.of<AddTaskProvider>(context, listen: false);
        addTaskProvider.updateCategory(newCategory.id);
      }

      if (mounted) {
        Navigator.pop(context, newCategory);
      }
    } else {
      widget.categoryModel!.title = _titleController.text.trim();
      widget.categoryModel!.colorValue = _selectedColor.toARGB32();
      widget.categoryModel!.iconCodePoint = _selectedIcon.codePoint;
      await categoryProvider.updateCategory(widget.categoryModel!);

      if (mounted) {
        Navigator.pop(context, false);
      }
    }
  }
}
