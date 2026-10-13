import 'package:shared_preferences/shared_preferences.dart';

class VoiceTaskPreferences {
  static const languageKey = 'voice_task_language';

  Future<String?> loadLanguageTag() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(languageKey);
  }

  Future<void> saveLanguageTag(String? languageTag) async {
    final preferences = await SharedPreferences.getInstance();
    if (languageTag == null || languageTag.trim().isEmpty) {
      await preferences.remove(languageKey);
      return;
    }

    await preferences.setString(languageKey, languageTag);
  }
}
