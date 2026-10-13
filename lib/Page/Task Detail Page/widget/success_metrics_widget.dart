import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Page/Task%20Detail%20Page/view_model/task_detail_view_model.dart';

class SuccessMetricsWidget extends StatelessWidget {
  final TaskDetailViewModel viewModel;

  const SuccessMetricsWidget({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            Text("${viewModel.completedTaskCount} ${LocaleKeys.Times.tr()}"),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.close, color: Colors.red),
            Text("${viewModel.failedTaskCount} ${LocaleKeys.Times.tr()}"),
          ],
        ),
        Text(
          "%${viewModel.successRate}",
          style: const TextStyle(fontSize: 18),
        ),
      ],
    );
  }
}
