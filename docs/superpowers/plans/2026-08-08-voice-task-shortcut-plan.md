# Sesli Görev Kısayolu Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Android ana ekranındaki “Sesli görev ekle” kısayolundan, ana ekranı arkada görünür bırakan bir panelle konuşmayı metne çevirip kullanıcı onayıyla checkbox görev oluşturmak.

**Architecture:** Konuşma tanıma `SpeechRecognitionClient` arayüzü arkasında tutulacak. `VoiceTaskProvider` tanıma durumunu ve onaylanmış metni yönetecek, `TaskProvider.addTask` üzerinden mevcut görev kayıt akışını kullanacak. Android shortcut intent’i MainActivity tarafından Flutter’a aktarılacak; soğuk açılışta saydam activity teması, sıcak açılışta mevcut activity üzerinde panel kullanılacak.

**Tech Stack:** Flutter/Dart, Provider, `speech_to_text`, SharedPreferences, Android App Shortcuts, Android Kotlin Flutter embedding, Flutter widget/unit tests.

## Global Constraints

- Tüm sesli görevler `TaskTypeEnum.CHECKBOX` olacaktır.
- Görev yalnızca kullanıcı “Ekle”ye bastığında kaydedilecektir.
- Varsayılan konuşma dili telefon dili, özel seçim `SharedPreferences` olacaktır.
- Varsayılan görev tarihi bugün; saat, alarm, bildirim, açıklama, kategori ve tekrar olmayacaktır.
- Android kısayol akışında arka planda sürekli mikrofon dinlenmeyecek ve ses kaydı saklanmayacaktır.
- Mevcut kullanıcı değişikliği `lib/Page/Home/Widget/routine_tasks_header.dart` korunacaktır.
- Her üretim davranışı için önce başarısız test yazılacak, sonra en küçük uygulama yapılacaktır.

---

## Dosya haritası

| Dosya | Sorumluluk |
|---|---|
| `lib/Service/speech_recognition_service.dart` | Konuşma tanıma paketi adaptörü ve locale çözümleme |
| `lib/Service/voice_task_preferences.dart` | Ses dili seçiminin kalıcı saklanması |
| `lib/Provider/voice_task_provider.dart` | Dinleme, metin, hata ve görev kaydı state’i |
| `lib/Page/Voice Task/voice_task_page.dart` | Şeffaf activity üzerinde alttan görünen panel |
| `lib/Page/Settings/voice_task_language_dialog.dart` | Ses dili seçimi arayüzü |
| `lib/Service/voice_task_shortcut_service.dart` | Android shortcut intent bridge’i |
| `lib/main.dart` | Provider kurulumu ve soğuk/sıcak shortcut yönlendirmesi |
| `android/app/src/main/kotlin/app/nextlevel/MainActivity.kt` | Shortcut intent’i ve activity tema/kanal yönetimi |
| `android/app/src/main/res/xml/shortcuts.xml` | Launcher shortcut tanımı |
| `android/app/src/main/res/values/styles.xml` | Saydam shortcut activity teması |
| `android/app/src/main/res/values/strings.xml` | Shortcut etiketi |
| `android/app/src/main/AndroidManifest.xml` | Mikrofon izni ve shortcut metadata |
| `assets/translations/en.json` | Sesli görev metinleri |
| `lib/Service/locale_keys.g.dart` | Yeni çeviri anahtarlarının generated çıktısı |

---

### Task 1: Ses dili tercihleri ve locale çözümleme

**Files:**
- Create: `lib/Service/voice_task_preferences.dart`
- Create: `test/Service/voice_task_preferences_test.dart`
- Modify: `pubspec.yaml` only if `shared_preferences` is not already present; it is already present, so no dependency change is needed in this task.

**Interfaces:**

```dart
class VoiceTaskPreferences {
  static const languageKey = 'voice_task_language';

  Future<String?> loadLanguageTag();
  Future<void> saveLanguageTag(String? languageTag);
}
```

- [ ] **Step 1: Write the failing preference tests**

```dart
test('returns null when voice language follows the phone language', () async {
  SharedPreferences.setMockInitialValues({});
  final preferences = VoiceTaskPreferences();

  expect(await preferences.loadLanguageTag(), isNull);
});

test('persists and clears a custom voice language', () async {
  SharedPreferences.setMockInitialValues({});
  final preferences = VoiceTaskPreferences();

  await preferences.saveLanguageTag('tr-TR');
  expect(await preferences.loadLanguageTag(), 'tr-TR');

  await preferences.saveLanguageTag(null);
  expect(await preferences.loadLanguageTag(), isNull);
});
```

- [ ] **Step 2: Run the tests and verify the expected failure**

Run: `flutter test test/Service/voice_task_preferences_test.dart`

Expected: FAIL because `VoiceTaskPreferences` does not exist yet.

- [ ] **Step 3: Implement the preference wrapper**

Use `SharedPreferences.getInstance()`, `getString(languageKey)`, `setString(languageKey, languageTag)`, and `remove(languageKey)` for a null selection. Do not store the phone locale as a custom value; null means “Telefon dili”.

- [ ] **Step 4: Run the tests and verify they pass**

Run: `flutter test test/Service/voice_task_preferences_test.dart`

Expected: PASS with 2 tests.

- [ ] **Step 5: Commit**

```powershell
git add lib/Service/voice_task_preferences.dart test/Service/voice_task_preferences_test.dart
git commit -m "feat: persist voice task language preference"
```

### Task 2: Konuşma tanıma adaptörü

**Files:**
- Modify: `pubspec.yaml` to add `speech_to_text` with `flutter pub add speech_to_text`
- Create: `lib/Service/speech_recognition_service.dart`
- Create: `test/Service/speech_recognition_service_test.dart`

**Interfaces:**

```dart
class SpeechLocale {
  const SpeechLocale({required this.id, required this.name});

  final String id;
  final String name;
}

abstract interface class SpeechRecognitionClient {
  Future<bool> initialize({
    required void Function(String status) onStatus,
    required void Function(String message) onError,
  });

  Future<List<SpeechLocale>> availableLocales();

  Future<void> listen({
    required String localeId,
    required void Function(String text, bool isFinal) onResult,
  });

  Future<void> stop();
  Future<void> cancel();
}

String resolveSpeechLocale({
  required String systemLocaleTag,
  required String? overrideLocaleTag,
  required List<SpeechLocale> availableLocales,
});
```

- [ ] **Step 1: Write failing locale resolution tests**

```dart
test('prefers the saved exact locale over the phone locale', () {
  final result = resolveSpeechLocale(
    systemLocaleTag: 'en-US',
    overrideLocaleTag: 'tr-TR',
    availableLocales: const [
      SpeechLocale(id: 'en_US', name: 'English'),
      SpeechLocale(id: 'tr_TR', name: 'Türkçe'),
    ],
  );

  expect(result, 'tr_TR');
});

test('falls back to the phone language when an exact locale is unavailable', () {
  final result = resolveSpeechLocale(
    systemLocaleTag: 'tr-TR',
    overrideLocaleTag: null,
    availableLocales: const [
      SpeechLocale(id: 'tr_TR', name: 'Türkçe'),
      SpeechLocale(id: 'en_US', name: 'English'),
    ],
  );

  expect(result, 'tr_TR');
});

test('uses the first available locale when the phone language is unsupported', () {
  final result = resolveSpeechLocale(
    systemLocaleTag: 'de-DE',
    overrideLocaleTag: null,
    availableLocales: const [
      SpeechLocale(id: 'en_US', name: 'English'),
    ],
  );

  expect(result, 'en_US');
});
```

- [ ] **Step 2: Run the tests and verify the expected failure**

Run: `flutter test test/Service/speech_recognition_service_test.dart`

Expected: FAIL because the locale value type and resolver do not exist.

- [ ] **Step 3: Add the package and implement the adapter**

Run: `flutter pub add speech_to_text`.

Wrap the package’s `SpeechToText` instance behind `SpeechRecognitionClient`. Convert the package locale objects to `SpeechLocale`, pass partial and final results through `onResult`, pass package status/errors through the callbacks, and map package permission/unavailable results to `initialize == false`. Keep all package imports in this file.

`resolveSpeechLocale` must compare exact normalized tags first, then language code, then the first available locale. A locale such as `tr-TR`, `tr_TR`, and `tr` must compare by language code after exact matching.

- [ ] **Step 4: Run the tests and verify they pass**

Run: `flutter test test/Service/speech_recognition_service_test.dart`

Expected: PASS with 3 locale tests.

- [ ] **Step 5: Commit**

```powershell
git add pubspec.yaml pubspec.lock lib/Service/speech_recognition_service.dart test/Service/speech_recognition_service_test.dart
git commit -m "feat: add speech recognition adapter"
```

### Task 3: VoiceTaskProvider state and task mapping

**Files:**
- Create: `lib/Provider/voice_task_provider.dart`
- Create: `test/Provider/voice_task_provider_test.dart`

**Interfaces:**

```dart
enum VoiceTaskStatus { idle, initializing, listening, ready, saving, error }

typedef VoiceTaskSaver = Future<void> Function(TaskModel task);

class VoiceTaskProvider extends ChangeNotifier {
  VoiceTaskProvider({
    required SpeechRecognitionClient speechClient,
    required VoiceTaskPreferences preferences,
    required VoiceTaskSaver saveTask,
    required String systemLocaleTag,
    DateTime Function()? now,
  });

  VoiceTaskStatus get status;
  String get text;
  String? get errorMessage;
  bool get canAdd;
  Future<void> startListening();
  Future<void> stopListening();
  void updateText(String value);
  Future<void> retry();
  Future<void> addTask();
}
```

- [ ] **Step 1: Write failing tests for the provider behavior**

Define `FakeSpeechRecognitionClient` in `test/Provider/voice_task_provider_test.dart` with the `SpeechRecognitionClient` methods, a `void emit(String text, {required bool isFinal})` helper, and counters for `listen`, `stop`, and `cancel`. Use a `List<TaskModel>` saver instead of a mock.

```dart
test('keeps the recognized text until the user explicitly adds it', () async {
  final client = FakeSpeechRecognitionClient();
  final savedTasks = <TaskModel>[];
  final provider = VoiceTaskProvider(
    speechClient: client,
    preferences: VoiceTaskPreferences(),
    saveTask: savedTasks.add,
    systemLocaleTag: 'en-US',
    now: () => DateTime(2026, 8, 8, 14, 30),
  );

  await provider.startListening();
  client.emit('Buy milk', isFinal: true);

  expect(provider.text, 'Buy milk');
  expect(savedTasks, isEmpty);
  expect(provider.canAdd, isTrue);
});

test('creates a checkbox task with the agreed defaults after addTask', () async {
  final client = FakeSpeechRecognitionClient();
  final savedTasks = <TaskModel>[];
  final provider = VoiceTaskProvider(
    speechClient: client,
    preferences: VoiceTaskPreferences(),
    saveTask: savedTasks.add,
    systemLocaleTag: 'en-US',
    now: () => DateTime(2026, 8, 8, 14, 30),
  );

  provider.updateText('Buy milk');
  await provider.addTask();

  expect(savedTasks.single.title, 'Buy milk');
  expect(savedTasks.single.type, TaskTypeEnum.CHECKBOX);
  expect(savedTasks.single.taskDate, DateTime(2026, 8, 8));
  expect(savedTasks.single.isNotificationOn, isFalse);
  expect(savedTasks.single.isAlarmOn, isFalse);
  expect(savedTasks.single.priority, 3);
});

test('does not save whitespace-only text', () async {
  final savedTasks = <TaskModel>[];
  final provider = VoiceTaskProvider(
    speechClient: FakeSpeechRecognitionClient(),
    preferences: VoiceTaskPreferences(),
    saveTask: savedTasks.add,
    systemLocaleTag: 'en-US',
  );

  provider.updateText('   ');
  await provider.addTask();

  expect(savedTasks, isEmpty);
  expect(provider.canAdd, isFalse);
});
```

- [ ] **Step 2: Run the tests and verify the expected failure**

Run: `flutter test test/Provider/voice_task_provider_test.dart`

Expected: FAIL because `VoiceTaskProvider` and its state contract do not exist.

- [ ] **Step 3: Implement the minimal provider**

On `startListening`, initialize the client, load the saved language, resolve the locale against available locales, then listen. Update `text` on every partial/final result. On `addTask`, trim the text, construct `TaskModel` with `DateTime(now.year, now.month, now.day)`, `TaskTypeEnum.CHECKBOX`, `isNotificationOn: false`, `isAlarmOn: false`, and `priority: 3`, then await `saveTask`. Never call `saveTask` from a recognition callback.

Set `status` to `error` with a user-facing message when initialization, recognition, or saving fails. Preserve `text` through all error transitions. `retry` cancels the old recognition session, clears only the error, and starts listening again.

- [ ] **Step 4: Run the tests and verify they pass**

Run: `flutter test test/Provider/voice_task_provider_test.dart`

Expected: PASS with the provider behavior tests.

- [ ] **Step 5: Commit**

```powershell
git add lib/Provider/voice_task_provider.dart test/Provider/voice_task_provider_test.dart
git commit -m "feat: add voice task state management"
```

### Task 4: Sesli görev paneli UI

**Files:**
- Create: `lib/Page/Voice Task/voice_task_page.dart`
- Create: `test/Page/voice_task_page_test.dart`
- Create: `test/helpers/voice_task_widget_test_helpers.dart`
- Modify: `assets/translations/en.json` with the voice task labels listed below.
- Regenerate: `lib/Service/locale_keys.g.dart` using the existing easy_localization command.

Add these new translation keys to `assets/translations/en.json`: `VoiceTask`, `VoiceTaskHint`, `Listening`, `SpeechReady`, `SpeechUnavailable`, `MicrophonePermissionRequired`, `OpenSettings`, `VoiceTaskEmpty`, `VoiceTaskSaveError`, and `PhoneLanguage`. Reuse the existing `Add`, `Cancel`, and `Retry` keys.

**Interfaces:**

```dart
class VoiceTaskPage extends StatefulWidget {
  const VoiceTaskPage({super.key, required this.provider, this.onFinished});

  final VoiceTaskProvider provider;
  final VoidCallback? onFinished;
}
```

- [ ] **Step 1: Write failing widget tests**

```dart
testWidgets('disables Add until the recognized text is non-empty', (tester) async {
  final provider = createVoiceTaskProvider();
  await tester.pumpWidget(wrapVoiceTaskPage(VoiceTaskPage(provider: provider)));

  expect(find.text('Add'), findsOneWidget);
  expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).enabled, isFalse);

  provider.updateText('Buy milk');
  await tester.pump();

  expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).enabled, isTrue);
});

testWidgets('passes edited text to the provider only when Add is pressed', (tester) async {
  final savedTasks = <TaskModel>[];
  final provider = createVoiceTaskProvider(saveTask: savedTasks.add);
  await tester.pumpWidget(wrapVoiceTaskPage(VoiceTaskPage(provider: provider)));

  await tester.enterText(find.byType(TextField), 'Buy milk');
  await tester.tap(find.text('Add'));
  await tester.pump();

  expect(savedTasks.single.title, 'Buy milk');
});
```

Implement `createVoiceTaskProvider({VoiceTaskSaver? saveTask})` and
`wrapVoiceTaskPage(Widget child)` in
`test/helpers/voice_task_widget_test_helpers.dart`; the wrapper returns a
`MaterialApp(home: child)` and the provider factory uses the fake speech
client, empty preferences, `en-US`, and a fixed clock.

- [ ] **Step 2: Run the widget tests and verify the expected failure**

Run: `flutter test test/Page/voice_task_page_test.dart`

Expected: FAIL because `VoiceTaskPage` does not exist.

- [ ] **Step 3: Add translations and implement the panel**

Run: `dart run easy_localization:generate -S assets/translations -f keys -O lib/Service -o locale_keys.g.dart`.

Render a transparent `Scaffold` with a bottom-aligned `SafeArea` and a rounded `Material` card. Show microphone/listening status, an editable `TextField`, error text, “Tekrar dene/Ayarları aç” actions where applicable, and “İptal/Ekle” buttons. Bind the field to `provider.updateText`; `Ekle` calls `provider.addTask` and then `onFinished`. Do not use `showModalBottomSheet` because this page itself is rendered inside the translucent shortcut activity.

- [ ] **Step 4: Run the widget tests and verify they pass**

Run: `flutter test test/Page/voice_task_page_test.dart`

Expected: PASS with the UI interaction tests.

- [ ] **Step 5: Commit**

```powershell
git add assets/translations/en.json lib/Service/locale_keys.g.dart "lib/Page/Voice Task/voice_task_page.dart" test/Page/voice_task_page_test.dart
git commit -m "feat: add voice task bottom panel"
```

### Task 5: Android shortcut intent and translucent window

**Files:**
- Create: `android/app/src/main/res/xml/shortcuts.xml`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `android/app/src/main/res/values/styles.xml`
- Modify: `android/app/src/main/res/values/strings.xml`
- Modify: `android/app/src/main/kotlin/app/nextlevel/MainActivity.kt`
- Create: `lib/Service/voice_task_shortcut_service.dart`
- Create: `test/Service/voice_task_shortcut_service_test.dart`

**Interfaces:**

```dart
class VoiceTaskShortcutService {
  static const channelName = 'app.nextlevel/voice_shortcut';

  Future<bool> getInitialShortcut();
  Stream<void> get shortcutEvents;
  Future<void> finishShortcut();
}

bool isVoiceTaskShortcutUri(Uri? uri);
```

- [ ] **Step 1: Write the failing Dart bridge tests**

Test the pure intent marker conversion used by the bridge: the `nextlevel://voice-task` URI is a voice shortcut, other URIs are not, and `finishShortcut` invokes the expected channel method using a `MethodChannel` mock handler.

- [ ] **Step 2: Run the tests and verify the expected failure**

Run: `flutter test test/Service/voice_task_shortcut_service_test.dart`

Expected: FAIL because the bridge class and URI parser do not exist.

- [ ] **Step 3: Implement the Flutter bridge**

Use a `MethodChannel` named `app.nextlevel/voice_shortcut`. Expose `getInitialShortcut`, a broadcast stream for `voiceTaskShortcut`, and `finishShortcut`. Keep channel calls in this service so `main.dart` does not contain platform strings.

- [ ] **Step 4: Run the tests and verify they pass**

Run: `flutter test test/Service/voice_task_shortcut_service_test.dart`

Expected: PASS.

- [ ] **Step 5: Add the Android static shortcut and permission**

Add `android.permission.RECORD_AUDIO` to the main manifest, add the `android.app.shortcuts` metadata to the launcher activity, and create a `voice_task` static shortcut targeting `app.nextlevel.MainActivity` with `android.intent.action.VIEW` and data URI `nextlevel://voice-task`. Add the localized shortcut label to `strings.xml`.

- [ ] **Step 6: Add the translucent shortcut theme**

Create `VoiceShortcutTheme` based on a no-action-bar Material theme with `windowIsTranslucent=true`, transparent `windowBackground`, no title, and no background dim. Keep `NormalTheme` unchanged for regular launches.

- [ ] **Step 7: Extend MainActivity without removing the timezone channel**

Before `super.onCreate`, inspect the intent data and call `setTheme(R.style.VoiceShortcutTheme)` for `nextlevel://voice-task`. In `configureFlutterEngine`, keep `app.nextlevel/timezone` intact and register the voice shortcut channel. Implement `getInitialShortcut`, `finishShortcut` by calling `finish()`, and `onNewIntent` for warm launches. Queue warm shortcut events until the Dart channel listener is attached.

- [ ] **Step 8: Build the Android project and verify the native resources compile**

Run: `flutter build apk --debug`

Expected: exit code 0 and a debug APK under `build/app/outputs/flutter-apk/`.

- [ ] **Step 9: Commit**

```powershell
git add android/app/src/main/AndroidManifest.xml android/app/src/main/res/xml/shortcuts.xml android/app/src/main/res/values/styles.xml android/app/src/main/res/values/strings.xml android/app/src/main/kotlin/app/nextlevel/MainActivity.kt lib/Service/voice_task_shortcut_service.dart test/Service/voice_task_shortcut_service_test.dart
git commit -m "feat: add Android voice task shortcut"
```

### Task 6: Uygulama wiring ve sıcak/soğuk açılış akışı

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/Service/voice_task_shortcut_service.dart` to expose a queued warm-shortcut event stream until the Dart listener is attached.
- Create: `test/main_voice_shortcut_test.dart` for the pure launch-mode decision helper.

**Interfaces:**

```dart
enum VoiceTaskLaunchMode { regular, coldShortcut, warmShortcut }

VoiceTaskLaunchMode resolveVoiceTaskLaunchMode({
  required bool initialShortcut,
  required bool appAlreadyVisible,
});
```

- [ ] **Step 1: Write the failing launch-mode tests**

```dart
test('cold shortcut uses the overlay root', () {
  expect(
    resolveVoiceTaskLaunchMode(initialShortcut: true, appAlreadyVisible: false),
    VoiceTaskLaunchMode.coldShortcut,
  );
});

test('shortcut received while app is visible uses a warm route', () {
  expect(
    resolveVoiceTaskLaunchMode(initialShortcut: true, appAlreadyVisible: true),
    VoiceTaskLaunchMode.warmShortcut,
  );
});
```

- [ ] **Step 2: Run the tests and verify the expected failure**

Run: `flutter test test/main_voice_shortcut_test.dart`

Expected: FAIL because the launch-mode enum and helper do not exist.

- [ ] **Step 3: Implement provider and launch wiring**

Register `VoiceTaskProvider` in `MultiProvider` with `SpeechRecognitionService`, `VoiceTaskPreferences`, the current platform locale tag, and `context.read<TaskProvider>().addTask` as the saver. Resolve the initial shortcut before choosing the app root. Use `VoiceTaskPage` as the root when cold-started from the shortcut; regular launches keep `NavbarPageManager`.

Subscribe to warm shortcut events after the app is mounted and push `VoiceTaskPage` with `NavigatorService`/GetX. On cold overlay completion or cancellation call `finishShortcut`; on warm launches pop only the voice route. Ensure a repeated warm intent does not create duplicate voice pages.

- [ ] **Step 4: Run the tests and verify they pass**

Run: `flutter test test/main_voice_shortcut_test.dart`

Expected: PASS.

- [ ] **Step 5: Verify full Dart analysis**

Run: `flutter analyze`

Expected: exit code 0 with no new analyzer errors.

- [ ] **Step 6: Commit**

```powershell
git add lib/main.dart lib/Service/voice_task_shortcut_service.dart test/main_voice_shortcut_test.dart
git commit -m "feat: wire voice shortcut launch flow"
```

### Task 7: Ses dili ayarları

**Files:**
- Create: `lib/Page/Settings/voice_task_language_dialog.dart`
- Create: `test/Page/voice_task_language_dialog_test.dart`
- Modify: `lib/Page/Settings/settings_page.dart`

- [ ] **Step 1: Write the failing settings widget tests**

```dart
testWidgets('shows Phone language as the default selection', (tester) async {
  final preferences = VoiceTaskPreferences();
  SharedPreferences.setMockInitialValues({});

  await tester.pumpWidget(MaterialApp(
    home: VoiceTaskLanguageDialog(
      preferences: preferences,
      loadLocales: () async => const [
        SpeechLocale(id: 'en_US', name: 'English'),
        SpeechLocale(id: 'tr_TR', name: 'Türkçe'),
      ],
    ),
  ));

  expect(find.text('Phone language'), findsOneWidget);
});

testWidgets('persists a selected speech locale', (tester) async {
  final preferences = VoiceTaskPreferences();
  SharedPreferences.setMockInitialValues({});

  await tester.pumpWidget(MaterialApp(
    home: VoiceTaskLanguageDialog(
      preferences: preferences,
      loadLocales: () async => const [
        SpeechLocale(id: 'tr_TR', name: 'Türkçe'),
      ],
    ),
  ));

  await tester.tap(find.text('Türkçe'));
  await tester.pump();

  expect(await preferences.loadLanguageTag(), 'tr-TR');
});
```

- [ ] **Step 2: Run the tests and verify the expected failure**

Run: `flutter test test/Page/voice_task_language_dialog_test.dart`

Expected: FAIL because the dialog does not exist.

- [ ] **Step 3: Implement the dialog and settings entry**

Load available locales from `SpeechRecognitionService`, show “Phone language” as a null selection, normalize selected IDs to BCP-47 tags before persisting, and close the dialog after selection. Add a “Voice task language” entry to `SettingsPage` that opens the dialog.

- [ ] **Step 4: Run the tests and verify they pass**

Run: `flutter test test/Page/voice_task_language_dialog_test.dart`

Expected: PASS.

- [ ] **Step 5: Run the full test suite**

Run: `flutter test`

Expected: all existing and new tests pass with zero failures.

- [ ] **Step 6: Commit**

```powershell
git add "lib/Page/Settings/voice_task_language_dialog.dart" test/Page/voice_task_language_dialog_test.dart lib/Page/Settings/settings_page.dart
git commit -m "feat: add voice task language setting"
```

### Task 8: Final verification and Android behavior check

**Files:**
- No planned source changes; only fix failures found by verification while preserving the existing user edit.

- [ ] **Step 1: Run the focused feature tests**

Run: `flutter test test/Service/voice_task_preferences_test.dart test/Service/speech_recognition_service_test.dart test/Provider/voice_task_provider_test.dart test/Page/voice_task_page_test.dart test/Service/voice_task_shortcut_service_test.dart test/Page/voice_task_language_dialog_test.dart test/main_voice_shortcut_test.dart`

Expected: all focused tests pass.

- [ ] **Step 2: Run the complete verification commands**

Run:

```powershell
flutter test
flutter analyze
flutter build apk --debug
```

Expected: each command exits with code 0; no new analyzer errors; debug APK is produced.

- [ ] **Step 3: Inspect the final diff**

Run: `git status --short` and `git log --oneline -8`

Confirm the feature commits and files are present, and `lib/Page/Home/Widget/routine_tasks_header.dart` remains an unstaged user change rather than being modified by this feature.

- [ ] **Step 4: Perform the Android manual smoke test**

Install the debug APK on an Android device or emulator. Add “Sesli görev ekle” to the launcher, tap it with the app closed, grant microphone permission, speak a task, edit the text, verify no task exists before tapping “Ekle”, tap “Ekle”, and verify the task appears in Next Level after returning from the translucent panel. Repeat with the app already open and verify only one voice panel appears.

- [ ] **Step 5: Commit any verification-only fixes**

```powershell
git add pubspec.yaml pubspec.lock assets/translations/en.json lib/main.dart lib/Service/speech_recognition_service.dart lib/Service/voice_task_preferences.dart lib/Service/voice_task_shortcut_service.dart lib/Service/locale_keys.g.dart lib/Provider/voice_task_provider.dart "lib/Page/Voice Task/voice_task_page.dart" "lib/Page/Settings/voice_task_language_dialog.dart" lib/Page/Settings/settings_page.dart android/app/src/main/AndroidManifest.xml android/app/src/main/kotlin/app/nextlevel/MainActivity.kt android/app/src/main/res/values/styles.xml android/app/src/main/res/values/strings.xml android/app/src/main/res/xml/shortcuts.xml
git commit -m "fix: verify voice task shortcut flow"
```
