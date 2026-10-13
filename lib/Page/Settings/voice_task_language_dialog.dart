import 'package:flutter/material.dart';
import 'package:next_level/Service/speech_recognition_service.dart';
import 'package:next_level/Service/voice_task_preferences.dart';

class VoiceTaskLanguageDialog extends StatefulWidget {
  const VoiceTaskLanguageDialog({
    super.key,
    required this.preferences,
    required this.loadLocales,
  });

  final VoiceTaskPreferences preferences;
  final Future<List<SpeechLocale>> Function() loadLocales;

  @override
  State<VoiceTaskLanguageDialog> createState() => _VoiceTaskLanguageDialogState();
}

class _VoiceTaskLanguageDialogState extends State<VoiceTaskLanguageDialog> {
  List<SpeechLocale> _locales = const [];
  String? _selectedLanguageTag;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final values = await Future.wait([
        widget.preferences.loadLanguageTag(),
        widget.loadLocales(),
      ]);
      if (!mounted) return;
      setState(() {
        _selectedLanguageTag = values[0] as String?;
        _locales = values[1] as List<SpeechLocale>;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _select(String? languageTag) async {
    await widget.preferences.saveLanguageTag(languageTag);
    if (mounted) Navigator.of(context).pop();
  }

  bool _isSelected(String? languageTag) {
    if (languageTag == null) return _selectedLanguageTag == null;
    return _normalize(languageTag) == _normalize(_selectedLanguageTag ?? '');
  }

  String _normalize(String value) => value.replaceAll('_', '-').toLowerCase();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Voice task language'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Text(_errorMessage!)
                : ListView(
                    shrinkWrap: true,
                    children: [
                      _languageTile(
                        title: 'Phone language',
                        subtitle: 'Use the device language',
                        languageTag: null,
                      ),
                      ..._locales.map(
                        (locale) => _languageTile(
                          title: locale.name,
                          languageTag: locale.id.replaceAll('_', '-'),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _languageTile({
    required String title,
    required String? languageTag,
    String? subtitle,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: _isSelected(languageTag)
          ? const Icon(Icons.check, color: Colors.green)
          : null,
      onTap: () => _select(languageTag),
    );
  }
}
