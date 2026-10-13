import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Page/Home/Widget/create_category_bottom_sheet.dart';
import 'package:next_level/Page/Inbox/archived_routines_page.dart';
import 'package:next_level/Page/Inbox/Widget/inbox_search_bar.dart';
import 'package:next_level/Page/Inbox/Widget/inbox_filter_dialog.dart';
import 'package:next_level/Page/Inbox/Widget/inbox_task_list.dart';
import 'package:next_level/Page/Inbox/Widget/date_filter_state.dart';
import 'package:next_level/Provider/category_provider.dart';
import 'package:next_level/Provider/navbar_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Widgets/Common/category_filter_widget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:next_level/Service/logging_service.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  CategoryModel? _selectedCategory;
  String? _selectedCategoryId;
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();

  // Filter states
  bool _showRoutines = true;
  bool _showTasks = true;
  bool _showTodayTasks = true; // Bugünkü task'ları göster
  DateFilterState _dateFilterState =
      DateFilterState.all; // Varsayılan olarak tüm task'ları göster
  final Set<TaskTypeEnum> _selectedTaskTypes = {
    TaskTypeEnum.CHECKBOX,
    TaskTypeEnum.COUNTER,
    TaskTypeEnum.TIMER,
  };
  final Set<TaskStatusEnum> _selectedStatuses = {};
  bool _showEmptyStatus = true; // Show tasks with null status by default

  @override
  void initState() {
    super.initState();
    _loadFilterPreferences();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Load saved filter preferences from SharedPreferences
  Future<void> _loadFilterPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      // Load task/routine filter preferences
      _showTasks = prefs.getBool('categories_show_tasks') ?? true;
      _showRoutines = prefs.getBool('categories_show_routines') ?? true;
      _showTodayTasks = prefs.getBool('categories_show_today_tasks') ?? true;
      LogService.debug(
          '✅ Inbox: Loaded showTodayTasks filter: $_showTodayTasks');

      // Load date filter preference
      final dateFilterIndex = prefs.getInt('categories_date_filter');
      if (dateFilterIndex != null &&
          dateFilterIndex >= 0 &&
          dateFilterIndex < DateFilterState.values.length) {
        _dateFilterState = DateFilterState.values[dateFilterIndex];
      } else {
        _dateFilterState =
            DateFilterState.all; // Varsayılan olarak tüm task'ları göster
      }
      LogService.debug(
          'Loaded date filter: $_dateFilterState (index: $dateFilterIndex)');

      // Load task type filter preferences
      final hasCheckbox = prefs.getBool('categories_show_checkbox') ?? true;
      final hasCounter = prefs.getBool('categories_show_counter') ?? true;
      final hasTimer = prefs.getBool('categories_show_timer') ?? true;

      // Clear and rebuild the set based on saved preferences
      _selectedTaskTypes.clear();
      if (hasCheckbox) _selectedTaskTypes.add(TaskTypeEnum.CHECKBOX);
      if (hasCounter) _selectedTaskTypes.add(TaskTypeEnum.COUNTER);
      if (hasTimer) _selectedTaskTypes.add(TaskTypeEnum.TIMER);

      // Ensure at least one task type is selected
      if (_selectedTaskTypes.isEmpty) {
        _selectedTaskTypes.add(TaskTypeEnum.CHECKBOX);
      }

      // Load status filter preferences
      final hasCompleted = prefs.getBool('categories_show_completed') ?? true;
      final hasFailed = prefs.getBool('categories_show_failed') ?? true;
      final hasCancel = prefs.getBool('categories_show_cancel') ?? true;
      final hasOverdue = prefs.getBool('categories_show_overdue') ?? true;
      final hasSkipped = prefs.getBool('categories_show_skipped') ?? true;
      _showEmptyStatus = prefs.getBool('categories_show_empty_status') ?? true;

      // Clear and rebuild the status set based on saved preferences
      _selectedStatuses.clear();
      if (hasCompleted) _selectedStatuses.add(TaskStatusEnum.DONE);
      if (hasFailed) _selectedStatuses.add(TaskStatusEnum.FAILED);
      if (hasCancel) _selectedStatuses.add(TaskStatusEnum.CANCEL);
      if (hasOverdue) _selectedStatuses.add(TaskStatusEnum.OVERDUE);
      if (hasSkipped) _selectedStatuses.add(TaskStatusEnum.SKIPPED);

      // Load selected category
      _selectedCategoryId = prefs.getString('categories_selected_category_id');
    });

    // Load the selected category if there's a saved ID
    if (_selectedCategoryId != null) {
      // Use a mounted check to avoid using BuildContext across async gaps
      if (!mounted) return;

      final categoryProvider =
          Provider.of<CategoryProvider>(context, listen: false);
      final categories = categoryProvider.getActiveCategories();
      for (var category in categories) {
        if (category.id == _selectedCategoryId) {
          setState(() {
            _selectedCategory = category;
          });
          break;
        }
      }
    }
  }

  // Save filter preferences to SharedPreferences
  Future<void> _saveFilterPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Save task/routine filter preferences
    await prefs.setBool('categories_show_tasks', _showTasks);
    await prefs.setBool('categories_show_routines', _showRoutines);
    await prefs.setBool('categories_show_today_tasks', _showTodayTasks);
    LogService.debug('✅ Inbox: Saved showTodayTasks filter: $_showTodayTasks');

    // Save date filter preference
    await prefs.setInt('categories_date_filter', _dateFilterState.index);
    LogService.debug(
        'Saved date filter: $_dateFilterState (index: ${_dateFilterState.index})');

    // Save task type filter preferences
    await prefs.setBool('categories_show_checkbox',
        _selectedTaskTypes.contains(TaskTypeEnum.CHECKBOX));
    await prefs.setBool('categories_show_counter',
        _selectedTaskTypes.contains(TaskTypeEnum.COUNTER));
    await prefs.setBool('categories_show_timer',
        _selectedTaskTypes.contains(TaskTypeEnum.TIMER));

    // Save status filter preferences
    await prefs.setBool('categories_show_completed',
        _selectedStatuses.contains(TaskStatusEnum.DONE));
    await prefs.setBool('categories_show_failed',
        _selectedStatuses.contains(TaskStatusEnum.FAILED));
    await prefs.setBool('categories_show_cancel',
        _selectedStatuses.contains(TaskStatusEnum.CANCEL));
    await prefs.setBool('categories_show_overdue',
        _selectedStatuses.contains(TaskStatusEnum.OVERDUE));
    await prefs.setBool('categories_show_skipped',
        _selectedStatuses.contains(TaskStatusEnum.SKIPPED));
    await prefs.setBool('categories_show_empty_status', _showEmptyStatus);

    // Save selected category
    if (_selectedCategory != null) {
      await prefs.setString(
          'categories_selected_category_id', _selectedCategory!.id);
    } else {
      await prefs.remove('categories_selected_category_id');
    }
  }

  // Calculate item counts for categories
  Map<dynamic, int> _calculateItemCounts(
      List<CategoryModel> categories, TaskProvider taskProvider) {
    final Map<dynamic, int> itemCounts = {};

    for (final category in categories) {
      final tasks = taskProvider.getTasksByCategoryId(category.id);
      final filteredTasks = _applyFiltersForCount(tasks);
      itemCounts[category.id] = filteredTasks.length;
    }

    // Calculate total count for "All" option
    final allTasks = taskProvider.getAllTasks();
    final filteredAllTasks = _applyFiltersForCount(allTasks);
    itemCounts[null] = filteredAllTasks.length;

    return itemCounts;
  }

  // Apply filters for counting items (same logic as InboxCategoriesSection)
  List<dynamic> _applyFiltersForCount(List<dynamic> tasks) {
    // Apply routine/task filter
    tasks = tasks.where((task) {
      bool isRoutine = task.routineID != null;
      return (isRoutine && _showRoutines) || (!isRoutine && _showTasks);
    }).toList();

    // Apply task type filter
    tasks =
        tasks.where((task) => _selectedTaskTypes.contains(task.type)).toList();

    // Apply date filter
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    tasks = tasks.where((task) {
      // Filter out today's tasks if showTodayTasks is false
      if (task.taskDate != null) {
        final taskDateOnly = DateTime(
            task.taskDate!.year, task.taskDate!.month, task.taskDate!.day);
        if (!_showTodayTasks && taskDateOnly.isAtSameMomentAs(todayDate)) {
          return false;
        }
      }

      switch (_dateFilterState) {
        case DateFilterState.all:
          return true;
        case DateFilterState.withDate:
          if (task.taskDate == null) return false;
          final taskDateOnly = DateTime(
              task.taskDate!.year, task.taskDate!.month, task.taskDate!.day);
          return !taskDateOnly.isAtSameMomentAs(todayDate);
        case DateFilterState.withoutDate:
          return task.taskDate == null;
      }
    }).toList();

    // Apply status filtering
    tasks = tasks.where((task) {
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

      return matchesStatus;
    }).toList();

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      tasks = tasks.where((task) {
        final lowerQuery = _searchController.text.toLowerCase();

        bool matchesTask = task.title.toLowerCase().contains(lowerQuery) ||
            (task.description?.toLowerCase().contains(lowerQuery) ?? false);

        bool matchesSubtasks = false;
        if (task.subtasks != null && task.subtasks!.isNotEmpty) {
          matchesSubtasks = task.subtasks!.any((subtask) {
            return subtask.title.toLowerCase().contains(lowerQuery) ||
                (subtask.description?.toLowerCase().contains(lowerQuery) ??
                    false);
          });
        }

        return matchesTask || matchesSubtasks;
      }).toList();
    }

    return tasks;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) {
        context.read<NavbarProvider>().goToMainPage();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text(
            LocaleKeys.Tasks.tr(),
          ),
          actions: [
            // Arama icon
            IconButton(
              icon: Icon(
                _isSearchActive ? Icons.search_off : Icons.search,
                size: 20,
              ),
              tooltip: LocaleKeys.Search.tr(),
              onPressed: () {
                setState(() {
                  _isSearchActive = !_isSearchActive;
                  if (!_isSearchActive) {
                    _searchController.clear();
                  }
                });
                LogService.debug('🔍 Inbox search toggled: $_isSearchActive');
              },
            ),
            // Arşiv icon - Arşivlenmiş rutinler sayfasına git
            IconButton(
              icon: const Icon(
                Icons.archive,
                size: 20,
              ),
              tooltip: LocaleKeys.ArchivedRoutines.tr(),
              onPressed: () {
                LogService.debug('📦 Navigating to archived routines page');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ArchivedRoutinesPage(),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(
                Icons.filter_list_rounded,
                size: 20,
                color: AppColors.text,
              ),
              tooltip: LocaleKeys.Filters.tr(),
              onPressed: _showFilterDialog,
            ),
          ],
        ),
        body: Column(
          children: [
            if (_isSearchActive)
              InboxSearchBar(
                controller: _searchController,
                onChanged: () => setState(() {}),
              ),
            // Kategori filtresi - CategoryFilterWidget kullanımı
            Consumer2<CategoryProvider, TaskProvider>(
              builder: (context, categoryProvider, taskProvider, child) {
                final categories = categoryProvider.getActiveCategories();
                // Sadece task kategorilerini göster
                final taskCategories = categories
                    .where((cat) => cat.categoryType == CategoryType.task)
                    .toList();
                final itemCounts =
                    _calculateItemCounts(taskCategories, taskProvider);

                return CategoryFilterWidget(
                  categories: taskCategories,
                  selectedCategoryId: _selectedCategory?.id,
                  onCategorySelected: (categoryId) {
                    setState(() {
                      if (categoryId == null) {
                        _selectedCategory = null;
                      } else {
                        _selectedCategory = taskCategories
                            .firstWhere((cat) => cat.id == categoryId);
                      }
                    });
                    _saveFilterPreferences();
                    LogService.debug(
                        '📂 Inbox: Category selected: ${_selectedCategory?.name ?? "All"}');
                  },
                  itemCounts: itemCounts,
                  onCategoryLongPress: (context, category) async {
                    LogService.debug(
                        '📝 Inbox: Long press on category: ${category.name}');
                    final result = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      barrierColor: Colors.transparent,
                      builder: (context) =>
                          CreateCategoryBottomSheet(categoryModel: category),
                    );

                    // Kategori silindiyse
                    if (result == true && context.mounted) {
                      LogService.debug(
                          '🔄 Inbox: Category deleted, reloading CategoryProvider');
                      await context.read<CategoryProvider>().initialize();
                      LogService.debug('✅ Inbox: CategoryProvider reloaded');

                      setState(() {
                        // Eğer silinen kategori seçiliyse, seçimi kaldır
                        if (_selectedCategory != null) {
                          final updatedCategories = context
                              .read<CategoryProvider>()
                              .getActiveCategories();
                          final categoryExists = updatedCategories
                              .any((cat) => cat.id == _selectedCategory!.id);
                          if (!categoryExists) {
                            _selectedCategory = null;
                            LogService.debug(
                                '❌ Inbox: Selected category was deleted, clearing selection');
                          }
                        }
                      });
                    }
                  },
                  categoryType: CategoryType.task,
                  showEmptyCategories: true,
                  onCategoryAdded: () {
                    LogService.debug('✨ Inbox: Category added');
                    setState(() {});
                  },
                );
              },
            ),

            Expanded(
              child: InboxTaskList(
                selectedCategory: _selectedCategory,
                searchQuery: _searchController.text,
                showRoutines: _showRoutines,
                showTasks: _showTasks,
                showTodayTasks: _showTodayTasks,
                dateFilterState: _dateFilterState,
                selectedTaskTypes: _selectedTaskTypes,
                selectedStatuses: _selectedStatuses,
                showEmptyStatus: _showEmptyStatus,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => InboxFilterDialog(
        showRoutines: _showRoutines,
        showTasks: _showTasks,
        showTodayTasks: _showTodayTasks,
        dateFilterState: _dateFilterState,
        selectedTaskTypes: _selectedTaskTypes,
        selectedStatuses: _selectedStatuses,
        showEmptyStatus: _showEmptyStatus,
        onFiltersChanged: (showRoutines, showTasks, showTodayTasks,
            dateFilterState, taskTypes, statuses, showEmpty) {
          setState(() {
            _showRoutines = showRoutines;
            _showTasks = showTasks;
            _showTodayTasks = showTodayTasks;
            _dateFilterState = dateFilterState;
            _selectedTaskTypes.clear();
            _selectedTaskTypes.addAll(taskTypes);
            _selectedStatuses.clear();
            _selectedStatuses.addAll(statuses);
            _showEmptyStatus = showEmpty;
          });
          _saveFilterPreferences();
        },
      ),
    );
  }
}
