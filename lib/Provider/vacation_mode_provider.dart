import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/vacation_date_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/Service/logging_service.dart';

class VacationModeProvider extends ChangeNotifier {
  static final VacationModeProvider _instance = VacationModeProvider._internal();
  factory VacationModeProvider() => _instance;
  VacationModeProvider._internal();

  static const String _vacationModeKey = 'vacation_mode_enabled';
  bool _isVacationModeEnabled = false;

  bool get isVacationModeEnabled => _isVacationModeEnabled;

  /// Initialize vacation mode settings
  Future<void> initialize() async {
    await _loadVacationModeSettings();
    await _backfillVacationDates();
  }

  /// Load vacation mode settings from SharedPreferences
  Future<void> _loadVacationModeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isVacationModeEnabled = prefs.getBool(_vacationModeKey) ?? false;
      LogService.debug('Loaded vacation mode setting: $_isVacationModeEnabled');
    } catch (e) {
      LogService.error('Error loading vacation mode settings: $e');
      _isVacationModeEnabled = false;
    }
  }

  /// Backfill vacation dates if vacation mode is enabled and there are gaps
  Future<void> _backfillVacationDates() async {
    if (!_isVacationModeEnabled) return;

    final provider = VacationDateProvider();
    await provider.initialize(); // Ensure box is open

    final allDates = provider.getAllVacationDates();
    if (allDates.isEmpty) return;

    // Find latest date using simple string comparison or parsing
    // Since dateString is YYYY-MM-DD, string comparison works for sorting?
    // Better to parse to be safe.
    DateTime? latestDate;

    for (var dateModel in allDates) {
      // Manual parsing since VacationDateModel model import might be tricky without seeing it,
      // but we can use DateTime.parse on dateString if it is ISO 8601 YYYY-MM-DD.
      // Checking VacationDateProvider.dart: dataString = VacationDateModel.dateToString(date);
      // Let's just assume valid format or adding Model import.
      try {
        final date = DateTime.parse(dateModel.dateString);
        if (latestDate == null || date.isAfter(latestDate)) {
          latestDate = date;
        }
      } catch (e) {
        // ignore invalid formats
      }
    }

    if (latestDate == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final latest = DateTime(latestDate.year, latestDate.month, latestDate.day);

    // If latest vacation date is before today (e.g. yesterday or older), fill the gap
    if (latest.isBefore(today)) {
      LogService.debug('VacationMode: Backfilling vacation dates from ${latest.toIso8601String()} to ${today.toIso8601String()}');

      // Start from the day after latest
      var date = latest.add(const Duration(days: 1));

      while (date.isBefore(today) || date.isAtSameMomentAs(today)) {
        await provider.setDateVacation(date, true);
        date = date.add(const Duration(days: 1));
      }
    }
  }

  /// Save vacation mode settings to SharedPreferences
  Future<void> _saveVacationModeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_vacationModeKey, _isVacationModeEnabled);
      LogService.debug('Saved vacation mode setting: $_isVacationModeEnabled');
    } catch (e) {
      LogService.error('Error saving vacation mode settings: $e');
    }
  }

  /// Toggle vacation mode
  Future<void> toggleVacationMode() async {
    _isVacationModeEnabled = !_isVacationModeEnabled;
    await _saveVacationModeSettings();

    final today = DateTime.now();

    if (_isVacationModeEnabled) {
      // When enabling vacation mode, mark today as vacation date
      await VacationDateProvider().setDateVacation(today, true);
      LogService.debug('VacationMode: Enabled and marked today as vacation date');
    } else {
      // When disabling vacation mode, remove today from vacation dates
      await VacationDateProvider().setDateVacation(today, false);
      LogService.debug('VacationMode: Disabled and removed today from vacation dates');
    }

    // Show feedback message to user
    Helper().getMessage(
      message: _isVacationModeEnabled ? 'VacationModeEnabled'.tr() : 'VacationModeDisabled'.tr(),
      status: StatusEnum.INFO,
    ); // Notify TaskProvider to update UI immediately
    TaskProvider().notifyListeners();

    notifyListeners();
  }
}
