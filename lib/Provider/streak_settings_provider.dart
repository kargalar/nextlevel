import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Service/logging_service.dart';

class StreakSettingsProvider extends ChangeNotifier {
  static final StreakSettingsProvider _instance =
      StreakSettingsProvider._internal();
  factory StreakSettingsProvider() => _instance;
  StreakSettingsProvider._internal();

  // Streak settings keys
  static const String _streakMinimumHoursKey = 'streak_minimum_hours';
  static const String _vacationDaysKey =
      'vacation_weekdays'; // Changed to weekdays

  // Default values
  double _streakMinimumHours = 1.0; // Default 1 hour per day
  final Set<int> _vacationWeekdays =
      {}; // 0 = Monday, 1 = Tuesday, ..., 6 = Sunday

  // Getters
  double get streakMinimumHours => _streakMinimumHours;
  Set<int> get vacationWeekdays => Set.from(_vacationWeekdays);

  /// Initialize streak settings
  Future<void> initialize() async {
    await _loadStreakSettings();
  }

  /// Load streak settings from SharedPreferences
  Future<void> _loadStreakSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _streakMinimumHours = prefs.getDouble(_streakMinimumHoursKey) ?? 1.0;

      // Load vacation weekdays
      final vacationWeekdaysString =
          prefs.getStringList(_vacationDaysKey) ?? [];
      _vacationWeekdays.clear();
      for (String weekdayStr in vacationWeekdaysString) {
        try {
          _vacationWeekdays.add(int.parse(weekdayStr));
        } catch (e) {
          LogService.error('Error parsing weekday: $weekdayStr');
        }
      }

      LogService.debug(
          'Loaded streak settings: minHours=$_streakMinimumHours, vacationWeekdays=$_vacationWeekdays');
    } catch (e) {
      LogService.error('Error loading streak settings: $e');
      // Set defaults
      _streakMinimumHours = 1.0;
      _vacationWeekdays.clear();
    }
  }

  /// Save streak settings to SharedPreferences
  Future<void> _saveStreakSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setDouble(_streakMinimumHoursKey, _streakMinimumHours);
      await prefs.setStringList(_vacationDaysKey,
          _vacationWeekdays.map((e) => e.toString()).toList());

      LogService.debug(
          'Saved streak settings: minHours=$_streakMinimumHours, vacationWeekdays=$_vacationWeekdays');
    } catch (e) {
      LogService.error('Error saving streak settings: $e');
    }
  }

  /// Set minimum hours required for streak
  Future<void> setStreakMinimumHours(double hours) async {
    if (hours <= 0) return;

    _streakMinimumHours = hours;
    await _saveStreakSettings();
    notifyListeners();

    Helper().getMessage(
      message:
          'Streak minimum hours updated to ${hours.toStringAsFixed(1)} hours',
      status: StatusEnum.SUCCESS,
    );
  }

  /// Toggle a vacation weekday
  Future<void> toggleVacationWeekday(int weekday) async {
    if (weekday < 0 || weekday > 6) return;

    final wasSelected = _vacationWeekdays.contains(weekday);
    if (_vacationWeekdays.contains(weekday)) {
      _vacationWeekdays.remove(weekday);
    } else {
      _vacationWeekdays.add(weekday);
    }

    await _saveStreakSettings();
    notifyListeners();

    Helper().getMessage(
      message: wasSelected ? 'Vacation day removed' : 'Vacation day added',
      status: StatusEnum.SUCCESS,
    );
  }

  /// Clear all vacation weekdays
  Future<void> clearVacationWeekdays() async {
    _vacationWeekdays.clear();
    await _saveStreakSettings();
    notifyListeners();

    Helper().getMessage(
      message: 'All vacation days cleared',
      status: StatusEnum.SUCCESS,
    );
  }

  /// Get weekday name for display
  String getWeekdayName(int weekday) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[weekday];
  }
}
