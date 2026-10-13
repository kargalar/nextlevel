import 'package:hive_flutter/hive_flutter.dart';

part 'daily_streak_model.g.dart';

@HiveType(typeId: 17) // Ensure this ID is unique
class DailyStreakModel extends HiveObject {
  @HiveField(0)
  DateTime date; // The date of the streak record

  @HiveField(1)
  Duration targetDuration; // The target duration set for that day

  @HiveField(2)
  Duration totalDuration; // The actual duration logged for that day

  @HiveField(3)
  bool isMet; // Whether the streak goal was met

  @HiveField(4)
  bool isVacation; // Whether it was a vacation day

  @HiveField(5, defaultValue: false)
  bool isFreeze; // Whether a freeze (pass day) was used

  DailyStreakModel({
    required this.date,
    required this.targetDuration,
    required this.totalDuration,
    required this.isMet,
    this.isVacation = false,
    this.isFreeze = false,
  });

  factory DailyStreakModel.fromJson(Map<String, dynamic> json) {
    Duration? stringToDuration(String? timeString) {
      if (timeString == null) return null;
      List<String> split = timeString.split(':');
      return Duration(hours: int.parse(split[0]), minutes: int.parse(split[1]), seconds: int.parse(split[2]));
    }

    return DailyStreakModel(
      date: DateTime.parse(json['date']),
      targetDuration: stringToDuration(json['target_duration']) ?? Duration.zero,
      totalDuration: stringToDuration(json['total_duration']) ?? Duration.zero,
      isMet: json['is_met'] ?? false,
      isVacation: json['is_vacation'] ?? false,
      isFreeze: json['is_freeze'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    String durationToString(Duration duration) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      final seconds = duration.inSeconds.remainder(60);
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    return {
      'date': date.toIso8601String(),
      'target_duration': durationToString(targetDuration),
      'total_duration': durationToString(totalDuration),
      'is_met': isMet,
      'is_vacation': isVacation,
      'is_freeze': isFreeze,
    };
  }
}
