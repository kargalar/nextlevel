import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';

/// Loading dialog that cannot be dismissed by back button
/// Shows a loading indicator with a message
class LoadingDialog extends StatelessWidget {
  final String message;
  final String? subtitle;

  const LoadingDialog({
    super.key,
    required this.message,
    this.subtitle,
  });

  /// Show the loading dialog
  static void show(
    BuildContext context, {
    required String message,
    String? subtitle,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false, // Cannot dismiss by tapping outside
      builder: (BuildContext context) {
        return PopScope(
          canPop: false, // Cannot dismiss by back button
          child: LoadingDialog(
            message: message,
            subtitle: subtitle,
          ),
        );
      },
    );
  }

  /// Hide the loading dialog
  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Loading indicator
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.main),
              ),
            ),
            const SizedBox(height: 24),

            // Main message
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
              textAlign: TextAlign.center,
            ),

            // Subtitle if provided
            if (subtitle != null) ...[
              const SizedBox(height: 12),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.text.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
