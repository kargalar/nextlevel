import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/task_log_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Model/store_item_model.dart';
import 'package:next_level/Page/Task%20Detail%20Page/view_model/task_progress_view_model.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/store_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Page/Task%20Detail%20Page/routine_detail_page.dart';
import 'package:next_level/Page/Home/Add%20Task/add_task_page.dart';
import 'package:next_level/Service/navigator_service.dart';

class DailyCreditTransactions extends StatefulWidget {
  const DailyCreditTransactions({super.key});

  @override
  State<DailyCreditTransactions> createState() => _DailyCreditTransactionsState();
}

class _DailyCreditTransactionsState extends State<DailyCreditTransactions> {
  late DateTime _selectedDate;
  List<dynamic> _storeItemLogCache = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadStoreItemLogsCache();
  }

  /// Store item loglarını cache'e yükle
  void _loadStoreItemLogsCache() async {
    try {
      final logs = await TaskProgressViewModel.getStoreItemLogs(-1);
      setState(() {
        _storeItemLogCache = logs;
      });
    } catch (e) {
      debugPrint('[Daily Credit Transactions] Error loading logs: $e');
    }
  }

  /// Verilen tarih için kredileri hesapla
  Map<String, dynamic> _calculateCreditsForDate(DateTime date) {
    final dateStart = DateTime(date.year, date.month, date.day);
    final dateEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

    // Belirtilen günün log'larını al
    final logsForDay = TaskLogProvider().taskLogList.where((log) => log.logDate.isAfter(dateStart) && log.logDate.isBefore(dateEnd)).toList();

    double earnedCredits = 0.0;
    double lostCredits = 0.0;
    final List<Map<String, dynamic>> transactions = [];

    for (final log in logsForDay) {
      try {
        // Counter ve Timer taskları burada atla (ayrı metodlarda hesaplanacak)
        if (log.count != null || log.duration != null) {
          continue;
        }

        TaskModel? task;
        try {
          task = TaskProvider().taskList.firstWhere((t) => t.id == log.taskId);
        } catch (_) {
          continue;
        }

        if (log.status == TaskStatusEnum.DONE) {
          // Checkbox task (sadece count ve duration olmayan)
          if (task.remainingDuration != null) {
            final credits = task.remainingDuration!.inMinutes / 60.0;
            earnedCredits += credits;
            transactions.add({
              'type': 'earn',
              'amount': credits,
              'taskTitle': log.taskTitle,
              'taskId': log.taskId,
              'taskDuration': task.remainingDuration,
              'icon': Icons.check_circle,
              'time': log.logDate,
            });
          }
        } else if (log.status == TaskStatusEnum.CANCEL || log.status == TaskStatusEnum.FAILED || log.status == TaskStatusEnum.OVERDUE) {
          // Iptal veya basarısız görev (sadece checkbox task)
          if (task.remainingDuration != null) {
            final credits = task.remainingDuration!.inMinutes / 60.0;
            lostCredits += credits;
            transactions.add({
              'type': 'lose',
              'amount': credits,
              'taskTitle': log.taskTitle,
              'taskId': log.taskId,
              'taskDuration': task.remainingDuration,
              'icon': Icons.cancel,
              'time': log.logDate,
            });
          }
        }
      } catch (e) {
        LogService.debug('Error calculating credits for log: $e');
      }
    }

    // Counter ve Timer task'ları kontrol et
    // Counter: her count için credit
    final counterTransactions = _calculateCounterCredits(logsForDay);
    earnedCredits += counterTransactions['earned'] as double;
    lostCredits += counterTransactions['lost'] as double;
    transactions.addAll((counterTransactions['transactions'] as List).cast<Map<String, dynamic>>());

    // Timer: aktif zamanlar
    final timerTransactions = _calculateTimerCredits(logsForDay);
    earnedCredits += timerTransactions['earned'] as double;
    lostCredits += timerTransactions['lost'] as double;
    transactions.addAll((timerTransactions['transactions'] as List).cast<Map<String, dynamic>>());

    // Store Item Purchase: satın alma işlemleri
    final purchaseTransactions = _calculateStorePurchases(dateStart, dateEnd);
    lostCredits += purchaseTransactions['lost'] as double;
    transactions.addAll((purchaseTransactions['transactions'] as List).cast<Map<String, dynamic>>());

    // İşlemleri zamana göre sırala (en son ilk)
    transactions.sort((a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime));

    LogService.debug(
      '💰 Credits for ${DateFormat('yyyy-MM-dd').format(date)} - Earned: $earnedCredits, Lost: $lostCredits',
    );

    return {
      'earned': earnedCredits,
      'lost': lostCredits,
      'transactions': transactions,
    };
  }

  Map<String, dynamic> _calculateCounterCredits(List<TaskLogModel> todayLogs) {
    double earned = 0.0;
    double lost = 0.0;
    final List<Map<String, dynamic>> transactions = [];

    // Counter task'ları grupla
    final counterLogs = todayLogs.where((log) => log.count != null).toList();

    for (final log in counterLogs) {
      try {
        TaskModel? task;
        try {
          task = TaskProvider().taskList.firstWhere((t) => t.id == log.taskId);
        } catch (_) {
          continue;
        }

        if (task.remainingDuration != null) {
          // Per count'a göre credit hesapla
          final creditPerCount = task.remainingDuration!.inMinutes / 60.0;
          final count = log.count ?? 0;

          if (count > 0) {
            final credits = creditPerCount * count;
            earned += credits;
            transactions.add({
              'type': 'earn',
              'amount': credits,
              'taskTitle': log.taskTitle,
              'taskId': log.taskId,
              'taskDuration': task.remainingDuration,
              'icon': Icons.add_circle,
              'time': log.logDate,
            });
          } else if (count < 0) {
            final credits = creditPerCount * count.abs();
            lost += credits;
            transactions.add({
              'type': 'lose',
              'amount': credits,
              'taskTitle': log.taskTitle,
              'taskId': log.taskId,
              'taskDuration': task.remainingDuration,
              'icon': Icons.remove_circle,
              'time': log.logDate,
            });
          }
        }
      } catch (e) {
        LogService.debug('Error calculating counter credits: $e');
      }
    }

    return {
      'earned': earned,
      'lost': lost,
      'transactions': transactions,
    };
  }

  Map<String, dynamic> _calculateTimerCredits(List<TaskLogModel> todayLogs) {
    double earned = 0.0;
    double lost = 0.0;
    final List<Map<String, dynamic>> transactions = [];

    // Timer task'ları (duration var olanlar)
    final timerLogs = todayLogs.where((log) => log.duration != null).toList();

    for (final log in timerLogs) {
      try {
        if (log.duration != null) {
          final credits = log.duration!.inMinutes / 60.0;

          if (log.status == TaskStatusEnum.DONE) {
            earned += credits;
            transactions.add({
              'type': 'earn',
              'amount': credits,
              'taskTitle': log.taskTitle,
              'taskId': log.taskId,
              'taskDuration': log.duration,
              'icon': Icons.timer,
              'time': log.logDate,
            });
          } else if (log.status == TaskStatusEnum.CANCEL || log.status == TaskStatusEnum.FAILED || log.status == TaskStatusEnum.OVERDUE) {
            lost += credits;
            transactions.add({
              'type': 'lose',
              'amount': credits,
              'taskTitle': log.taskTitle,
              'taskId': log.taskId,
              'taskDuration': log.duration,
              'icon': Icons.timer_off,
              'time': log.logDate,
            });
          } else {
            // Diğer statuslar için de transaction'ı kaydet
            earned += credits;
            transactions.add({
              'type': 'earn',
              'amount': credits,
              'taskTitle': log.taskTitle,
              'taskId': log.taskId,
              'taskDuration': log.duration,
              'icon': Icons.timer,
              'time': log.logDate,
            });
            LogService.debug('Timer log with status ${log.status} recorded for ${log.taskTitle}');
          }
        }
      } catch (e) {
        LogService.debug('Error calculating timer credits: $e');
      }
    }

    return {
      'earned': earned,
      'lost': lost,
      'transactions': transactions,
    };
  }

  /// Store item satın almalarını hesapla
  Map<String, dynamic> _calculateStorePurchases(DateTime dateStart, DateTime dateEnd) {
    double lost = 0.0;
    final List<Map<String, dynamic>> transactions = [];

    // Cache'deki store item loglarını kullan
    final allStoreLogs = _storeItemLogCache;

    // Belirtilen gündeki purchase loglarını filtrele
    final purchaseLogsForDay = allStoreLogs.where((log) => log.isPurchase && log.logDate.isAfter(dateStart) && log.logDate.isBefore(dateEnd)).toList();

    for (final log in purchaseLogsForDay) {
      try {
        // Store item'ı bul
        ItemModel? item;
        try {
          item = StoreProvider().storeItemList.firstWhere((i) => i.id == log.itemId);
        } catch (_) {
          // Item bulunamadıysa devam et
          continue;
        }

        // Kredi harcaması
        final creditCost = item.credit.toDouble();
        if (creditCost > 0) {
          lost += creditCost;
          transactions.add({
            'type': 'lose',
            'amount': creditCost,
            'taskTitle': '🛒 ${item.title}', // Shopping emoji ile belirt
            'icon': Icons.shopping_cart,
            'time': log.logDate,
          });
        }
      } catch (e) {
        LogService.debug('Error calculating store purchase: $e');
      }
    }

    return {
      'earned': 0.0,
      'lost': lost,
      'transactions': transactions,
    };
  }

  /// Dialog içeriğini oluştur
  Widget _buildDialogContent(
    double earned,
    double lost,
    List<Map<String, dynamic>> transactions,
  ) {
    return SizedBox(
      width: 2222,
      height: 500,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                LocaleKeys.TodayCredits.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                Icons.calendar_today,
                size: 20,
                color: AppColors.main.withValues(alpha: 0.6),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Earned ve Lost summary
          Row(
            children: [
              Expanded(
                child: _buildCreditSummary(
                  title: LocaleKeys.Earned.tr(),
                  amount: earned,
                  color: Colors.green,
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCreditSummary(
                  title: LocaleKeys.Lost.tr(),
                  amount: lost,
                  color: Colors.red,
                  icon: Icons.trending_down,
                ),
              ),
            ],
          ),
          // Transactions list
          if (transactions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(
              color: AppColors.text.withValues(alpha: 0.1),
              height: 1,
            ),
            const SizedBox(height: 12),
            Text(
              LocaleKeys.Transactions.tr(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.text.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  final isEarn = transaction['type'] == 'earn';
                  final amount = transaction['amount'] as double;
                  final taskTitle = transaction['taskTitle'] as String;
                  final icon = transaction['icon'] as IconData;
                  final time = transaction['time'] as DateTime;
                  final taskId = transaction['taskId'] as int?;
                  final taskDuration = transaction['taskDuration'] as Duration?;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: taskId != null
                          ? () {
                              try {
                                final task = TaskProvider().taskList.firstWhere((t) => t.id == taskId);
                                // Rutin tasksa, rutin detay sayfasına git
                                if (task.routineID != null) {
                                  NavigatorService().goTo(RoutineDetailPage(taskModel: task));
                                } else {
                                  // Normal task ise, edit sayfasına git
                                  NavigatorService().goTo(AddTaskPage(editTask: task));
                                }
                              } catch (e) {
                                LogService.debug('Error navigating to task detail: $e');
                              }
                            }
                          : null,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (isEarn ? Colors.green : Colors.red).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              icon,
                              size: 18,
                              color: isEarn ? Colors.green : Colors.red,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  taskTitle,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Row(
                                  children: [
                                    Text(
                                      DateFormat('HH:mm').format(time),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.text.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    if (taskDuration != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '• ${taskDuration.inHours}h ${taskDuration.inMinutes % 60}m',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.text.withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ]
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${isEarn ? '+' : '-'}${amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isEarn ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  LocaleKeys.NoTransactions.tr(),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.text.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final creditData = _calculateCreditsForDate(_selectedDate);
    final earned = creditData['earned'] as double;
    final lost = creditData['lost'] as double;

    return GestureDetector(
      onTap: () {
        // Dialog açılmadan önce cache'i güncelleyelim
        _loadStoreItemLogsCache();
        showDialog(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setState) {
              final creditDataDialog = _calculateCreditsForDate(_selectedDate);
              final earnedDialog = creditDataDialog['earned'] as double;
              final lostDialog = creditDataDialog['lost'] as double;
              final transactionsDialog = creditDataDialog['transactions'] as List<Map<String, dynamic>>;

              return AlertDialog(
                scrollable: true,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        setState(() {
                          _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                        });
                      },
                    ),
                    Text(DateFormat('dd.MM.yyyy').format(_selectedDate)),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: _selectedDate.day == DateTime.now().day && _selectedDate.month == DateTime.now().month && _selectedDate.year == DateTime.now().year
                          ? null
                          : () {
                              setState(() {
                                _selectedDate = _selectedDate.add(const Duration(days: 1));
                              });
                            },
                    ),
                  ],
                ),
                content: _buildDialogContent(earnedDialog, lostDialog, transactionsDialog),
              );
            },
          ),
        );
      },
      child: Row(
        children: [
          const SizedBox(width: 8),
          // Earn badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.trending_up, size: 14, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  earned.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Loss badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.trending_down, size: 14, color: Colors.red),
                const SizedBox(width: 4),
                Text(
                  lost.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditSummary({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${amount.toStringAsFixed(2)} 💰',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
