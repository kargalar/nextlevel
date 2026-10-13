import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Page/Task%20Detail%20Page/view_model/checkbox_status_view_model.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';

class CheckboxStatusWidget extends StatefulWidget {
  final TaskModel taskModel;
  final VoidCallback onStatusChanged;
  final TaskLogProvider taskLogProvider;

  const CheckboxStatusWidget({
    super.key,
    required this.taskModel,
    required this.onStatusChanged,
    required this.taskLogProvider,
  });

  @override
  State<CheckboxStatusWidget> createState() => _CheckboxStatusWidgetState();
}

class _CheckboxStatusWidgetState extends State<CheckboxStatusWidget> {
  late final CheckboxStatusViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = CheckboxStatusViewModel(
      taskModel: widget.taskModel,
      taskLogProvider: widget.taskLogProvider,
    );

    // ViewModel'deki değişiklikleri dinle
    _viewModel.addListener(() {
      widget.onStatusChanged();
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            _getCheckboxStatus(),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusButton(
                label: LocaleKeys.Done.tr(),
                status: TaskStatusEnum.DONE,
                color: AppColors.green,
              ),
              _buildStatusButton(
                label: LocaleKeys.Failed.tr(),
                status: TaskStatusEnum.FAILED,
                color: AppColors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getCheckboxStatus() {
    switch (_viewModel.currentStatus) {
      case TaskStatusEnum.DONE:
        return LocaleKeys.Done.tr();
      case TaskStatusEnum.FAILED:
        return LocaleKeys.Failed.tr();
      case TaskStatusEnum.CANCEL:
        return LocaleKeys.Cancelled.tr();
      case TaskStatusEnum.SKIPPED:
        return LocaleKeys.Skipped.tr();
      default:
        return LocaleKeys.InProgress.tr();
    }
  }

  // Status change button
  Widget _buildStatusButton({
    required String label,
    required TaskStatusEnum status,
    required Color color,
  }) {
    final bool isSelected = _viewModel.currentStatus == status;

    return ElevatedButton(
      onPressed: () {
        _viewModel.updateStatus(status);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : color.withValues(alpha: 0.2),
        foregroundColor: isSelected ? Colors.white : color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12),
      ),
      child: Text(label),
    );
  }
}
