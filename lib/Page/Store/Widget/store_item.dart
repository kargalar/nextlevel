import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/General/accessible.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Store/add_store_item_page.dart';
import 'package:next_level/Page/Store/Widget/store_item_buy_button.dart';
import 'package:next_level/Page/Store/Widget/store_item_type_icon.dart';
import 'package:next_level/Page/Task%20Detail%20Page/view_model/task_progress_view_model.dart';
import 'package:next_level/Service/global_timer.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Repository/store_repository.dart';
import 'package:next_level/Provider/store_provider.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/store_item_model.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Widgets/Common/log_bottom_sheet.dart';
import 'package:next_level/Widgets/Common/app_components.dart';

class StoreItem extends StatefulWidget {
  const StoreItem({
    super.key,
    required this.storeItemModel,
  });

  final ItemModel storeItemModel;

  @override
  State<StoreItem> createState() => _StoreItemState();
}

class _StoreItemState extends State<StoreItem> {
  ItemModel get _item => widget.storeItemModel;
  bool get _isTimerActive => _item.isTimerActive ?? false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Slidable(
        key: ValueKey(_item.id),
        startActionPane: _buildEditAction(),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            splashColor: AppColors.main.withValues(alpha: 0.08),
            highlightColor: AppColors.main.withValues(alpha: 0.04),
            onTap: _handleItemAction,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _isTimerActive
                      ? AppColors.main.withValues(alpha: 0.55)
                      : AppColors.outlineSoft,
                  width: _isTimerActive ? 1.4 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.deepBlack.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                  if (_isTimerActive)
                    BoxShadow(
                      color: AppColors.main.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StoreItemTypeIcon(
                        type: _item.type,
                        isTimerActive: _isTimerActive,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTitleSection()),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: _buildItemSummary()),
                      const SizedBox(width: 10),
                      StoreItemBuyButton(
                        amountText: _buildAmountText(),
                        credit: _item.credit,
                        onTap: _handlePurchase,
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

  // ──────────────────── UI BUILDERS ────────────────────

  ActionPane _buildEditAction() {
    final bool canAddLog =
        _item.type == TaskTypeEnum.COUNTER || _item.type == TaskTypeEnum.TIMER;
    final double extentRatio =
        canAddLog ? 0.6 : 0.4; // Increase extent if there are 2 actions

    return ActionPane(
      extentRatio: extentRatio,
      dismissible: DismissiblePane(
        dismissThreshold: 0.3,
        closeOnCancel: true,
        confirmDismiss: () async {
          await NavigatorService()
              .goTo(
                AddStoreItemPage(editItemModel: _item),
                transition: Transition.size,
              )
              .then((_) => StoreProvider().setStateItems());
          return false;
        },
        onDismissed: () {},
      ),
      motion: const ScrollMotion(),
      children: [
        SlidableAction(
          onPressed: (_) async {
            await NavigatorService()
                .goTo(
                  AddStoreItemPage(editItemModel: _item),
                  transition: Transition.size,
                )
                .then((_) => StoreProvider().setStateItems());
          },
          backgroundColor: AppColors.matteBlue,
          borderRadius: BorderRadius.circular(14),
          foregroundColor: Colors.white,
          icon: Icons.edit_rounded,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          label: LocaleKeys.Edit.tr(),
        ),
        if (canAddLog) _buildAddLogAction(),
      ],
    );
  }

  SlidableAction _buildAddLogAction() {
    return SlidableAction(
      onPressed: (context) async {
        LogService.debug('📝 Store Item ${_item.id} - Add log action started');
        final result = await showModalBottomSheet<dynamic>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => LogBottomSheet(
            type: _item.type,
            isEdit: false,
          ),
        );

        if (result != null && result is LogResult) {
          try {
            Duration? customDuration;
            int? customCount;

            if (_item.type == TaskTypeEnum.TIMER && result.value is Duration) {
              customDuration = result.value;
            } else if (_item.type == TaskTypeEnum.COUNTER &&
                result.value is int) {
              customCount = result.value;
            }

            await TaskProgressViewModel.addStoreItemLog(
              itemId: _item.id,
              action: 'manual_add',
              value: customDuration ?? customCount ?? 0,
              logDate: result.date,
              type: _item.type,
              affectsProgress: true,
            );

            LogService.debug(
                '✅ Store Item ${_item.id} - Log added successfully');
            StoreProvider().setStateItems();
          } catch (e) {
            LogService.error(
                '❌ Store Item ${_item.id} - Failed to add log: $e');
          }
        } else {
          LogService.debug('⚠️ Store Item ${_item.id} - Add log cancelled');
        }
      },
      backgroundColor: AppColors.matteGreen,
      borderRadius: BorderRadius.circular(14),
      icon: Icons.add_chart,
      label: LocaleKeys.AddManualLog.tr(),
      foregroundColor: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _item.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                  letterSpacing: -0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_isTimerActive) ...[
              const SizedBox(width: 8),
              _buildActivePill(),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _buildTypeLabel(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _typeColor.withValues(alpha: 0.9),
            letterSpacing: 1.1,
          ),
        ),
        if (_item.description != null && _item.description!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            _item.description!,
            style: const TextStyle(
              fontSize: 12,
              height: 1.25,
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildActivePill() {
    return AppStatusPill(
      label: LocaleKeys.TimerActive.tr(),
      color: AppColors.main,
      icon: Icons.circle,
    );
  }

  Widget _buildItemSummary() {
    final summary = _buildSummaryData();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _typeColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            summary.icon,
            size: 15,
            color: _typeColor.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            summary.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (_item.type != TaskTypeEnum.CHECKBOX) ...[
          const SizedBox(width: 8),
          _buildRemainingBadge(),
        ],
      ],
    );
  }

  _StoreItemSummary _buildSummaryData() {
    switch (_item.type) {
      case TaskTypeEnum.CHECKBOX:
        return _StoreItemSummary(
            Icons.check_circle_outline, LocaleKeys.Checkbox.tr());
      case TaskTypeEnum.COUNTER:
        return _StoreItemSummary(
          Icons.add_circle_outline_rounded,
          '+${_item.addCount ?? 1} ${LocaleKeys.Counter.tr()}',
        );
      case TaskTypeEnum.TIMER:
        return _StoreItemSummary(
          Icons.timelapse_rounded,
          '+${_item.addDuration?.textLongDynamicWithoutZero() ?? ''} ${LocaleKeys.Timer.tr()}',
        );
      case TaskTypeEnum.FREEZE:
        return _StoreItemSummary(
            Icons.ac_unit_rounded, LocaleKeys.UsePassDay.tr());
    }
  }

  String _buildTypeLabel() {
    switch (_item.type) {
      case TaskTypeEnum.CHECKBOX:
        return LocaleKeys.Checkbox.tr().toUpperCase();
      case TaskTypeEnum.COUNTER:
        return LocaleKeys.Counter.tr().toUpperCase();
      case TaskTypeEnum.TIMER:
        return LocaleKeys.Timer.tr().toUpperCase();
      case TaskTypeEnum.FREEZE:
        return LocaleKeys.UsePassDay.tr().toUpperCase();
    }
  }

  Color get _typeColor {
    if (_isTimerActive) return AppColors.main;

    switch (_item.type) {
      case TaskTypeEnum.CHECKBOX:
        return AppColors.green;
      case TaskTypeEnum.COUNTER:
        return AppColors.orange;
      case TaskTypeEnum.TIMER:
        return AppColors.purple;
      case TaskTypeEnum.FREEZE:
        return AppColors.blue;
    }
  }

  Widget _buildRemainingBadge() {
    final String valueText;
    final Color badgeColor;
    final IconData iconData;

    if (_item.type == TaskTypeEnum.COUNTER) {
      valueText = '${_item.currentCount}';
      badgeColor = AppColors.text;
      iconData = Icons.numbers_rounded;
    } else if (_item.type == TaskTypeEnum.FREEZE) {
      valueText = '${loginUser?.freezeCount ?? 0}';
      badgeColor = AppColors.blue;
      iconData = Icons.ac_unit_rounded;
    } else {
      valueText = _item.currentDuration!.textShortDynamic();
      badgeColor = _isTimerActive ? AppColors.main : AppColors.text;
      iconData = Icons.timer_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: badgeColor.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 13, color: badgeColor.withValues(alpha: 0.7)),
          const SizedBox(width: 4),
          Text(
            valueText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: badgeColor.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  String _buildAmountText() {
    if (_item.type == TaskTypeEnum.COUNTER ||
        _item.type == TaskTypeEnum.FREEZE) {
      return '${_item.addCount ?? 1}';
    }
    return _item.addDuration?.textLongDynamicWithoutZero() ?? '';
  }

  // ──────────────────── ACTIONS ────────────────────

  Future<bool> _handlePurchase({bool showAutoPurchaseMessage = false}) async {
    return StoreProvider().purchaseItem(
      _item,
      showSuccessMessage: showAutoPurchaseMessage,
    );
  }

  void _handleItemAction() async {
    dynamic value;
    String action;

    if (_item.type == TaskTypeEnum.COUNTER) {
      // Count 0'dayken kullanılmaya çalışılırsa otomatik satın al
      if (_item.currentCount! <= 0) {
        LogService.debug('🛒 Counter at 0 – auto-purchasing ${_item.title}');
        final purchased = await _handlePurchase(showAutoPurchaseMessage: true);
        if (!purchased) return;
      }
      _item.currentCount = _item.currentCount! - 1;
      value = -1;
      action = 'Usage';
      StoreRepository().updateItem(_item);
    } else {
      bool wasTimerActive = _isTimerActive;

      if (!wasTimerActive &&
          _item.type == TaskTypeEnum.TIMER &&
          (_item.currentDuration ?? Duration.zero) <= Duration.zero) {
        final purchased = await _handlePurchase(showAutoPurchaseMessage: true);
        if (!purchased) return;
      }

      Duration? elapsedTime;
      if (wasTimerActive) {
        final prefs = await SharedPreferences.getInstance();
        String? timerStartTimeStr =
            prefs.getString('item_timer_start_time_${_item.id}');
        String? timerStartDurationStr =
            prefs.getString('item_timer_start_duration_${_item.id}');

        LogService.debug('DEBUG: Timer will be stopped for item ${_item.id}');
        LogService.debug('DEBUG: timerStartTimeStr = $timerStartTimeStr');
        LogService.debug(
            'DEBUG: timerStartDurationStr = $timerStartDurationStr');

        if (timerStartTimeStr != null && timerStartDurationStr != null) {
          DateTime timerStartTime =
              DateTime.fromMillisecondsSinceEpoch(int.parse(timerStartTimeStr));
          DateTime currentTime = DateTime.now();

          elapsedTime = currentTime.difference(timerStartTime);

          LogService.debug('DEBUG: timerStartTime = $timerStartTime');
          LogService.debug('DEBUG: currentTime = $currentTime');
          LogService.debug(
              'DEBUG: elapsedTime = ${elapsedTime.inSeconds} seconds (${elapsedTime.inMinutes}m ${elapsedTime.inSeconds % 60}s)');
          LogService.debug(
              'DEBUG: elapsedTime.inMilliseconds = ${elapsedTime.inMilliseconds}');
        }
      }

      bool success = await GlobalTimer().startStopTimer(storeItemModel: _item);
      if (!success) return;

      if (!wasTimerActive && _isTimerActive) {
        action = 'Timer Started';
        value = Duration.zero;
      } else if (wasTimerActive && !_isTimerActive) {
        action = 'Timer Stopped';

        if (elapsedTime != null) {
          value = -elapsedTime;
          LogService.debug('DEBUG: value to log = ${value.inSeconds} seconds');
          LogService.debug(
              'DEBUG: value.inMinutes = ${value.inMinutes}, value.inSeconds % 60 = ${value.inSeconds % 60}');
        } else {
          LogService.debug(
              'DEBUG: Timer data was not available, logging as zero');
          value = Duration.zero;
        }
      } else {
        value = Duration.zero;
        action = 'Timer Action';
      }

      StoreRepository().updateItem(_item);
    }

    if (_item.type == TaskTypeEnum.COUNTER ||
        (_item.type == TaskTypeEnum.TIMER && action == 'Timer Stopped')) {
      await TaskProgressViewModel.addStoreItemLog(
        itemId: _item.id,
        action: action,
        value: value,
        type: _item.type,
      );
    }

    StoreProvider().setStateItems();
  }
}

class _StoreItemSummary {
  const _StoreItemSummary(this.icon, this.label);

  final IconData icon;
  final String label;
}
