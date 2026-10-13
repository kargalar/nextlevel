import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';

class SectionPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool showDivider;
  final Widget? trailing; // optional trailing widget in header

  const SectionPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.showDivider = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.main, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (showDivider)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(
                color: AppColors.text.withValues(alpha: 0.1),
                height: 1,
              ),
            ),
          child,
        ],
      ),
    );
  }
}
