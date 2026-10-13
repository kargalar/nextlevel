import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/General/date_formatter.dart';
import 'package:next_level/Service/locale_keys.g.dart';

class InboxDateHeader extends StatelessWidget {
  final DateTime date;

  const InboxDateHeader({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));

    String dateText;
    Color? backgroundColor;
    Color? textColor;

    if (date.year == 1969 && date.month == 1 && date.day == 1) {
      dateText = "Overdue"; // Special case for overdue tasks
      backgroundColor = const Color.fromARGB(255, 214, 121, 0).withValues(alpha: 0.1);
      textColor = const Color.fromARGB(255, 255, 123, 0);
    } else if (date.year == 1970 && date.month == 1 && date.day == 1) {
      dateText = "Inbox"; // Special case for tasks without dates
    } else if (date.isAtSameMomentAs(today)) {
      dateText = LocaleKeys.Today.tr();
    } else if (date.isAtSameMomentAs(tomorrow)) {
      dateText = LocaleKeys.Tomorrow.tr();
    } else if (date.isAtSameMomentAs(yesterday)) {
      dateText = LocaleKeys.Yesterday.tr();
    } else {
      dateText = DateFormatter.formatDate(date);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.panelBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        dateText,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: textColor ?? AppColors.text.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
