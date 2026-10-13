import 'package:next_level/Widgets/Common/duration_picker/duration_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/locale_keys.g.dart';

class LogResult {
  final dynamic value;
  final DateTime date;
  LogResult(this.value, this.date);
}

class LogBottomSheet extends StatefulWidget {
  final TaskTypeEnum type;
  final dynamic initialValue;
  final DateTime? initialDate;
  final bool isEdit;

  const LogBottomSheet({
    super.key,
    required this.type,
    this.initialValue,
    this.initialDate,
    this.isEdit = false,
  });

  @override
  State<LogBottomSheet> createState() => _LogBottomSheetState();
}

class _LogBottomSheetState extends State<LogBottomSheet> {
  late dynamic _value;
  late TextEditingController _counterController;
  late DateTime _selectedDate;
  late bool _canPop;

  int _parseCounterValue(dynamic rawValue) {
    if (rawValue is int) return rawValue;
    if (rawValue is num) return rawValue.toInt();
    if (rawValue is String) {
      return int.tryParse(rawValue.replaceAll('+', '').trim()) ?? 0;
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _canPop = !widget.isEdit;
    _selectedDate = widget.initialDate ?? DateTime.now();
    if (widget.type == TaskTypeEnum.COUNTER) {
      _value = _parseCounterValue(widget.initialValue);
      _counterController = TextEditingController(text: _value == 0 && !widget.isEdit ? '' : _value.toString());
      if (_value > 0 && !widget.isEdit) {
        _counterController.text = "+$_value";
      }
    } else if (widget.type == TaskTypeEnum.CHECKBOX) {
      _value = widget.initialValue ?? TaskStatusEnum.DONE;
    } else {
      _value = widget.initialValue ?? const Duration(minutes: 30);
    }
  }

  @override
  void dispose() {
    if (widget.type == TaskTypeEnum.COUNTER) {
      _counterController.dispose();
    }
    super.dispose();
  }

  LogResult? _getLogResult() {
    if (widget.type == TaskTypeEnum.COUNTER) {
      if (_counterController.text.trim().isEmpty) return null;
      try {
        int val = int.parse(_counterController.text.replaceAll('+', ''));
        return LogResult(val, _selectedDate);
      } catch (e) {
        return null;
      }
    } else {
      return LogResult(_value, _selectedDate);
    }
  }

  void _onSave() {
    final result = _getLogResult();
    if (result != null) {
      Navigator.pop(context, result);
    } else {
      Helper().getMessage(message: LocaleKeys.InvalidFormat.tr(), status: StatusEnum.WARNING);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<dynamic>(
      canPop: _canPop,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        setState(() {
          _canPop = true;
        });

        await Future.delayed(Duration.zero);
        if (!context.mounted) return;

        if (result == 'DELETE') {
          Navigator.pop(context, 'DELETE');
        } else {
          final logResult = _getLogResult();
          if (logResult != null) {
            Navigator.pop(context, logResult);
          } else {
            Navigator.pop(context, null);
          }
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.isEdit ? LocaleKeys.EditLog.tr() : LocaleKeys.Add.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (widget.type == TaskTypeEnum.COUNTER) _buildCounterInput() else if (widget.type == TaskTypeEnum.CHECKBOX) _buildCheckboxInput() else _buildTimerInput(),
            const SizedBox(height: 20),
            InkWell(
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: Theme.of(context).colorScheme.copyWith(
                              primary: AppColors.main, // header background color
                            ),
                        textButtonTheme: TextButtonThemeData(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.main, // button text color
                          ),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (pickedDate != null) {
                  setState(() => _selectedDate = pickedDate);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.main.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMM dd, yyyy').format(_selectedDate),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.text),
                    ),
                    Icon(Icons.calendar_today, color: AppColors.main),
                  ],
                ),
              ),
            ),
            if (!widget.isEdit) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.main,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  LocaleKeys.Save.tr(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
            if (widget.isEdit) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context, 'DELETE'),
                child: Text(
                  LocaleKeys.Delete.tr(),
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxInput() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      children: [TaskStatusEnum.DONE, TaskStatusEnum.CANCEL, TaskStatusEnum.FAILED].map((status) {
        String label = '';
        Color color = Colors.grey;

        switch (status) {
          case TaskStatusEnum.DONE:
            label = LocaleKeys.Done.tr();
            color = AppColors.green;
            break;
          case TaskStatusEnum.CANCEL:
            label = LocaleKeys.Cancel.tr();
            color = AppColors.orange;
            break;
          case TaskStatusEnum.FAILED:
            label = LocaleKeys.Failed.tr();
            color = AppColors.red;
            break;
          default:
            break;
        }

        final isSelected = _value == status;

        return ChoiceChip(
          label: Text(label),
          showCheckmark: false,
          selected: isSelected,
          selectedColor: color,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _value = status;
              });
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildCounterInput() {
    return Column(
      children: [
        TextField(
          controller: _counterController,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          autofocus: true,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: '+1',
            hintStyle: TextStyle(color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.main),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.main, width: 2),
            ),
            filled: true,
            fillColor: AppColors.panelBackground,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _quickAddButton(-1),
            const SizedBox(width: 8),
            _quickAddButton(1),
            const SizedBox(width: 8),
            _quickAddButton(5),
          ],
        ),
      ],
    );
  }

  Widget _quickAddButton(int change) {
    String label = change > 0 ? '+$change' : '$change';
    return ActionChip(
      label: Text(label),
      onPressed: () {
        int current = _parseCounterValue(_counterController.text);
        int newVal = current + change;
        String text = newVal > 0 ? '+$newVal' : '$newVal';
        _counterController.text = text;
        // Move cursor to end
        _counterController.selection = TextSelection.fromPosition(TextPosition(offset: _counterController.text.length));
      },
      backgroundColor: AppColors.panelBackground,
      side: BorderSide.none,
    );
  }

  Widget _buildTimerInput() {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: DurationPicker(
            duration: _value,
            baseUnit: BaseUnit.minute,
            onChange: (val) {
              setState(() => _value = val);
            },
            // ignore: deprecated_member_use
            snapToMins: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _formatDuration(_value),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.main,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    bool negative = d.isNegative;
    Duration absD = d.abs();
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(absD.inMinutes.remainder(60));
    // String twoDigitSeconds = twoDigits(absD.inSeconds.remainder(60));
    return "${negative ? "-" : ""}${twoDigits(absD.inHours)}h ${twoDigitMinutes}m";
  }
}
