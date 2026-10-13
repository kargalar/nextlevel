import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Core/Handlers/task_action_handler.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Page/Home/Add Task/add_task_page.dart';
import 'package:next_level/Page/Home/Widget/task_item.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:get/route_manager.dart';
import 'package:provider/provider.dart';

class InboxTasksPage extends StatelessWidget {
  final CategoryModel? category; // Optional category for filtering

  const InboxTasksPage({
    super.key,
    this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: category != null
            // Show category title and color if a category is provided
            ? Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: category!.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category!.title,
                  ),
                ],
              )
            // Show "All Tasks" title if no category is provided
            : Text(
                LocaleKeys.AllTasks.tr(),
              ),
      ),
      body: _TaskList(category: category),
    );
  }
}

class _TaskList extends StatefulWidget {
  final CategoryModel? category;

  const _TaskList({this.category});

  @override
  State<_TaskList> createState() => _TaskListState();
}

class _TaskListState extends State<_TaskList> {
  // Key to identify the dragged task
  TaskModel? _draggedTask;
  // Animation controller for the dragged task
  bool _isDragging = false;
  // Timer for long press
  Timer? _longPressTimer;
  // Position where long press started
  Offset? _longPressPosition;

  @override
  void dispose() {
    // Cancel timer if active when widget is disposed
    if (_longPressTimer != null) {
      _longPressTimer!.cancel();
      _longPressTimer = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();

    // Get tasks based on whether a category is provided
    final List<TaskModel> tasks = widget.category != null ? taskProvider.getTasksByCategoryId(widget.category!.id) : taskProvider.getAllTasks();

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              widget.category != null ? LocaleKeys.NoTasksInCategory.tr() : LocaleKeys.NoTasksYet.tr(),
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Group tasks by date and status
    final Map<DateTime, List<TaskModel>> groupedTasks = {};
    final List<TaskModel> overdueTasks = [];
    final List<TaskModel> tasksWithoutDate = [];
    final DateTime today = DateTime.now();
    final DateTime todayDate = DateTime(today.year, today.month, today.day);

    for (var task in tasks) {
      if (task.status == TaskStatusEnum.OVERDUE) {
        // Overdue tasks go to a special group
        overdueTasks.add(task);
      } else if (task.taskDate == null) {
        // Tasks without date
        tasksWithoutDate.add(task);
      } else {
        final date = DateTime(task.taskDate!.year, task.taskDate!.month, task.taskDate!.day);
        if (!groupedTasks.containsKey(date)) {
          groupedTasks[date] = [];
        }
        groupedTasks[date]!.add(task);
      }
    }

    // Create ordered list of dates with special keys
    final List<DateTime> sortedDates = [];

    // 1. Add overdue tasks first (if any)
    if (overdueTasks.isNotEmpty) {
      final overdueDate = DateTime(1969, 1, 1); // Special date for overdue tasks
      groupedTasks[overdueDate] = overdueTasks;
      sortedDates.add(overdueDate);
    }

    // 2. Add today's tasks
    if (groupedTasks.containsKey(todayDate)) {
      sortedDates.add(todayDate);
    }

    // 3. Add tasks without dates
    if (tasksWithoutDate.isNotEmpty) {
      final inboxDate = DateTime(1970, 1, 1); // Special date for inbox/no date
      groupedTasks[inboxDate] = tasksWithoutDate;
      sortedDates.add(inboxDate);
    }

    // 4. Add future tasks (sorted ascending)
    final futureDates = groupedTasks.keys.where((date) => date.isAfter(todayDate) && date.year > 1970).toList()..sort();
    sortedDates.addAll(futureDates);

    // 5. Add past tasks (sorted descending - most recent first)
    final pastDates = groupedTasks.keys.where((date) => date.isBefore(todayDate) && date.year > 1970).toList()..sort((a, b) => b.compareTo(a)); // Descending order
    sortedDates.addAll(pastDates);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final tasksForDate = groupedTasks[date]!;

        // Sort tasks by priority and time
        taskProvider.sortTasksByPriorityAndTime(tasksForDate);

        return DragTarget<TaskModel>(
          onWillAcceptWithDetails: (details) {
            // Accept the drag if it's a different date
            if (details.data.taskDate == null) {
              // If task has no date, accept the drag to assign a date
              return true;
            }

            final taskDate = DateTime(details.data.taskDate!.year, details.data.taskDate!.month, details.data.taskDate!.day);
            return taskDate != date;
          },
          onAcceptWithDetails: (details) {
            // Update the task's date when dropped
            taskProvider.changeTaskDateWithoutDialog(
              taskModel: details.data,
              newDate: date,
            );
            setState(() {
              _isDragging = false;
              _draggedTask = null;
            });
          },
          builder: (context, candidateData, rejectedData) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date header
                _buildDateHeader(date),
                const SizedBox(height: 8),
                // Tasks for this date
                ...tasksForDate.map((task) {
                  // Create a draggable task item
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: GestureDetector(
                      onLongPressStart: (details) {
                        // Start a timer when long press begins
                        _longPressPosition = details.globalPosition;
                        _longPressTimer = Timer(const Duration(milliseconds: 300), () {
                          // After 300ms, start dragging
                          setState(() {
                            _isDragging = true;
                            _draggedTask = task;
                          });
                        });
                      },
                      onLongPressMoveUpdate: (details) {
                        // If user moves finger while long pressing, check if it's a drag
                        if (_longPressPosition != null) {
                          final distance = (_longPressPosition! - details.globalPosition).distance;
                          // If moved more than 10 logical pixels, consider it a drag
                          if (distance > 10 && _longPressTimer != null) {
                            _longPressTimer!.cancel();
                            _longPressTimer = null;
                          }
                        }
                      },
                      onLongPressEnd: (details) {
                        // If timer is still active, it means user just did a long press without dragging
                        if (_longPressTimer != null) {
                          _longPressTimer!.cancel();
                          _longPressTimer = null;
                          // Navigate to task edit page
                          TaskActionHandler.handleTaskLongPress(task);
                        }
                        setState(() {
                          _isDragging = false;
                          _draggedTask = null;
                        });
                      },
                      child: Draggable<TaskModel>(
                        data: task,
                        onDragStarted: () {
                          setState(() {
                            _isDragging = true;
                            _draggedTask = task;
                          });
                        },
                        onDragEnd: (details) {
                          setState(() {
                            _isDragging = false;
                            _draggedTask = null;
                          });
                        },
                        onDraggableCanceled: (velocity, offset) {
                          setState(() {
                            _isDragging = false;
                            _draggedTask = null;
                          });
                        },
                        feedback: Material(
                          elevation: 4.0,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width - 60,
                            child: TaskItem(taskModel: task),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: TaskItem(taskModel: task),
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: _draggedTask?.id == task.id && _isDragging ? Border.all(color: AppColors.main, width: 2) : null,
                          ),
                          child: TaskItem(taskModel: task),
                        ),
                      ),
                    ),
                  );
                }),
                // Add space between date groups
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));

    String dateText;
    Color? backgroundColor;
    Color? textColor;

    if (date.year == 1969 && date.month == 1 && date.day == 1) {
      dateText = "Overdue"; // Special case for overdue tasks
      backgroundColor = AppColors.red.withValues(alpha: 0.1);
      textColor = AppColors.red;
    } else if (date.year == 1970 && date.month == 1 && date.day == 1) {
      dateText = "Inbox"; // Special case for tasks without dates
    } else if (date.isAtSameMomentAs(today)) {
      dateText = LocaleKeys.Today.tr();
    } else if (date.isAtSameMomentAs(tomorrow)) {
      dateText = LocaleKeys.Tomorrow.tr();
    } else if (date.isAtSameMomentAs(yesterday)) {
      dateText = LocaleKeys.Yesterday.tr();
    } else {
      dateText = DateFormat.yMMMd().format(date);
    }

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: backgroundColor ?? AppColors.panelBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              dateText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor ?? AppColors.text.withValues(alpha: 0.8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Add button to add a task for this date
        InkWell(
          onTap: () => _addTaskForDate(date),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.panelBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.add,
              size: 20,
              color: AppColors.main,
            ),
          ),
        ),
      ],
    );
  }

  // Method to open the add task page with the selected date
  Future<void> _addTaskForDate(DateTime date) async {
    // Get the AddTaskProvider
    final addTaskProvider = Provider.of<AddTaskProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    // Reset the provider to default values
    addTaskProvider.taskNameController.clear();
    addTaskProvider.descriptionController.clear();
    addTaskProvider.locationController.clear();
    addTaskProvider.selectedTime = null;
    addTaskProvider.selectedDate = date; // Set the selected date
    addTaskProvider.isNotificationOn = false;
    addTaskProvider.isAlarmOn = false;
    addTaskProvider.targetCount = 1;
    addTaskProvider.taskDuration = const Duration(hours: 0, minutes: 0);
    addTaskProvider.selectedTaskType = TaskTypeEnum.CHECKBOX;
    addTaskProvider.selectedDays.clear();
    addTaskProvider.selectedTraits.clear();
    addTaskProvider.priority = 3;
    addTaskProvider.categoryId = widget.category?.id; // Set the category if available
    addTaskProvider.clearSubtasks();

    // Navigate to the add task page
    await NavigatorService().goTo(
      const AddTaskPage(),
      transition: Transition.downToUp,
    );

    // Reset the selectedDate to today after returning from the add task page
    addTaskProvider.selectedDate = taskProvider.selectedDate;
  }
}
