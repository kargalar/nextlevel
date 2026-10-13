import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/streak_settings_provider.dart';

class StreakTargetDialog extends StatefulWidget {
  const StreakTargetDialog({super.key});

  @override
  State<StreakTargetDialog> createState() => _StreakTargetDialogState();
}

class _StreakTargetDialogState extends State<StreakTargetDialog> {
  late final StreakSettingsProvider _streakProvider;
  late double _selectedHours;

  @override
  void initState() {
    super.initState();
    _streakProvider = StreakSettingsProvider();
    _selectedHours = _streakProvider.streakMinimumHours;
    debugPrint('StreakTargetDialog initialized with $_selectedHours hours');
  }

  void _updateHours(double newValue) {
    setState(() {
      _selectedHours = newValue;
      debugPrint('Hours updated to: $_selectedHours');
    });
  }

  void _saveStreakTarget() {
    debugPrint('Saving streak target: $_selectedHours hours');
    _streakProvider.setStreakMinimumHours(_selectedHours);
    Navigator.of(context).pop(true); // Return true to indicate success

    // Show success message
    Helper().getMessage(
      message: 'Streak target updated to ${_selectedHours.toStringAsFixed(1)} hours',
      status: StatusEnum.SUCCESS,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.white, width: 1),
      ),
      title: _buildTitle(),
      content: _buildContent(),
      actions: _buildActions(),
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.main.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.local_fire_department_rounded,
            color: AppColors.main,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          "Streak Target",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Set the minimum hours needed to maintain your daily streak.",
          style: TextStyle(
            fontSize: 14,
            color: AppColors.text.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 24),
        _buildHoursDisplay(),
        const SizedBox(height: 16),
        _buildHoursSlider(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHoursDisplay() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.main.withValues(alpha: 0.2),
              AppColors.main.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.main.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.access_time_rounded,
              color: AppColors.main,
              size: 32,
            ),
            const SizedBox(width: 12),
            Text(
              _selectedHours.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppColors.main,
                height: 1,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Hours'.tr().toLowerCase(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.text.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoursSlider() {
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.main,
            inactiveTrackColor: AppColors.main.withValues(alpha: 0.2),
            thumbColor: AppColors.main,
            overlayColor: AppColors.main.withValues(alpha: 0.2),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
          ),
          child: Slider(
            value: _selectedHours,
            min: 0.0,
            max: 12.0,
            divisions: 24,
            label: _selectedHours.toStringAsFixed(1),
            onChanged: _updateHours,
          ),
        ),
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //   children: [
        //     Text(
        //       '0h',
        //       style: TextStyle(
        //         fontSize: 12,
        //         color: AppColors.text.withValues(alpha: 0.6),
        //       ),
        //     ),
        //     Text(
        //       '12h',
        //       style: TextStyle(
        //         fontSize: 12,
        //         color: AppColors.text.withValues(alpha: 0.6),
        //       ),
        //     ),
        //   ],
        // ),
      ],
    );
  }

  List<Widget> _buildActions() {
    return [
      TextButton(
        onPressed: () {
          debugPrint('Streak target dialog cancelled');
          Navigator.of(context).pop(false);
        },
        child: Text(
          'Cancel'.tr(),
          style: TextStyle(color: AppColors.text.withValues(alpha: 0.7)),
        ),
      ),
      ElevatedButton(
        onPressed: _saveStreakTarget,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.main,
          foregroundColor: AppColors.white,
        ),
        child: const Text("Save"),
      ),
    ];
  }
}
