import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:next_level/Core/Adapter/color_adapter.dart';
import 'package:next_level/Core/Adapter/duration_adapter.dart';
import 'package:next_level/Core/Adapter/time_of_day_adapter.dart';
import 'package:next_level/General/Adapter/task_status_enum_adapter.dart';
import 'package:next_level/General/Adapter/task_type_enum_adapter.dart';
import 'package:next_level/General/Adapter/trait_type_enum_adapter.dart';
import 'package:next_level/Enum/repeat_type_enum.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Model/subtask_model.dart';
import 'package:next_level/Model/task_log_model.dart';
import 'package:next_level/Model/task_template_model.dart';
import 'package:next_level/Model/vacation_date_model.dart';
import 'package:next_level/Model/note_model.dart';
import 'package:next_level/Model/project_model.dart';
import 'package:next_level/Model/project_subtask_model.dart';
import 'package:next_level/Model/store_item_log_model.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Model/routine_model.dart';
import 'package:next_level/Model/store_item_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Model/daily_streak_model.dart';
import 'package:next_level/Model/trait_model.dart';
import 'package:next_level/Model/user_model.dart';
import 'package:next_level/Page/Task Detail Page/routine_detail_page.dart';
import 'package:next_level/Page/Home/Add Task/add_task_page.dart';
import 'package:get/route_manager.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Core/Widgets/sure_dialog.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:table_calendar/table_calendar.dart';

class Helper {
  Future registerAdapters() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final hivePath = '${appDocDir.path}/NextLevel';
    await Directory(hivePath).create(recursive: true);
    await Hive.initFlutter(hivePath);

    Hive.registerAdapter(ColorAdapter());
    Hive.registerAdapter(DurationAdapter());
    Hive.registerAdapter(TimeOfDayAdapter());

    Hive.registerAdapter(RoutineModelAdapter());
    Hive.registerAdapter(ItemModelAdapter());
    Hive.registerAdapter(TaskModelAdapter());
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(TraitModelAdapter());
    Hive.registerAdapter(SubTaskModelAdapter());
    Hive.registerAdapter(CategoryTypeAdapter());
    Hive.registerAdapter(CategoryModelAdapter());
    Hive.registerAdapter(NoteModelAdapter());
    Hive.registerAdapter(ProjectModelAdapter());
    Hive.registerAdapter(ProjectSubtaskModelAdapter());
    Hive.registerAdapter(TaskTypeEnumAdapter());
    Hive.registerAdapter(RepeatTypeEnumAdapter());
    Hive.registerAdapter(TraitTypeEnumAdapter());
    Hive.registerAdapter(TaskStatusEnumAdapter());
    Hive.registerAdapter(TaskLogModelAdapter());
    Hive.registerAdapter(VacationDateModelAdapter());
    Hive.registerAdapter(TaskTemplateModelAdapter());
    Hive.registerAdapter(StoreItemLogAdapter());
    Hive.registerAdapter(DailyStreakModelAdapter());
  }

  Future<void> getDialog({
    String? title,
    required String message,
    bool withTimer = false,
    Function? onAccept,
    acceptButtonText,
  }) async {
    await Get.dialog(
      CustomDialogWidget(
        title: title,
        contentText: message,
        withTimer: withTimer,
        onAccept: onAccept,
        acceptButtonText: acceptButtonText ?? LocaleKeys.Okay.tr(),
      ),
    );
  }

  void getMessage({
    String? title,
    required String message,
    StatusEnum status = StatusEnum.SUCCESS,
    IconData? icon,
    Duration? duration,
    Function? onMainButtonPressed,
    String? mainButtonText,
  }) {
    Get.closeCurrentSnackbar();

    Get.snackbar(
      title ??
          (status == StatusEnum.WARNING
              ? LocaleKeys.Warning.tr()
              : status == StatusEnum.INFO
                  ? LocaleKeys.Info.tr()
                  : LocaleKeys.Success.tr()),
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.panelBackground.withValues(alpha: 0.9),
      animationDuration: const Duration(milliseconds: 400),
      duration: duration ?? const Duration(milliseconds: 1300),
      dismissDirection: DismissDirection.horizontal,
      icon: icon != null
          ? Icon(icon)
          : (status == StatusEnum.WARNING
              ? const Icon(
                  Icons.warning,
                  color: AppColors.red,
                )
              : status == StatusEnum.INFO
                  ? const Icon(Icons.info)
                  : const Icon(Icons.check)),
      mainButton: onMainButtonPressed != null
          ? TextButton(
              onPressed: () {
                onMainButtonPressed();
                Get.back();
              },
              child: Text(
                mainButtonText ?? LocaleKeys.Okay.tr(),
                style: const TextStyle(color: AppColors.white),
              ),
            )
          : null,
    );
  }

  void getUndoMessage({
    required String message,
    required Function onUndo,
    Color? statusColor,
    String? statusWord,
    String? taskName,
    String? dateInfo,
    TaskModel? taskModel, // Task detay sayfasına gitmek için
  }) {
    Get.closeCurrentSnackbar(); // Build detailed message
    String detailedMessage = message;
    if (taskName != null) {
      if (dateInfo != null) {
        // For date changes, create a cleaner message format
        detailedMessage = '"$taskName" $dateInfo';
      } else {
        // For other actions (delete, complete, etc.)
        detailedMessage = '"$taskName" $message';
      }
    } else if (dateInfo != null) {
      detailedMessage = '$message $dateInfo';
    }

    Get.snackbar(
      "",
      "",
      messageText: _buildRichMessage(detailedMessage, statusColor, statusWord),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.panelBackground.withValues(alpha: 0.9),
      animationDuration: const Duration(milliseconds: 400),
      duration: const Duration(seconds: 4),
      dismissDirection: DismissDirection.horizontal,
      onTap: taskModel != null
          ? (snackbar) {
              // Mesaja tıklandığında task detay sayfasına git
              Get.back(); // Snackbar'ı kapat
              _navigateToTaskDetail(taskModel);
            }
          : null,
      icon: const Icon(
        Icons.delete_rounded,
        color: AppColors.red,
      ),
      mainButton: TextButton(
        onPressed: () {
          onUndo();
          Get.back();
        },
        child: Text(
          LocaleKeys.Undo.tr(),
          style: TextStyle(
            color: AppColors.main,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      titleText: const SizedBox.shrink(), // Hide title
    );
  }

  Widget _buildRichMessage(String message, Color? statusColor, String? statusWord) {
    if (statusColor == null || statusWord == null) {
      return Text(
        message,
        style: TextStyle(
          color: AppColors.text,
          fontSize: 14,
        ),
      );
    }

    // Find the status word in the message and make it colored
    final lowerMessage = message.toLowerCase();
    final lowerStatusWord = statusWord.toLowerCase();
    final startIndex = lowerMessage.indexOf(lowerStatusWord);

    if (startIndex == -1) {
      return Text(
        message,
        style: TextStyle(
          color: AppColors.text,
          fontSize: 14,
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: AppColors.text,
          fontSize: 14,
        ),
        children: [
          if (startIndex > 0) TextSpan(text: message.substring(0, startIndex)),
          TextSpan(
            text: message.substring(startIndex, startIndex + statusWord.length),
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          if (startIndex + statusWord.length < message.length) TextSpan(text: message.substring(startIndex + statusWord.length)),
        ],
      ),
    );
  }

  Future<bool> photosAccessRequest() async {
    // android sürüm 33 den büyük ise photos izni alınmalı yoksa storage izni yeterli
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    AndroidDeviceInfo androidDeviceInfo = await deviceInfoPlugin.androidInfo;
    if (androidDeviceInfo.version.sdkInt >= 33) {
      await Permission.photos.request();
      if (await Permission.photos.isGranted == false) {
        Helper().getMessage(
          message: LocaleKeys.PermissionRequired.tr(),
          status: StatusEnum.WARNING,
        );
        return false;
      }

      if (await Permission.photos.isGranted == false) {
        if (await Permission.photos.isPermanentlyDenied) {
          Helper().getDialog(
            message: LocaleKeys.PhotosAccessRequired.tr(),
            onAccept: () async {
              await openAppSettings();
            },
          );
          return false;
        } else if (!await Permission.photos.isGranted) {
          Helper().getMessage(
            message: LocaleKeys.PhotosAccessRequired.tr(),
            status: StatusEnum.WARNING,
          );
          return false;
        }
      }
    } else {
      await Permission.storage.request();

      if (await Permission.storage.isGranted == false) {
        if (await Permission.storage.isPermanentlyDenied) {
          Helper().getDialog(
            message: LocaleKeys.StorageAccessRequired.tr(),
            onAccept: () async {
              await openAppSettings();
            },
          );
          return false;
        } else if (!await Permission.storage.isGranted) {
          Helper().getMessage(
            message: LocaleKeys.StorageAccessRequired.tr(),
            status: StatusEnum.WARNING,
          );
          return false;
        }
      }
    }

    return true;
  }

  Color getColorForPercentage(double percentage) {
    // Yüzdeye göre kırmızıdan yeşile renk gradyanı oluşturun
    if (percentage >= 90) return Colors.green;
    if (percentage >= 80) return Colors.lightGreen;
    if (percentage >= 70) return Colors.orange;

    return Colors.red;
  }

  int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  // Emoji Picker
  Future<String> showEmojiPicker(BuildContext context) async {
    late final String selectedEmoji;

    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SizedBox(
            height: 0.4.sh,
            child: EmojiPicker(
              onEmojiSelected: (emoji, category) {
                selectedEmoji = category.emoji;
                Get.back();
              },
              config: Config(
                bottomActionBarConfig: const BottomActionBarConfig(showBackspaceButton: false, enabled: false),
                categoryViewConfig: CategoryViewConfig(
                  extraTab: CategoryExtraTab.SEARCH,
                  backgroundColor: AppColors.panelBackground,
                ),
                emojiViewConfig: EmojiViewConfig(
                  backgroundColor: AppColors.panelBackground,
                ),
                viewOrderConfig: const ViewOrderConfig(
                  top: EmojiPickerItem.searchBar,
                  middle: EmojiPickerItem.categoryBar,
                  bottom: EmojiPickerItem.emojiView,
                ),
                searchViewConfig: SearchViewConfig(
                  backgroundColor: AppColors.panelBackground,
                  buttonIconColor: AppColors.text,
                ),
              ),
            ),
          ),
        );
      },
    );

    return selectedEmoji;
  }

  Future<Color> selectColor() async {
    Color selectedColor = AppColors.main;

    final List<Color> colors = [
      AppColors.main,
      AppColors.red,
      AppColors.orange,
      AppColors.orange2,
      AppColors.yellow,
      AppColors.green,
      AppColors.blue,
      AppColors.purple,
      AppColors.deepPurple,
      AppColors.pink,
      const Color(0xFF009688), // teal
      const Color(0xFF3F51B5), // indigo
      const Color(0xFF795548), // brown
      const Color(0xFF9E9E9E), // grey
      const Color(0xFF607D8B), // blueGrey
    ];

    await Get.dialog(
      AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleKeys.SelectColor.tr(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: colors.map((color) {
                return GestureDetector(
                  onTap: () {
                    selectedColor = color;
                    Get.back();
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          color.withValues(alpha: 0.9),
                          color,
                        ],
                        center: const Alignment(-0.3, -0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );

    return selectedColor;
  }

  Future<Map<String, dynamic>?> selectTime(
    BuildContext context, {
    TimeOfDay? initialTime,
    DateTime? referenceDate,
    int? initialNotificationAlarmState,
    int? initialEarlyReminderMinutes,
  }) async {
    TimeOfDay selectedTime = initialTime ?? TimeOfDay.now();
    bool dateChanged = false;
    int notificationAlarmState = initialNotificationAlarmState ?? 0; // 0: Off, 1: Notification, 2: Alarm
    int? earlyReminderMinutes = initialEarlyReminderMinutes ?? 0; // Default: Now (0 min)
    late FixedExtentScrollController hourController;
    late FixedExtentScrollController minuteController;

    return await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Initialize controllers
            hourController = FixedExtentScrollController(initialItem: selectedTime.hour);
            minuteController = FixedExtentScrollController(initialItem: selectedTime.minute);

            return AlertDialog(
              insetPadding: const EdgeInsets.all(18),
              contentPadding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Time Display
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.main.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: AppColors.main,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (dateChanged)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.red.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '📅 +1 Day',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.red,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Direct Time Picker Wheel
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppColors.panelBackground.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.main.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Hour Picker
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Hour',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.text.withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: ListWheelScrollView.useDelegate(
                                    controller: hourController,
                                    itemExtent: 50,
                                    perspective: 0.005,
                                    diameterRatio: 1.2,
                                    physics: const FixedExtentScrollPhysics(),
                                    onSelectedItemChanged: (index) {
                                      setState(() {
                                        selectedTime = TimeOfDay(
                                          hour: index,
                                          minute: selectedTime.minute,
                                        );
                                        dateChanged = false;
                                      });
                                    },
                                    childDelegate: ListWheelChildBuilderDelegate(
                                      childCount: 24,
                                      builder: (context, index) {
                                        final isSelected = index == selectedTime.hour;
                                        return Center(
                                          child: Text(
                                            index.toString().padLeft(2, '0'),
                                            style: TextStyle(
                                              fontSize: isSelected ? 32 : 24,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              color: isSelected ? AppColors.main : AppColors.text.withValues(alpha: 0.5),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Separator
                          Container(
                            width: 2,
                            height: 150,
                            color: AppColors.main.withValues(alpha: 0.2),
                          ),

                          // Minute Picker
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Minute',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.text.withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: ListWheelScrollView.useDelegate(
                                    controller: minuteController,
                                    itemExtent: 50,
                                    perspective: 0.005,
                                    diameterRatio: 1.2,
                                    physics: const FixedExtentScrollPhysics(),
                                    onSelectedItemChanged: (index) {
                                      setState(() {
                                        selectedTime = TimeOfDay(
                                          hour: selectedTime.hour,
                                          minute: index,
                                        );
                                        dateChanged = false;
                                      });
                                    },
                                    childDelegate: ListWheelChildBuilderDelegate(
                                      childCount: 60,
                                      builder: (context, index) {
                                        final isSelected = index == selectedTime.minute;
                                        return Center(
                                          child: Text(
                                            index.toString().padLeft(2, '0'),
                                            style: TextStyle(
                                              fontSize: isSelected ? 32 : 24,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              color: isSelected ? AppColors.main : AppColors.text.withValues(alpha: 0.5),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Quick time buttons - MOVED TO TOP
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Quick Selection',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 2.5,
                          children: [
                            _buildQuickTimeDialogButton(
                              context,
                              null,
                              selectedTime,
                              (time, changed) {
                                setState(() {
                                  selectedTime = time;
                                  dateChanged = changed;
                                  hourController.animateToItem(
                                    time.hour,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                  minuteController.animateToItem(
                                    time.minute,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                });
                              },
                            ),
                            _buildQuickTimeDialogButton(
                              context,
                              15,
                              selectedTime,
                              (time, changed) {
                                setState(() {
                                  selectedTime = time;
                                  dateChanged = changed;
                                  hourController.animateToItem(
                                    time.hour,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                  minuteController.animateToItem(
                                    time.minute,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                });
                              },
                            ),
                            _buildQuickTimeDialogButton(
                              context,
                              60,
                              selectedTime,
                              (time, changed) {
                                setState(() {
                                  selectedTime = time;
                                  dateChanged = changed;
                                  hourController.animateToItem(
                                    time.hour,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                  minuteController.animateToItem(
                                    time.minute,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Notification/Alarm Settings - Single Button with 3 States
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 12,
                      children: [
                        // Single toggle button: Off -> Notification -> Alarm -> Off
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              notificationAlarmState = (notificationAlarmState + 1) % 3;
                              switch (notificationAlarmState) {
                                case 0:
                                  debugPrint('🔇 State: Off');
                                case 1:
                                  debugPrint('📢 State: Notification');
                                case 2:
                                  debugPrint('🔔 State: Alarm');
                              }
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: notificationAlarmState == 0
                                  ? AppColors.background.withValues(alpha: 0.3)
                                  : notificationAlarmState == 1
                                      ? AppColors.blue.withValues(alpha: 0.2)
                                      : AppColors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: notificationAlarmState == 0
                                    ? AppColors.text.withValues(alpha: 0.1)
                                    : notificationAlarmState == 1
                                        ? AppColors.blue
                                        : AppColors.red,
                                width: 1.5,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  notificationAlarmState == 0
                                      ? Icons.notifications_off_rounded
                                      : notificationAlarmState == 1
                                          ? Icons.notifications_active_rounded
                                          : Icons.alarm_rounded,
                                  color: notificationAlarmState == 0
                                      ? AppColors.text.withValues(alpha: 0.5)
                                      : notificationAlarmState == 1
                                          ? AppColors.blue
                                          : AppColors.red,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  notificationAlarmState == 0
                                      ? 'Off'
                                      : notificationAlarmState == 1
                                          ? 'Notification'
                                          : 'Alarm',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: notificationAlarmState == 0
                                        ? AppColors.text.withValues(alpha: 0.6)
                                        : notificationAlarmState == 1
                                            ? AppColors.blue
                                            : AppColors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Early Reminder Buttons (visible if not Off)
                        if (notificationAlarmState != 0) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  'Early Reminder',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.text.withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                              GridView.count(
                                crossAxisCount: 3,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 2.5,
                                children: [
                                  _buildReminderButton(
                                      0,
                                      'Now',
                                      earlyReminderMinutes == 0,
                                      () => setState(() {
                                            earlyReminderMinutes = 0;
                                            debugPrint('⏰ Early reminder: 0 min');
                                          })),
                                  _buildReminderButton(
                                      5,
                                      '5 min',
                                      earlyReminderMinutes == 5,
                                      () => setState(() {
                                            earlyReminderMinutes = 5;
                                            debugPrint('⏰ Early reminder: 5 min');
                                          })),
                                  _buildReminderButton(
                                      20,
                                      '20 min',
                                      earlyReminderMinutes == 20,
                                      () => setState(() {
                                            earlyReminderMinutes = 20;
                                            debugPrint('⏰ Early reminder: 20 min');
                                          })),
                                  _buildReminderButton(
                                      60,
                                      '1 hour',
                                      earlyReminderMinutes == 60,
                                      () => setState(() {
                                            earlyReminderMinutes = 60;
                                            debugPrint('⏰ Early reminder: 60 min');
                                          })),
                                  _buildReminderButton(
                                      180,
                                      '3 hours',
                                      earlyReminderMinutes == 180,
                                      () => setState(() {
                                            earlyReminderMinutes = 180;
                                            debugPrint('⏰ Early reminder: 180 min');
                                          })),
                                  _buildReminderButton(
                                      600,
                                      '10 hours',
                                      earlyReminderMinutes == 600,
                                      () => setState(() {
                                            earlyReminderMinutes = 600;
                                            debugPrint('⏰ Early reminder: 600 min');
                                          })),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.text.withValues(alpha: 0.6)),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(
                    context,
                    {
                      'time': selectedTime,
                      'dateChanged': dateChanged,
                      'notificationAlarmState': notificationAlarmState,
                      'earlyReminderMinutes': notificationAlarmState != 0 ? earlyReminderMinutes : null,
                    },
                  ),
                  child: Text(
                    'Confirm',
                    style: TextStyle(color: AppColors.main, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildReminderButton(int minutes, String label, bool isSelected, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppColors.main : AppColors.panelBackground.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.main : AppColors.main.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected ? AppColors.white : AppColors.main,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickTimeDialogButton(
    BuildContext context,
    int? addMinutes,
    TimeOfDay currentTime,
    Function(TimeOfDay, bool) onSelect,
  ) {
    // Determine what time this button represents
    late TimeOfDay buttonTime;
    late String buttonLabel;

    int newHour = DateTime.now().hour;
    int newMinute = DateTime.now().minute;
    bool dayChanged = false;

    if (addMinutes != null && addMinutes > 0) {
      int now = DateTime.now().hour * 60 + DateTime.now().minute;
      int totalMinutes = now + addMinutes;

      if (totalMinutes >= 24 * 60) {
        dayChanged = true;
        totalMinutes = totalMinutes % (24 * 60);
      }

      newHour = totalMinutes ~/ 60;
      newMinute = totalMinutes % 60;
      buttonLabel = addMinutes == 15 ? 'In 15 Min' : 'In 1 Hour';
    } else {
      buttonLabel = 'Now';
    }

    buttonTime = TimeOfDay(hour: newHour, minute: newMinute);

    // Check if this button is selected
    final isSelected = currentTime.hour == buttonTime.hour && currentTime.minute == buttonTime.minute;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          onSelect(buttonTime, dayChanged);
          debugPrint('✅ Quick time selected: ${newHour.toString().padLeft(2, '0')}:${newMinute.toString().padLeft(2, '0')} ${dayChanged ? '(+1 Day)' : ''}');
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppColors.main : AppColors.panelBackground.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.main : AppColors.main.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Center(
            child: Text(
              buttonLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.white : AppColors.main,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Future<DateTime?> selectDate({
    required BuildContext context,
    DateTime? initialDate,
  }) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );

    return selectedDate;
  }

  Future<DateTime?> selectDateWithQuickActions({
    required BuildContext context,
    DateTime? initialDate,
    bool isRoutine = false,
  }) async {
    return await showDialog<DateTime?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.all(18),
          contentPadding: const EdgeInsets.all(12),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Direct calendar view with TableCalendar
                SizedBox(
                  height: 323,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.panelBackground.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.text.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: TableCalendar<DateTime>(
                      locale: context.locale.toLanguageTag(),
                      rowHeight: 36,
                      firstDay: DateTime(1950),
                      lastDay: DateTime(2100),
                      focusedDay: initialDate ?? DateTime.now(),
                      selectedDayPredicate: (day) => initialDate != null && isSameDay(initialDate, day),
                      calendarFormat: CalendarFormat.month,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      availableGestures: AvailableGestures.horizontalSwipe,
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.main,
                        ),
                        leftChevronIcon: Icon(Icons.chevron_left_rounded, size: 24, color: AppColors.main),
                        rightChevronIcon: Icon(Icons.chevron_right_rounded, size: 24, color: AppColors.main),
                        headerPadding: const EdgeInsets.symmetric(vertical: 8),
                        headerMargin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.main.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text.withValues(alpha: 0.7),
                        ),
                        weekendStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text.withValues(alpha: 0.7),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.panelBackground.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      calendarStyle: CalendarStyle(
                        selectedDecoration: BoxDecoration(
                          color: AppColors.main,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: AppColors.main.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.text.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        defaultTextStyle: TextStyle(fontSize: 14, color: AppColors.text),
                        weekendTextStyle: TextStyle(fontSize: 14, color: AppColors.text),
                        selectedTextStyle: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                        todayTextStyle: TextStyle(fontSize: 14, color: AppColors.main, fontWeight: FontWeight.bold),
                        outsideTextStyle: TextStyle(fontSize: 14, color: AppColors.text.withValues(alpha: 0.4)),
                        cellMargin: const EdgeInsets.all(2),
                        cellPadding: EdgeInsets.zero,
                      ),
                      onDaySelected: (selectedDay, focusedDay) {
                        Navigator.of(context).pop(selectedDay);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Quick action buttons - First Row
                Row(
                  children: [
                    // Today button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop(DateTime.now());
                        },
                        icon: const Icon(Icons.today_rounded, size: 18),
                        label: Text(LocaleKeys.Today.tr(), style: const TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange.withValues(alpha: 0.1),
                          foregroundColor: AppColors.orange,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Tomorrow button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop(DateTime.now().add(const Duration(days: 1)));
                        },
                        icon: const Icon(Icons.event_rounded, size: 18),
                        label: Text(LocaleKeys.Tomorrow.tr(), style: const TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green.withValues(alpha: 0.1),
                          foregroundColor: AppColors.green,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Next Week button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop(DateTime.now().add(const Duration(days: 7)));
                        },
                        icon: const Icon(Icons.date_range_rounded, size: 18),
                        label: Text(LocaleKeys.NextWeek.tr(), style: const TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue.withValues(alpha: 0.1),
                          foregroundColor: AppColors.blue,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Quick action buttons - Second Row
                Row(
                  children: [
                    // Next Month button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final now = DateTime.now();
                          final nextMonth = DateTime(now.year, now.month + 1, now.day);
                          Navigator.of(context).pop(nextMonth);
                        },
                        icon: const Icon(Icons.calendar_month_rounded, size: 18),
                        label: Text(LocaleKeys.NextMonth.tr(), style: const TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.purple.withValues(alpha: 0.1),
                          foregroundColor: AppColors.purple,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    // Next Year button
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final now = DateTime.now();
                          final nextYear = DateTime(now.year + 1, now.month, now.day);
                          Navigator.of(context).pop(nextYear);
                        },
                        icon: const Icon(Icons.calendar_today_rounded, size: 18),
                        label: Text(LocaleKeys.NextYear.tr(), style: const TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.deepBlue.withValues(alpha: 0.1),
                          foregroundColor: AppColors.deepBlue,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),

                    // Undated button
                    if (!isRoutine) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Use epoch time as marker for dateless selection
                            Navigator.of(context).pop(DateTime.fromMillisecondsSinceEpoch(0));
                          },
                          icon: const Icon(Icons.event_busy_rounded, size: 18),
                          label: Text(LocaleKeys.NoDate.tr(), style: const TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.red.withValues(alpha: 0.1),
                            foregroundColor: AppColors.red,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> selectDateAndTime({
    required BuildContext context,
    DateTime? initialDate,
    TimeOfDay? initialTime,
    bool isRoutine = false,
  }) async {
    DateTime? selectedDate;

    // İlk olarak tarih seçişini göster
    selectedDate = await selectDateWithQuickActions(
      context: context,
      initialDate: initialDate,
      isRoutine: isRoutine,
    );

    if (selectedDate == null || !context.mounted) {
      return null;
    }

    // Tarih seçildikten sonra kullanıcı saat seçmek isterse
    return {
      'date': selectedDate,
      'time': initialTime,
    };
  }

  // Task detay sayfasına navigate etmek için yardımcı metod
  void _navigateToTaskDetail(TaskModel taskModel) {
    if (taskModel.routineID != null) {
      // Routine task ise RoutineDetailPage açılır
      Get.to(
        () => RoutineDetailPage(taskModel: taskModel),
        transition: Transition.rightToLeft,
      );
    } else {
      // Normal task ise AddTaskPage (edit modunda) açılır
      Get.to(
        () => AddTaskPage(editTask: taskModel),
        transition: Transition.rightToLeft,
      );
    }
  }
}
