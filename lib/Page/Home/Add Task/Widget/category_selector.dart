import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Page/Home/Widget/create_category_bottom_sheet.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Provider/category_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Widgets/clickable_tooltip.dart';
import 'package:provider/provider.dart';

class CategorySelector extends StatelessWidget {
  const CategorySelector({super.key});

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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Unfocus any text fields before showing bottom sheet
          addTaskProvider.unfocusAll();

          // Show the category selection bottom sheet
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            barrierColor: Colors.transparent,
            builder: (context) => const CategoryBottomSheet(),
          );
        },
        borderRadius: BorderRadius.circular(12),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Category icon
              Icon(
                Icons.label_rounded,
                color: AppColors.main,
                size: 20,
              ),
              const SizedBox(width: 8),

              // Category text
              Text(
                LocaleKeys.Category.tr(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(width: 8),

              // Selected category indicator
              if (selectedCategory != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: selectedCategory.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: selectedCategory.color.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: selectedCategory.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        selectedCategory.title,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: selectedCategory.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Text(
                  LocaleKeys.NoCategory.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.text.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              const Spacer(),

              // Arrow icon to indicate it opens a bottom sheet
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.text.withValues(alpha: 0.3),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryBottomSheet extends StatelessWidget {
  const CategoryBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final addTaskProvider = context.watch<AddTaskProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    // SADECE TASK KATEGORİLERİNİ GÖSTER
    final activeCategories = categoryProvider.getActiveCategories().where((cat) => cat.categoryType == CategoryType.task).toList();

    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: const Border(
          top: BorderSide(color: AppColors.dirtyWhite),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.text.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header with title and add button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.label_rounded,
                      color: AppColors.main,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    ClickableTooltip(
                      titleKey: LocaleKeys.Category,
                      bulletPoints: [
                        LocaleKeys.tooltip_category_bullet_1.tr(),
                        LocaleKeys.tooltip_category_bullet_2.tr(),
                        LocaleKeys.tooltip_category_bullet_3.tr(),
                        LocaleKeys.tooltip_category_bullet_4.tr(),
                      ],
                      child: Text(
                        LocaleKeys.Category.tr(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                _buildAddCategoryButton(context),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Categories content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: activeCategories.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.category_outlined,
                            color: AppColors.text.withValues(alpha: 0.3),
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            LocaleKeys.NoCategory.tr(),
                            style: TextStyle(
                              color: AppColors.text.withValues(alpha: 0.5),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          // Category Tags
                          ...activeCategories.map((category) => _buildCategoryTag(
                                context: context,
                                category: category,
                                isSelected: addTaskProvider.categoryId == category.id,
                                onTap: () {
                                  // Unfocus any text fields before updating category
                                  addTaskProvider.unfocusAll();
                                  addTaskProvider.categoryId == category.id ? addTaskProvider.updateCategory(null) : addTaskProvider.updateCategory(category.id);
                                },
                                onLongPress: () {
                                  // Unfocus any text fields before showing bottom sheet
                                  addTaskProvider.unfocusAll();
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    barrierColor: Colors.transparent,
                                    builder: (context) => CreateCategoryBottomSheet(categoryModel: category),
                                  );
                                },
                              )),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTag({
    required BuildContext context,
    required CategoryModel category,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    final String label = category.title;
    final Color color = category.color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : AppColors.panelBackground.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color.withValues(alpha: 0.7) : AppColors.text.withValues(alpha: 0.1),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Color indicator with animation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 1,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 6),

                // Category name with animation
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? color : AppColors.text.withValues(alpha: 0.7),
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddCategoryButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          // Unfocus any text fields before showing bottom sheet
          context.read<AddTaskProvider>().unfocusAll();
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            barrierColor: Colors.transparent,
            builder: (context) => const CreateCategoryBottomSheet(
              initialCategoryType: CategoryType.task,
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.main.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                Icons.add_rounded,
                size: 16,
                color: AppColors.main,
              ),
              const SizedBox(width: 4),
              Text(
                LocaleKeys.Add.tr(),
                style: TextStyle(
                  color: AppColors.main,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
