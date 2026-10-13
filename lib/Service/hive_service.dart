import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:get/get.dart' hide Trans;
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Service/backup_archive_service.dart';
import 'package:next_level/Service/file_storage_service.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Service/notification_services.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/store_provider.dart';
import 'package:next_level/Provider/trait_provider.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Service/global_timer.dart';
import 'package:next_level/Provider/category_provider.dart';
import 'package:next_level/Provider/notes_provider.dart';
import 'package:next_level/Provider/projects_provider.dart';
import 'package:next_level/Service/projects_service.dart';
import 'package:next_level/Service/project_subtasks_service.dart';
import 'package:next_level/Service/notes_service.dart';
import 'package:next_level/Provider/user_provider.dart';
import 'package:next_level/Provider/daily_streak_provider.dart';
import 'package:next_level/Widgets/Common/loading_dialog.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:next_level/Model/user_model.dart';
import 'package:next_level/Model/store_item_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Model/task_log_model.dart';
import 'package:next_level/Model/trait_model.dart';
import 'package:next_level/Model/project_model.dart';
import 'package:next_level/Model/project_subtask_model.dart';
import 'package:next_level/Model/note_model.dart';
import 'package:next_level/Model/routine_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Model/daily_streak_model.dart';
import 'package:next_level/Model/task_template_model.dart';
import 'package:next_level/Model/vacation_date_model.dart';
import 'package:next_level/Model/store_item_log_model.dart';
import 'package:path/path.dart' as path;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:next_level/Core/task_due_date_helper.dart';
import 'package:next_level/Service/data_mutation_notifier.dart';

class HiveService {
  // Singleton Pattern
  static final HiveService _instance = HiveService._internal();

  factory HiveService() {
    return _instance;
  }

  HiveService._internal();

  // Centralized SharedPreferences access
  Future<SharedPreferences> get sharedPrefs async {
    return await SharedPreferences.getInstance();
  }

  static const String _userBoxName = 'userBox';
  static const String _itemBoxName = 'itemBox';
  static const String _traitBoxName = 'traitBox';
  static const String _routineBoxName = 'routineBox';
  static const String _taskBoxName = 'taskBox';
  static const String _taskLogBoxName = 'taskLogBox';
  static const String _categoryBoxName = 'categoryBox_v2';
  static const String _dailyStreakBoxName = 'dailyStreakBox';
  static const String _taskTemplateBoxName = 'task_templates';
  static const String _vacationDateBoxName = 'vacation_dates';
  static const String _storeItemLogBoxName = 'storeItemLogBox';

  Future<Box<UserModel>> get _userBox async =>
      await Hive.openBox<UserModel>(_userBoxName);
  Future<Box<ItemModel>> get _itemBox async =>
      await Hive.openBox<ItemModel>(_itemBoxName);
  Future<Box<TraitModel>> get _traitBox async =>
      await Hive.openBox<TraitModel>(_traitBoxName);
  Future<Box<RoutineModel>> get _routineBox async =>
      await Hive.openBox<RoutineModel>(_routineBoxName);
  Future<Box<TaskModel>> get _taskBox async =>
      await Hive.openBox<TaskModel>(_taskBoxName);
  Future<Box<TaskLogModel>> get _taskLogBox async =>
      await Hive.openBox<TaskLogModel>(_taskLogBoxName);
  Future<Box<CategoryModel>> get _categoryBox async =>
      await Hive.openBox<CategoryModel>(_categoryBoxName);
  Future<Box<DailyStreakModel>> get _dailyStreakBox async =>
      await Hive.openBox<DailyStreakModel>(_dailyStreakBoxName);
  Future<Box<TaskTemplateModel>> get _taskTemplateBox async =>
      await Hive.openBox<TaskTemplateModel>(_taskTemplateBoxName);
  Future<Box<VacationDateModel>> get _vacationDateBox async =>
      await Hive.openBox<VacationDateModel>(_vacationDateBoxName);
  Future<Box<StoreItemLog>> get _storeItemLogBox async =>
      await Hive.openBox<StoreItemLog>(_storeItemLogBoxName);

  final BackupArchiveService _backupArchiveService = BackupArchiveService();

  Future<void> _copyAttachmentFileToBackup({
    required File sourceFile,
    required Directory tempAttachmentsDir,
    required Set<String> copiedSourcePaths,
  }) async {
    if (copiedSourcePaths.contains(sourceFile.path)) {
      return;
    }

    if (!await sourceFile.exists()) {
      LogService.error(
          '⚠️ HiveService: Skipping missing attachment during backup: ${sourceFile.path}');
      return;
    }

    final fileName = path.basename(sourceFile.path);
    final targetPath = path.join(tempAttachmentsDir.path, fileName);
    await sourceFile.copy(targetPath);
    copiedSourcePaths.add(sourceFile.path);
  }

  Future<void> _copyReferencedTaskAttachmentsToBackup({
    required Map<dynamic, dynamic> taskMap,
    required Directory tempAttachmentsDir,
    required Set<String> copiedSourcePaths,
  }) async {
    for (final taskData in taskMap.values) {
      if (taskData is! Map) {
        continue;
      }

      final attachmentPaths = taskData['attachment_paths'];
      if (attachmentPaths is! List) {
        continue;
      }

      for (final attachmentPath in attachmentPaths) {
        final rawPath = attachmentPath?.toString();
        if (rawPath == null || rawPath.isEmpty) {
          continue;
        }

        await _copyAttachmentFileToBackup(
          sourceFile: File(rawPath),
          tempAttachmentsDir: tempAttachmentsDir,
          copiedSourcePaths: copiedSourcePaths,
        );
      }
    }
  }

  List<String>? _normalizeImportedAttachmentPaths(
    List<String>? attachmentPaths,
    Map<String, String> restoredAttachmentPaths,
  ) {
    if (attachmentPaths == null || attachmentPaths.isEmpty) {
      return null;
    }

    final normalizedPaths = <String>[];

    for (final originalPath in attachmentPaths) {
      final fileName = path.basename(originalPath);
      final restoredPath = restoredAttachmentPaths[fileName];

      if (restoredPath != null) {
        normalizedPaths.add(restoredPath);
        continue;
      }

      if (File(originalPath).existsSync()) {
        normalizedPaths.add(originalPath);
        continue;
      }

      LogService.error(
          '⚠️ HiveService: Imported attachment could not be restored: $originalPath');
    }

    return normalizedPaths.isEmpty ? null : normalizedPaths;
  }

  // User methods
  Future<void> addUser(UserModel userModel) async {
    final box = await _userBox;
    await box.put(userModel.id, userModel);
  }

  Future<UserModel?> getUser(int id) async {
    final box = await _userBox;
    return box.get(id);
  }

  Future<void> updateUser(UserModel userModel) async {
    final box = await _userBox;
    await box.put(userModel.id, userModel);
  }

  Future<List<UserModel>> getUsers() async {
    final box = await _userBox;
    return box.values.toList();
  }

  // Item methods
  Future<void> addItem(ItemModel itemModel) async {
    final box = await _itemBox;
    await box.put(itemModel.id, itemModel);
  }

  Future<List<ItemModel>> getItems() async {
    final box = await _itemBox;
    final items = box.values.toList();

    // Order alanına göre sort et (eğer atanmışsa)
    items.sort((a, b) => a.order!.compareTo(b.order!));

    return items;
  }

  Future<void> updateItem(ItemModel itemModel) async {
    final box = await _itemBox;
    await box.put(itemModel.id, itemModel);
  }

  Future<void> deleteItem(int id) async {
    final box = await _itemBox;
    await box.delete(id);
  }

  // Trait methods
  Future<void> addTrait(TraitModel traitModel) async {
    final box = await _traitBox;
    await box.put(traitModel.id, traitModel);
  }

  Future<List<TraitModel>> getTraits() async {
    final box = await _traitBox;
    return box.values.toList();
  }

  Future<void> updateTrait(TraitModel traitModel) async {
    final box = await _traitBox;
    await box.put(traitModel.id, traitModel);
  }

  Future<void> deleteTrait(int id) async {
    final box = await _traitBox;
    await box.delete(id);
  }

  // Routine methods
  Future<void> addRoutine(RoutineModel routineModel) async {
    final box = await _routineBox;
    await box.put(routineModel.id, routineModel);
  }

  Future<List<RoutineModel>> getRoutines() async {
    final box = await _routineBox;
    return box.values.toList();
  }

  Future<void> updateRoutine(RoutineModel routineModel) async {
    final box = await _routineBox;
    LogService.debug(
        'Updating routine in Hive: ID=${routineModel.id}, Title=${routineModel.title}');

    try {
      // First save the HiveObject to ensure changes are persisted
      routineModel.save();

      // Then update the box with the routine model
      await box.put(routineModel.id, routineModel);

      // Verify the routine was saved correctly
      final savedRoutine = box.get(routineModel.id);
      if (savedRoutine != null) {
        LogService.debug(
            'Routine successfully saved to Hive: ID=${savedRoutine.id}, Title=${savedRoutine.title}');
      } else {
        LogService.error('ERROR: Failed to retrieve saved routine from Hive');
      }
    } catch (e) {
      LogService.error('ERROR saving routine to Hive: $e');
      rethrow;
    }
  }

  Future<void> deleteRoutine(int id) async {
    final box = await _routineBox;
    await box.delete(id);

    // delete success check
    if (!box.containsKey(id)) {
      LogService.debug('Routine with ID $id deleted from Hive storage');
    } else {
      LogService.debug('Routine with ID $id not deleted from Hive storage');
    }
  }

  // Task methods
  Future<void> addTask(TaskModel taskModel) async {
    final box = await _taskBox;
    await box.put(taskModel.id, taskModel);
  }

  Future<List<TaskModel>> getTasks() async {
    final box = await _taskBox;
    final tasks = box.values.toList();

    // sortOrder'a göre sırala (yüksek değer = üstte)
    tasks.sort((a, b) => b.sortOrder.compareTo(a.sortOrder));

    LogService.debug(
        '📋 Loaded ${tasks.length} tasks from Hive (sorted by sortOrder)');
    for (int i = 0; i < tasks.length && i < 5; i++) {
      LogService.debug(
          '  ${i + 1}. Task ${tasks[i].id}: "${tasks[i].title}" - sortOrder: ${tasks[i].sortOrder}');
    }

    return tasks;
  }

  Future<void> updateTask(TaskModel taskModel) async {
    final box = await _taskBox;

    try {
      // LogService.debug(
      //     '💾 Saving task to Hive: ID=${taskModel.id}, sortOrder=${taskModel.sortOrder}');

      // Update the box with the task model
      await box.put(taskModel.id, taskModel);

      // Verify the task was saved correctly
      final savedTask = box.get(taskModel.id);
      if (savedTask != null) {
        // LogService.debug(
        //     '✅ Task verified in Hive: ID=${savedTask.id}, Title="${savedTask.title}", sortOrder=${savedTask.sortOrder}');
        if (savedTask.sortOrder != taskModel.sortOrder) {
          LogService.error(
              '⚠️ CRITICAL: sortOrder mismatch after save! Expected: ${taskModel.sortOrder}, Got: ${savedTask.sortOrder}');
        }
      } else {
        LogService.error(
            '❌ CRITICAL ERROR: Failed to retrieve saved task from Hive');
      }
    } catch (e) {
      LogService.error('❌ CRITICAL ERROR saving task to Hive: $e');
      rethrow;
    }
  }

  Future<void> deleteTask(int id) async {
    final box = await _taskBox;
    await box.delete(id);

    // delete succes check
    if (!box.containsKey(id)) {
      LogService.debug('Task with ID $id deleted from Hive storage');
    } else {
      LogService.debug('Task with ID $id not deleted from Hive storage');
    }
  }

  // Category methods
  Future<void> addCategory(CategoryModel categoryModel) async {
    final box = await _categoryBox;
    await box.put(categoryModel.id, categoryModel);
  }

  Future<List<CategoryModel>> getCategories() async {
    final box = await _categoryBox;
    return box.values.toList();
  }

  Future<void> updateCategory(CategoryModel categoryModel) async {
    final box = await _categoryBox;
    // Önce eski kaydı sil, sonra yenisini ekle (HiveObject duplicate key hatasını önlemek için)
    await box.delete(categoryModel.id);
    await box.put(categoryModel.id, categoryModel);
  }

  Future<void> deleteCategory(String id) async {
    final box = await _categoryBox;
    LogService.debug('🗑️ HiveService: Deleting category with ID: $id');
    await box.delete(id);

    // Verify deletion
    if (!box.containsKey(id)) {
      LogService.debug(
          '✅ HiveService: Category $id successfully deleted from Hive');
    } else {
      LogService.debug(
          '❌ HiveService: Category $id still exists in Hive after deletion attempt');
    }
  }

  Future<void> clearCategoryBox() async {
    await Hive.deleteBoxFromDisk(_categoryBoxName);
  }

  // Task Log methods
  Future<void> addTaskLog(TaskLogModel taskLogModel) async {
    final box = await _taskLogBox;
    await box.put(taskLogModel.id, taskLogModel);
  }

  Future<List<TaskLogModel>> getTaskLogs() async {
    final box = await _taskLogBox;
    return box.values.toList();
  }

  Future<List<TaskLogModel>> getTaskLogsByTaskId(int taskId) async {
    final box = await _taskLogBox;
    return box.values.where((log) => log.taskId == taskId).toList();
  }

  Future<List<TaskLogModel>> getTaskLogsByRoutineId(int routineId) async {
    final box = await _taskLogBox;
    return box.values.where((log) => log.routineId == routineId).toList();
  }

  Future<void> deleteTaskLog(int id) async {
    final box = await _taskLogBox;
    await box.delete(id);
  }

  // Daily Streak methods
  Future<void> addDailyStreak(DailyStreakModel streakModel) async {
    final box = await _dailyStreakBox;
    // Use date as key to ensure uniqueness per day
    final key =
        "${streakModel.date.year}-${streakModel.date.month}-${streakModel.date.day}";
    await box.put(key, streakModel);
    DataMutationNotifier().markDirty('daily_streak:save');
  }

  Future<DailyStreakModel?> getDailyStreak(DateTime date) async {
    final box = await _dailyStreakBox;
    final key = "${date.year}-${date.month}-${date.day}";
    return box.get(key);
  }

  Future<List<DailyStreakModel>> getAllDailyStreaks() async {
    final box = await _dailyStreakBox;
    return box.values.toList();
  }

  Future<void> clearDailyStreakBox() async {
    final box = await _dailyStreakBox;
    await box.clear();
    DataMutationNotifier().markDirty('daily_streak:clear');
  }

  static List<DateTime> routineGenerationDates({
    required DateTime lastLoginDate,
    required DateTime today,
    DateTime? generationStartDate,
  }) {
    DateTime dateOnly(DateTime date) =>
        DateTime(date.year, date.month, date.day);

    final normalizedToday = dateOnly(today);
    final firstDate = generationStartDate != null
        ? dateOnly(generationStartDate)
        : dateOnly(lastLoginDate).add(const Duration(days: 1));

    if (firstDate.isAfter(normalizedToday)) return const [];

    return [
      for (DateTime date = firstDate;
          !date.isAfter(normalizedToday);
          date = date.add(const Duration(days: 1)))
        date,
    ];
  }

  Future<void> createTasksFromRoutines() => _createTasksFromRoutines();

  Future<void> createTasksFromRoutinesAfterRestore({DateTime? now}) {
    return createTasksForToday(now: now);
  }

  Future<void> createTasksForToday({DateTime? now}) {
    final restoreDate = now ?? DateTime.now();
    return _createTasksFromRoutines(
      generationStartDate: restoreDate,
      now: restoreDate,
    );
  }

  Future<void> _createTasksFromRoutines({
    DateTime? generationStartDate,
    DateTime? now,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final currentTime = now ?? DateTime.now();
    final DateTime today =
        DateTime(currentTime.year, currentTime.month, currentTime.day);
    final String? lastLoginDateString = prefs.getString('lastLoginDate');
    final DateTime lastLoginDate = lastLoginDateString != null
        ? DateTime.parse(lastLoginDateString)
        : today;
    final generationDates = routineGenerationDates(
      lastLoginDate: lastLoginDate,
      today: today,
      generationStartDate: generationStartDate,
    );

    int getNextRoutineSortOrder() {
      final taskList = TaskProvider().taskList;
      final routineList = TaskProvider().routineList;
      final maxTaskSortOrder = taskList.isEmpty
          ? 0
          : taskList
              .map((task) => task.sortOrder)
              .reduce((a, b) => a > b ? a : b);
      final maxRoutineSortOrder = routineList.isEmpty
          ? 0
          : routineList
              .map((routine) => routine.sortOrder)
              .reduce((a, b) => a > b ? a : b);
      return (maxTaskSortOrder > maxRoutineSortOrder
              ? maxTaskSortOrder
              : maxRoutineSortOrder) +
          1;
    }

    LogService.debug('=== createTasksFromRoutines Debug ===');
    LogService.debug('Today: $today');
    LogService.debug('Last login date: $lastLoginDate');
    LogService.debug('Routine count: ${TaskProvider().routineList.length}');

    if (TaskProvider().routineList.isNotEmpty) {
      // Get all existing tasks to find the highest ID
      final existingTasks = await getTasks();
      int highestTaskId = prefs.getInt("last_task_id") ?? 0;

      // Find the highest ID among existing tasks
      for (final task in existingTasks) {
        if (task.id > highestTaskId) {
          highestTaskId = task.id;
        }
      }

      int taskID = highestTaskId;
      int tasksCreated = 0;

      for (final date in generationDates) {
        LogService.debug('Checking date: $date (weekday: ${date.weekday})');

        for (RoutineModel routine in TaskProvider().routineList) {
          LogService.debug('  Routine: ${routine.title}');
          LogService.debug('    Repeat days: ${routine.repeatDays}');
          LogService.debug('    Start date: ${routine.startDate}');
          LogService.debug('    Is archived: ${routine.isArchived}');
          LogService.debug('    Date weekday-1: ${date.weekday - 1}');
          LogService.debug(
              '    Contains weekday: ${routine.repeatDays.contains(date.weekday - 1)}');

          if (routine.sortOrder <= 0) {
            final existingRoutineTasks = TaskProvider()
                .taskList
                .where((task) =>
                    task.routineID == routine.id && task.sortOrder > 0)
                .toList();
            final resolvedSortOrder = existingRoutineTasks.isNotEmpty
                ? existingRoutineTasks
                    .map((task) => task.sortOrder)
                    .reduce((a, b) => a > b ? a : b)
                : getNextRoutineSortOrder();

            routine.sortOrder = resolvedSortOrder;
            await updateRoutine(routine);
            LogService.debug(
                '    ✅ Persisted routine ${routine.id} sortOrder: $resolvedSortOrder');
          }

          if (routine.isActiveForThisDate(date)) {
            // Check if a task for this routine on this date already exists (e.g., from import)
            final bool taskAlreadyExists = TaskProvider().taskList.any(
                (existingTask) =>
                    existingTask.routineID == routine.id &&
                    existingTask.taskDate != null &&
                    existingTask.taskDate!.year == date.year &&
                    existingTask.taskDate!.month == date.month &&
                    existingTask.taskDate!.day == date.day);

            if (taskAlreadyExists) {
              LogService.debug(
                  '    SKIPPING task creation for routine ${routine.title} on $date as it already exists.');
            } else {
              LogService.debug(
                  '    ✓ Creating task for routine ${routine.title} on $date');
              taskID++;
              tasksCreated++;

              final TaskModel task = TaskModel(
                id: taskID,
                title: routine.title,
                description: routine.description,
                taskDate: date,
                status: null,
                type: routine.type,
                isNotificationOn: routine.isNotificationOn,
                isAlarmOn: routine.isAlarmOn,
                priority: routine.priority,
                routineID: routine.id,
                time: routine.time,
                attributeIDList: routine.attirbuteIDList,
                skillIDList: routine.skillIDList,
                currentCount: routine.type == TaskTypeEnum.COUNTER ? 0 : null,
                targetCount: routine.targetCount,
                currentDuration:
                    routine.type == TaskTypeEnum.TIMER ? Duration.zero : null,
                remainingDuration: routine.remainingDuration,
                isTimerActive:
                    routine.type == TaskTypeEnum.TIMER ? false : null,
                sortOrder: routine.sortOrder,
              );

              await addTask(task);
              TaskProvider().taskList.add(task);

              // Bildirim veya alarm ayarla
              if (task.time != null &&
                  (task.isNotificationOn || task.isAlarmOn)) {
                LogService.debug(
                    '    Setting notification for task: ${task.title}');
                TaskProvider().checkNotification(task);
              }
            }
          } else {
            LogService.debug(
                '    ✗ Routine ${routine.title} not active for $date');
          }
        }
      }

      LogService.debug('Total tasks created: $tasksCreated');

      // Update the last task ID in SharedPreferences if tasks were created
      if (TaskProvider().taskList.isNotEmpty) {
        await prefs.setInt("last_task_id", taskID);
      }
    } else {
      LogService.debug('No routines found to create tasks from');
    }

    if (TaskProvider().taskList.isNotEmpty) {
      // Collect unique past dates that have tasks being auto-updated
      final Set<String> processedDates = {};

      // Mark past tasks based on type when the day has passed.
      // Routine tasks become failed, regular tasks become overdue.
      for (TaskModel task in TaskProvider().taskList) {
        final shouldFailRoutine =
            TaskDueDateHelper.shouldAutoMarkFailed(task, currentTime);
        final shouldMarkOverdue =
            TaskDueDateHelper.shouldAutoMarkOverdue(task, currentTime);
        if (shouldFailRoutine || shouldMarkOverdue) {
          final TaskStatusEnum rolloverStatus = shouldFailRoutine
              ? TaskStatusEnum.FAILED
              : TaskStatusEnum.OVERDUE;
          task.status = rolloverStatus;

          LogService.debug(
            'Auto-updated past ${task.routineID != null ? 'routine' : 'regular'} task to ${rolloverStatus.name}: '
            'ID=${task.id}, Title=${task.title}',
          );

          // Create log for the updated task status.
          await TaskLogProvider().addTaskLog(
            task,
            customStatus: rolloverStatus,
          );

          await updateTask(task);

          // Track the date for daily penalty bonus calculation
          final dateKey =
              '${task.taskDate!.year}-${task.taskDate!.month}-${task.taskDate!.day}';
          processedDates.add(dateKey);
        }
      }

      // Recalculate daily bonuses/penalties for each affected past day.
      // checkDailyDPBonuses has been removed from TaskProvider
      // for (final dateKey in processedDates) {
      //   final parts = dateKey.split('-');
      //   final pastDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      // }
    }

    await prefs.setString('lastLoginDate', today.toIso8601String());
  }

  // delete all data
  Future<void> deleteAllData({
    bool isLogout = false,
    bool isImport = false,
    bool showUi = true,
  }) async {
    if (showUi) {
      Get.dialog(
        LoadingDialog(
          message: LocaleKeys.deleting_all_data.tr(),
          subtitle: LocaleKeys.please_wait_restarting.tr(),
        ),
        barrierDismissible: false,
      );
    }

    try {
      // Cancel all notifications first
      try {
        await NotificationService().cancelAllNotifications();
      } catch (e) {
        LogService.error(
            'Error canceling notifications during data deletion: $e');
        // Devam et, bildirimler iptal edilemese bile veri silinebilir
      }

      // Clear all attachment files
      try {
        await FileStorageService.instance.clearAllAttachments();
      } catch (e) {
        LogService.error('Error clearing attachment files: $e');
      }

      // Clear Hive boxes
      // final box = await _userBox; // Don't clear user box, just reset credits
      // await box.clear();

      final box2 = await _itemBox;
      await box2.clear();

      final box3 = await _traitBox;
      await box3.clear();

      final box4 = await _routineBox;
      await box4.clear();

      final box5 = await _taskBox;
      await box5.clear();

      final box6 = await _taskLogBox;
      await box6.clear();

      final box7 = await _categoryBox;
      await box7.clear();

      final box8 = await _dailyStreakBox;
      await box8.clear();

      // Clear Task Templates
      try {
        final taskTemplateBox = await _taskTemplateBox;
        await taskTemplateBox.clear();
      } catch (e) {
        LogService.error('Error clearing task templates: $e');
      }

      // Clear Vacation Dates
      try {
        final vacationDateBox = await _vacationDateBox;
        await vacationDateBox.clear();
      } catch (e) {
        LogService.error('Error clearing vacation dates: $e');
      }

      // Clear Store Item Logs
      try {
        final storeItemLogBox = await _storeItemLogBox;
        await storeItemLogBox.clear();
      } catch (e) {
        LogService.error('Error clearing store item logs: $e');
      }

      final prefs = await SharedPreferences.getInstance();
      final preservedBackupPreferences = isImport
          ? <String, Object?>{
              'auto_backup_enabled': prefs.getBool('auto_backup_enabled'),
              'backup_wifi_only': prefs.getBool('backup_wifi_only'),
              'drive_backup_frequency':
                  prefs.getString('drive_backup_frequency'),
              'drive_backup_last_attempt':
                  prefs.getString('drive_backup_last_attempt'),
              'drive_backup_last_success':
                  prefs.getString('drive_backup_last_success'),
              'drive_backup_last_error':
                  prefs.getString('drive_backup_last_error'),
              'drive_backup_last_restore':
                  prefs.getString('drive_backup_last_restore'),
            }
          : const <String, Object?>{};

      await prefs.clear();
      for (final entry in preservedBackupPreferences.entries) {
        if (entry.value is bool) {
          await prefs.setBool(entry.key, entry.value! as bool);
        } else if (entry.value is String) {
          await prefs.setString(entry.key, entry.value! as String);
        }
      }

      // Refresh providers
      TaskProvider().taskList.clear();
      TaskProvider().routineList.clear();
      TaskProvider().updateItems();

      TraitProvider().traitList.clear();

      StoreProvider().storeItemList.clear();
      // Clear task logs in the provider
      await TaskLogProvider().clearAllLogs();

      // Clear projects, project subtasks, and notes boxes
      await ProjectsService().clearAllProjects();
      await ProjectSubtasksService().clearAllSubtasks();
      await NotesService().clearAllNotes();

      // Clear category, notes, projects providers
      CategoryProvider().clearAllCategories();
      NotesProvider().clearAllNotes();
      ProjectsProvider().clearAllProjects();

      // Reset user credits instead of deleting user
      await UserProvider().resetCredit();

      if (showUi) {
        Helper().getMessage(message: LocaleKeys.DeleteAllDataSuccess.tr());
      }
      LogService.debug('✅ All data deleted successfully, user credits reset');

      // If this is a logout operation, don't exit the app
      if (isLogout) {
        if (showUi && Get.isDialogOpen == true) {
          Get.back();
        }
        LogService.debug(
            '📋 Data cleared for logout, app will continue running');
        return;
      }

      if (!isImport) {
        LogService.debug('🔄 Restarting app after data deletion...');
        await Future.delayed(const Duration(seconds: 2));
        exit(0);
      }
    } catch (e) {
      if (showUi && Get.isDialogOpen == true) {
        Get.back();
      }
      LogService.error('❌ Error during data deletion: $e');
      if (showUi) {
        Helper().getMessage(message: 'Error deleting data: $e');
      }
      rethrow;
    }
  }

  Future<File> createBackupArchive({Directory? outputDirectory}) async {
    Directory? workingDirectory;
    try {
      final now = DateTime.now().toUtc();
      final timestamp = now.toIso8601String().replaceAll(RegExp(r'[:.-]'), '');
      final fileName = 'nextlevel_backup_$timestamp.zip';
      final directory =
          outputDirectory ?? await getApplicationDocumentsDirectory();
      await directory.create(recursive: true);

      final Map<String, dynamic> allData = {};
      final packageInfo = await PackageInfo.fromPlatform();
      allData['_metadata'] = {
        'schemaVersion': 1,
        'createdAt': now.toIso8601String(),
        'appVersion': packageInfo.version,
        'buildNumber': packageInfo.buildNumber,
      };

      // Export users
      final userBox = await _userBox;
      final userMap = {};
      for (var key in userBox.keys) {
        final user = userBox.get(key);
        if (user != null) userMap[key.toString()] = user.toJson();
      }
      allData[_userBoxName] = userMap;

      // Export items
      final itemBox = await _itemBox;
      final itemMap = {};
      for (var key in itemBox.keys) {
        final item = itemBox.get(key);
        if (item != null) itemMap[key.toString()] = item.toJson();
      }
      allData[_itemBoxName] = itemMap;

      // Export traits
      final traitBox = await _traitBox;
      final traitMap = {};
      for (var key in traitBox.keys) {
        final trait = traitBox.get(key);
        if (trait != null) traitMap[key.toString()] = trait.toJson();
      }
      allData[_traitBoxName] = traitMap;

      // Export routines
      final routineBox = await _routineBox;
      final routineMap = {};
      for (var key in routineBox.keys) {
        final routine = routineBox.get(key);
        if (routine != null) routineMap[key.toString()] = routine.toJson();
      }
      allData[_routineBoxName] = routineMap;

      // Export tasks
      final taskBox = await _taskBox;
      final taskMap = {};
      for (var key in taskBox.keys) {
        final task = taskBox.get(key);
        if (task != null) taskMap[key.toString()] = task.toJson();
      }
      allData[_taskBoxName] = taskMap;

      // Export task logs
      final taskLogBox = await _taskLogBox;
      final taskLogMap = {};
      for (var key in taskLogBox.keys) {
        final taskLog = taskLogBox.get(key);
        if (taskLog != null) taskLogMap[key.toString()] = taskLog.toJson();
      }
      allData[_taskLogBoxName] = taskLogMap;

      // Export categories
      final categoryBox = await _categoryBox;
      final categoryMap = {};
      for (var key in categoryBox.keys) {
        final category = categoryBox.get(key);
        if (category != null) categoryMap[key.toString()] = category.toJson();
      }
      allData[_categoryBoxName] = categoryMap;
      LogService.debug('✅ Exported ${categoryMap.length} categories');

      // Export projects
      final projects = await ProjectsService().getProjects();
      final projectMap = {};
      for (var project in projects) {
        projectMap[project.id.toString()] = project.toJson();
      }
      allData["projects"] = projectMap;

      // Export project subtasks
      final projectSubtasks = await ProjectSubtasksService().getAllSubtasks();
      final projectSubtaskMap = {};
      for (var subtask in projectSubtasks) {
        projectSubtaskMap[subtask.id.toString()] = subtask.toJson();
      }
      allData["project_subtasks"] = projectSubtaskMap;

      // Export Daily Streaks
      final dailyStreakBox = await _dailyStreakBox;
      final dailyStreakMap = {};
      for (var key in dailyStreakBox.keys) {
        final streak = dailyStreakBox.get(key);
        if (streak != null) dailyStreakMap[key.toString()] = streak.toJson();
      }
      allData[_dailyStreakBoxName] = dailyStreakMap;

      // Export notes
      final notes = await NotesService().getNotes();
      final noteMap = {};
      for (var note in notes) {
        noteMap[note.id.toString()] = note.toJson();
      }
      allData["notes"] = noteMap;

      // Export Task Templates
      final taskTemplateBox = await _taskTemplateBox;
      final templateMap = {};
      for (var key in taskTemplateBox.keys) {
        final template = taskTemplateBox.get(key);
        if (template != null) templateMap[key.toString()] = template.toJson();
      }
      allData[_taskTemplateBoxName] = templateMap;
      LogService.debug('✅ Exported ${templateMap.length} task templates');

      // Export Vacation Dates
      final vacationDateBox = await _vacationDateBox;
      final vacationDateMap = {};
      for (var key in vacationDateBox.keys) {
        final vacationDate = vacationDateBox.get(key);
        if (vacationDate != null) {
          vacationDateMap[key.toString()] = vacationDate.toJson();
        }
      }
      allData[_vacationDateBoxName] = vacationDateMap;
      LogService.debug('✅ Exported ${vacationDateMap.length} vacation dates');

      // Export Store Item Logs
      final storeItemLogBox = await _storeItemLogBox;
      final storeItemLogMap = {};
      for (var key in storeItemLogBox.keys) {
        final log = storeItemLogBox.get(key);
        if (log != null) storeItemLogMap[key.toString()] = log.toJson();
      }
      allData[_storeItemLogBoxName] = storeItemLogMap;
      LogService.debug('✅ Exported ${storeItemLogMap.length} store item logs');

      // Export SharedPrefs
      final prefs = await SharedPreferences.getInstance();
      final sharedPrefsMap = {};
      const excludedBackupKeys = {
        'auto_backup_enabled',
        'backup_wifi_only',
        'drive_backup_frequency',
        'drive_backup_last_attempt',
        'drive_backup_last_success',
        'drive_backup_last_error',
        'drive_backup_last_restore',
      };
      for (final key in prefs.getKeys()) {
        if (!excludedBackupKeys.contains(key)) {
          sharedPrefsMap[key] = prefs.get(key);
        }
      }

      // Export existing settings
      sharedPrefsMap["lastLoginDate"] = prefs.getString('lastLoginDate');
      sharedPrefsMap["last_task_id"] = prefs.getInt('last_task_id') ?? 0;
      sharedPrefsMap["last_routine_id"] = prefs.getInt('last_routine_id') ?? 0;
      sharedPrefsMap["last_trait_id"] = prefs.getInt('last_trait_id') ?? 0;
      sharedPrefsMap["last_category_id"] =
          prefs.getInt('last_category_id') ?? 0;

      // Export inbox page filter settings with default values
      sharedPrefsMap["categories_show_tasks"] =
          prefs.getBool('categories_show_tasks') ?? true;
      sharedPrefsMap["categories_show_routines"] =
          prefs.getBool('categories_show_routines') ?? true;
      sharedPrefsMap["categories_show_today_tasks"] =
          prefs.getBool('categories_show_today_tasks') ?? true;
      sharedPrefsMap["categories_date_filter"] =
          prefs.getInt('categories_date_filter') ?? 0;
      sharedPrefsMap["categories_show_checkbox"] =
          prefs.getBool('categories_show_checkbox') ?? true;
      sharedPrefsMap["categories_show_counter"] =
          prefs.getBool('categories_show_counter') ?? true;
      sharedPrefsMap["categories_show_timer"] =
          prefs.getBool('categories_show_timer') ?? true;
      sharedPrefsMap["categories_show_completed"] =
          prefs.getBool('categories_show_completed') ?? true;
      sharedPrefsMap["categories_show_failed"] =
          prefs.getBool('categories_show_failed') ?? true;
      sharedPrefsMap["categories_show_cancel"] =
          prefs.getBool('categories_show_cancel') ?? true;
      sharedPrefsMap["categories_show_archived"] =
          prefs.getBool('categories_show_archived') ?? false;
      sharedPrefsMap["categories_show_overdue"] =
          prefs.getBool('categories_show_overdue') ?? true;
      sharedPrefsMap["categories_show_empty_status"] =
          prefs.getBool('categories_show_empty_status') ?? true;
      sharedPrefsMap["categories_selected_category_id"] =
          prefs.getString('categories_selected_category_id') ?? '-1';

      // Export home page setting
      sharedPrefsMap["show_completed"] =
          prefs.getBool('show_completed') ?? false;

      // Export theme setting
      sharedPrefsMap["isDark"] = prefs.getBool('isDark') ?? false;

      // Export main color setting
      sharedPrefsMap["main_color"] = prefs.getInt('main_color') ?? 0;

      // Export language setting
      sharedPrefsMap["selected_language"] =
          prefs.getString('selected_language') ?? 'en';

      // Export vacation mode setting
      sharedPrefsMap["vacation_mode_enabled"] =
          prefs.getBool('vacation_mode_enabled') ?? false;

      // Export streak settings
      sharedPrefsMap["streak_minimum_hours"] =
          prefs.getDouble('streak_minimum_hours') ?? 1.0;
      sharedPrefsMap["vacation_weekdays"] =
          prefs.getStringList('vacation_weekdays') ?? [];

      allData["SharedPreferances"] = sharedPrefsMap;

      final jsonString = jsonEncode(allData);

      // Create a temporary directory for grouping files into zip
      final tempDir = Directory(
          '${directory.path}/temp_gamify_export_${DateTime.now().millisecondsSinceEpoch}');
      workingDirectory = tempDir;
      await tempDir.create();

      // Write JSON backup
      final jsonFile = File('${tempDir.path}/gamify_todo_backup.json');
      await jsonFile.writeAsString(jsonString);

      // Create attachments folder inside the temp dir and copy files
      final tempAttachmentsDir = Directory('${tempDir.path}/attachments');
      await tempAttachmentsDir.create();
      final actualAttachmentsDir =
          await FileStorageService.instance.getAttachmentsDirectory();
      final copiedAttachmentPaths = <String>{};

      if (await actualAttachmentsDir.exists()) {
        final attachmentFiles = actualAttachmentsDir.listSync();
        for (var fileEntity in attachmentFiles) {
          if (fileEntity is File) {
            await _copyAttachmentFileToBackup(
              sourceFile: fileEntity,
              tempAttachmentsDir: tempAttachmentsDir,
              copiedSourcePaths: copiedAttachmentPaths,
            );
          }
        }
      }

      await _copyReferencedTaskAttachmentsToBackup(
        taskMap: taskMap,
        tempAttachmentsDir: tempAttachmentsDir,
        copiedSourcePaths: copiedAttachmentPaths,
      );

      final filePath = path.join(directory.path, fileName);
      try {
        await _backupArchiveService.createZipFromDirectory(
          sourceDirectory: tempDir,
          zipFilePath: filePath,
        );
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }

      final archiveFile = File(filePath);
      LogService.debug('Backup archive created at: $filePath');
      return archiveFile;
    } catch (e) {
      LogService.error('Backup archive creation failed: $e');
      rethrow;
    } finally {
      try {
        if (workingDirectory != null && await workingDirectory.exists()) {
          await workingDirectory.delete(recursive: true);
        }
      } catch (error) {
        LogService.error('Backup creation cleanup failed: $error');
      }
    }
  }

  Future<String?> exportData() async {
    try {
      final archiveFile = await createBackupArchive();
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(archiveFile.path)],
          text: 'Gamify Todo Backup',
          subject: 'Gamify Todo Backup Archive',
        ),
      );
      LogService.debug('File Shared: ${archiveFile.path}');

      NavigatorService().back();

      LogService.debug(
          'Backup created and shared successfully at: ${archiveFile.path}');

      return archiveFile.path;
    } catch (e) {
      Helper().getMessage(
        message: LocaleKeys.backup_creation_error.tr(args: [e.toString()]),
      );
      rethrow;
    }
  }

  void _validateBackupData(Map<String, dynamic> allData) {
    Map<String, dynamic> readMap(String key, {bool required = false}) {
      final value = allData[key];
      if (value == null && !required) {
        return const {};
      }
      if (value is! Map) {
        throw FormatException('Backup section "$key" is missing or invalid.');
      }
      return Map<String, dynamic>.from(value);
    }

    final metadata = readMap('_metadata');
    final schemaVersion = metadata['schemaVersion'];
    if (schemaVersion is num && schemaVersion.toInt() > 1) {
      throw const FormatException(
        'This backup was created by a newer, unsupported app version.',
      );
    }

    void validateEntries(
      String key,
      void Function(Map<String, dynamic>) parser, {
      bool required = false,
    }) {
      final values = readMap(key, required: required);
      for (final value in values.values) {
        if (value is! Map) {
          throw FormatException('Backup section "$key" contains invalid data.');
        }
        parser(Map<String, dynamic>.from(value));
      }
    }

    validateEntries(_userBoxName, UserModel.fromJson, required: true);
    validateEntries(_itemBoxName, ItemModel.fromJson, required: true);
    validateEntries(_traitBoxName, TraitModel.fromJson, required: true);
    validateEntries(_routineBoxName, RoutineModel.fromJson, required: true);
    validateEntries(_taskBoxName, TaskModel.fromJson, required: true);
    validateEntries(_taskLogBoxName, TaskLogModel.fromJson);
    validateEntries(_categoryBoxName, CategoryModel.fromJson);
    validateEntries('projects', ProjectModel.fromJson);
    validateEntries('project_subtasks', ProjectSubtaskModel.fromJson);
    validateEntries(_dailyStreakBoxName, DailyStreakModel.fromJson);
    validateEntries('notes', NoteModel.fromJson);
    validateEntries(_taskTemplateBoxName, TaskTemplateModel.fromJson);
    validateEntries(_vacationDateBoxName, VacationDateModel.fromJson);
    validateEntries(_storeItemLogBoxName, StoreItemLog.fromJson);
    readMap('SharedPreferances', required: true);
  }

  Future<bool> importData({
    File? archiveFile,
    bool showUi = true,
    bool restartApp = true,
  }) async {
    Directory? workingDirectory;
    try {
      File? zipFile = archiveFile;
      if (zipFile == null) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['zip'],
        );
        final pickedPath = result?.files.single.path;
        if (pickedPath != null) {
          zipFile = File(pickedPath);
        }
      }

      if (zipFile != null) {
        if (await zipFile.exists()) {
          if (showUi) {
            Get.dialog(
              LoadingDialog(
                message: LocaleKeys.restoring_backup.tr(),
                subtitle: LocaleKeys.please_wait_restarting.tr(),
              ),
              barrierDismissible: false,
            );
          }

          // Get temp directory for extraction
          final directory = await getApplicationDocumentsDirectory();
          final tempExtractDir = Directory(
              '${directory.path}/temp_gamify_import_${DateTime.now().millisecondsSinceEpoch}');
          workingDirectory = tempExtractDir;
          await tempExtractDir.create();

          await _backupArchiveService.extractZipSafely(
            zipFile: zipFile,
            destinationDirectory: tempExtractDir,
          );

          // Locate the JSON backup file
          final jsonFile =
              await _backupArchiveService.findBackupJsonFile(tempExtractDir);
          if (jsonFile == null || !await jsonFile.exists()) {
            await tempExtractDir.delete(recursive: true);
            throw Exception('Backup JSON file not found in the archive.');
          }

          final archiveRootDir = jsonFile.parent;

          final content = await jsonFile.readAsString();
          final Map<String, dynamic> allData = jsonDecode(content);

          _validateBackupData(allData);

          // Clear existing data first (this will also clear SharedPreferences)
          await deleteAllData(isImport: true, showUi: showUi);

          // Restore attachments
          final restoredAttachmentPaths = <String, String>{};
          final tempAttachmentsDir =
              await _backupArchiveService.findAttachmentsDirectory(
            extractedRoot: tempExtractDir,
            preferredRoot: archiveRootDir,
          );
          if (tempAttachmentsDir != null) {
            final actualAttachmentsDir =
                await FileStorageService.instance.getAttachmentsDirectory();
            restoredAttachmentPaths.addAll(
              await _backupArchiveService.restoreAttachments(
                sourceDirectory: tempAttachmentsDir,
                destinationDirectory: actualAttachmentsDir,
              ),
            );
          }

          // Cleanup temp extraction directory
          await tempExtractDir.delete(recursive: true);

          // Import users
          final userBox = await _userBox;
          final userData = allData[_userBoxName] as Map<String, dynamic>;
          for (var entry in userData.entries) {
            final user = UserModel.fromJson(entry.value);
            await userBox.put(int.parse(entry.key), user);
            UserProvider().setUser(user);
          }

          // Import items
          final itemBox = await _itemBox;
          final itemData = allData[_itemBoxName] as Map<String, dynamic>;
          for (var entry in itemData.entries) {
            final item = ItemModel.fromJson(entry.value);
            await itemBox.put(int.parse(entry.key), item);
            StoreProvider().storeItemList.add(item);
          }
          LogService.debug(TraitProvider().traitList.toString());
          // Import traits
          final traitBox = await _traitBox;
          final traitData = allData[_traitBoxName] as Map<String, dynamic>;
          for (var entry in traitData.entries) {
            final trait = TraitModel.fromJson(entry.value);
            await traitBox.put(int.parse(entry.key), trait);
            TraitProvider().traitList.add(trait);
          }
          LogService.debug(TraitProvider().traitList.toString());

          // Import routines
          final routineBox = await _routineBox;
          final routineData = allData[_routineBoxName] as Map<String, dynamic>;
          for (var entry in routineData.entries) {
            final routine = RoutineModel.fromJson(entry.value);
            await routineBox.put(int.parse(entry.key), routine);
            TaskProvider().routineList.add(routine);
          }

          // Import tasks
          final taskBox = await _taskBox;
          final taskData = allData[_taskBoxName] as Map<String, dynamic>;
          for (var entry in taskData.entries) {
            final task = TaskModel.fromJson(entry.value);
            task.attachmentPaths = _normalizeImportedAttachmentPaths(
              task.attachmentPaths,
              restoredAttachmentPaths,
            );
            await taskBox.put(int.parse(entry.key), task);
            TaskProvider().taskList.add(task);
          }

          // Import categories if they exist
          final categoryBox = await _categoryBox;
          if (allData.containsKey(_categoryBoxName)) {
            final categoryData =
                allData[_categoryBoxName] as Map<String, dynamic>;
            CategoryProvider().categoryList.clear();
            for (var entry in categoryData.entries) {
              final category = CategoryModel.fromJson(entry.value);
              await categoryBox.put(entry.key, category);
              CategoryProvider().categoryList.add(category);
            }
            CategoryProvider().notifyCategoryUpdate();
            LogService.debug('✅ Imported ${categoryData.length} categories');
          }

          // Import task logs if they exist
          final taskLogBox = await _taskLogBox;
          if (allData.containsKey(_taskLogBoxName)) {
            final taskLogData =
                allData[_taskLogBoxName] as Map<String, dynamic>;
            for (var entry in taskLogData.entries) {
              final taskLog = TaskLogModel.fromJson(entry.value);
              await taskLogBox.put(int.parse(entry.key), taskLog);
            }

            // Reload task logs into provider so that statistics and streaks are correct
            await TaskLogProvider().loadTaskLogs();
          }

          // Import projects if they exist
          if (allData.containsKey("projects")) {
            final projectData = allData["projects"] as Map<String, dynamic>;
            for (var entry in projectData.entries) {
              final project = ProjectModel.fromJson(entry.value);
              await ProjectsService().addProject(project);
            }
            await ProjectsProvider().loadProjects();
          }

          // Import project subtasks if they exist
          if (allData.containsKey("project_subtasks")) {
            final subtaskData =
                allData["project_subtasks"] as Map<String, dynamic>;
            for (var entry in subtaskData.entries) {
              final subtask = ProjectSubtaskModel.fromJson(entry.value);
              await ProjectSubtasksService().addSubtask(subtask);
            }
          }

          // Import Daily Streaks if they exist
          final dailyStreakBox = await _dailyStreakBox;
          if (allData.containsKey(_dailyStreakBoxName)) {
            final streakData =
                allData[_dailyStreakBoxName] as Map<String, dynamic>;
            for (var entry in streakData.entries) {
              final streak = DailyStreakModel.fromJson(entry.value);
              await dailyStreakBox.put(entry.key, streak);
            }
            LogService.debug('✅ Imported ${streakData.length} daily streaks');
          }

          // Import notes if they exist
          if (allData.containsKey("notes")) {
            final noteData = allData["notes"] as Map<String, dynamic>;
            for (var entry in noteData.entries) {
              final note = NoteModel.fromJson(entry.value);
              await NotesService().addNote(note);
            }
            await NotesProvider().loadNotes();
          }

          // Import Task Templates if they exist
          if (allData.containsKey(_taskTemplateBoxName)) {
            final taskTemplateBox = await _taskTemplateBox;
            final templateData =
                allData[_taskTemplateBoxName] as Map<String, dynamic>;
            for (var entry in templateData.entries) {
              final template = TaskTemplateModel.fromJson(entry.value);
              await taskTemplateBox.put(entry.key, template);
            }
            LogService.debug(
                '✅ Imported ${templateData.length} task templates');
          }

          // Import Vacation Dates if they exist
          if (allData.containsKey(_vacationDateBoxName)) {
            final vacationDateBox = await _vacationDateBox;
            final vacationData =
                allData[_vacationDateBoxName] as Map<String, dynamic>;
            for (var entry in vacationData.entries) {
              final vacationDate = VacationDateModel.fromJson(entry.value);
              await vacationDateBox.put(entry.key, vacationDate);
            }
            LogService.debug(
                '✅ Imported ${vacationData.length} vacation dates');
          }

          // Import Store Item Logs if they exist
          if (allData.containsKey(_storeItemLogBoxName)) {
            final storeItemLogBox = await _storeItemLogBox;
            final storeItemLogData =
                allData[_storeItemLogBoxName] as Map<String, dynamic>;
            for (var entry in storeItemLogData.entries) {
              final log = StoreItemLog.fromJson(entry.value);
              await storeItemLogBox.put(int.parse(entry.key), log);
            }
            LogService.debug(
                '✅ Imported ${storeItemLogData.length} store item logs');
          }

          // Import SharedPrefs
          final prefs = await SharedPreferences.getInstance();
          final sharedPrefsMap =
              allData["SharedPreferances"] as Map<String, dynamic>;

          for (final entry in sharedPrefsMap.entries) {
            final value = entry.value;
            if (value is bool) {
              await prefs.setBool(entry.key, value);
            } else if (value is int) {
              await prefs.setInt(entry.key, value);
            } else if (value is double) {
              await prefs.setDouble(entry.key, value);
            } else if (value is String) {
              await prefs.setString(entry.key, value);
            } else if (value is List) {
              await prefs.setStringList(
                entry.key,
                value.map((item) => item.toString()).toList(),
              );
            }
          }

          // Advance the routine-generation cursor immediately so an
          // interrupted restore cannot backfill the backup gap on next launch.
          // The backup already contains its own historical tasks; only today's
          // instance is generated explicitly below.
          final restoreDate = DateTime.now();
          await prefs.setString(
              'lastLoginDate',
              DateTime(restoreDate.year, restoreDate.month, restoreDate.day)
                  .toIso8601String());
          await prefs.setInt(
              'last_task_id', sharedPrefsMap["last_task_id"] ?? 0);
          await prefs.setInt(
              'last_routine_id', sharedPrefsMap["last_routine_id"] ?? 0);
          await prefs.setInt(
              'last_trait_id', sharedPrefsMap["last_trait_id"] ?? 0);
          await prefs.setInt(
              'last_category_id', sharedPrefsMap["last_category_id"] ?? 0);

          // Import inbox page filter settings with proper defaults
          await prefs.setBool(
              'categories_show_tasks',
              (sharedPrefsMap["categories_show_tasks"] is bool)
                  ? sharedPrefsMap["categories_show_tasks"]
                  : true);
          await prefs.setBool(
              'categories_show_routines',
              (sharedPrefsMap["categories_show_routines"] is bool)
                  ? sharedPrefsMap["categories_show_routines"]
                  : true);
          await prefs.setBool(
              'categories_show_today_tasks',
              (sharedPrefsMap["categories_show_today_tasks"] is bool)
                  ? sharedPrefsMap["categories_show_today_tasks"]
                  : true);
          await prefs.setInt('categories_date_filter',
              sharedPrefsMap["categories_date_filter"] ?? 0);
          await prefs.setBool(
              'categories_show_checkbox',
              (sharedPrefsMap["categories_show_checkbox"] is bool)
                  ? sharedPrefsMap["categories_show_checkbox"]
                  : true);
          await prefs.setBool(
              'categories_show_counter',
              (sharedPrefsMap["categories_show_counter"] is bool)
                  ? sharedPrefsMap["categories_show_counter"]
                  : true);
          await prefs.setBool(
              'categories_show_timer',
              (sharedPrefsMap["categories_show_timer"] is bool)
                  ? sharedPrefsMap["categories_show_timer"]
                  : true);
          await prefs.setBool(
              'categories_show_completed',
              (sharedPrefsMap["categories_show_completed"] is bool)
                  ? sharedPrefsMap["categories_show_completed"]
                  : true);
          await prefs.setBool(
              'categories_show_failed',
              (sharedPrefsMap["categories_show_failed"] is bool)
                  ? sharedPrefsMap["categories_show_failed"]
                  : true);
          await prefs.setBool(
              'categories_show_cancel',
              (sharedPrefsMap["categories_show_cancel"] is bool)
                  ? sharedPrefsMap["categories_show_cancel"]
                  : true);
          await prefs.setBool(
              'categories_show_archived',
              (sharedPrefsMap["categories_show_archived"] is bool)
                  ? sharedPrefsMap["categories_show_archived"]
                  : false);
          await prefs.setBool(
              'categories_show_overdue',
              (sharedPrefsMap["categories_show_overdue"] is bool)
                  ? sharedPrefsMap["categories_show_overdue"]
                  : true);
          await prefs.setBool(
              'categories_show_empty_status',
              (sharedPrefsMap["categories_show_empty_status"] is bool)
                  ? sharedPrefsMap["categories_show_empty_status"]
                  : true);
          await prefs.setString('categories_selected_category_id',
              sharedPrefsMap["categories_selected_category_id"] ?? '-1');

          // Import home page setting
          await prefs.setBool(
              'show_completed',
              (sharedPrefsMap["show_completed"] is bool)
                  ? sharedPrefsMap["show_completed"]
                  : false);

          // Import theme setting
          await prefs.setBool(
              'isDark',
              (sharedPrefsMap["isDark"] is bool)
                  ? sharedPrefsMap["isDark"]
                  : false);

          // Import main color setting
          await prefs.setInt('main_color', sharedPrefsMap["main_color"] ?? 0);

          // Import language setting
          await prefs.setString(
              'selected_language', sharedPrefsMap["selected_language"] ?? 'en');

          // Import vacation mode setting
          await prefs.setBool(
              'vacation_mode_enabled',
              (sharedPrefsMap["vacation_mode_enabled"] is bool)
                  ? sharedPrefsMap["vacation_mode_enabled"]
                  : false);

          // Import streak settings
          if (sharedPrefsMap["streak_minimum_hours"] != null) {
            await prefs.setDouble(
                'streak_minimum_hours',
                (sharedPrefsMap["streak_minimum_hours"] is num)
                    ? (sharedPrefsMap["streak_minimum_hours"] as num).toDouble()
                    : 1.0);
          }
          if (sharedPrefsMap["vacation_weekdays"] != null) {
            await prefs.setStringList(
                'vacation_weekdays',
                (sharedPrefsMap["vacation_weekdays"] as List)
                    .map((e) => e.toString())
                    .toList());
          }

          // Mark first launch as done to prevent sample data dialog after restore
          await prefs.setBool('is_first_launch', false);
          await prefs.setBool('is_default_data_loaded', true);

          // Update TaskProvider before creating tasks so it has the imported routines
          TaskProvider().updateItems();

          // Create only today's legitimate routine instances. Historical data
          // is already in the backup; the non-lived gap must stay empty.
          await createTasksFromRoutinesAfterRestore(now: restoreDate);

          // Cancel all notifications after import and task creation to clean up any old notifications
          await NotificationService().cancelAllNotifications();

          // Re-schedule notifications for imported tasks that have notification/alarm settings
          for (TaskModel task in TaskProvider().taskList) {
            if ((task.isNotificationOn || task.isAlarmOn) &&
                task.time != null &&
                task.taskDate != null) {
              TaskProvider().checkNotification(task);
            }
          }

          // Refresh providers
          TaskProvider().updateItems();
          StoreProvider().setStateItems();
          await DailyStreakProvider().reload();

          if (showUi) {
            NavigatorService().goBackNavbar(
              isHome: true,
              isDialog: true,
            );
            Helper().getMessage(
              message: LocaleKeys.backup_restored_successfully.tr(),
            );
          }
          LogService.debug('✅ Backup restored successfully');

          // Ensure all async operations are completed before restarting
          LogService.debug(
              '💾 Flushing Hive boxes to ensure data persistence...');
          await Future.wait([
            userBox.flush(),
            itemBox.flush(),
            traitBox.flush(),
            routineBox.flush(),
            taskBox.flush(),
            taskLogBox.flush(),
            categoryBox.flush(),
            if (allData.containsKey(_taskTemplateBoxName))
              (await _taskTemplateBox).flush(),
            if (allData.containsKey(_vacationDateBoxName))
              (await _vacationDateBox).flush(),
            if (allData.containsKey(_storeItemLogBoxName))
              (await _storeItemLogBox).flush(),
          ]);

          LogService.debug('✅ All data flushed to disk');
          if (restartApp) {
            LogService.debug('🔄 Restarting app after data restore...');
            await Future.delayed(const Duration(seconds: 2));
            LogService.debug('👋 Exiting app now...');
            exit(0);
          }
          return true;
        }
      }
      if (showUi && Get.isDialogOpen == true) {
        Get.back();
      }
      if (showUi) {
        Helper().getMessage(
          message: LocaleKeys.backup_restore_cancelled.tr(),
        );
      }
      return false;
    } catch (e) {
      if (showUi && Get.isDialogOpen == true) {
        Get.back();
      }
      if (showUi) {
        Helper().getMessage(
          message: LocaleKeys.backup_restore_error.tr(args: [e.toString()]),
        );
      }
      rethrow;
    } finally {
      try {
        if (workingDirectory != null && await workingDirectory.exists()) {
          await workingDirectory.delete(recursive: true);
        }
      } catch (error) {
        LogService.error('Backup extraction cleanup failed: $error');
      }
    }
  }

  // Reset all routine progress
  Future<void> resetAllRoutineProgress() async {
    LogService.debug('=== RESETTING ALL ROUTINE PROGRESS ===');

    final taskProvider = TaskProvider();
    final taskLogProvider = TaskLogProvider();
    final today = DateTime.now();

    // Get all tasks that belong to routines
    final routineTasks =
        taskProvider.taskList.where((task) => task.routineID != null).toList();

    // Separate tasks: past tasks to delete, today's tasks to reset
    final tasksToDelete = <TaskModel>[];
    final tasksToReset = <TaskModel>[];

    for (final task in routineTasks) {
      // Check if task is from a past date
      if (task.taskDate != null) {
        final taskDate = task.taskDate!;
        final isPastTask = taskDate.year < today.year ||
            (taskDate.year == today.year && taskDate.month < today.month) ||
            (taskDate.year == today.year &&
                taskDate.month == today.month &&
                taskDate.day < today.day);

        if (isPastTask) {
          tasksToDelete.add(task);
        } else {
          tasksToReset.add(task);
        }
      } else {
        // If no taskDate, consider it as a current task to reset
        tasksToReset.add(task);
      }
    }

    // Delete past routine tasks completely
    for (final task in tasksToDelete) {
      LogService.debug(
          'Deleting past routine task: ${task.title} (ID=${task.id}, Date=${task.taskDate})');
      await deleteTask(task.id);
    }

    // Reset progress for current routine tasks (today's tasks)
    for (final task in tasksToReset) {
      LogService.debug(
          'Resetting progress for current routine task: ${task.title} (ID=${task.id})');

      // Reset progress values
      if (task.type == TaskTypeEnum.COUNTER) {
        task.currentCount = 0;
      } else if (task.type == TaskTypeEnum.TIMER) {
        task.currentDuration = Duration.zero;
        // Also stop timer if it's active
        if (task.isTimerActive == true) {
          task.isTimerActive = false;
          GlobalTimer().startStopTimer(taskModel: task);
        }
      }

      // Reset task status to null (in progress)
      task.status = null;

      // Update task in storage
      await updateTask(task);
    }

    // Delete all task logs for routine tasks
    final taskLogBox = await _taskLogBox;
    final allLogs = taskLogBox.values.toList();
    final routineLogIds = <int>[];

    for (final log in allLogs) {
      if (log.routineId != null) {
        routineLogIds.add(log.id);
      }
    }

    // Delete routine logs from Hive
    for (final logId in routineLogIds) {
      await taskLogBox.delete(logId);
    }

    // Clear routine logs from provider
    taskLogProvider.taskLogList.removeWhere((log) => log.routineId != null);

    // Remove deleted tasks from provider
    taskProvider.taskList.removeWhere((task) => tasksToDelete.contains(task));

    // Update providers
    taskProvider.updateItems();

    LogService.debug(
        'Routine progress reset completed. Deleted ${tasksToDelete.length} past tasks, reset ${tasksToReset.length} current tasks, and deleted ${routineLogIds.length} logs.');

    // Show success message
    Helper().getMessage(message: LocaleKeys.ResetRoutineProgressSuccess.tr());
  }
}
