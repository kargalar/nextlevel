import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Settings/color_selection_dialog.dart';
import 'package:next_level/Page/Settings/contact_us_dialog.dart';
import 'package:next_level/Page/Settings/file_storage_management_page.dart';
import 'package:next_level/Page/Settings/navbar_customization_page.dart';
import 'package:next_level/Page/Settings/privacy_policy_webview_page.dart';
import 'package:next_level/Page/Settings/alarm_sound_selection_dialog.dart';
import 'package:next_level/Provider/color_provider.dart';
import 'package:next_level/Provider/user_provider.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/app_launch_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Page/Settings/Sub Pages/google_drive_backup_page.dart';
import 'package:next_level/Page/Settings/local_analytics_page.dart';
import 'package:next_level/Page/Settings/voice_task_language_dialog.dart';
import 'package:next_level/Service/speech_recognition_service.dart';
import 'package:next_level/Service/voice_task_preferences.dart';
import 'package:next_level/Widgets/Common/app_components.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _getAppVersion();
    LogService.debug('Settings Page: Initialized');
  }

  Future<void> _getAppVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      });
      LogService.debug(
          'Settings: App version loaded successfully: $_appVersion');
    } catch (e) {
      LogService.error('Settings: Error loading app version: $e');
      setState(() {
        _appVersion = '1.3.1+35';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to ColorProvider changes to rebuild the page
    context.watch<ColorProvider>();
    LogService.debug('Settings Page: Rebuilding UI due to color change');

    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.Settings.tr()),
        leading: InkWell(
          borderRadius: AppColors.borderRadiusAll,
          onTap: () {
            NavigatorService().back();
          },
          child: const Icon(Icons.arrow_back_ios),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // CUSTOMIZATION SECTION
            const AppSectionHeader(
              eyebrow: 'SETUP',
              title: 'Personalize your space',
            ),
            _settingsOption(
              title: 'Alarm Sound Selection',
              subtitle: 'Configure alarm sounds for different task types',
              icon: Icons.music_note,
              onTap: () async {
                await showDialog(
                  context: context,
                  builder: (context) => const AlarmSoundSelectionDialog(),
                );
                LogService.debug('Settings: Alarm sound dialog closed');
              },
            ),
            Consumer<ColorProvider>(
              builder: (context, colorProvider, child) {
                return _settingsOption(
                  title: LocaleKeys.SelectMainColor.tr(),
                  subtitle:
                      "${LocaleKeys.ChooseColorTheme.tr()} ${colorProvider.getColorName(colorProvider.currentColor)}",
                  icon: Icons.color_lens,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => const ColorSelectionDialog(),
                    );
                  },
                  trailing: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: colorProvider.currentColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.text.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                );
              },
            ),
            _settingsOption(
              title: LocaleKeys.NavbarCustomization.tr(),
              subtitle: LocaleKeys.NavbarCustomizationSubtitle.tr(),
              icon: Icons.view_carousel,
              onTap: () {
                NavigatorService().goTo(const NavbarCustomizationPage());
              },
            ),
            _settingsOption(
              title: 'Voice task language',
              subtitle: 'Choose the language used for voice tasks',
              icon: Icons.language,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => VoiceTaskLanguageDialog(
                    preferences: VoiceTaskPreferences(),
                    loadLocales: SpeechRecognitionService().availableLocales,
                  ),
                );
              },
            ),
            Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                return Column(
                  children: [
                    _settingsOption(
                      title: 'Allow Negative Credits',
                      subtitle:
                          'Lets you make store purchases even when your credit balance is insufficient.',
                      icon: Icons.account_balance_wallet,
                      onTap: () {
                        userProvider.setAllowNegativeBalance(
                            !userProvider.allowNegativeBalance);
                      },
                      trailing: Switch(
                        value: userProvider.allowNegativeBalance,
                        onChanged: (value) {
                          userProvider.setAllowNegativeBalance(value);
                        },
                        activeThumbColor: AppColors.main,
                      ),
                    ),
                    _settingsOption(
                      title: 'Deduct Credits for Failed Tasks',
                      subtitle:
                          'Applies a credit penalty to overdue or failed tasks.',
                      icon: Icons.money_off,
                      onTap: () {
                        userProvider.setDeductCreditOnFail(
                            !userProvider.deductCreditOnFail);
                      },
                      trailing: Switch(
                        value: userProvider.deductCreditOnFail,
                        onChanged: (value) {
                          userProvider.setDeductCreditOnFail(value);
                        },
                        activeThumbColor: AppColors.main,
                      ),
                    ),
                  ],
                );
              },
            ),

            // DATA MANAGEMENT SECTION
            AppSectionHeader(
              eyebrow: 'DATA',
              title: LocaleKeys.DataManagement.tr(),
            ),
            _settingsOption(
              title: 'Google Drive Backup',
              subtitle: 'Backup your data to Google Drive',
              icon: Icons.cloud_done,
              onTap: () {
                NavigatorService().goTo(const GoogleDriveBackupPage());
              },
            ),
            _settingsOption(
              title: LocaleKeys.DataManagement.tr(),
              subtitle: LocaleKeys.DataManagementSubtitle.tr(),
              icon: Icons.storage_rounded,
              onTap: () {
                NavigatorService().goTo(const FileStorageManagementPage());
              },
            ),
            _settingsOption(
              title: 'Usage Analytics',
              subtitle: 'See page visits stored only on this device',
              icon: Icons.analytics_outlined,
              onTap: () {
                NavigatorService().goTo(const LocalAnalyticsPage());
              },
            ),

            // OTHER SECTION
            AppSectionHeader(
              eyebrow: 'SUPPORT',
              title: LocaleKeys.Others.tr(),
            ),
            _settingsOption(
              title: LocaleKeys.ContactUs.tr(),
              subtitle: LocaleKeys.ContactUsSubtitle.tr(),
              icon: Icons.contact_support,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => const ContactUsDialog(),
                );
              },
            ),
            _settingsOption(
              title: LocaleKeys.PrivacyPolicy.tr(),
              subtitle: LocaleKeys.PrivacyPolicySubtitle.tr(),
              icon: Icons.privacy_tip,
              onTap: () async {
                const url =
                    'https://kargalar.github.io/nextlevel_privacy2/privacy-policy/';
                LogService.debug('Settings: Opening Privacy Policy');

                // Check if webview is supported on this platform
                if (defaultTargetPlatform == TargetPlatform.android ||
                    defaultTargetPlatform == TargetPlatform.iOS ||
                    kIsWeb) {
                  LogService.debug(
                      'Settings: Using WebView for Privacy Policy');
                  NavigatorService().goTo(const PrivacyPolicyWebViewPage());
                } else {
                  // For unsupported platforms (like Windows), use external browser
                  LogService.debug(
                      'Settings: Using external browser for Privacy Policy: $url');
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url),
                        mode: LaunchMode.externalApplication);
                    LogService.debug(
                        'Settings: Privacy Policy URL launched successfully');
                  } else {
                    LogService.error(
                        'Settings: Could not launch Privacy Policy URL');
                  }
                }
              },
            ),
            _settingsOption(
              title: 'Source Code',
              subtitle: 'View project on GitHub',
              icon: Icons.code,
              onTap: () async {
                const url = 'https://github.com/kargalar/gamify_todo';
                LogService.debug('Settings: Opening GitHub source code');

                try {
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url),
                        mode: LaunchMode.externalApplication);
                    LogService.debug(
                        'Settings: GitHub source code URL launched successfully');
                  } else {
                    LogService.error('Settings: Could not launch GitHub URL');
                  }
                } catch (e) {
                  LogService.error('Settings: Error launching GitHub URL: $e');
                }
              },
            ),

            // Development mode: Review test button
            if (kDebugMode) ...[
              const SizedBox(height: 16),
              _settingsOption(
                title: 'Test App Review',
                subtitle: 'Reset all review data and test system',
                icon: Icons.bug_report,
                color: AppColors.dirtyRed,
                onTap: () async {
                  final appLaunchService = AppLaunchService();
                  await appLaunchService.resetLaunchCount();
                  final count = await appLaunchService.getLaunchCount();
                  LogService.debug(
                      'Settings: All review data reset, launch count: $count');

                  Helper().getMessage(
                    message:
                        'Review data reset! Restart app to test.\nWill ask at: 5, 20, 40, 60 launches.',
                    status: StatusEnum.INFO,
                    duration: const Duration(seconds: 4),
                  );
                },
              ),
              _settingsOption(
                title: 'Show Launch Info',
                subtitle: 'Display current app launch and review status',
                icon: Icons.info_outline,
                onTap: () async {
                  final appLaunchService = AppLaunchService();
                  final count = await appLaunchService.getLaunchCount();
                  final reviewCompleted =
                      await appLaunchService.isReviewCompleted();

                  LogService.debug(
                      'Settings: Count: $count, Completed: $reviewCompleted');

                  // Sonraki review'un hangi açılışta olacağını hesapla
                  final nextReviewAt = ((count ~/ 10) + 1) * 10;

                  if (mounted) {
                    showDialog(
                      // ignore: use_build_context_synchronously
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Launch & Review Info'),
                        content: Text(
                          'Current launch count: $count\n'
                          'Review completed: ${reviewCompleted ? "Yes" : "No"}\n'
                          'Next review at: $nextReviewAt launches',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
              _settingsOption(
                title: 'Mark Review as Completed',
                subtitle: 'Tell app you have reviewed (stops asking)',
                icon: Icons.check_circle_outline,
                color: AppColors.deepGreen,
                onTap: () async {
                  final appLaunchService = AppLaunchService();
                  await appLaunchService.markReviewAsCompleted();
                  LogService.debug('Settings: Review marked as completed');

                  Helper().getMessage(
                    message:
                        'Review marked as completed! App will not ask again.',
                    status: StatusEnum.SUCCESS,
                    duration: const Duration(seconds: 3),
                  );
                },
              ),
            ],

            // App Version at the bottom
            const SizedBox(height: 24),
            Center(
              child: Opacity(
                opacity: 0.5,
                child: Text(
                  _appVersion,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<dynamic> yardimDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text(
          LocaleKeys.Help.tr(),
        ),
        content: Text(
          LocaleKeys.HelpDialog.tr(),
        ),
      ),
    );
  }

  Widget _settingsOption({
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Color? color,
    Widget? trailing,
    IconData? icon,
  }) {
    return AppSurface(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20),
      accent: color ?? AppColors.main,
      backgroundColor: color ?? AppColors.surface,
      onTap: onTap,
      child: Row(
        mainAxisAlignment: subtitle != null
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 20,
              color: color != null ? AppColors.white : AppColors.lightMain,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color != null ? AppColors.white : AppColors.text,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      color: color != null
                          ? AppColors.white.withAlpha(180)
                          : AppColors.textSecondary,
                    ),
                  ),
                ]
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
