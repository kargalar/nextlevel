import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/log_display_model.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/duraiton_picker.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/select_task_type.dart';
import 'package:next_level/Page/Home/Add%20Task/Widget/task_name.dart';

import 'package:next_level/Widgets/Common/log_bottom_sheet.dart';

import 'package:next_level/Page/Store/Widget/set_credit.dart';
import 'package:next_level/Widgets/Common/recent_logs_widget.dart';
import 'package:next_level/Page/Task%20Detail%20Page/view_model/task_progress_view_model.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Service/hive_service.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Provider/add_store_item_provider.dart';
import 'package:next_level/Provider/store_provider.dart';
import 'package:next_level/Model/store_item_model.dart';
import 'package:provider/provider.dart';

class AddStoreItemPage extends StatefulWidget {
  const AddStoreItemPage({
    super.key,
    this.editItemModel,
  });

  final ItemModel? editItemModel;

  @override
  State<AddStoreItemPage> createState() => _AddStoreItemPageState();
}

class _AddStoreItemPageState extends State<AddStoreItemPage> with WidgetsBindingObserver {
  late final addStoreItemProvider = context.read<AddStoreItemProvider>();
  late final storeProvider = context.read<StoreProvider>();

  bool isLoading = false;
  List<LogDisplayModel> _logs = [];
  ItemModel? _currentItemModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentItemModel = widget.editItemModel;
    storeProvider.addListener(_handleStoreProviderChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        addStoreItemProvider.setEditItem(_currentItemModel);
        if (_currentItemModel != null) {
          _loadLogs();
        }
      }
    });
  }

  void _handleStoreProviderChange() {
    final currentItem = _currentItemModel;
    if (currentItem == null || !mounted) return;

    final itemIndex = storeProvider.storeItemList.indexWhere((item) => item.id == currentItem.id);
    if (itemIndex == -1) return;

    final updatedItem = storeProvider.storeItemList[itemIndex];
    if (!identical(updatedItem, _currentItemModel)) {
      setState(() {
        _currentItemModel = updatedItem;
      });
    }
  }

  Future<void> _loadLogs() async {
    final currentItem = _currentItemModel;
    if (currentItem == null) return;

    final storeLogs = await TaskProgressViewModel.getStoreItemLogs(currentItem.id);
    final List<LogDisplayModel> displayLogs = [];

    for (var log in storeLogs.where((log) => log.itemId == currentItem.id)) {
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      DateTime yesterday = today.subtract(const Duration(days: 1));
      DateTime logDateOnly = DateTime(log.logDate.year, log.logDate.month, log.logDate.day);

      String? datePart;
      if (logDateOnly == today) {
        datePart = 'Today';
      } else if (logDateOnly == yesterday) {
        datePart = 'Yesterday';
      } else {
        datePart = DateFormat('d MMM yyyy').format(log.logDate);
      }

      displayLogs.add(LogDisplayModel(
        id: log.key as int, // Hive key should be int
        dateTime: log.logDate,
        displayAmount: log.formattedValue,
        amount: log.value,
        status: "",
        type: log.type,
        isPurchase: log.isPurchase,
        datePart: datePart,
        canEdit: true,
      ));
    }

    if (mounted) {
      setState(() {
        _logs = displayLogs;
      });
    }
  }

  @override
  void didUpdateWidget(covariant AddStoreItemPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editItemModel != oldWidget.editItemModel) {
      _currentItemModel = widget.editItemModel;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          addStoreItemProvider.setEditItem(_currentItemModel);
          _loadLogs();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    storeProvider.removeListener(_handleStoreProviderChange);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (addStoreItemProvider.isDescriptionTimerActive) {
        addStoreItemProvider.pauseDescriptionTimer();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (addStoreItemProvider.descriptionFocus.hasFocus && !addStoreItemProvider.isDescriptionTimerActive) {
        addStoreItemProvider.startDescriptionTimer();
      }
    }
  }

  void _showAddLogDialog() async {
    final currentItem = _currentItemModel;
    if (currentItem == null) return;

    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => LogBottomSheet(
        type: currentItem.type,
        isEdit: false,
      ),
    );

    if (result != null) {
      await TaskProgressViewModel.addStoreItemLog(
        itemId: currentItem.id,
        action: "Manual Entry",
        value: result,
        type: currentItem.type,
        affectsProgress: true,
      );
      await _loadLogs();
      Helper().getMessage(
        message: LocaleKeys.Success.tr(),
        status: StatusEnum.SUCCESS,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) goBackCheck();
      },
      child: GestureDetector(
        onTap: () {
          addStoreItemProvider.unfocusAll();
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(_currentItemModel != null ? LocaleKeys.EditItem.tr() : LocaleKeys.AddItem.tr()),
            leading: InkWell(
              borderRadius: AppColors.borderRadiusAll,
              onTap: () {
                addStoreItemProvider.unfocusAll();
                FocusScope.of(context).unfocus();
                goBackCheck();
              },
              child: const Icon(Icons.arrow_back_ios),
            ),
            actions: [
              if (_currentItemModel == null)
                TextButton(
                  onPressed: () {
                    addStoreItemProvider.unfocusAll();
                    FocusScope.of(context).unfocus();
                    addItem();
                  },
                  child: Text(
                    LocaleKeys.Save.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (_currentItemModel != null) ...[
                IconButton(
                  onPressed: _showAddLogDialog,
                  icon: const Icon(Icons.post_add),
                  tooltip: LocaleKeys.AddManualLog.tr(),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'reset_item_progress') {
                      _showResetItemProgressDialog();
                    } else if (value == 'delete_item') {
                      addStoreItemProvider.unfocusAll();
                      FocusScope.of(context).unfocus();

                      Helper().getDialog(
                        message: "Are you sure you want to delete this item?",
                        onAccept: () {
                          storeProvider.deleteItem(_currentItemModel!.id);
                          NavigatorService().goBackNavbar();
                        },
                      );
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'reset_item_progress',
                      child: Row(
                        children: [
                          Icon(Icons.refresh, color: AppColors.text),
                          const SizedBox(width: 8),
                          Text(LocaleKeys.ResetStoreProgress.tr()),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete_item',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: AppColors.red),
                          const SizedBox(width: 8),
                          Text(
                            LocaleKeys.Delete.tr(),
                            style: const TextStyle(
                              color: AppColors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          body: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  TaskName(
                    isStore: true,
                    autoFocus: _currentItemModel == null,
                    onTaskSubmit: null,
                  ),
                  const SizedBox(height: 10),

                  Container(
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
                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                    child: const Row(
                      children: [
                        Text(
                          "Cost",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Spacer(),
                        SetCredit(),
                      ],
                    ),
                  ),

                  if (_currentItemModel == null) ...[
                    const SizedBox(height: 10),
                    Container(
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
                      child: const SelectTaskType(isStore: true),
                    ),
                  ],

                  Consumer<AddStoreItemProvider>(
                    builder: (context, provider, child) {
                      final selectedType = provider.selectedTaskType;
                      if (selectedType == TaskTypeEnum.COUNTER) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          const SizedBox(height: 10),
                          Container(
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
                            child: const DurationPickerWidget(isStore: true),
                          ),
                        ],
                      );
                    },
                  ),

                  // Recent Logs
                  const SizedBox(height: 24),
                  RecentLogsWidget(
                    logs: _logs,
                    showAddButton: true,
                    defaultType: _currentItemModel!.type,
                    onAddLogSubmit: (value, date) async {
                      await TaskProgressViewModel.addStoreItemLog(
                        itemId: _currentItemModel!.id,
                        action: "Manual Entry",
                        value: value,
                        logDate: date,
                        type: _currentItemModel!.type,
                        affectsProgress: true,
                      );
                      await _loadLogs();
                    },
                    onEditLog: (log, newValue, date) async {
                      await TaskProgressViewModel.editStoreItemLogByKey(log.id, newValue, newDate: date);
                      await _loadLogs();
                    },
                    onDeleteLog: (log) async {
                      await TaskProgressViewModel.deleteStoreItemLogByKey(log.id);
                      await _loadLogs();
                    },
                    onClearAll: () async {
                      await TaskProgressViewModel.clearStoreItemLogs(_currentItemModel!.id);
                      await _loadLogs();
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void addItem() {
    if (addStoreItemProvider.taskNameController.text.trim().isEmpty) {
      addStoreItemProvider.taskNameController.clear();
      Helper().getMessage(
        message: LocaleKeys.NameEmpty.tr(),
        status: StatusEnum.WARNING,
      );
      return;
    }

    if (isLoading) return;
    isLoading = true;

    addStoreItemProvider.addItem();
    NavigatorService().goBackNavbar();
  }

  void goBackCheck() {
    if (_currentItemModel != null) {
      if (addStoreItemProvider.taskNameController.text.trim().isEmpty) {
        addStoreItemProvider.taskNameController.clear();
        Helper().getMessage(
          message: LocaleKeys.NameEmpty.tr(),
          status: StatusEnum.WARNING,
        );
        return;
      }

      if (isLoading) return;
      isLoading = true;

      addStoreItemProvider.updateItem(_currentItemModel!);
      NavigatorService().back();
    } else {
      NavigatorService().back();
    }
  }

  void _showResetItemProgressDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(LocaleKeys.ResetStoreProgress.tr()),
          content: Text(LocaleKeys.ResetStoreProgressWarning.tr()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(LocaleKeys.Cancel.tr()),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _resetSingleItemProgress();
              },
              child: Text(LocaleKeys.Yes.tr()),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetSingleItemProgress() async {
    try {
      if (_currentItemModel == null) return;

      final item = _currentItemModel!;

      if (item.type == TaskTypeEnum.COUNTER) {
        item.currentCount = 0;
      } else if (item.type == TaskTypeEnum.TIMER) {
        item.currentDuration = Duration.zero;
        if (item.isTimerActive == true) {
          item.isTimerActive = false;
        }
      }

      await HiveService().updateItem(item);

      await TaskProgressViewModel.clearStoreItemLogs(item.id);

      storeProvider.setStateItems();

      Helper().getMessage(message: LocaleKeys.ResetStoreProgressSuccess.tr());

      if (mounted) {
        setState(() {
          _currentItemModel = item;
        });
        await _loadLogs();
      }
    } catch (e) {
      Helper().getMessage(message: "Hata: $e");
    }
  }
}
