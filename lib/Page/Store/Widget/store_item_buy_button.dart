import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/locale_keys.g.dart';

/// Buy/add CTA for store items with an optional credit badge.
class StoreItemBuyButton extends StatelessWidget {
  final String amountText;
  final int credit;
  final VoidCallback onTap;

  const StoreItemBuyButton({
    super.key,
    required this.amountText,
    required this.credit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final actionText = credit == 0 ? LocaleKeys.Add.tr() : LocaleKeys.Buy.tr();

    return Semantics(
      button: true,
      label: '$actionText $amountText',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            height: 40,
            constraints: const BoxConstraints(minWidth: 104, maxWidth: 160),
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              color: AppColors.main,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.lightMain.withValues(alpha: 0.18)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.main.withValues(alpha: 0.22),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    credit == 0
                        ? Icons.add_rounded
                        : Icons.shopping_bag_outlined,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$actionText $amountText',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.15,
                    ),
                    maxLines: 1,
                  ),
                  if (credit != 0) ...[
                    const SizedBox(width: 7),
                    _buildCreditBadge(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreditBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.deepMain.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$credit',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 2),
          const Icon(
            Icons.monetization_on_rounded,
            size: 12,
            color: Color(0xFFFFD600),
          ),
        ],
      ),
    );
  }
}
