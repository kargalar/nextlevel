import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Task%20Detail%20Page/routine_detail_page.dart';
import 'package:next_level/Page/Schedule/task_calendar_page.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/routine_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:get/route_manager.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.Schedule.tr()),
        leading: const BackButton(),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.blue,
          indicatorWeight: 3,
          labelColor: AppColors.blue,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(
              icon: Icon(Icons.repeat),
              text: LocaleKeys.WeeklyRoutines.tr(),
            ),
            Tab(
              icon: Icon(Icons.calendar_month),
              text: LocaleKeys.TaskCalendar.tr(),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          WeeklyRoutineView(),
          TaskCalendarPage(),
        ],
      ),
    );
  }
}

class WeeklyRoutineView extends StatelessWidget {
  const WeeklyRoutineView({super.key});

  String _getDurationText(BuildContext context, dynamic item) {
    if (item.remainingDuration == null) {
      return LocaleKeys.UnspecifiedDuration.tr();
    }

    if (item.type == TaskTypeEnum.COUNTER) {
      final totalMicroseconds =
          (item.remainingDuration as Duration).inMicroseconds *
              (item.targetCount as int);
      final totalDuration = Duration(microseconds: totalMicroseconds.toInt());
      return totalDuration.textShort2hour();
    }

    return (item.remainingDuration as Duration).textShort2hour();
  }

  Duration _calculateTotalDuration(List<dynamic> routines) {
    int totalMicroseconds = 0;

    for (var routine in routines) {
      if (routine.remainingDuration != null) {
        if (routine.type == TaskTypeEnum.COUNTER) {
          totalMicroseconds +=
              (routine.remainingDuration as Duration).inMicroseconds *
                  (routine.targetCount as int);
        } else {
          totalMicroseconds +=
              (routine.remainingDuration as Duration).inMicroseconds;
        }
      }
    }

    return Duration(microseconds: totalMicroseconds);
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final routines = taskProvider.routineList;
    final locale = Localizations.localeOf(context).languageCode;
    final today = DateTime.now().weekday;
    final startOfWeek = DateTime.now().subtract(Duration(days: today - 1));
    final weekDays = List.generate(
      7,
      (index) => DateFormat.EEEE(locale).format(
        startOfWeek.add(Duration(days: index)),
      ),
    );

    if (routines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.repeat, size: 48, color: AppColors.dirtyWhite),
            const SizedBox(height: 16),
            Text(
              LocaleKeys.NoRoutinesYet.tr(),
              style: TextStyle(fontSize: 16, color: AppColors.text),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: weekDays.length,
      itemBuilder: (context, index) {
        final startOfWeek = DateTime.now().subtract(Duration(days: today - 1));
        final targetDate = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day + index,
        );
        final dayRoutines = routines
            .where((routine) => routine.isActiveForThisDate(targetDate))
            .toList();
        final totalDuration = _calculateTotalDuration(dayRoutines);
        final isToday = today - 1 == index; // today is 1-7, index is 0-6

        if (dayRoutines.isEmpty) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 0,
            color: isToday
                ? AppColors.panelBackground2
                : AppColors.panelBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isToday ? AppColors.blue : AppColors.dirtyWhite,
                width: isToday ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:
                          isToday ? AppColors.blue : AppColors.panelBackground3,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        weekDays[index].substring(0, 2),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isToday ? AppColors.white : AppColors.text,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    weekDays[index],
                    style: TextStyle(
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      fontSize: 16,
                      color: isToday ? AppColors.blue : AppColors.text,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    LocaleKeys.NoRoutines.tr(),
                    style: TextStyle(
                      color: AppColors.dirtyWhite,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 0,
          color:
              isToday ? AppColors.panelBackground2 : AppColors.panelBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isToday ? AppColors.blue : AppColors.dirtyWhite,
              width: isToday ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isToday
                            ? AppColors.blue
                            : AppColors.panelBackground3,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          weekDays[index].substring(0, 2),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isToday ? AppColors.white : AppColors.text,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weekDays[index],
                          style: TextStyle(
                            fontWeight:
                                isToday ? FontWeight.bold : FontWeight.normal,
                            fontSize: 16,
                            color: isToday ? AppColors.blue : AppColors.text,
                          ),
                        ),
                        Text(
                          '${LocaleKeys.Total.tr()}: ${totalDuration.textShort2hour()}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.dirtyWhite,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (isToday)
                      IconButton(
                        tooltip: LocaleKeys.SkipRoutine.tr(),
                        icon: const Icon(Icons.skip_next,
                            color: AppColors.orange),
                        onPressed: () => context
                            .read<TaskProvider>()
                            .skipRoutinesForDate(targetDate),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${dayRoutines.length} ${LocaleKeys.Routines.tr()}',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              const Divider(
                  height: 1, thickness: 1, color: AppColors.dirtyWhite),

              // Routines list
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dayRoutines.length,
                itemBuilder: (context, routineIndex) {
                  final routine = dayRoutines[routineIndex];
                  return InkWell(
                    onTap: () async {
                      final routineTask = taskProvider.taskList.firstWhere(
                        (task) => task.routineID == routine.id,
                        orElse: () => TaskModel(
                          title: routine.title,
                          type: routine.type,
                          taskDate: DateTime.now(),
                          isNotificationOn: routine.isNotificationOn,
                          isAlarmOn: routine.isAlarmOn,
                          routineID: routine.id,
                        ),
                      );

                      await NavigatorService().goTo(
                        RoutineDetailPage(
                          taskModel: routineTask,
                        ),
                        transition: Transition.rightToLeft,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          _buildTypeIcon(routine.type),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  routine.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.timer_outlined,
                                      size: 12,
                                      color: AppColors.dirtyWhite,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getDurationText(context, routine),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.dirtyWhite,
                                      ),
                                    ),
                                    if (routine.time != null) ...[
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.access_time,
                                        size: 12,
                                        color: AppColors.dirtyWhite,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${routine.time!.hour}:${routine.time!.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.dirtyWhite,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.dirtyWhite,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypeIcon(TaskTypeEnum type) {
    switch (type) {
      case TaskTypeEnum.CHECKBOX:
        return Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: AppColors.green,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_box_outlined,
            color: AppColors.white,
            size: 16,
          ),
        );
      case TaskTypeEnum.COUNTER:
        return Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: AppColors.orange,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.add,
            color: AppColors.white,
            size: 16,
          ),
        );
      case TaskTypeEnum.TIMER:
        return Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: AppColors.blue,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.timer,
            color: AppColors.white,
            size: 16,
          ),
        );
      case TaskTypeEnum.FREEZE:
        return Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Colors.purple,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.ac_unit,
            color: AppColors.white,
            size: 16,
          ),
        );
      // Default case (tüm enum değerleri kapsandığı için gerekli değil)
    }
  }
}
