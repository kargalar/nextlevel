// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:next_level/Service/logging_service.dart';

class AddManualLogDialog extends StatefulWidget {
  final TaskModel taskModel;

  const AddManualLogDialog({
    super.key,
    required this.taskModel,
  });

  @override
  State<AddManualLogDialog> createState() => _AddManualLogDialogState();
}

class _AddManualLogDialogState extends State<AddManualLogDialog> {
  late DateTime selectedDateTime = DateTime.now();

  // Progress değerleri
  int count = 1;
  int hours = 0;
  int minutes = 15; // Default 15 dakika

  // Durum değeri
  TaskStatusEnum selectedStatus = TaskStatusEnum.DONE;

  @override
  void initState() {
    super.initState();
    _loadLastValues();
  }

  Future<void> _loadLastValues() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (widget.taskModel.type == TaskTypeEnum.TIMER) {
        final lastDuration = prefs.getString('last_logged_duration_${widget.taskModel.id}');
        if (lastDuration != null) {
          final seconds = int.tryParse(lastDuration) ?? 0;
          setState(() {
            hours = seconds ~/ 3600;
            minutes = (seconds % 3600) ~/ 60;
          });
          LogService.debug('✅ Manuel log: Son kaydedilen süre yüklendi - $hours saat $minutes dakika');
        }
      } else if (widget.taskModel.type == TaskTypeEnum.COUNTER) {
        final lastCount = prefs.getInt('last_logged_count_${widget.taskModel.id}');
        if (lastCount != null) {
          setState(() {
            count = lastCount;
          });
          LogService.debug('✅ Manuel log: Son kaydedilen count yüklendi - $count');
        }
      }
    } catch (e) {
      LogService.error('❌ Manuel log: Son değerler yüklenirken hata - $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        LocaleKeys.AddManualLog.tr(),
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tarih ve Saat seçimi (her zaman göster)
              _buildSectionTitle(LocaleKeys.DateAndTime.tr()),
              const SizedBox(height: 8),
              _buildDateTimeSelector(),
              const SizedBox(height: 20),

              // Durum seçimi (sadece checkbox için)
              if (widget.taskModel.type == TaskTypeEnum.CHECKBOX) ...[
                _buildSectionTitle(LocaleKeys.Status.tr()),
                const SizedBox(height: 8),
                _buildStatusSelector(),
                const SizedBox(height: 20),
              ],

              // İlerleme girişi (task tipine göre)
              if (widget.taskModel.type != TaskTypeEnum.CHECKBOX) ...[
                _buildSectionTitle(LocaleKeys.Progress.tr()),
                const SizedBox(height: 12),
                if (widget.taskModel.type == TaskTypeEnum.COUNTER) _buildCounterSelector(),
                if (widget.taskModel.type == TaskTypeEnum.TIMER) _buildTimerSelector(),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            LocaleKeys.Cancel.tr(),
            style: const TextStyle(fontSize: 16),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            await _addManualLog();
            if (context.mounted) {
              Navigator.of(context).pop(true);
            }
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            LocaleKeys.Add.tr(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }

  Widget _buildDateTimeSelector() {
    return InkWell(
      onTap: () async {
        // Önce tarih seç
        final date = await Helper().selectDate(
          context: context,
          initialDate: selectedDateTime,
        );
        if (date != null && context.mounted) {
          // !!!!!!! Saat seçmesin direkt şuanki saati alsın.
          // Sonra saat seç
          final result = await Helper().selectTime(
            context,
            initialTime: TimeOfDay.fromDateTime(selectedDateTime),
          );
          if (result != null) {
            final TimeOfDay time = result['time'] as TimeOfDay;
            final bool dateChanged = result['dateChanged'] as bool;

            setState(() {
              selectedDateTime = DateTime(
                date.year,
                date.month,
                date.day,
                time.hour,
                time.minute,
              );

              // Eğer tarih değiştiyse +1 gün ekle
              if (dateChanged) {
                selectedDateTime = selectedDateTime.add(const Duration(days: 1));
              }
            });
            LogService.debug('✅ Manuel log: Tarih ve saat seçildi - ${DateFormat('d MMMM yyyy HH:mm').format(selectedDateTime)}${dateChanged ? ' (+1 gün)' : ''}');
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.panelBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('d MMMM yyyy').format(selectedDateTime),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(selectedDateTime),
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.calendar_month, size: 24, color: AppColors.main),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TaskStatusEnum>(
          value: selectedStatus,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: AppColors.main),
          items: [
            DropdownMenuItem(
              value: TaskStatusEnum.DONE,
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 12),
                  Text(LocaleKeys.Done.tr(), style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
            DropdownMenuItem(
              value: TaskStatusEnum.FAILED,
              child: Row(
                children: [
                  const Icon(Icons.cancel, color: Colors.red, size: 20),
                  const SizedBox(width: 12),
                  Text(LocaleKeys.Failed.tr(), style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
            DropdownMenuItem(
              value: TaskStatusEnum.CANCEL,
              child: Row(
                children: [
                  const Icon(Icons.block, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Text(LocaleKeys.Cancelled.tr(), style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedStatus = value;
              });
              LogService.debug('✅ Manuel log: Durum değişti - $value');
            }
          },
        ),
      ),
    );
  }

  Widget _buildCounterSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Azalt butonu
          _buildCounterButton(
            icon: Icons.remove,
            onPressed: () {
              if (count > 1) {
                setState(() {
                  count--;
                });
                LogService.debug('✅ Manuel log: Count azaltıldı - $count');
              }
            },
            enabled: count > 1,
          ),

          // Sayı gösterimi
          Expanded(
            child: Center(
              child: Column(
                children: [
                  Text(
                    count.toString(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    LocaleKeys.Count.tr(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Artır butonu
          _buildCounterButton(
            icon: Icons.add,
            onPressed: () {
              setState(() {
                count++;
              });
              LogService.debug('✅ Manuel log: Count artırıldı - $count');
            },
            enabled: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimerSelector() {
    return Column(
      children: [
        // Saat seçici
        _buildTimeInputRow(
          label: LocaleKeys.Hours.tr(),
          value: hours,
          onDecrease: () {
            if (hours > 0) {
              setState(() {
                hours--;
              });
              LogService.debug('✅ Manuel log: Saat azaltıldı - $hours');
            }
          },
          onIncrease: () {
            if (hours < 23) {
              setState(() {
                hours++;
              });
              LogService.debug('✅ Manuel log: Saat artırıldı - $hours');
            }
          },
        ),
        const SizedBox(height: 12),
        // Dakika seçici
        _buildTimeInputRow(
          label: LocaleKeys.Minutes.tr(),
          value: minutes,
          onDecrease: () {
            if (minutes > 0) {
              setState(() {
                minutes = (minutes - 5).clamp(0, 59);
              });
              LogService.debug('✅ Manuel log: Dakika azaltıldı - $minutes');
            }
          },
          onIncrease: () {
            if (minutes < 59) {
              setState(() {
                minutes = (minutes + 5).clamp(0, 59);
              });
              LogService.debug('✅ Manuel log: Dakika artırıldı - $minutes');
            }
          },
        ),
        const SizedBox(height: 12),
        // Toplam süre gösterimi
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            '${LocaleKeys.TotalTime.tr()}: ${_formatDuration(Duration(hours: hours, minutes: minutes))}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.main,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeInputRow({
    required String label,
    required int value,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Label
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),

          // Azalt butonu
          _buildCounterButton(
            icon: Icons.remove,
            onPressed: onDecrease,
            enabled: value > 0,
            size: 36,
          ),

          // Değer gösterimi
          Container(
            width: 60,
            alignment: Alignment.center,
            child: Text(
              value.toString().padLeft(2, '0'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Artır butonu
          _buildCounterButton(
            icon: Icons.add,
            onPressed: onIncrease,
            enabled: true,
            size: 36,
          ),
        ],
      ),
    );
  }

  Widget _buildCounterButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool enabled,
    double size = 48,
  }) {
    return Material(
      color: enabled ? AppColors.main : Colors.grey.shade300,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: enabled ? Colors.white : Colors.grey.shade500,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '$hours ${LocaleKeys.Hours.tr().toLowerCase()} $minutes ${LocaleKeys.Minutes.tr().toLowerCase()}';
    }
    return '$minutes ${LocaleKeys.Minutes.tr().toLowerCase()}';
  }

  Future<void> _addManualLog() async {
    try {
      // Seçilen tarih/saati kullan (rutin olup olmadığına bakmaksızın)
      final now = DateTime.now();
      final logDateTime = DateTime(
        selectedDateTime.year,
        selectedDateTime.month,
        selectedDateTime.day,
        selectedDateTime.hour,
        selectedDateTime.minute,
        now.second,
        now.millisecond,
      );

      // Task tipine göre ilerleme değerini ayarla
      Duration? duration;
      int? countValue;

      if (widget.taskModel.type == TaskTypeEnum.TIMER) {
        duration = Duration(hours: hours, minutes: minutes);

        // Timer için son loglanan süreyi SharedPreferences'a kaydet
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_logged_duration_${widget.taskModel.id}', duration.inSeconds.toString());
        LogService.debug('✅ Manuel log: Timer değeri kaydedildi - ${duration.inMinutes} dakika');
      } else if (widget.taskModel.type == TaskTypeEnum.COUNTER) {
        countValue = count;

        // Counter için son loglanan sayıyı SharedPreferences'a kaydet
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('last_logged_count_${widget.taskModel.id}', count);
        LogService.debug('✅ Manuel log: Counter değeri kaydedildi - $count');
      }

      // Status kontrolü: Hedefe ulaşılmış mı?
      TaskStatusEnum logStatus;

      if (widget.taskModel.type == TaskTypeEnum.CHECKBOX) {
        // Checkbox için kullanıcının seçtiği status'u kullan
        logStatus = selectedStatus;
      } else if (widget.taskModel.type == TaskTypeEnum.TIMER) {
        // Timer için: Mevcut tüm logların toplamı + bu log >= hedef mi?
        final existingLogs = TaskLogProvider().getLogsByTaskId(widget.taskModel.id);
        Duration totalDuration = Duration.zero;
        for (var log in existingLogs) {
          if (log.duration != null) {
            totalDuration += log.duration!;
          }
        }
        // Yeni log'u da ekle
        totalDuration += duration!;

        // Hedefe ulaşıldı mı kontrol et
        if (widget.taskModel.remainingDuration != null && totalDuration >= widget.taskModel.remainingDuration!) {
          logStatus = TaskStatusEnum.DONE;
          LogService.debug('✅ Timer: Hedefe ulaşıldı! ${totalDuration.inMinutes}/${widget.taskModel.remainingDuration!.inMinutes} dakika');
        } else {
          logStatus = TaskStatusEnum.DONE; // Her log Done olarak kaydedilir ama task InProgress olabilir
          LogService.debug('⏳ Timer: Hedefe henüz ulaşılmadı. ${totalDuration.inMinutes}/${widget.taskModel.remainingDuration?.inMinutes ?? 0} dakika');
        }
      } else if (widget.taskModel.type == TaskTypeEnum.COUNTER) {
        // Counter için: Mevcut tüm logların toplamı + bu log >= hedef mi?
        final existingLogs = TaskLogProvider().getLogsByTaskId(widget.taskModel.id);
        int totalCount = 0;
        for (var log in existingLogs) {
          if (log.count != null) {
            totalCount += log.count!;
          }
        }
        // Yeni log'u da ekle
        totalCount += countValue!;

        // Hedefe ulaşıldı mı kontrol et
        if (widget.taskModel.targetCount != null && totalCount >= widget.taskModel.targetCount!) {
          logStatus = TaskStatusEnum.DONE;
          LogService.debug('✅ Counter: Hedefe ulaşıldı! $totalCount/${widget.taskModel.targetCount} adet');
        } else {
          logStatus = TaskStatusEnum.DONE; // Her log Done olarak kaydedilir ama task InProgress olabilir
          LogService.debug('⏳ Counter: Hedefe henüz ulaşılmadı. $totalCount/${widget.taskModel.targetCount ?? 0} adet');
        }
      } else {
        logStatus = TaskStatusEnum.DONE;
      }

      LogService.debug('✅ Manuel log ekleniyor: ${widget.taskModel.title}');
      LogService.debug('   Tarih: ${DateFormat('d MMMM yyyy HH:mm').format(logDateTime)}');
      LogService.debug('   Durum: $logStatus');
      LogService.debug('   Rutin ID: ${widget.taskModel.routineID ?? "Rutin değil"}');
      if (duration != null) LogService.debug('   Süre: ${duration.inMinutes} dakika');
      if (countValue != null) LogService.debug('   Count: $countValue');

      await TaskLogProvider().addTaskLog(
        widget.taskModel,
        customLogDate: logDateTime,
        customDuration: duration, // Manuel girilen süre doğrudan log olarak kaydedilir
        customCount: countValue, // Manuel girilen sayı doğrudan log olarak kaydedilir
        customStatus: logStatus,
        adjustCredit: true,
      );

      LogService.debug('✅ Manuel log başarıyla eklendi!');
    } catch (e) {
      LogService.error('❌ Manuel log eklenirken hata oluştu: $e');
    }
  }
}
