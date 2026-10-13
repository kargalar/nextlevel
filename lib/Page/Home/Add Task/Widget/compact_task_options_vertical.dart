import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/category_selector.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/location_input.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Provider/category_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:provider/provider.dart';

class CompactTaskOptionsVertical extends StatelessWidget {
  const CompactTaskOptionsVertical({super.key});

  @override
  Widget build(BuildContext context) {
    final addTaskProvider = context.watch<AddTaskProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    // Get selected category if any
    CategoryModel? selectedCategory;
    if (addTaskProvider.categoryId != null) {
      selectedCategory = categoryProvider.categoryList.firstWhere(
        (category) => category.id == addTaskProvider.categoryId,
        orElse: () => CategoryModel(id: '', title: LocaleKeys.NoCategory.tr(), colorValue: AppColors.main.toARGB32()),
      );
    }
    // Get location info
    final hasLocation = addTaskProvider.locationController.text.isNotEmpty;

    return Column(
      children: [
        // Location
        _buildVerticalOption(
          context: context,
          icon: Icons.location_on_rounded,
          iconColor: hasLocation ? AppColors.main : AppColors.text.withValues(alpha: 0.5),
          label: LocaleKeys.Location.tr(),
          value: hasLocation ? addTaskProvider.locationController.text : LocaleKeys.NotSet.tr(),
          hasValue: hasLocation,
          onTap: () {
            addTaskProvider.unfocusAll();
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              barrierColor: Colors.transparent,
              builder: (context) => const LocationBottomSheet(),
            );
          },
        ),

        const SizedBox(height: 6),

        // Category
        _buildVerticalOption(
          context: context,
          icon: Icons.label_rounded,
          iconColor: selectedCategory != null ? selectedCategory.color : AppColors.text.withValues(alpha: 0.5),
          label: LocaleKeys.Category.tr(),
          value: selectedCategory?.title ?? LocaleKeys.NotSet.tr(),
          hasValue: selectedCategory != null,
          onTap: () {
            addTaskProvider.unfocusAll();
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              barrierColor: Colors.transparent,
              builder: (context) => const CategoryBottomSheet(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildVerticalOption({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool hasValue,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: iconColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.text.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: hasValue ? FontWeight.bold : FontWeight.normal,
                          color: hasValue ? AppColors.text : AppColors.text.withValues(alpha: 0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.text.withValues(alpha: 0.3),
                  size: 10,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
