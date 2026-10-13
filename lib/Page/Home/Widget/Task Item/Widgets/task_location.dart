import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:url_launcher/url_launcher.dart';

class TaskLocation extends StatelessWidget {
  const TaskLocation({
    super.key,
    required this.taskModel,
  });

  final TaskModel taskModel;

  @override
  Widget build(BuildContext context) {
    if (taskModel.location == null || taskModel.location!.isEmpty) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: () => _launchMaps(taskModel.location!),
      borderRadius: AppColors.borderRadiusAll,
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.panelBackground,
            borderRadius: AppColors.borderRadiusAll,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on,
                size: 16,
                color: AppColors.red,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  taskModel.location!.length > 15 ? "${taskModel.location!.substring(0, 15)}..." : taskModel.location!,
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchMaps(String location) async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}
