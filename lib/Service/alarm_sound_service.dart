import 'package:shared_preferences/shared_preferences.dart';
import 'package:next_level/Service/logging_service.dart';

/// Alarm sound selection service
class AlarmSoundService {
  static const String defaultSoundId = 'alarm1';
  static const String _itemAlarmSoundKey = 'selected_item_alarm_sound';
  static const String _scheduledAlarmSoundKey =
      'selected_scheduled_alarm_sound';
  static const String _timerAlarmSoundKey = 'selected_timer_alarm_sound';

  /// Available alarm sounds
  static const List<AlarmSound> availableSounds = [
    AlarmSound(
      id: 'alarm1',
      name: 'Di Di Di Dit (Default)',
      fileName: 'alarm1.mp3',
      description: 'Default four-beat alarm sound',
    ),
    AlarmSound(
      id: 'alarm2',
      name: 'Soft Alarm',
      fileName: 'alarm2.mp3',
      description: 'Softer alarm sound',
    ),
    AlarmSound(
      id: 'alarm3',
      name: 'Strong Alarm',
      fileName: 'alarm3.mp3',
      description: 'Stronger and more attention-grabbing',
    ),
  ];

  /// Save selected alarm sound for specific type
  Future<void> saveSelectedSound(String soundId, AlarmType type) async {
    try {
      if (!availableSounds.any((sound) => sound.id == soundId)) {
        throw ArgumentError.value(soundId, 'soundId', 'Unknown alarm sound');
      }
      final prefs = await SharedPreferences.getInstance();
      final key = _getKeyForType(type);
      await prefs.setString(key, soundId);
      LogService.debug(
          'AlarmSoundService: Alarm sound saved for ${type.name}: $soundId');
    } catch (e) {
      LogService.error('AlarmSoundService: Error saving alarm sound: $e');
    }
  }

  /// Get selected alarm sound ID for specific type
  Future<String> getSelectedSoundId(AlarmType type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getKeyForType(type);
      final storedSoundId = prefs.getString(key);
      final soundId = availableSounds.any((sound) => sound.id == storedSoundId)
          ? storedSoundId!
          : defaultSoundId;
      LogService.debug(
          'AlarmSoundService: Current ${type.name} alarm sound: $soundId');
      return soundId;
    } catch (e) {
      LogService.error('AlarmSoundService: Error reading alarm sound: $e');
      return defaultSoundId;
    }
  }

  /// Get selected alarm sound file name for specific type
  Future<String> getSelectedSoundFileName(AlarmType type) async {
    final soundId = await getSelectedSoundId(type);
    final sound = availableSounds.firstWhere(
      (s) => s.id == soundId,
      orElse: () => availableSounds[0],
    );
    return sound.fileName;
  }

  /// Get selected alarm sound full path (with assets folder) for specific type
  Future<String> getSelectedSoundPath(AlarmType type) async {
    final fileName = await getSelectedSoundFileName(type);
    return 'assets/sounds/$fileName';
  }

  /// Get alarm sound by ID
  AlarmSound getSoundById(String id) {
    return availableSounds.firstWhere(
      (s) => s.id == id,
      orElse: () => availableSounds[0],
    );
  }

  /// Get SharedPreferences key for alarm type
  String _getKeyForType(AlarmType type) {
    switch (type) {
      case AlarmType.item:
        return _itemAlarmSoundKey;
      case AlarmType.scheduled:
        return _scheduledAlarmSoundKey;
      case AlarmType.timer:
        return _timerAlarmSoundKey;
    }
  }
}

/// Alarm sound model
class AlarmSound {
  final String id;
  final String name;
  final String fileName;
  final String description;

  const AlarmSound({
    required this.id,
    required this.name,
    required this.fileName,
    required this.description,
  });
}

/// Alarm types for different use cases
enum AlarmType {
  item, // Regular task items
  scheduled, // Scheduled tasks
  timer, // Timer completed tasks
}
