import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/log_display_model.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:next_level/Widgets/Common/log_bottom_sheet.dart';

class RecentLogsWidget extends StatefulWidget {
  final List<LogDisplayModel> logs;
  final VoidCallback?
      onAddLog; // For generic add or if we want to trigger external logic
  final Function(dynamic value, DateTime date)?
      onAddLogSubmit; // If we want to handle add inside
  final Function(LogDisplayModel log, dynamic newValue, DateTime date)?
      onEditLog;
  final Function(LogDisplayModel log)? onDeleteLog;
  final VoidCallback? onClearAll;
  final TaskTypeEnum? defaultType; // Needed for Add dialog if logs is empty
  final bool showAddButton;

  const RecentLogsWidget({
    super.key,
    required this.logs,
    this.onAddLog,
    this.onAddLogSubmit,
    this.onEditLog,
    this.onDeleteLog,
    this.onClearAll,
    this.defaultType,
    this.showAddButton = false,
  });

  @override
  State<RecentLogsWidget> createState() => _RecentLogsWidgetState();
}

class _RecentLogsWidgetState extends State<RecentLogsWidget> {
  bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String _getDateHeaderLabel(LogDisplayModel log) {
    return log.datePart?.tr() ?? DateFormat('d MMM yyyy').format(log.dateTime);
  }

  void _showAddLogDialog() async {
    if (widget.defaultType == null) return;

    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => LogBottomSheet(
        type: widget.defaultType!,
        isEdit: false,
      ),
    );

    if (result != null && widget.onAddLogSubmit != null) {
      if (result is LogResult) {
        widget.onAddLogSubmit!(result.value, result.date);
      } else {
        widget.onAddLogSubmit!(result, DateTime.now());
      }
    }
  }

  void _showEditLogDialog(LogDisplayModel log) async {
    if (!log.canEdit || widget.onEditLog == null) return;

    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => LogBottomSheet(
        type: log.type,
        initialValue: log.type == TaskTypeEnum.CHECKBOX
            ? log.rawStatus
            : log.amount, // Pass raw status for Checkbox
        initialDate: log.dateTime,
        isEdit: true,
      ),
    );

    if (result != null) {
      if (result == 'DELETE') {
        widget.onDeleteLog?.call(log);
      } else if (result is LogResult) {
        widget.onEditLog!(log, result.value, result.date);
      } else {
        widget.onEditLog!(log, result, log.dateTime);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          if (widget.logs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.history_toggle_off,
                        size: 32, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text(
                      LocaleKeys.NoLogsYet.tr(),
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                for (int index = 0; index < widget.logs.length; index++) ...[
                  if (index == 0 ||
                      !_isSameDate(widget.logs[index - 1].dateTime,
                          widget.logs[index].dateTime))
                    _buildDateHeader(widget.logs[index]),
                  _buildLogItem(widget.logs[index]),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(LogDisplayModel log) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(
        children: [
          Text(
            _getDateHeaderLabel(log),
            style: TextStyle(
              color: AppColors.main,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(
              color: Colors.grey.withValues(alpha: 0.15),
              thickness: 1,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${LocaleKeys.RecentLogs.tr()} (${widget.logs.length})',
          style: const TextStyle(color: Colors.grey),
        ),
        Row(
          children: [
            if (widget.onClearAll != null && widget.logs.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear_all, size: 20, color: Colors.red),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(LocaleKeys.ConfirmationTitle.tr()),
                      content: Text(LocaleKeys.ClearAllLogsConfirmation.tr()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(LocaleKeys.Cancel.tr()),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(LocaleKeys.Delete.tr(),
                              style: const TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    widget.onClearAll!();
                  }
                },
                tooltip: LocaleKeys.ClearAllLogs.tr(),
              ),
            if (widget.showAddButton && widget.onAddLogSubmit != null)
              IconButton(
                icon: Icon(
                  Icons.add,
                  color: AppColors.main,
                  size: 20,
                ),
                onPressed: _showAddLogDialog,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLogItem(LogDisplayModel log) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Slidable(
        key: ValueKey(log.id),
        endActionPane: (widget.onDeleteLog != null)
            ? ActionPane(
                motion: const ScrollMotion(),
                extentRatio: 0.25,
                children: [
                  SlidableAction(
                    onPressed: (context) {
                      widget.onDeleteLog!(log);
                    },
                    backgroundColor: AppColors.red,
                    foregroundColor: Colors.white,
                    icon: Icons.delete,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              )
            : null,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: (log.canEdit && widget.onEditLog != null)
                ? () => _showEditLogDialog(log)
                : null,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: Row(
                children: [
                  // Icon based on status or type
                  _buildLogIcon(log),
                  const SizedBox(width: 12),

                  // Date and Time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: DateFormat('HH:mm').format(log.dateTime),
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (log.status.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: _buildStatusPill(log),
                          ),
                      ],
                    ),
                  ),

                  // Value
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        log.displayAmount,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.text,
                        ),
                      ),
                      if (log.isPurchase)
                        Text(
                          'PURCHASED',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: AppColors.main,
                            letterSpacing: 0.5,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogIcon(LogDisplayModel log) {
    if (log.isPurchase) {
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.main.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.shopping_cart, size: 16, color: AppColors.main),
      );
    }

    Color iconColor;
    IconData iconData;

    switch (log.status) {
      case 'Done':
        iconColor = AppColors.green;
        iconData = Icons.check;
        break;
      case 'Failed':
        iconColor = AppColors.red;
        iconData = Icons.close;
        break;
      case 'Skipped':
        iconColor = AppColors.orange;
        iconData = Icons.skip_next;
        break;
      default:
        iconColor = Colors.grey[400]!;
        iconData = Icons.history;
    }

    if (log.statusColor != null) {
      iconColor = log.statusColor!;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, size: 16, color: iconColor),
    );
  }

  Widget _buildStatusPill(LogDisplayModel log) {
    Color color = log.statusColor ?? Colors.grey;
    if (log.status == 'Done') color = AppColors.green;
    if (log.status == 'Failed') color = AppColors.red;
    if (log.status == 'Skipped') color = AppColors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        log.status,
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }
}
