import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/date_formatter.dart';
import 'package:next_level/Service/locale_keys.g.dart';

extension DurationFormatting on Duration {
  String integer2() {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(inMinutes);
    final seconds = twoDigits(inSeconds.remainder(60));

    return [minutes, seconds].join(':');
  }

  String integer3() {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = twoDigits(inHours);
    final minutes = twoDigits(inMinutes.remainder(60));
    final seconds = twoDigits(inSeconds.remainder(60));

    return [hours, minutes, seconds].join(':');
  }

  String integerDynamic() {
    if (inHours != 0) {
      return integer3();
    } else {
      return integer2();
    }
  }

  String textLong2() {
    final minutes = inMinutes;
    final seconds = inSeconds.remainder(60);

    return "$minutes ${LocaleKeys.Minute.tr()} $seconds ${LocaleKeys.Second.tr()}";
  }

  String textLong3() {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);

    return "$hours ${LocaleKeys.Hour.tr()} $minutes ${LocaleKeys.Minute.tr()} $seconds ${LocaleKeys.Second.tr()}";
  }

  String textLongDynamic() {
    if (inHours != 0) {
      return textLong3();
    } else {
      return textLong2();
    }
  }

  String textShort2() {
    final minutes = inMinutes;
    final seconds = inSeconds.remainder(60);

    return "$minutes${LocaleKeys.m.tr()} $seconds${LocaleKeys.s.tr()}";
  }

  String textShort2hour() {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);

    return "$hours${LocaleKeys.h.tr()} $minutes${LocaleKeys.m.tr()}";
  }

  String textShort3() {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);

    return "$hours${LocaleKeys.h.tr()} $minutes${LocaleKeys.m.tr()} $seconds${LocaleKeys.s.tr()}";
  }

  String textShortDynamic() {
    if (inHours != 0) {
      return textShort3();
    } else {
      return textShort2();
    }
  }

  String textLongDynamicWithoutZero() {
    final seconds = inSeconds.remainder(60);
    final minutes = inMinutes.remainder(60);
    final hours = inHours;

    if (hours > 0 && minutes > 0 && seconds == 0) {
      return "$hours${LocaleKeys.h.tr()} $minutes${LocaleKeys.m.tr()}";
    } else if (hours == 0 && minutes > 0 && seconds == 0) {
      return "$minutes${LocaleKeys.m.tr()}";
    } else if (hours > 0 && minutes == 0 && seconds == 0) {
      return "$hours${LocaleKeys.h.tr()}";
    } else if (hours == 0 && minutes == 0 && seconds > 0) {
      return "$seconds${LocaleKeys.s.tr()}";
    } else if (hours == 0 && minutes > 0 && seconds > 0) {
      return "$minutes${LocaleKeys.m.tr()} $seconds${LocaleKeys.s.tr()}";
    } else if (hours == 0 && minutes == 0 && seconds == 0) {
      return "$hours${LocaleKeys.h.tr()}";
    } else {
      return "$hours${LocaleKeys.h.tr()} $minutes${LocaleKeys.m.tr()} $seconds${LocaleKeys.s.tr()}";
    }
  }

  // Erken hatırlatma için kompakt format
  String compactFormat() {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);

    if (hours > 0 && minutes > 0) {
      // 1 saat 25 dakika -> "1h 25m"
      return "$hours${LocaleKeys.h.tr()} $minutes${LocaleKeys.m.tr()}";
    } else if (hours > 0) {
      // 1 saat -> "1h"
      return "$hours${LocaleKeys.h.tr()}";
    } else {
      // 20 dakika -> "20m"
      return "$minutes${LocaleKeys.m.tr()}";
    }
  }

  String toLevel() {

    return "${inHours ~/ 10} LVL";
  }

  Duration operator /(int value) {
    if (inSeconds == 0) {
      return Duration.zero;
    }

    return Duration(
      hours: inHours ~/ value,
      minutes: (inMinutes ~/ value) % 60,
      seconds: (inSeconds ~/ value) % 60,
    );
  }
}

extension IntFormatting on int {
  String secondToTime() {
    final int hours = this ~/ 3600;
    final int minutes = this % 3600 ~/ 60;
    final int remainingSeconds = this % 60;

    return "${hours}h ${minutes}m ${remainingSeconds}s";
  }
}

extension TimeOfDayConverter on TimeOfDay {
  String to24Hours() {
    final String hour = this.hour.toString().padLeft(2, "0");
    final String min = minute.toString().padLeft(2, "0");
    return "$hour:$min";
  }

  String to12Hours() {
    String hour = this.hour.toString().padLeft(2, "0");
    bool isAm = true;

    if (this.hour >= 12) {
      hour = (this.hour - (this.hour > 12 ? 12 : 0)).toString().padLeft(2, "0");
      isAm = false;
    }

    final String min = minute.toString().padLeft(2, "0");
    return "$hour:$min ${isAm ? "AM" : "PM"}";
  }
}

extension DateTimeExtension on DateTime {
  bool isSameDay(DateTime date) {
    return year == date.year && month == date.month && day == date.day;
  }

  bool isBeforeDay(DateTime date) {
    return year < date.year || (year == date.year && month < date.month) || (year == date.year && month == date.month && day < date.day);
  }

  bool isBeforeOrSameDay(DateTime date) {
    return year < date.year || (year == date.year && month < date.month) || (year == date.year && month == date.month && day <= date.day);
  }

  bool isAfterDay(DateTime date) {
    return year > date.year || (year == date.year && month > date.month) || (year == date.year && month == date.month && day > date.day);
  }

  bool isAfterOrSameDay(DateTime date) {
    return year > date.year || (year == date.year && month > date.month) || (year == date.year && month == date.month && day >= date.day);
  }

  String compactDate() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays == 0) {
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormatter.formatDate(this);
    }
  }
}
