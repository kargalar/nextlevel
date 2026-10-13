import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/create_trait_bottom_sheet.dart';
import 'package:next_level/Page/Profile/Widget/skill_list_item.dart';
import 'package:next_level/Page/Profile/Widget/attribute_list_item.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Provider/trait_provider.dart';
import 'package:next_level/Enum/trait_type_enum.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Provider/profile_view_model.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Widgets/Common/app_components.dart';

class TraitList extends StatefulWidget {
  const TraitList({
    super.key,
    required this.isSkill,
  });

  final bool isSkill;

  @override
  State<TraitList> createState() => _TraitListState();
}

class _TraitListState extends State<TraitList> {
  @override
  Widget build(BuildContext context) {
    LogService.debug(
        "TraitList: Building trait list successfully - colors updated from AppColors");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          eyebrow: widget.isSkill ? 'DEVELOPMENT' : 'FOUNDATION',
          title: widget.isSkill
              ? LocaleKeys.Skills.tr()
              : LocaleKeys.Attributes.tr(),
          action: IconButton(
            tooltip: LocaleKeys.Add.tr(),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: AppColors.transparent,
                barrierColor: AppColors.transparent,
                builder: (context) =>
                    CreateTraitBottomSheet(isSkill: widget.isSkill),
              ).then((value) => setState(() {}));
            },
            icon: const Icon(Icons.add_rounded),
          ),
        ),
        const SizedBox(height: 2),
        Builder(builder: (context) {
          final traitProvider = Provider.of<TraitProvider>(context);
          final skills = traitProvider.traitList
              .where((t) => t.type == TraitTypeEnum.SKILL && !t.isArchived)
              .toList();
          final attributes = traitProvider.traitList
              .where((t) => t.type == TraitTypeEnum.ATTRIBUTE && !t.isArchived)
              .toList();

          if (widget.isSkill) {
            // Use combined totals to include TIMER, COUNTER, and CHECKBOX (reactive)
            final viewModel = context.watch<ProfileViewModel>();
            final traitTotals = viewModel.getTraitTotalsCombined(isSkill: true);
            // Single preferred design: gradient-tinted 2-column grid
            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.6,
              children: skills.map((skill) {
                final Duration totalDuration =
                    traitTotals[skill.id] ?? Duration.zero;
                return SkillListItem(
                  skill: skill,
                  totalDuration: totalDuration,
                );
              }).toList(),
            );
          }

          // Attributes: show compact 2-column grid
          final viewModel = context.watch<ProfileViewModel>();
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.8,
            children: attributes.map((attribute) {
              final traitTotals =
                  viewModel.getTraitTotalsCombined(isSkill: false);
              final Duration totalDuration =
                  traitTotals[attribute.id] ?? Duration.zero;

              return AttributeListItem(
                attribute: attribute,
                totalDuration: totalDuration,
              );
            }).toList(),
          );
        })
      ],
    );
  }
}
