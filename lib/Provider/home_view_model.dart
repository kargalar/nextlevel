import 'package:flutter/foundation.dart';
import 'package:next_level/Model/routine_model.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/task_log_provider.dart';
// task_log model used via provider
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Provider/streak_settings_provider.dart';
// TaskProvider already used below via import in this file context
import 'package:next_level/Provider/category_provider.dart';
import 'package:next_level/Core/duration_calculator.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Page/Inbox/Widget/date_filter_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// HomeViewModel acts as the mediator between Home views and TaskProvider.
/// It exposes UI-ready state and commands without requiring BuildContext.
class HomeViewModel extends ChangeNotifier {
  late final VoidCallback _taskListener;
  late final VoidCallback _streakListener;
  late final VoidCallback _taskLogListener;

  Duration? _todayTotalDuration;

  // Filter states (similar to Inbox filters)
  bool _showRoutines = true;
  bool _showTasks = true;
  bool _showTodayTasks = true;
  bool _showRoutineStreakIcon = true;
  DateFilterState _dateFilterState = DateFilterState.all;
  final Set<TaskTypeEnum> _selectedTaskTypes = {
    TaskTypeEnum.CHECKBOX,
    TaskTypeEnum.COUNTER,
    TaskTypeEnum.TIMER,
  };
  final Set<TaskStatusEnum> _selectedStatuses = {};
  bool _showEmptyStatus = true;
  bool _isFilterActive = true;
  bool _isFocusModeEnabled = false;
  bool _focusModeOnlyRoutines = false;

  HomeViewModel() {
    // Re-emit TaskProvider changes to rebuild Home views
    _taskListener = () {
      _updateTodayTotalDuration();
      notifyListeners();
    };
    TaskProvider().addListener(_taskListener);
    // Listen to StreakSettingsProvider changes so target updates when settings change
    _streakListener = () {
      _updateTodayTotalDuration();
      notifyListeners();
    };
    StreakSettingsProvider().addListener(_streakListener);
    // Listen to TaskLogProvider changes for log updates
    _taskLogListener = () {
      _updateTodayTotalDuration();
      notifyListeners();
    };
    TaskLogProvider().addListener(_taskLogListener);

    _updateTodayTotalDuration();
    _loadFilterPreferences();
  }

  @override
  void dispose() {
    TaskProvider().removeListener(_taskListener);
    StreakSettingsProvider().removeListener(_streakListener);
    TaskLogProvider().removeListener(_taskLogListener);
    super.dispose();
  }

  void _updateTodayTotalDuration() {
    _todayTotalDuration =
        DurationCalculator.calculateTotalDurationForDate(selectedDate);
  }

  // State
  DateTime get selectedDate => TaskProvider().selectedDate;

  bool get showCompleted => TaskProvider().showCompleted;

  bool get showArchived => TaskProvider().showArchived;

  String? get selectedCategoryId => TaskProvider().selectedCategoryId;

  List<dynamic> get taskCategories => CategoryProvider().categoryList;

  Map<int, int> get taskCounts {
    final counts = <int, int>{};
    final allTasks = TaskProvider().taskList;

    for (var category in taskCategories) {
      counts[category.id] =
          allTasks.where((task) => task.categoryId == category.id).length;
    }
    return counts;
  }

  // Commands
  void changeSelectedDate(DateTime date) {
    TaskProvider().changeSelectedDate(date);
    _updateTodayTotalDuration();
  }

  Future<void> toggleShowCompleted() async {
    await TaskProvider().changeShowCompleted();
  }

  Future<void> toggleShowArchived() async {
    await TaskProvider().toggleShowArchived();
  }

  void setSelectedCategory(String? categoryId) {
    TaskProvider().setSelectedCategory(categoryId);
    notifyListeners();
  }

  void goToday() => changeSelectedDate(DateTime.now());

  int? _getCurrentFocusPriority(DateTime date, {required bool routinesOnly}) {
    if (!isToday(date)) return null;

    final tasks = TaskProvider().getTasksForDate(date);
    final routineTasks = TaskProvider().getRoutineTasksForDate(date);

    // Select the appropriate pool
    final List<dynamic> pool = routinesOnly ? routineTasks : tasks;

    int minPriority = 4;

    for (var item in pool) {
      if (item is TaskModel && item.status == null) {
        // Bypassed routines don't restrict the focus level of other routines
        if (routinesOnly && item.routineID != null) {
          try {
            final routine = TaskProvider()
                .routineList
                .firstWhere((r) => r.id == item.routineID);
            if (routine.isFocusModeBypassed) continue;
          } catch (_) {}
        }

        if (item.priority < minPriority) {
          minPriority = item.priority;
        }
      }
    }

    return minPriority == 4 ? null : minPriority;
  }

  // Helper method to apply filters to a list of tasks
  List<dynamic> _applyFilters(List<dynamic> tasks) {
    if (!_isFilterActive) return tasks;

    // IMPORTANT: Tasks with active timer should always be shown, regardless of filters
    tasks = tasks.where((task) {
      // If timer is active, always show this task
      if (task is TaskModel && task.isTimerActive == true) {
        return true;
      }

      if (task is TaskModel && _isHiddenByFocusFilter(task, selectedDate)) {
        return false;
      }

      return _passesNonFocusFilters(task);
    }).toList();

    return tasks;
  }

  bool _isHiddenByFocusFilter(TaskModel task, DateTime date) {
    if (!_isFilterActive || !_isFocusModeEnabled || !isToday(date)) {
      return false;
    }

    final bool isRoutineTask = task.routineID != null;

    if (isRoutineTask) {
      bool isFocusModeBypassed = false;
      try {
        final routine = TaskProvider()
            .routineList
            .firstWhere((r) => r.id == task.routineID);
        isFocusModeBypassed = routine.isFocusModeBypassed;
      } catch (_) {}

      if (isFocusModeBypassed) return false;

      final int? routineFocusPriority =
          _getCurrentFocusPriority(date, routinesOnly: true);
      return routineFocusPriority != null &&
          task.priority > routineFocusPriority;
    }

    if (_focusModeOnlyRoutines) return false;

    final int? taskFocusPriority =
        _getCurrentFocusPriority(date, routinesOnly: false);
    return taskFocusPriority != null && task.priority > taskFocusPriority;
  }

  bool _passesNonFocusFilters(dynamic task) {
    if (task is! TaskModel) return true;

    // Apply routine/task filter
    bool isRoutine = task.routineID != null;
    if (!((isRoutine && _showRoutines) || (!isRoutine && _showTasks))) {
      return false;
    }

    // Apply task type filter
    if (!_selectedTaskTypes.contains(task.type)) {
      return false;
    }

    // Apply today tasks filter
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    if (task.taskDate != null) {
      final taskDateOnly = DateTime(
          task.taskDate!.year, task.taskDate!.month, task.taskDate!.day);
      if (!_showTodayTasks && taskDateOnly.isAtSameMomentAs(todayDate)) {
        return false;
      }
    }

    // Apply date filter
    switch (_dateFilterState) {
      case DateFilterState.all:
        break;
      case DateFilterState.withDate:
        if (task.taskDate == null) return false;
        final taskDateOnly = DateTime(
            task.taskDate!.year, task.taskDate!.month, task.taskDate!.day);
        if (taskDateOnly.isAtSameMomentAs(todayDate)) return false;
        break;
      case DateFilterState.withoutDate:
        if (task.taskDate != null) return false;
        break;
    }

    // Apply status filtering
    bool matchesStatus = false;

    if (_selectedStatuses.isNotEmpty &&
        _selectedStatuses.contains(task.status)) {
      matchesStatus = true;
    }

    if (_showEmptyStatus && task.status == null) {
      matchesStatus = true;
    }

    if (_selectedStatuses.isEmpty && !_showEmptyStatus) {
      return false;
    }

    if (!matchesStatus) {
      return false;
    }

    return true;
  }

  int countFocusHiddenTasks(Iterable<TaskModel> tasks, {DateTime? date}) {
    final targetDate = date ?? selectedDate;
    if (!_isFilterActive || !_isFocusModeEnabled || !isToday(targetDate)) {
      return 0;
    }

    return tasks
        .where((task) =>
            task.isTimerActive != true &&
            _passesNonFocusFilters(task) &&
            _isHiddenByFocusFilter(task, targetDate))
        .length;
  }

  // Queries
  List<TaskModel> getOverdueTasks() {
    final overdueTasks = TaskProvider().getOverdueTasks();
    if (selectedCategoryId == null) {
      return _applyFilters(overdueTasks).cast<TaskModel>();
    }
    final filtered = overdueTasks
        .where((task) => task.categoryId == selectedCategoryId)
        .toList();
    return _applyFilters(filtered).cast<TaskModel>();
  }

  List<dynamic> getTasksForDate(DateTime date) {
    final tasks = TaskProvider().getTasksForDate(date);

    // Pinned taskları çıkar - sadece PIN bölümünde gösterilecek
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;

    List<dynamic> filteredTasks = tasks;
    if (isToday) {
      final pinnedTasks = TaskProvider().getPinnedTasksForToday();
      final pinnedTaskIds = pinnedTasks.map((t) => t.id).toSet();
      filteredTasks =
          tasks.where((task) => !pinnedTaskIds.contains(task.id)).toList();
    }

    // Apply filters only for today's view, not for past or future days
    if (isToday) {
      if (selectedCategoryId == null) {
        return _applyFilters(filteredTasks);
      }
      final filtered = filteredTasks
          .where((task) => task.categoryId == selectedCategoryId)
          .toList();
      return _applyFilters(filtered);
    } else {
      // For past and future days, only apply category filter without other filters
      if (selectedCategoryId == null) {
        return filteredTasks;
      }
      return filteredTasks
          .where((task) => task.categoryId == selectedCategoryId)
          .toList();
    }
  }

  List<TaskModel> getPinnedTasksForToday() {
    return TaskProvider().getPinnedTasksForToday();
  }

  List<dynamic> getRoutineTasksForDate(DateTime date) {
    final routines = TaskProvider().getRoutineTasksForDate(date);

    // Determine if this is today
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;

    // Apply filters only for today's view
    if (isToday) {
      if (selectedCategoryId == null) {
        return _applyFilters(routines);
      }
      final filtered = routines
          .where((routine) => routine.categoryId == selectedCategoryId)
          .toList();
      return _applyFilters(filtered);
    } else {
      // For past and future days, only apply category filter
      if (selectedCategoryId == null) {
        return routines;
      }
      return routines
          .where((routine) => routine.categoryId == selectedCategoryId)
          .toList();
    }
  }

  List<dynamic> getGhostRoutineTasksForDate(DateTime date) {
    final ghostRoutines = TaskProvider().getGhostRoutineTasksForDate(date);

    // Determine if this is today
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;

    // Apply filters only for today's view
    if (isToday) {
      if (selectedCategoryId == null) {
        return _applyFilters(ghostRoutines);
      }
      final filtered = ghostRoutines
          .where((routine) => routine.categoryId == selectedCategoryId)
          .toList();
      return _applyFilters(filtered);
    } else {
      // For past and future days, only apply category filter
      if (selectedCategoryId == null) {
        return ghostRoutines;
      }
      return ghostRoutines
          .where((routine) => routine.categoryId == selectedCategoryId)
          .toList();
    }
  }

  List<TaskModel> getArchivedTasks() {
    final archivedTasks = TaskProvider().getArchivedTasks();
    if (selectedCategoryId == null) {
      return archivedTasks;
    }
    return archivedTasks
        .where((task) => task.categoryId == selectedCategoryId)
        .toList();
  }

  // Get tasks with active timer (shown regardless of other filters)
  // But exclude if already shown in pinned, overdue, or routine sections
  List<TaskModel> getActiveTimerTasks() {
    final allTasks = TaskProvider().taskList;
    final activeTimerTasks =
        allTasks.where((task) => task.isTimerActive == true).toList();

    // Exclude pinned tasks - they're shown in pinned section
    final pinnedTasks = TaskProvider().getPinnedTasksForToday();
    final pinnedTaskIds = pinnedTasks.map((t) => t.id).toSet();

    // Exclude overdue tasks - they're shown in overdue section
    final overdueTasks = TaskProvider().getOverdueTasks();
    final overdueTaskIds = overdueTasks.map((t) => t.id).toSet();

    // Exclude routine tasks - they're shown in routine section
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final routineTasks = TaskProvider().getRoutineTasksForDate(today);
    final routineTaskIds = routineTasks.map((t) => t.id).toSet();

    return activeTimerTasks
        .where((task) =>
            !pinnedTaskIds.contains(task.id) &&
            !overdueTaskIds.contains(task.id) &&
            !routineTaskIds.contains(task.id))
        .toList();
  }

  List<RoutineModel> getArchivedRoutines() {
    final archivedRoutines = TaskProvider().getArchivedRoutines();
    if (selectedCategoryId == null) {
      return archivedRoutines;
    }
    return archivedRoutines
        .where((routine) => routine.categoryId == selectedCategoryId)
        .toList();
  }

  // Paging helpers (kept UI-agnostic)
  int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  int pageForDate(
      {required DateTime baseDate,
      required DateTime targetDate,
      int referencePage = 1000}) {
    final int dayDiff = daysBetween(baseDate, targetDate);
    return referencePage + dayDiff;
  }

  DateTime dateForPage(
      {required DateTime baseDate,
      required int pageIndex,
      int referencePage = 1000}) {
    final int diff = pageIndex - referencePage;
    return baseDate.add(Duration(days: diff));
  }

  void onPageChanged(
      {required int pageIndex,
      required DateTime baseDate,
      int referencePage = 1000}) {
    final DateTime newDate = dateForPage(
        baseDate: baseDate, pageIndex: pageIndex, referencePage: referencePage);
    changeSelectedDate(newDate);
  }

  bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Calculate total duration logged for the selected date (today by default)
  /// This sums up durations from task logs and includes running timers' currentDuration
  Duration get todayTotalDuration => _todayTotalDuration ?? Duration.zero;

  String get todayTotalText => todayTotalDuration.compactFormat();

  // / Today's target: sum of today's tasks' target durations (remainingDuration) if available.
  // / Fallback to streak minimum hours (converted to Duration) or 1 hour.
  Duration get todayTargetDuration {
    return DurationCalculator.calculateTodayTargetDuration(selectedDate);
  }

  /// Streak minimum duration (from settings)
  Duration get streakDuration {
    final double hours = StreakSettingsProvider().streakMinimumHours;
    if (hours > 0) return Duration(minutes: (hours * 60).toInt());
    return const Duration(hours: 1);
  }

  /// Progress percent toward today's target (0..1)
  double get todayProgressPercent {
    if (streakDuration.inSeconds == 0) return 0.0;
    final double p = todayTotalDuration.inSeconds / streakDuration.inSeconds;
    if (p.isNaN || p.isInfinite) return 0.0;
    return p;
  }

  /// Breakdown of contributions for selected date: list of map with title and duration
  List<Map<String, dynamic>> todayContributions() {
    return DurationCalculator.getContributionsForDate(selectedDate);
  }

  /// Get streak statuses for last 5 days, today, and tomorrow
  List<Map<String, dynamic>> get streakStatuses {
    final statuses = DurationCalculator.getStreakStatuses();
    LogService.debug('HomeViewModel: Streak statuses: $statuses');
    return statuses;
  }

  // Filter getters
  bool get showRoutines => _showRoutines;
  bool get showTasks => _showTasks;
  bool get showTodayTasks => _showTodayTasks;
  bool get showRoutineStreakIcon => _showRoutineStreakIcon;
  DateFilterState get dateFilterState => _dateFilterState;
  Set<TaskTypeEnum> get selectedTaskTypes => _selectedTaskTypes;
  Set<TaskStatusEnum> get selectedStatuses => _selectedStatuses;
  bool get showEmptyStatus => _showEmptyStatus;
  bool get isFilterActive => _isFilterActive;
  bool get isFocusModeEnabled => _isFocusModeEnabled;
  bool get focusModeOnlyRoutines => _focusModeOnlyRoutines;

  void toggleFocusMode() {
    _isFocusModeEnabled = !_isFocusModeEnabled;
    _saveFilterPreferences();
    notifyListeners();
  }

  void toggleFocusModeOnlyRoutines() {
    _focusModeOnlyRoutines = !_focusModeOnlyRoutines;
    _saveFilterPreferences();
    notifyListeners();
  }

  // Load filter preferences from SharedPreferences
  Future<void> _loadFilterPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    _showTasks = prefs.getBool('home_show_tasks') ?? true;
    _showRoutines = prefs.getBool('home_show_routines') ?? true;
    _showTodayTasks = prefs.getBool('home_show_today_tasks') ?? true;
    _showRoutineStreakIcon =
        prefs.getBool('home_show_routine_streak_icon') ?? true;
    LogService.debug(
        '✅ Home: Loaded filters - Tasks: $_showTasks, Routines: $_showRoutines, TodayTasks: $_showTodayTasks');

    // Load date filter preference
    final dateFilterIndex = prefs.getInt('home_date_filter');
    if (dateFilterIndex != null &&
        dateFilterIndex >= 0 &&
        dateFilterIndex < DateFilterState.values.length) {
      _dateFilterState = DateFilterState.values[dateFilterIndex];
    }
    LogService.debug(
        'Loaded date filter: $_dateFilterState (index: $dateFilterIndex)');

    // Load task type filter preferences
    final hasCheckbox = prefs.getBool('home_show_checkbox') ?? true;
    final hasCounter = prefs.getBool('home_show_counter') ?? true;
    final hasTimer = prefs.getBool('home_show_timer') ?? true;

    _selectedTaskTypes.clear();
    if (hasCheckbox) _selectedTaskTypes.add(TaskTypeEnum.CHECKBOX);
    if (hasCounter) _selectedTaskTypes.add(TaskTypeEnum.COUNTER);
    if (hasTimer) _selectedTaskTypes.add(TaskTypeEnum.TIMER);

    if (_selectedTaskTypes.isEmpty) {
      _selectedTaskTypes.add(TaskTypeEnum.CHECKBOX);
    }

    // Load status filter preferences
    final hasCompleted = prefs.getBool('home_show_completed') ?? true;
    final hasFailed = prefs.getBool('home_show_failed') ?? true;
    final hasCancel = prefs.getBool('home_show_cancel') ?? true;
    final hasOverdue = prefs.getBool('home_show_overdue') ?? true;
    final hasSkipped = prefs.getBool('home_show_skipped') ?? true;

    _selectedStatuses.clear();
    if (hasCompleted) _selectedStatuses.add(TaskStatusEnum.DONE);
    if (hasFailed) _selectedStatuses.add(TaskStatusEnum.FAILED);
    if (hasCancel) _selectedStatuses.add(TaskStatusEnum.CANCEL);
    if (hasOverdue) _selectedStatuses.add(TaskStatusEnum.OVERDUE);
    if (hasSkipped) _selectedStatuses.add(TaskStatusEnum.SKIPPED);

    _showEmptyStatus = prefs.getBool('home_show_empty_status') ?? true;
    _isFilterActive = prefs.getBool('home_is_filter_active') ?? true;
    _isFocusModeEnabled = prefs.getBool('home_is_focus_mode_enabled') ?? false;
    _focusModeOnlyRoutines =
        prefs.getBool('home_focus_mode_only_routines') ?? false;
    LogService.debug(
        '✅ Home: Loaded all filter preferences - Statuses: $_selectedStatuses, ShowEmpty: $_showEmptyStatus, FilterActive: $_isFilterActive, FocusMode: $_isFocusModeEnabled, OnlyRoutines: $_focusModeOnlyRoutines');

    notifyListeners();
  }

  // Save filter preferences to SharedPreferences
  Future<void> _saveFilterPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('home_show_tasks', _showTasks);
    await prefs.setBool('home_show_routines', _showRoutines);
    await prefs.setBool('home_show_today_tasks', _showTodayTasks);
    await prefs.setBool(
        'home_show_routine_streak_icon', _showRoutineStreakIcon);
    LogService.debug('✅ Home: Saved showTodayTasks filter: $_showTodayTasks');

    await prefs.setInt('home_date_filter', _dateFilterState.index);
    LogService.debug(
        'Saved date filter: $_dateFilterState (index: ${_dateFilterState.index})');

    await prefs.setBool('home_show_checkbox',
        _selectedTaskTypes.contains(TaskTypeEnum.CHECKBOX));
    await prefs.setBool(
        'home_show_counter', _selectedTaskTypes.contains(TaskTypeEnum.COUNTER));
    await prefs.setBool(
        'home_show_timer', _selectedTaskTypes.contains(TaskTypeEnum.TIMER));
    LogService.debug('Saved task type filters: $_selectedTaskTypes');

    // Save status filter preferences
    await prefs.setBool(
        'home_show_completed', _selectedStatuses.contains(TaskStatusEnum.DONE));
    await prefs.setBool(
        'home_show_failed', _selectedStatuses.contains(TaskStatusEnum.FAILED));
    await prefs.setBool(
        'home_show_cancel', _selectedStatuses.contains(TaskStatusEnum.CANCEL));
    await prefs.setBool('home_show_overdue',
        _selectedStatuses.contains(TaskStatusEnum.OVERDUE));
    await prefs.setBool('home_show_skipped',
        _selectedStatuses.contains(TaskStatusEnum.SKIPPED));
    LogService.debug('✅ Home: Saved status filters: $_selectedStatuses');

    await prefs.setBool('home_show_empty_status', _showEmptyStatus);
    await prefs.setBool('home_is_filter_active', _isFilterActive);
    await prefs.setBool('home_is_focus_mode_enabled', _isFocusModeEnabled);
    await prefs.setBool(
        'home_focus_mode_only_routines', _focusModeOnlyRoutines);
  }

  Future<void> toggleFilterActive() async {
    _isFilterActive = !_isFilterActive;
    LogService.debug(
        '🔄 Home: Filter active state toggled to $_isFilterActive');
    await _saveFilterPreferences();
    notifyListeners();
  }

  // Update filters
  Future<void> updateFilters(
    bool showRoutines,
    bool showTasks,
    bool showTodayTasks,
    bool showRoutineStreakIcon,
    DateFilterState dateFilterState,
    Set<TaskTypeEnum> selectedTaskTypes,
    Set<TaskStatusEnum> selectedStatuses,
    bool showEmptyStatus,
    bool isFocusModeEnabled,
  ) async {
    _showRoutines = showRoutines;
    _showTasks = showTasks;
    _showTodayTasks = showTodayTasks;
    _showRoutineStreakIcon = showRoutineStreakIcon;
    _dateFilterState = dateFilterState;
    _selectedTaskTypes.clear();
    _selectedTaskTypes.addAll(selectedTaskTypes);
    _selectedStatuses.clear();
    _selectedStatuses.addAll(selectedStatuses);
    _showEmptyStatus = showEmptyStatus;
    _isFocusModeEnabled = isFocusModeEnabled;

    await _saveFilterPreferences();
    notifyListeners();
    LogService.debug('🔄 Home: Filters updated');
  }
}
