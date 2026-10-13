import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Page/Task%20Detail%20Page/view_model/task_detail_view_model.dart';

class BestPerformanceWidget extends StatelessWidget {
  final TaskDetailViewModel viewModel;

  const BestPerformanceWidget({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          children: [
            Text(LocaleKeys.BestHour.tr(), style: const TextStyle(color: Colors.grey)),
            Text(viewModel.bestHour),
          ],
        ),
        Column(
          children: [
            Text(LocaleKeys.BestDay.tr(), style: const TextStyle(color: Colors.grey)),
            Text(viewModel.bestDay),
          ],
        ),
      ],
    );
  }
}
