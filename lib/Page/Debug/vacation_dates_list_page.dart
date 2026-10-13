import 'package:flutter/material.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/vacation_date_provider.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:intl/intl.dart';

class VacationDatesListPage extends StatefulWidget {
  const VacationDatesListPage({super.key});

  @override
  State<VacationDatesListPage> createState() => _VacationDatesListPageState();
}

class _VacationDatesListPageState extends State<VacationDatesListPage> {
  List<DateTime> _vacationDates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVacationDates();
    LogService.debug('VacationDatesListPage: Initialized');
  }

  Future<void> _loadVacationDates() async {
    setState(() => _isLoading = true);

    try {
      final vacationDateProvider = VacationDateProvider();
      final allVacationDates = vacationDateProvider.getAllVacationDates();

      // Convert to DateTime list and sort (newest first)
      _vacationDates = allVacationDates.map((model) => DateTime.parse(model.dateString)).toList()..sort((a, b) => b.compareTo(a));

      LogService.debug('VacationDatesListPage: Loaded ${_vacationDates.length} vacation dates');
    } catch (e) {
      LogService.error('VacationDatesListPage: Error loading vacation dates: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeVacationDate(DateTime date) async {
    try {
      await VacationDateProvider().setDateVacation(date, false);
      LogService.debug('VacationDatesListPage: Removed vacation date: ${date.toIso8601String()}');

      // Show success message
      Helper().getMessage(
        message: 'Vacation date removed: ${DateFormat('dd MMM yyyy').format(date)}',
        status: StatusEnum.SUCCESS,
      );

      // Reload the list
      await _loadVacationDates();
    } catch (e) {
      LogService.error('VacationDatesListPage: Error removing vacation date: $e');

      Helper().getMessage(
        message: 'Error removing vacation date: $e',
        status: StatusEnum.WARNING,
      );
    }
  }

  Future<void> _clearAllVacationDates() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Clear All Vacation Dates?'),
        content: const Text('This will remove all vacation dates from history. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await VacationDateProvider().clearAllVacationDates();
      LogService.debug('VacationDatesListPage: Cleared all vacation dates');

      Helper().getMessage(
        message: 'All vacation dates cleared',
        status: StatusEnum.SUCCESS,
      );

      // Reload the list
      await _loadVacationDates();
    } catch (e) {
      LogService.error('VacationDatesListPage: Error clearing vacation dates: $e');

      Helper().getMessage(
        message: 'Error clearing vacation dates: $e',
        status: StatusEnum.WARNING,
      );
    }
  }

  String _getDayName(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (checkDate.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    } else if (checkDate.isAfter(today)) {
      return 'Future';
    } else {
      return 'Past';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vacation Dates History'),
        backgroundColor: AppColors.main,
        actions: [
          if (_vacationDates.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: _clearAllVacationDates,
              tooltip: 'Clear All',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVacationDates,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vacationDates.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.beach_access,
                        size: 64,
                        color: AppColors.text.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No vacation dates recorded',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.text.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vacation dates will appear here when you enable vacation mode',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.text.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Summary Card
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.panelBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.text.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.beach_access,
                            color: AppColors.main,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Vacation Days',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.text.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_vacationDates.length} days',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _vacationDates.length,
                        itemBuilder: (context, index) {
                          final date = _vacationDates[index];
                          final dayName = _getDayName(date);
                          final isToday = dayName == 'Today';
                          final isFuture = dayName == 'Future';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: isToday ? AppColors.main.withValues(alpha: 0.1) : AppColors.panelBackground,
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isToday
                                      ? AppColors.main.withValues(alpha: 0.2)
                                      : isFuture
                                          ? Colors.blue.withValues(alpha: 0.2)
                                          : Colors.orange.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.beach_access,
                                  color: isToday
                                      ? AppColors.main
                                      : isFuture
                                          ? Colors.blue
                                          : Colors.orange,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                DateFormat('EEEE, dd MMMM yyyy').format(date),
                                style: TextStyle(
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                dayName,
                                style: TextStyle(
                                  color: isToday ? AppColors.main : AppColors.text.withValues(alpha: 0.6),
                                  fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                color: AppColors.red.withValues(alpha: 0.7),
                                onPressed: () => _removeVacationDate(date),
                                tooltip: 'Remove',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
