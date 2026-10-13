import 'package:flutter/material.dart';
import 'package:next_level/Core/extensions.dart';
import 'package:next_level/Core/repeat_date_codec.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:next_level/Model/subtask_model.dart';
import 'package:next_level/Enum/repeat_type_enum.dart';

class RoutineModel extends HiveObject {
  @HiveField(0)
  int id; // id si
  @HiveField(1)
  String title; // başlığı
  @HiveField(2)
  String? description; // başlığı
  @HiveField(3)
  TaskTypeEnum type; // türü
  @HiveField(4)
  final DateTime createdDate; // oluşturulma tarihi
  @HiveField(5)
  DateTime? startDate; // başlama tarihi
  @HiveField(6)
  TimeOfDay? time; // saati
  @HiveField(7)
  bool isNotificationOn; // notification açık mı
  @HiveField(8)
  bool isAlarmOn; // notification açık mı
  @HiveField(9)
  Duration?
      remainingDuration; // timer ise hedef süre timer değilse tecrübe puanı buna göre gelecek
  @HiveField(10)
  int? targetCount; // counter ise hedef sayı
  @HiveField(11)
  List<int> repeatDays; // tekrar günleri
  @HiveField(22)
  RepeatTypeEnum? repeatType; // Tekrar tipi
  @HiveField(23)
  List<int>? customDates; // Özel tekrar günleri/ayları
  @HiveField(12)
  List<int>? attirbuteIDList; // etki edeceği özellikler
  @HiveField(13)
  List<int>? skillIDList; // etki edecği yetenekler
  @HiveField(14)
  bool isArchived; // tamamlandı mı
  @HiveField(15)
  int priority; // öncelik değeri (1: Yüksek, 2: Orta, 3: Düşük)
  @HiveField(16)
  String? categoryId; // kategori id'si
  @HiveField(17)
  int? earlyReminderMinutes; // erken hatırlatma süresi (dakika cinsinden)
  @HiveField(18)
  List<SubTaskModel>? subtasks; // alt görevler
  @HiveField(19)
  bool isActiveOnVacationDays; // tatil günlerinde aktif mi
  @HiveField(20)
  int sortOrder; // Sıralama için kullanılır
  @HiveField(21)
  bool isFocusModeBypassed; // Odak modu filtresini yoksayar

  RoutineModel({
    this.id = 0,
    required this.title,
    required this.description,
    required this.type,
    required this.createdDate,
    this.startDate,
    this.time,
    required this.isNotificationOn,
    required this.isAlarmOn,
    this.remainingDuration,
    this.targetCount,
    required this.repeatDays,
    this.attirbuteIDList,
    this.skillIDList,
    required this.isArchived,
    this.priority = 3,
    this.categoryId,
    this.earlyReminderMinutes,
    this.subtasks,
    this.isActiveOnVacationDays = false, // default: tatilde aktif değil
    this.sortOrder = 0,
    this.isFocusModeBypassed = false,
    this.repeatType,
    this.customDates,
  });

  factory RoutineModel.fromJson(Map<String, dynamic> json) {
    Duration stringToDuration(String timeString) {
      List<String> split = timeString.split(':');
      return Duration(
          hours: int.parse(split[0]),
          minutes: int.parse(split[1]),
          seconds: int.parse(split[2]));
    }

    TaskTypeEnum type = TaskTypeEnum.values
        .firstWhere((e) => e.toString().split('.').last == json['type']);

    return RoutineModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: type,
      createdDate: DateTime.parse(json['created_date']),
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      time: json['time'] != null
          ? TimeOfDay.fromDateTime(DateTime.parse("1970-01-01 ${json['time']}"))
          : null,
      isNotificationOn: json['is_notification_on'],
      isAlarmOn: json['is_alarm_on'],
      remainingDuration: json['remaining_duration'] != null
          ? stringToDuration(json['remaining_duration'])
          : null,
      targetCount: json['target_count'],
      repeatDays: (json['repeat_days'] as List)
          .map((e) => int.parse(e.toString()))
          .toList(),
      attirbuteIDList: json['attribute_id_list'] != null
          ? List<int>.from(json['attribute_id_list'])
          : null,
      skillIDList: json['skill_id_list'] != null
          ? List<int>.from(json['skill_id_list'])
          : null,
      isArchived: json['is_archived'],
      priority: json['priority'] ?? 3,
      categoryId: json['category_id'],
      earlyReminderMinutes: json['early_reminder_minutes'],
      subtasks: json['subtasks'] != null
          ? (json['subtasks'] as List)
              .map((i) => SubTaskModel.fromJson(i))
              .toList()
          : null,
      isActiveOnVacationDays: json['is_active_on_vacation_days'] ?? false,
      sortOrder: json['sort_order'] ?? 0,
      isFocusModeBypassed: json['is_focus_mode_bypassed'] ?? false,
      repeatType: json['repeat_type'] != null
          ? RepeatTypeEnum.values.firstWhere(
              (e) => e.toString().split('.').last == json['repeat_type'],
              orElse: () => RepeatTypeEnum.weekly)
          : null,
      customDates: json['custom_dates'] != null
          ? List<int>.from(json['custom_dates'])
          : null,
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
      'description': description,
      'type': type.toString().split('.').last,
      'created_date': createdDate.toIso8601String(),
      'start_date': startDate?.toIso8601String(),
      'time': time != null
          ? '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}:00'
          : null,
      'is_notification_on': isNotificationOn,
      'is_alarm_on': isAlarmOn,
      'remaining_duration': remainingDuration != null
          ? durationToString(remainingDuration!)
          : null,
      'target_count': targetCount,
      'repeat_days': repeatDays,
      'attribute_id_list': attirbuteIDList,
      'skill_id_list': skillIDList,
      'is_archived': isArchived,
      'priority': priority,
      'category_id': categoryId,
      'early_reminder_minutes': earlyReminderMinutes,
      'subtasks': subtasks?.map((i) => i.toJson()).toList(),
      'is_active_on_vacation_days': isActiveOnVacationDays,
      'sort_order': sortOrder,
      'is_focus_mode_bypassed': isFocusModeBypassed,
      'repeat_type': repeatType?.toString().split('.').last,
      'custom_dates': customDates,
    };
  }
}

extension RoutineModelExtension on RoutineModel {
  bool isActiveForThisDate(DateTime date) {
    if (isArchived) return false;

    // A routine must never produce entries for days before it existed. Older
    // routines may not have a startDate, so createdDate is the safe fallback.
    final firstActiveDate = startDate ?? createdDate;
    if (date.isBeforeDay(firstActiveDate)) return false;

    // Eğer repeatType tanımlanmışsa gelişmiş kuralları kullan
    if (repeatType != null) {
      switch (repeatType!) {
        case RepeatTypeEnum.daily:
          return true;
        case RepeatTypeEnum.weekly:
          return repeatDays.contains(date.weekday - 1);
        case RepeatTypeEnum.monthly:
          if (customDates == null || customDates!.isEmpty) return false;
          // Ay sonu mantığı: eğer customDate 31 ise ve bulunduğumuz ay 28 veya 30 çekiyorsa
          // ayın son günü olarak kabul et.
          int lastDayOfMonth = DateTime(date.year, date.month + 1, 0).day;
          for (int targetDay in customDates!) {
            int effectiveDay =
                targetDay > lastDayOfMonth ? lastDayOfMonth : targetDay;
            if (date.day == effectiveDay) return true;
          }
          return false;
        case RepeatTypeEnum.yearly:
          return RepeatDateCodec.matchesYearlyDate(
            customDates,
            date,
            fallbackDate: startDate,
          );
        case RepeatTypeEnum.custom:
          // Özel aralıklarla tekrar (örneğin 3 günde bir)
          if (customDates != null &&
              customDates!.isNotEmpty &&
              startDate != null) {
            int interval = customDates!.first;
            int daysDiff = date
                .difference(
                    DateTime(startDate!.year, startDate!.month, startDate!.day))
                .inDays;
            return daysDiff >= 0 && daysDiff % interval == 0;
          }
          return false;
      }
    }

    // Eski mantık (Geriye uyumluluk için)
    return repeatDays.contains(date.weekday - 1);
  }
}

class RoutineModelAdapter extends TypeAdapter<RoutineModel> {
  @override
  final int typeId = 4;

  @override
  RoutineModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return RoutineModel(
      id: fields[0] as int,
      title: fields[1] as String,
      description: fields[2] as String?,
      type: fields[3] as TaskTypeEnum,
      createdDate: fields[4] as DateTime,
      startDate: fields[5] as DateTime?,
      time: fields[6] as TimeOfDay?,
      isNotificationOn: fields[7] as bool,
      isAlarmOn: fields[8] as bool,
      remainingDuration: fields[9] as Duration?,
      targetCount: fields[10] as int?,
      repeatDays: (fields[11] as List).cast<int>(),
      attirbuteIDList: (fields[12] as List?)?.cast<int>(),
      skillIDList: (fields[13] as List?)?.cast<int>(),
      isArchived: fields[14] as bool,
      priority: fields[15] as int,
      categoryId: fields[16] is int
          ? (fields[16] as int).toString()
          : fields[16] as String?,
      earlyReminderMinutes: fields[17] as int?,
      subtasks: (fields[18] as List?)?.cast<SubTaskModel>(),
      isActiveOnVacationDays: fields[19] as bool? ?? false,
      sortOrder: fields[20] as int? ?? 0,
      isFocusModeBypassed: fields[21] as bool? ?? false,
      repeatType: fields[22] as RepeatTypeEnum?,
      customDates: (fields[23] as List?)?.cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, RoutineModel obj) {
    writer
      ..writeByte(24)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.createdDate)
      ..writeByte(5)
      ..write(obj.startDate)
      ..writeByte(6)
      ..write(obj.time)
      ..writeByte(7)
      ..write(obj.isNotificationOn)
      ..writeByte(8)
      ..write(obj.isAlarmOn)
      ..writeByte(9)
      ..write(obj.remainingDuration)
      ..writeByte(10)
      ..write(obj.targetCount)
      ..writeByte(11)
      ..write(obj.repeatDays)
      ..writeByte(12)
      ..write(obj.attirbuteIDList)
      ..writeByte(13)
      ..write(obj.skillIDList)
      ..writeByte(14)
      ..write(obj.isArchived)
      ..writeByte(15)
      ..write(obj.priority)
      ..writeByte(16)
      ..write(obj.categoryId)
      ..writeByte(17)
      ..write(obj.earlyReminderMinutes)
      ..writeByte(18)
      ..write(obj.subtasks)
      ..writeByte(19)
      ..write(obj.isActiveOnVacationDays)
      ..writeByte(20)
      ..write(obj.sortOrder)
      ..writeByte(21)
      ..write(obj.isFocusModeBypassed)
      ..writeByte(22)
      ..write(obj.repeatType)
      ..writeByte(23)
      ..write(obj.customDates);
  }
}
