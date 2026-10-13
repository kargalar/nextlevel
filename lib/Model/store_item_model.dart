import 'package:next_level/Enum/task_type_enum.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'store_item_model.g.dart';

@HiveType(typeId: 3)
class ItemModel extends HiveObject {
  @HiveField(0)
  int id; // id si
  @HiveField(1)
  final String title; // başlığı
  @HiveField(2)
  final TaskTypeEnum type; // türü
  @HiveField(3)
  Duration? currentDuration; // timer ise süre buradan takip edilecek
  @HiveField(4)
  final Duration? addDuration; // timer ise hedef süre timer değilse tecrübe puanı buna göre gelecek
  @HiveField(5)
  int? currentCount; // counter ise sayı buradan takip edilecek
  @HiveField(6)
  bool? isTimerActive; // timer aktif mi
  @HiveField(7)
  int credit;
  @HiveField(8)
  int? addCount;
  @HiveField(9)
  final String? description;
  @HiveField(10)
  int? order; // itemlerin sırasını belirtmek için

  ItemModel({
    this.id = 0,
    required this.title,
    required this.type,
    this.currentDuration,
    this.addDuration,
    this.currentCount,
    this.addCount,
    this.isTimerActive,
    required this.credit,
    this.description,
    this.order = 0,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    Duration stringToDuration(String timeString) {
      List<String> split = timeString.split(':');
      return Duration(hours: int.parse(split[0]), minutes: int.parse(split[1]), seconds: int.parse(split[2]));
    }

    final TaskTypeEnum type = TaskTypeEnum.values.firstWhere((e) => e.toString().split('.').last == json['type']);

    return ItemModel(
      id: json['id'],
      title: json['title'],
      type: type,
      currentDuration: json['current_duration'] != null ? stringToDuration(json['current_duration']) : null,
      addDuration: json['add_duration'] != null ? stringToDuration(json['add_duration']) : null,
      currentCount: json['current_count'],
      isTimerActive: json['is_timer_active'] ?? (type == TaskTypeEnum.TIMER ? false : null),
      credit: json['credit'],
      addCount: json['add_count'],
      description: json['description'],
      order: json['order'] ?? 0,
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
      'id': id,
      'title': title,
      'type': type.toString().split('.').last,
      'current_duration': currentDuration != null ? durationToString(currentDuration!) : null,
      'add_duration': addDuration != null ? durationToString(addDuration!) : null,
      'current_count': currentCount,
      'credit': credit,
      'is_timer_active': isTimerActive,
      'add_count': addCount,
      'description': description,
      'order': order ?? 0,
    };
  }
}
