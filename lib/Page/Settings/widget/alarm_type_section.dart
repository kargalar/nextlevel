import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/alarm_sound_service.dart';
import 'package:next_level/Service/logging_service.dart';

class AlarmTypeSection extends StatelessWidget {
  final String title;
  final String description;
  final AlarmType alarmType;
  final String selectedSoundId;
  final String? playingSoundId;
  final Function(String) onPlayPreview;
  final Function(String, AlarmType) onSelectSound;

  const AlarmTypeSection({
    super.key,
    required this.title,
    required this.description,
    required this.alarmType,
    required this.selectedSoundId,
    required this.playingSoundId,
    required this.onPlayPreview,
    required this.onSelectSound,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.text.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        ...AlarmSoundService.availableSounds.map((sound) {
          final isSelected = selectedSoundId == sound.id;
          final isPlaying = playingSoundId == sound.id;

          // Debug: Log state for each sound
          if (isPlaying) {
            LogService.debug('AlarmTypeSection: UI - Sound ${sound.id} is PLAYING, showing STOP icon');
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Container(
              decoration: BoxDecoration(
                color: isPlaying ? AppColors.dirtyRed.withValues(alpha: 0.1) : (isSelected ? AppColors.main.withValues(alpha: 0.1) : AppColors.panelBackground),
                borderRadius: AppColors.borderRadiusAll,
                border: isPlaying ? Border.all(color: AppColors.dirtyRed, width: 2) : (isSelected ? Border.all(color: AppColors.main, width: 2) : null),
              ),
              child: ListTile(
                dense: true,
                leading: IconButton(
                  icon: Icon(
                    isPlaying ? Icons.stop_circle : Icons.play_circle,
                    color: isPlaying ? AppColors.dirtyRed : AppColors.main,
                    size: 32,
                  ),
                  onPressed: () async {
                    await onPlayPreview(sound.id);
                  },
                  tooltip: isPlaying ? 'Stop preview' : 'Play preview',
                ),
                title: Text(
                  sound.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.main : AppColors.text,
                  ),
                ),
                subtitle: Text(
                  sound.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.text.withValues(alpha: 0.6),
                  ),
                ),
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle,
                        color: AppColors.main,
                        size: 20,
                      )
                    : const SizedBox(width: 20), // Placeholder for alignment
                onTap: () async {
                  await onSelectSound(sound.id, alarmType);
                },
              ),
            ),
          );
        }),
      ],
    );
  }
}
