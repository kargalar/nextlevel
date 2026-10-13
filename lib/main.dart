import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:next_level/Service/widget_isolate_coordinator.dart';
import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:next_level/Service/notification_services.dart';
import 'package:next_level/Widgets/alarm_overlay.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:next_level/General/app_theme.dart';
import 'package:next_level/General/init_app.dart';
import 'package:next_level/Page/navbar_page_manager.dart';
import 'package:next_level/Service/product_localization.dart';
import 'package:next_level/Service/app_launch_service.dart';
import 'package:next_level/Provider/add_store_item_provider.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Provider/quick_add_task_provider.dart';
import 'package:next_level/Provider/voice_task_provider.dart';
import 'package:next_level/Provider/category_provider.dart';
import 'package:next_level/Provider/navbar_provider.dart';
import 'package:next_level/Provider/navbar_visibility_provider.dart';
import 'package:next_level/Provider/streak_settings_provider.dart';
import 'package:next_level/Provider/vacation_mode_provider.dart';
import 'package:next_level/Provider/vacation_date_provider.dart';
import 'package:next_level/Provider/store_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Provider/theme_provider.dart';
import 'package:next_level/Provider/trait_provider.dart';
import 'package:next_level/Provider/color_provider.dart';
import 'package:next_level/Provider/notes_provider.dart';
import 'package:next_level/Provider/projects_provider.dart';
import 'package:next_level/Provider/user_provider.dart';
import 'package:next_level/Provider/task_template_provider.dart';
import 'package:next_level/Service/task_template_service.dart';
import 'package:next_level/Service/home_widget_service.dart';
import 'package:get/route_manager.dart';
import 'package:next_level/Provider/daily_streak_provider.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Service/backup_scheduler_service.dart';
import 'package:next_level/Service/backup_service.dart';
import 'package:next_level/Service/local_first_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:next_level/Page/Voice Task/voice_task_page.dart';
import 'package:next_level/Service/speech_recognition_service.dart';
import 'package:next_level/Service/voice_task_preferences.dart';
import 'package:next_level/Service/voice_task_shortcut_service.dart';
import 'package:next_level/Service/navigator_service.dart';

Future<String?> _checkAutomaticBackupSession() async {
  final prefs = await SharedPreferences.getInstance();
  final enabled =
      prefs.getBool(BackupSchedulerService.enabledPreference) ?? false;
  if (!enabled) return null;

  final account = await BackupService().initialize();
  return automaticBackupStartupWarning(
    enabled: enabled,
    signedIn: account != null,
    lastError: BackupService().lastError,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? startupBackupWarning;
  try {
    await BackupSchedulerService().initialize();
    startupBackupWarning = await _checkAutomaticBackupSession();
  } catch (error) {
    startupBackupWarning =
        'Google Drive automatic backup could not be initialized: $error';
    debugPrint('Drive backup scheduler initialization failed: $error');
  }

  await initApp();
  await LocalFirstSyncService().initialize();

  await TaskTemplateService.initialize();

  final selectedLocale = await ProductLocalization.loadSelectedLanguage();

  // Initialize ColorProvider and load saved color
  final colorProvider = ColorProvider();
  await colorProvider.loadSavedColor();

  // Initialize VacationModeProvider
  final vacationModeProvider = VacationModeProvider();
  await vacationModeProvider.initialize();

  // Initialize VacationDateProvider
  final vacationDateProvider = VacationDateProvider();
  await vacationDateProvider.initialize();

  // Initialize StreakSettingsProvider
  final streakSettingsProvider = StreakSettingsProvider();
  await streakSettingsProvider.initialize();

  // Initialize DailyStreakProvider
  final dailyStreakProvider = DailyStreakProvider();
  await dailyStreakProvider.initialize();

  if (!kIsWeb && Platform.isAndroid) {
    await HomeWidgetService.updateAllWidgets();
  }

  // Initialize NavbarVisibilityProvider
  final navbarVisibilityProvider = NavbarVisibilityProvider();

  // Initialize AppLaunchService and increment launch count
  final appLaunchService = AppLaunchService();
  await appLaunchService.incrementLaunchCountAndRequestReview();

  final voiceTaskShortcutService = VoiceTaskShortcutService();

  if (!kIsWeb && Platform.isAndroid) {
    WidgetIsolateCoordinator.foregroundReady();
  }

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ChangeNotifierProvider(create: (context) => NavbarProvider()),
      ChangeNotifierProvider.value(value: navbarVisibilityProvider),
      ChangeNotifierProvider(create: (context) => TaskProvider()),
      ChangeNotifierProvider(create: (context) => TaskTemplateProvider()),
      ChangeNotifierProvider.value(value: colorProvider),
      ChangeNotifierProvider.value(value: vacationModeProvider),
      ChangeNotifierProvider.value(value: vacationDateProvider),
      ChangeNotifierProvider.value(value: streakSettingsProvider),
      ChangeNotifierProvider.value(value: dailyStreakProvider),
      ChangeNotifierProvider(create: (context) => StoreProvider()),
      ChangeNotifierProvider(create: (context) => AddTaskProvider()),
      ChangeNotifierProvider(create: (context) => QuickAddTaskProvider()),
      ChangeNotifierProvider(
        create: (context) => VoiceTaskProvider(
          speechClient: SpeechRecognitionService(),
          preferences: VoiceTaskPreferences(),
          saveTask: context.read<TaskProvider>().addTask,
          systemLocaleTag:
              WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag(),
        ),
      ),
      ChangeNotifierProvider(create: (context) => AddStoreItemProvider()),
      ChangeNotifierProvider(create: (context) => TraitProvider()),
      ChangeNotifierProvider(create: (context) => TaskLogProvider()),
      ChangeNotifierProvider(create: (context) => CategoryProvider()),
      ChangeNotifierProvider(create: (context) => NotesProvider()),
      ChangeNotifierProvider(create: (context) => ProjectsProvider()),
      ChangeNotifierProvider(create: (context) => UserProvider()),
    ],
    child: ProductLocalization(
      startLocale: selectedLocale,
      child: Main(voiceTaskShortcutService: voiceTaskShortcutService),
    ),
  ));

  final warning = startupBackupWarning;
  if (warning != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.snackbar(
        'Google Drive Backup',
        warning,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 8),
      );
    });
  }
}

class Main extends StatefulWidget {
  const Main({super.key, required this.voiceTaskShortcutService});

  final VoiceTaskShortcutService voiceTaskShortcutService;

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> {
  StreamSubscription<void>? _shortcutSubscription;
  bool _launchResolved = false;
  bool _initialShortcut = false;
  bool _voicePageOpen = false;

  @override
  void initState() {
    super.initState();
    _resolveInitialLaunch();
    _shortcutSubscription =
        widget.voiceTaskShortcutService.shortcutEvents.listen((_) {
      _openWarmVoiceTask();
    });
  }

  Future<void> _resolveInitialLaunch() async {
    final initialShortcut =
        await widget.voiceTaskShortcutService.getInitialShortcut();
    if (!mounted) return;
    setState(() {
      _initialShortcut = initialShortcut;
      _launchResolved = true;
    });
  }

  void _openWarmVoiceTask() {
    if (!mounted || _initialShortcut || _voicePageOpen) return;
    _voicePageOpen = true;
    NavigatorService().goTo(
      VoiceTaskPage(
        provider: context.read<VoiceTaskProvider>(),
        onFinished: _closeWarmVoiceTask,
      ),
    );
  }

  void _closeWarmVoiceTask() {
    if (!_voicePageOpen) return;
    _voicePageOpen = false;
    NavigatorService().back();
  }

  void _finishColdShortcut() {
    unawaited(widget.voiceTaskShortcutService.finishShortcut());
  }

  @override
  void dispose() {
    _shortcutSubscription?.cancel();
    unawaited(widget.voiceTaskShortcutService.dispose());
    super.dispose();
  }

  Widget _home(BuildContext context) {
    if (!_launchResolved) return const SizedBox.expand();
    if (_initialShortcut) {
      return VoiceTaskPage(
        provider: context.read<VoiceTaskProvider>(),
        onFinished: _finishColdShortcut,
      );
    }
    return const NavbarPageManager();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    context.watch<ColorProvider>();

    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X boyutunu referans aldık
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'NextLevel',
          theme: AppTheme().theme,
          debugShowCheckedModeBanner: false,
          showPerformanceOverlay: false,
          home: _home(context),
          builder: (context, child) => StreamBuilder<AlarmSet>(
            stream: Alarm.ringing,
            initialData: Alarm.ringing.value,
            builder: (context, snapshot) => AlarmOverlay(
              alarms: snapshot.data ?? AlarmSet.empty(),
              stopAlarm: NotificationService().stopRingingAlarm,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
          routes: {
            '/main': (context) => const NavbarPageManager(),
          },
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
        );
      },
    );
  }
}
