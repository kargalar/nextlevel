import 'package:flutter/material.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Page/Trait%20Detail%20Page/trait_detail_page.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/trait_model.dart';
import 'package:get/route_manager.dart';

class TraitItemDetailed extends StatefulWidget {
  const TraitItemDetailed({
    super.key,
    required this.trait,
  });

  final TraitModel trait;

  @override
  State<TraitItemDetailed> createState() => _TraitItemDetailedState();
}

class _TraitItemDetailedState extends State<TraitItemDetailed> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // compute duration fresh
    final Duration totalDuration = TaskProvider().taskList.fold(
      Duration.zero,
      (previousValue, element) {
        if (((element.skillIDList != null && element.skillIDList!.contains(widget.trait.id)) || (element.attributeIDList != null && element.attributeIDList!.contains(widget.trait.id))) && element.remainingDuration != null) {
          if (element.type == TaskTypeEnum.CHECKBOX && element.status != TaskStatusEnum.DONE) {
            return previousValue;
          }
          return previousValue +
              (element.type == TaskTypeEnum.CHECKBOX
                  ? element.remainingDuration!
                  : element.type == TaskTypeEnum.COUNTER
                      ? element.remainingDuration! * element.currentCount!
                      : element.currentDuration!);
        }
        return previousValue;
      },
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: () async {
          await NavigatorService().goTo(
            TraitDetailPage(
              traitModel: widget.trait,
            ),
            transition: Transition.rightToLeft,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6, offset: const Offset(0, 2))],
            border: Border.all(color: widget.trait.color.withValues(alpha: 0.15)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: widget.trait.color, borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text(widget.trait.icon, style: const TextStyle(fontSize: 20, color: Colors.white))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.trait.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(totalDuration.textShort2hour(), style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(totalDuration.toLevel(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
