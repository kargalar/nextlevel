import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Enum/trait_type_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/trait_model.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/compact_trait_chip.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/create_trait_bottom_sheet.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/trait_item.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Provider/trait_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Widgets/clickable_tooltip.dart';
import 'package:provider/provider.dart';

class CompactTraitOptions extends StatefulWidget {
  const CompactTraitOptions({super.key});

  @override
  State<CompactTraitOptions> createState() => _CompactTraitOptionsState();
}

class _CompactTraitOptionsState extends State<CompactTraitOptions> {
  @override
  Widget build(BuildContext context) {
    context.watch<TraitProvider>();
    final addTaskProvider = context.watch<AddTaskProvider>();
    final traitProvider = TraitProvider();

    // Get attributes and skills
    final attributes = traitProvider.traitList.where((trait) => trait.type == TraitTypeEnum.ATTRIBUTE).toList();
    final skills = traitProvider.traitList.where((trait) => trait.type == TraitTypeEnum.SKILL).toList();

    // Get selected attributes and skills
    final selectedAttributes = addTaskProvider.selectedTraits.where((trait) => trait.type == TraitTypeEnum.ATTRIBUTE).toList();
    final selectedSkills = addTaskProvider.selectedTraits.where((trait) => trait.type == TraitTypeEnum.SKILL).toList();

    // Calculate total selected traits
    final totalSelected = selectedAttributes.length + selectedSkills.length;

    return Container(
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
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with total count
          Row(
            children: [
              Icon(
                Icons.psychology_rounded,
                color: AppColors.main,
                size: 18,
              ),
              const SizedBox(width: 6),
              ClickableTooltip(
                titleKey: LocaleKeys.tooltip_attributes_skills_title,
                bulletPoints: [
                  LocaleKeys.tooltip_attributes_skills_bullet_1.tr(),
                  LocaleKeys.tooltip_attributes_skills_bullet_2.tr(),
                  LocaleKeys.tooltip_attributes_skills_bullet_3.tr(),
                ],
                child: Text(
                  "${LocaleKeys.Attributes.tr()} & ${LocaleKeys.Skills.tr()}",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              // Show total selected count
              if (totalSelected > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.main.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    totalSelected.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.main,
                    ),
                  ),
                ),
            ],
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(
              color: AppColors.text.withValues(alpha: 0.1),
              height: 1,
            ),
          ),

          // Trait sections in a row for more compact layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Attributes section
              Expanded(
                child: _buildTraitSection(
                  context: context,
                  title: LocaleKeys.Attributes.tr(),
                  icon: Icons.auto_awesome_rounded,
                  traits: attributes,
                  selectedTraits: selectedAttributes,
                  isSkill: false,
                  onAddTap: () => _showTraitBottomSheet(context, false),
                  onViewAllTap: () => _showTraitsBottomSheet(context, false),
                ),
              ),

              const SizedBox(width: 8),

              // Skills section
              Expanded(
                child: _buildTraitSection(
                  context: context,
                  title: LocaleKeys.Skills.tr(),
                  icon: Icons.psychology_rounded,
                  traits: skills,
                  selectedTraits: selectedSkills,
                  isSkill: true,
                  onAddTap: () => _showTraitBottomSheet(context, true),
                  onViewAllTap: () => _showTraitsBottomSheet(context, true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTraitSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<TraitModel> traits,
    required List<TraitModel> selectedTraits,
    required bool isSkill,
    required VoidCallback onAddTap,
    required VoidCallback onViewAllTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onViewAllTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.text.withValues(alpha: 0.1),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header
              Row(
                children: [
                  Icon(
                    icon,
                    color: AppColors.main,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  // Selected count
                  if (selectedTraits.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.main.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        selectedTraits.length.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.main,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Add button
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: onAddTap,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.main.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: AppColors.main,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Selected traits preview or empty state
              if (selectedTraits.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    isSkill ? "No skills selected" : "No attributes selected",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.text.withValues(alpha: 0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 90), // Increased to allow more space for wrapping
                  child: SingleChildScrollView(
                    child: Wrap(
                      runSpacing: 8,
                      children: selectedTraits.map((trait) => CompactTraitChip(trait: trait)).toList(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTraitBottomSheet(BuildContext context, bool isSkill) {
    final addTaskProvider = context.read<AddTaskProvider>();
    addTaskProvider.unfocusAll();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => CreateTraitBottomSheet(isSkill: isSkill),
    ).then(
      (value) {
        setState(() {});
      },
    );
  }

  void _showTraitsBottomSheet(BuildContext context, bool isSkill) {
    final addTaskProvider = context.read<AddTaskProvider>();
    addTaskProvider.unfocusAll();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => TraitsBottomSheet(
        isSkill: isSkill,
        onChanged: () {
          setState(() {});
        },
      ),
    ).then(
      (value) {
        setState(() {});
      },
    );
  }
}

class TraitsBottomSheet extends StatefulWidget {
  final bool isSkill;
  final VoidCallback? onChanged;

  const TraitsBottomSheet({
    super.key,
    required this.isSkill,
    this.onChanged,
  });

  @override
  State<TraitsBottomSheet> createState() => _TraitsBottomSheetState();
}

class _TraitsBottomSheetState extends State<TraitsBottomSheet> {
  @override
  Widget build(BuildContext context) {
    context.watch<TraitProvider>();
    context.watch<AddTaskProvider>(); // Watch for trait selection changes
    final traitProvider = TraitProvider();
    final traits = widget.isSkill ? traitProvider.traitList.where((trait) => trait.type == TraitTypeEnum.SKILL).toList() : traitProvider.traitList.where((trait) => trait.type == TraitTypeEnum.ATTRIBUTE).toList();

    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
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

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.isSkill ? Icons.psychology_rounded : Icons.auto_awesome_rounded,
                      color: AppColors.main,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    ClickableTooltip(
                      titleKey: widget.isSkill ? LocaleKeys.Skills : LocaleKeys.Attributes,
                      bulletPoints: [
                        LocaleKeys.tooltip_skills_attributes_bullet_1.tr(args: [widget.isSkill ? 'skill'.tr() : 'attribute'.tr()]),
                        LocaleKeys.tooltip_skills_attributes_bullet_2.tr(args: [widget.isSkill ? 'skill'.tr() : 'attribute'.tr()]),
                        widget.isSkill ? LocaleKeys.tooltip_skills_attributes_bullet_3.tr(args: ['Skills'.tr()]) : LocaleKeys.tooltip_attributes_bullet_3.tr(args: ['Attributes'.tr()]),
                      ],
                      child: Text(
                        widget.isSkill ? LocaleKeys.Skills.tr() : LocaleKeys.Attributes.tr(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                _buildAddTraitButton(context),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Traits content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: traits.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          Icon(
                            widget.isSkill ? Icons.psychology_alt_outlined : Icons.auto_awesome_outlined,
                            color: AppColors.text.withValues(alpha: 0.3),
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.isSkill ? "No skills yet" : "No attributes yet",
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
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const AlwaysScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        childAspectRatio: 1,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: traits.length,
                      itemBuilder: (context, index) {
                        return TraitItem(
                          trait: traits[index],
                          onChanged: () {
                            setState(() {});
                            // Notify parent to update the main trait options display
                            widget.onChanged?.call();
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddTraitButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          // Unfocus any text fields when opening bottom sheet
          context.read<AddTaskProvider>().unfocusAll();

          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            barrierColor: Colors.transparent,
            builder: (context) => CreateTraitBottomSheet(isSkill: widget.isSkill),
          ).then(
            (value) {
              setState(() {});
            },
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.main.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                size: 18,
                color: AppColors.main,
              ),
              const SizedBox(width: 4),
              Text(
                LocaleKeys.Add.tr(),
                style: TextStyle(
                  color: AppColors.main,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
