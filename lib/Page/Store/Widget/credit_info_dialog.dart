import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/locale_keys.g.dart';

class CreditInfoDialog extends StatelessWidget {
  const CreditInfoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.help_outline, color: AppColors.main),
          const SizedBox(width: 8),
          Text(LocaleKeys.HowToEarnCredits.tr()),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleKeys.EarnCreditsDescription.tr(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 16),
            _buildEarnCreditItem(
              Icons.check_box_rounded,
              LocaleKeys.CheckboxTasks.tr(),
              LocaleKeys.CheckboxTasksDesc.tr(),
            ),
            const SizedBox(height: 12),
            _buildEarnCreditItem(
              Icons.add_circle_outline,
              LocaleKeys.CounterTasks.tr(),
              LocaleKeys.CounterTasksDesc.tr(),
            ),
            const SizedBox(height: 12),
            _buildEarnCreditItem(
              Icons.timer_outlined,
              LocaleKeys.TimerTasks.tr(),
              LocaleKeys.TimerTasksDesc.tr(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.main.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.main.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: AppColors.main, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.text,
                        ),
                        children: [
                          TextSpan(
                            text: '${LocaleKeys.CreditRate.tr()}\n',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.main,
                            ),
                          ),
                          TextSpan(
                            text: LocaleKeys.CreditExample.tr(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(LocaleKeys.Understood.tr()),
        ),
      ],
    );
  }

  Widget _buildEarnCreditItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.main.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppColors.main),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.text.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
