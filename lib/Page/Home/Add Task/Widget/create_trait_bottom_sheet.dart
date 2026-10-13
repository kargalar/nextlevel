import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Provider/trait_provider.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Enum/trait_type_enum.dart';
import 'package:next_level/Model/trait_model.dart';

class CreateTraitBottomSheet extends StatefulWidget {
  const CreateTraitBottomSheet({
    super.key,
    required this.isSkill,
  });

  final bool isSkill;

  @override
  State<CreateTraitBottomSheet> createState() => _CreateTraitBottomSheetState();
}

class _CreateTraitBottomSheetState extends State<CreateTraitBottomSheet> {
  final TextEditingController _titleController = TextEditingController();
  String _traitIcon = '🎯';
  Color _selectedColor = AppColors.main;

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
            const SizedBox(height: 16),
            _buildEmojiAndColorRow(),
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
        // Animated preview
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
          child: Center(
            child: Text(
              _traitIcon,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.isSkill ? LocaleKeys.CreateSkill.tr() : LocaleKeys.CreateAttribute.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextField(
      autofocus: true,
      controller: _titleController,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: LocaleKeys.Name.tr(),
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

  Widget _buildEmojiAndColorRow() {
    return Row(
      children: [
        // Emoji picker
        Expanded(
          child: _buildPickerTile(
            onTap: () async {
              _traitIcon = await Helper().showEmojiPicker(context);
              setState(() {});
            },
            child: Text(
              _traitIcon,
              style: const TextStyle(fontSize: 28),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Color picker
        Expanded(
          child: _buildColorTile(),
        ),
      ],
    );
  }

  Widget _buildPickerTile({
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.panelBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.panelBackground2.withValues(alpha: 0.5),
            ),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }

  Widget _buildColorTile() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          _selectedColor = await Helper().selectColor();
          setState(() {});
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _selectedColor.withValues(alpha: 0.8),
                _selectedColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _selectedColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.palette_rounded,
              color: Colors.white.withValues(alpha: 0.8),
              size: 22,
            ),
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
        // Create
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _createTrait,
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
              LocaleKeys.Create.tr(),
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

  void _createTrait() {
    if (_titleController.text.trim().isEmpty) {
      _titleController.clear();
      Helper().getMessage(
        message: LocaleKeys.TraitNameEmpty.tr(),
        status: StatusEnum.WARNING,
      );
      return;
    }

    final newTrait = TraitModel(
      title: _titleController.text,
      icon: _traitIcon,
      color: _selectedColor,
      type: widget.isSkill ? TraitTypeEnum.SKILL : TraitTypeEnum.ATTRIBUTE,
    );

    TraitProvider().addTrait(newTrait);

    final addTaskProvider = Provider.of<AddTaskProvider>(context, listen: false);
    addTaskProvider.selectedTraits.add(newTrait);

    Navigator.pop(context);
  }
}
