import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Task%20Detail%20Page/view_model/task_detail_view_model.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Page/Task%20Detail%20Page/widget/progress_bar.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Provider/trait_provider.dart';
import 'package:next_level/Page/Trait Detail Page/trait_detail_page.dart';

class TraitProgressWidget extends StatelessWidget {
  final TaskDetailViewModel viewModel;

  const TraitProgressWidget({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    if (!viewModel.hasTraits) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: AppColors.borderRadiusAll,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Attributes Section
          if (viewModel.attributeProgressList.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: AppColors.main,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  LocaleKeys.Attributes.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildTraitGrid(viewModel.attributeProgressList),
            const SizedBox(height: 16),
          ],

          // Skills Section
          if (viewModel.skillProgressList.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: AppColors.main,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  LocaleKeys.Skills.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildTraitGrid(viewModel.skillProgressList),
          ],
        ],
      ),
    );
  }

  Widget _buildTraitGrid(List<TraitProgressData> list) {
    final bars = list
        .map(
          (e) => ProgressBar(
            title: e.title,
            progress: e.progress,
            color: e.color,
            icon: e.icon,
            onTap: () async {
              // Find trait by id and navigate to its detail page
              final trait = TraitProvider().traitList.firstWhere(
                    (t) => t.id == e.traitId,
                    orElse: () => throw ArgumentError('Trait not found: ${e.traitId}'),
                  );
              await NavigatorService().goTo(TraitDetailPage(traitModel: trait));
            },
          ),
        )
        .toList();

    // If there's only one trait, don't use a grid
    if (bars.length == 1) {
      return bars.first;
    }

    // Create a grid layout for multiple traits
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: bars.length,
      itemBuilder: (c, i) => bars[i],
    );
  }
}
