import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/alarm_sound_service.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Page/Settings/widget/alarm_type_section.dart';
import 'package:just_audio/just_audio.dart';

/// Alarm sound selection dialog
class AlarmSoundSelectionDialog extends StatefulWidget {
  const AlarmSoundSelectionDialog({super.key});

  @override
  State<AlarmSoundSelectionDialog> createState() =>
      _AlarmSoundSelectionDialogState();
}

class _AlarmSoundSelectionDialogState extends State<AlarmSoundSelectionDialog> {
  final AlarmSoundService _alarmSoundService = AlarmSoundService();
  String _selectedItemSoundId = AlarmSoundService.defaultSoundId;
  String _selectedScheduledSoundId = AlarmSoundService.defaultSoundId;
  String _selectedTimerSoundId = AlarmSoundService.defaultSoundId;
  bool _isLoading = true;
  String? _playingSoundId; // Track which sound is currently playing

  // Audio player for preview (no notification!)
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadSelectedSounds();
    LogService.debug('AlarmSoundSelectionDialog: Initialized');
  }

  @override
  void dispose() {
    // Stop and dispose audio player
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadSelectedSounds() async {
    try {
      final itemSoundId =
          await _alarmSoundService.getSelectedSoundId(AlarmType.item);
      final scheduledSoundId =
          await _alarmSoundService.getSelectedSoundId(AlarmType.scheduled);
      final timerSoundId =
          await _alarmSoundService.getSelectedSoundId(AlarmType.timer);

      if (mounted) {
        setState(() {
          _selectedItemSoundId = itemSoundId;
          _selectedScheduledSoundId = scheduledSoundId;
          _selectedTimerSoundId = timerSoundId;
          _isLoading = false;
        });
      }
      LogService.debug('AlarmSoundSelectionDialog: All alarm sounds loaded');
      LogService.debug(
          '  Item: $itemSoundId, Scheduled: $scheduledSoundId, Timer: $timerSoundId');
    } catch (e) {
      LogService.error('AlarmSoundSelectionDialog: Error loading sounds: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectSound(String soundId, AlarmType type) async {
    try {
      await _alarmSoundService.saveSelectedSound(soundId, type);
      if (mounted) {
        setState(() {
          switch (type) {
            case AlarmType.item:
              _selectedItemSoundId = soundId;
              break;
            case AlarmType.scheduled:
              _selectedScheduledSoundId = soundId;
              break;
            case AlarmType.timer:
              _selectedTimerSoundId = soundId;
              break;
          }
        });
      }

      final soundName = _alarmSoundService.getSoundById(soundId).name;
      LogService.debug(
          'AlarmSoundSelectionDialog: Sound selected for ${type.name}: $soundId');

      // Success message
      Helper().getMessage(
        message: '$soundName selected for ${_getTypeDisplayName(type)}',
        status: StatusEnum.SUCCESS,
      );
    } catch (e) {
      LogService.error('AlarmSoundSelectionDialog: Error selecting sound: $e');
    }
  }

  Future<void> _playPreview(String soundId) async {
    try {
      // If same sound is playing, stop it
      if (_playingSoundId == soundId) {
        await _stopPreview();
        return;
      }

      // Stop any currently playing preview
      await _stopPreview();

      // Get the sound file path
      final sound = _alarmSoundService.getSoundById(soundId);
      // Ensure full asset path is used. 'assets/' prefix is required for setAsset
      final soundPath = 'assets/sounds/${sound.fileName}';

      LogService.debug(
          'AlarmSoundSelectionDialog: Starting preview for: $soundId, path: $soundPath');

      // Update state IMMEDIATELY to show stop icon
      if (mounted) {
        setState(() {
          _playingSoundId = soundId;
        });
      }

      // Play audio using just_audio (NO NOTIFICATION!)
      // Explicitly stop and reset to ensure no caching issues
      await _audioPlayer.stop();
      await _audioPlayer.seek(Duration.zero);

      // Load the new asset
      await _audioPlayer.setAsset(soundPath);
      await _audioPlayer.setLoopMode(LoopMode.one); // Loop the sound
      await _audioPlayer.play();

      LogService.debug(
          'AlarmSoundSelectionDialog: ✓ Preview playing (sound only, NO notification): $soundId');

      // Auto-stop after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (_playingSoundId == soundId && mounted) {
          _stopPreview();
        }
      });
    } catch (e) {
      LogService.error(
          'AlarmSoundSelectionDialog: ✗ Error playing preview: $e');

      // Reset state on error
      if (mounted) {
        setState(() {
          _playingSoundId = null;
        });

        Helper().getMessage(
          message: 'Error playing sound: $e',
          status: StatusEnum.WARNING,
        );
      }
    }
  }

  Future<void> _stopPreview() async {
    try {
      if (_playingSoundId != null) {
        LogService.debug(
            'AlarmSoundSelectionDialog: Stopping preview for: $_playingSoundId');
      }

      await _audioPlayer.stop();

      if (mounted) {
        setState(() {
          _playingSoundId = null;
        });
      }

      LogService.debug('AlarmSoundSelectionDialog: ✓ Preview stopped');
    } catch (e) {
      LogService.error(
          'AlarmSoundSelectionDialog: ✗ Error stopping preview: $e');
      // Force reset state even on error
      if (mounted) {
        setState(() {
          _playingSoundId = null;
        });
      }
    }
  }

  String _getTypeDisplayName(AlarmType type) {
    switch (type) {
      case AlarmType.item:
        return 'Task Items';
      case AlarmType.scheduled:
        return 'Scheduled Tasks';
      case AlarmType.timer:
        return 'Timer Completed';
    }
  }

  String _getSelectedSoundId(AlarmType type) {
    switch (type) {
      case AlarmType.item:
        return _selectedItemSoundId;
      case AlarmType.scheduled:
        return _selectedScheduledSoundId;
      case AlarmType.timer:
        return _selectedTimerSoundId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      title: Row(
        children: [
          Icon(Icons.music_note, color: AppColors.main),
          const SizedBox(width: 8),
          const Text(
            'Alarm Sound Selection',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Alarm Section
                  AlarmTypeSection(
                    title: '🎯 Task Items',
                    description: 'Alarm sound for regular task items',
                    alarmType: AlarmType.item,
                    selectedSoundId: _getSelectedSoundId(AlarmType.item),
                    playingSoundId: _playingSoundId,
                    onPlayPreview: _playPreview,
                    onSelectSound: _selectSound,
                  ),
                  const SizedBox(height: 20),

                  // Scheduled Alarm Section
                  AlarmTypeSection(
                    title: '📅 Scheduled Tasks',
                    description: 'Alarm sound for scheduled tasks',
                    alarmType: AlarmType.scheduled,
                    selectedSoundId: _getSelectedSoundId(AlarmType.scheduled),
                    playingSoundId: _playingSoundId,
                    onPlayPreview: _playPreview,
                    onSelectSound: _selectSound,
                  ),
                  const SizedBox(height: 20),

                  // Timer Alarm Section
                  AlarmTypeSection(
                    title: '⏱️ Timer Completed',
                    description:
                        'Alarm sound when timer reaches target duration',
                    alarmType: AlarmType.timer,
                    selectedSoundId: _getSelectedSoundId(AlarmType.timer),
                    playingSoundId: _playingSoundId,
                    onPlayPreview: _playPreview,
                    onSelectSound: _selectSound,
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () async {
            // Stop any playing preview before closing
            await _stopPreview();
            if (context.mounted) {
              Navigator.of(context).pop();
            }
            LogService.debug('AlarmSoundSelectionDialog: Dialog closed');
          },
          child: Text(
            LocaleKeys.Close.tr(),
            style: TextStyle(color: AppColors.main),
          ),
        ),
      ],
    );
  }
}
