import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Trait%20Detail%20Page/trait_detail_page.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Model/trait_model.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import 'package:provider/provider.dart';

class TraitItem extends StatefulWidget {
  const TraitItem({
    super.key,
    required this.trait,
    this.isStatisticsPage = false,
    this.onChanged,
  });

  final TraitModel trait;
  final bool isStatisticsPage;
  final VoidCallback? onChanged;

  @override
  State<TraitItem> createState() => _TraitItemState();
}

class _TraitItemState extends State<TraitItem> {
  late final addTaskProvider = context.read<AddTaskProvider>();

  late bool isSelected;

  @override
  void initState() {
    super.initState();
    if (widget.isStatisticsPage) {
      isSelected = true;
    } else {
      isSelected = addTaskProvider.selectedTraits.contains(widget.trait);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          // Unfocus any text fields when selecting trait
          if (!widget.isStatisticsPage) {
            addTaskProvider.unfocusAll();
          }

          if (widget.isStatisticsPage) {
            await NavigatorService().goTo(
              TraitDetailPage(traitModel: widget.trait),
            );
          } else {
            if (isSelected) {
              addTaskProvider.selectedTraits.remove(widget.trait);
            } else {
              addTaskProvider.selectedTraits.add(widget.trait);
            }
            setState(() {
              isSelected = !isSelected;
            }); // Notify parent widget of the change
            widget.onChanged?.call();

            // Also trigger real-time updates for any listening widgets
            addTaskProvider.updateTraitSelection();
          }
        },
        onLongPress: () async {
          // Unfocus any text fields when long pressing trait
          if (!widget.isStatisticsPage) {
            addTaskProvider.unfocusAll();
          }

          await NavigatorService().goTo(
            TraitDetailPage(
              traitModel: widget.trait,
            ),
            transition: Transition.rightToLeft,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? widget.trait.color.withValues(alpha: 0.9) : AppColors.panelBackground.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? widget.trait.color : AppColors.text.withValues(alpha: 0.1),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: widget.trait.color.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Stack(
              children: [
                // Main content (icon and title)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon
                    Text(
                      widget.trait.icon,
                      style: TextStyle(
                        fontSize: 24,
                        shadows: isSelected
                            ? [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                    ),

                    // Small space between icon and title
                    const SizedBox(height: 4),

                    // Trait title
                    Text(
                      widget.trait.title,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: AppColors.text,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
