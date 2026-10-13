import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';

class DefaultDataDialog {
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: _buildTitle(),
          content: _buildContent(),
          actions: _buildActions(context),
        );
      },
    );
  }

  static Widget _buildTitle() {
    return Row(
      children: [
        Icon(Icons.rocket_launch, color: AppColors.main, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Welcome to Next Level! 🎉',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Would you like to load sample data to explore the app features?',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 16,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeaturesList(),
        const SizedBox(height: 12),
        Text(
          'You can delete these anytime from settings.',
          style: TextStyle(
            color: AppColors.text.withValues(alpha: 0.6),
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  static Widget _buildFeaturesList() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.main.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.main.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sample data includes:',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildFeatureItem('✓ Categories & Tasks'),
          _buildFeatureItem('✓ Projects with notes'),
          _buildFeatureItem('✓ Store items & rewards'),
          _buildFeatureItem('✓ Skills & Attributes'),
          _buildFeatureItem('✓ Daily routines'),
        ],
      ),
    );
  }

  static Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.text.withValues(alpha: 0.85),
          fontSize: 14,
        ),
      ),
    );
  }

  static List<Widget> _buildActions(BuildContext context) {
    return [
      TextButton(
        onPressed: () {
          Navigator.of(context).pop(false);
        },
        child: Text(
          'Skip',
          style: TextStyle(
            color: AppColors.text.withValues(alpha: 0.7),
            fontSize: 16,
          ),
        ),
      ),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.main,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          Navigator.of(context).pop(true);
        },
        child: const Text(
          'Load Sample Data',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ];
  }

  static Widget buildLoadingDialog() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.main),
            const SizedBox(height: 16),
            Text(
              'Loading sample data...',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
