import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:next_level/Model/vacation_date_model.dart';
import 'package:next_level/Provider/vacation_mode_provider.dart';
import 'package:next_level/Provider/streak_settings_provider.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Service/data_mutation_notifier.dart';

class VacationDateProvider extends ChangeNotifier {
  static final VacationDateProvider _instance =
      VacationDateProvider._internal();
  factory VacationDateProvider() => _instance;
  VacationDateProvider._internal();

  static const String _boxName = 'vacation_dates';
  Box<VacationDateModel>? _vacationBox;

  /// Initialize the vacation dates box
  Future<void> initialize() async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        _vacationBox = await Hive.openBox<VacationDateModel>(_boxName);
        LogService.debug(
            'VacationDateProvider: Initialized with ${_vacationBox!.length} vacation dates');
      } else {
        _vacationBox = Hive.box<VacationDateModel>(_boxName);
      }
    } catch (e) {
      LogService.error('VacationDateProvider: Error initializing box: $e');
    }
  }

  /// Check if a specific date is marked as vacation
  bool isDateVacation(DateTime date) {
    if (_vacationBox == null) return false;

    final dateString = VacationDateModel.dateToString(date);
    final vacationDate = _vacationBox!.get(dateString);

    final result = vacationDate?.isVacation ?? false;
    return result;
  }

  /// Set a date as vacation or not
  Future<void> setDateVacation(DateTime date, bool isVacation) async {
    if (_vacationBox == null) {
      await initialize();
    }

    final dateString = VacationDateModel.dateToString(date);

    if (isVacation) {
      // Add or update vacation date
      final vacationDate = VacationDateModel(
        dateString: dateString,
        isVacation: true,
      );
      await _vacationBox!.put(dateString, vacationDate);
      LogService.debug('VacationDateProvider: Set $dateString as vacation');
    } else {
      // Remove vacation date
      await _vacationBox!.delete(dateString);
      LogService.debug(
          'VacationDateProvider: Removed vacation from $dateString');
    }

    DataMutationNotifier().markDirty('vacation_date:set');
    notifyListeners();
  }

  /// Toggle vacation status for a date
  Future<void> toggleDateVacation(DateTime date) async {
    final currentStatus = isDateVacation(date);
    await setDateVacation(date, !currentStatus);
  }

  /// Get all vacation dates
  List<VacationDateModel> getAllVacationDates() {
    if (_vacationBox == null) return [];
    return _vacationBox!.values.where((v) => v.isVacation).toList();
  }

  /// Clear all vacation dates (for debugging/reset)
  Future<void> clearAllVacationDates() async {
    if (_vacationBox == null) return;
    await _vacationBox!.clear();
    DataMutationNotifier().markDirty('vacation_date:clear');
    LogService.debug('VacationDateProvider: Cleared all vacation dates');
    notifyListeners();
  }

  /// Get vacation dates in a date range
  List<DateTime> getVacationDatesInRange(DateTime start, DateTime end) {
    if (_vacationBox == null) return [];

    final List<DateTime> vacationDates = [];
    for (var date = start;
        date.isBefore(end) || date.isAtSameMomentAs(end);
        date = date.add(const Duration(days: 1))) {
      if (isDateVacation(date)) {
        vacationDates.add(date);
      }
    }
    return vacationDates;
  }

  /// Check if a date is a vacation day - CENTRALIZED VACATION LOGIC
  /// Returns true if:
  /// 1. The date is specifically marked as vacation in Hive (date-specific vacation)
  /// 2. Vacation mode is active (applies to TODAY and optionally FUTURE dates)
  /// 3. The day is a vacation weekday (e.g., every Saturday) - ONLY for future dates
  bool isVacationDay(DateTime date, {bool includeFutureVacationMode = true}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(date.year, date.month, date.day);

    final isToday = checkDate.isAtSameMomentAs(today);
    final isFuture = checkDate.isAfter(today);

    // 1. Check if this specific date is marked as vacation in Hive
    final isSpecificDateVacation = isDateVacation(checkDate);

    // 2. Check if vacation mode is globally enabled (for TODAY and optionally FUTURE dates)
    final isVacationModeActive = VacationModeProvider().isVacationModeEnabled;
    final isVacationModeApplicable = isVacationModeActive &&
        (isToday || (includeFutureVacationMode && isFuture));

    // 3. Check if this specific weekday is marked as vacation
    // IMPORTANT: Only apply weekday rule for FUTURE dates, not past
    final vacationWeekdays = StreakSettingsProvider().vacationWeekdays;
    // weekday: 1 = Monday, 2 = Tuesday, ..., 7 = Sunday
    // Convert to 0-based index for our Set (0 = Monday, 1 = Tuesday, ..., 6 = Sunday)
    final weekdayIndex = date.weekday - 1;
    final isVacationWeekday =
        vacationWeekdays.contains(weekdayIndex) && (isFuture || isToday);

    final result =
        isSpecificDateVacation || isVacationModeApplicable || isVacationWeekday;

    // if (isToday) {
    //   LogService.debug(
    //       '🏖️ VacationDateProvider.isVacationDay TODAY: result=$result, specificDate=$isSpecificDateVacation, vacationMode=$isVacationModeApplicable (active=$isVacationModeActive, includeFuture=$includeFutureVacationMode), weekday=$isVacationWeekday (index=$weekdayIndex, vacationWeekdays=$vacationWeekdays)');
    // } else {
    //   LogService.debug('VacationDateProvider: isVacationDay for ${date.toIso8601String()}: $result (specificDate: $isSpecificDateVacation, vacationMode: $isVacationModeApplicable, weekday: $isVacationWeekday, isPast: $isPast, isFuture: $isFuture, includeFuture=$includeFutureVacationMode)');
    // }

    return result;
  }
}
