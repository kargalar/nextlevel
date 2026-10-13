import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/General/category_icons.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Page/Home/Widget/create_category_bottom_sheet.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Widgets/Common/category_chip.dart';

/// Common category filter widget used across Tasks, Notes, and Projects pages
class CategoryFilterWidget extends StatelessWidget {
  final List<dynamic> categories;
  final dynamic selectedCategoryId; // Can be int? or String?
  final Function(dynamic) onCategorySelected;
  final Map<dynamic, int>? itemCounts; // Optional count display
  final Function(BuildContext, dynamic)? onCategoryLongPress; // Optional long press handler
  final VoidCallback? onCategoryAdded; // Optional callback when a category is added
  final CategoryType? categoryType; // Category type for auto-detection when adding
  final bool showEmptyCategories; // Whether to show categories with 0 items

  const CategoryFilterWidget({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    this.itemCounts,
    this.onCategoryLongPress,
    this.onCategoryAdded,
    this.categoryType,
    this.showEmptyCategories = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // "All" option
          _buildAllChip(),
          const SizedBox(width: 8),

          // Categories
          ...categories.map((category) {
            final count = itemCounts?[category.id] ?? 0;
            if (!showEmptyCategories && count == 0 && selectedCategoryId != category.id) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildCategoryChip(context, category, count),
            );
          }),

          // Add category button
          _buildAddChip(context),
        ],
      ),
    );
  }

  Widget _buildAllChip() {
    final isSelected = selectedCategoryId == null;
    final totalCount = itemCounts?.values.fold(0, (sum, count) => sum + count) ?? 0;

    return CategoryChip(
      label: LocaleKeys.All.tr(),
      icon: Icons.all_inclusive_rounded,
      isSelected: isSelected,
      accentColor: AppColors.text,
      count: itemCounts != null ? totalCount : null,
      onTap: () => onCategorySelected(null),
    );
  }

  Widget _buildAddChip(BuildContext context) {
    return CategoryChip(
      label: LocaleKeys.Add.tr(),
      icon: Icons.add_rounded,
      isSelected: false,
      accentColor: AppColors.main,
      onTap: () async {
        LogService.debug('➕ CategoryFilterWidget: Add category button pressed, type: $categoryType');
        final result = await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.transparent,
          builder: (context) => CreateCategoryBottomSheet(
            initialCategoryType: categoryType,
          ),
        );

        LogService.debug('✅ CategoryFilterWidget: Bottom sheet closed, result: $result');

        if (context.mounted) {
          onCategoryAdded?.call();
        }
      },
    );
  }

  Widget _buildCategoryChip(BuildContext context, dynamic category, int count) {
    final isSelected = selectedCategoryId == category.id;
    final categoryColor = category.colorValue != null ? Color(category.colorValue) : AppColors.main;

    return CategoryChip(
      label: category.name ?? (category.title ?? ''),
      icon: category.iconCodePoint != null ? CategoryIcons.getIconByCodePoint(category.iconCodePoint) ?? Icons.category : null,
      isSelected: isSelected,
      accentColor: categoryColor,
      count: itemCounts != null ? count : null,
      onTap: () {
        LogService.debug('🏷️ CategoryFilterWidget: Category selected - ${category.name ?? category.title}');
        onCategorySelected(category.id);
      },
      onLongPress: onCategoryLongPress != null ? () => onCategoryLongPress!(context, category) : null,
    );
  }
}
