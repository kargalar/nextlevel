import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LevelProgressSnapshot {
  const LevelProgressSnapshot({
    required this.totalDuration,
    required this.level,
    required this.hoursInCurrentLevel,
    required this.progress,
  });

  final Duration totalDuration;
  final int level;
  final int hoursInCurrentLevel;
  final double progress;
}

/// Single source of truth for profile and level-up calculations.
class LevelProgressService {
  static const int hoursPerLevel = 10;
  static const String _lastKnownLevelKey = 'last_known_profile_level';

  static final LevelProgressService _instance =
      LevelProgressService._internal();

  factory LevelProgressService() => _instance;

  LevelProgressService._internal();

  LevelProgressSnapshot calculate([List<TaskModel>? tasks]) {
    final source = tasks ?? TaskProvider().taskList;
    final totalDuration = source.fold<Duration>(Duration.zero, (total, task) {
      switch (task.type) {
        case TaskTypeEnum.CHECKBOX:
          if (task.status != TaskStatusEnum.DONE) return total;
          return total + (task.remainingDuration ?? Duration.zero);
        case TaskTypeEnum.COUNTER:
          return total +
              (task.remainingDuration ?? Duration.zero) *
                  (task.currentCount ?? 0);
        case TaskTypeEnum.TIMER:
          return total + (task.currentDuration ?? Duration.zero);
        case TaskTypeEnum.FREEZE:
          return total;
      }
    });

    final totalHours = totalDuration.inHours;
    final level = totalHours ~/ hoursPerLevel;
    final hoursInCurrentLevel = totalHours % hoursPerLevel;

    return LevelProgressSnapshot(
      totalDuration: totalDuration,
      level: level,
      hoursInCurrentLevel: hoursInCurrentLevel,
      progress: hoursInCurrentLevel / hoursPerLevel,
    );
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_lastKnownLevelKey)) {
      await prefs.setInt(_lastKnownLevelKey, calculate().level);
    }
  }

  Future<int?> consumeLevelChange() async {
    final prefs = await SharedPreferences.getInstance();
    final currentLevel = calculate().level;
    final previousLevel = prefs.getInt(_lastKnownLevelKey) ?? currentLevel;

    if (currentLevel != previousLevel) {
      await prefs.setInt(_lastKnownLevelKey, currentLevel);
    }

    return currentLevel > previousLevel ? currentLevel : null;
  }
}
