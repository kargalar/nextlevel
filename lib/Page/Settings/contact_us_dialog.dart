import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Service/logging_service.dart';

class ContactUsDialog extends StatelessWidget {
  const ContactUsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      title: Text(LocaleKeys.ContactUs.tr()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _contactOption(
            icon: Icons.email,
            title: LocaleKeys.Email.tr(),
            subtitle: "kargalarx@gmail.com",
            onTap: () async {
              try {
                final Email email = Email(
                  body: '',
                  subject: 'Gamify Todo App Support',
                  recipients: ['kargalarx@gmail.com'],
                );
                LogService.debug('ContactUsDialog: Sending email');
                await FlutterEmailSender.send(email);
                LogService.debug('ContactUsDialog: Email sent successfully');
              } catch (e) {
                LogService.error('ContactUsDialog: Could not send email - $e');
                Helper().getMessage(
                  message: 'Cannot open email client. Please contact: kargalarx@gmail.com',
                  status: StatusEnum.WARNING,
                );
              }
            },
          ),
          // const SizedBox(height: 8),
          // _contactOption(
          //   icon: Icons.web,
          //   title: LocaleKeys.Website.tr(),
          //   subtitle: "www.gamifytodo.com",
          //   onTap: () async {
          //     final Uri url = Uri.parse('https://www.gamifytodo.com');
          //     if (await canLaunchUrl(url)) {
          //       await launchUrl(url, mode: LaunchMode.externalApplication);
          //     } else {
          //       await Clipboard.setData(
          //         const ClipboardData(text: 'www.gamifytodo.com'),
          //       );
          //       if (context.mounted) {
          //         ScaffoldMessenger.of(context).showSnackBar(
          //           SnackBar(
          //             content: const Text('Website URL copied to clipboard'),
          //             backgroundColor: AppColors.main,
          //           ),
          //         );
          //       }
          //     }
          //   },
          // ),
          const SizedBox(height: 8),
          _contactOption(
            icon: Icons.bug_report,
            title: LocaleKeys.ReportBug.tr(),
            subtitle: LocaleKeys.SendUsBugReports.tr(),
            onTap: () async {
              try {
                final Email email = Email(
                  body: 'Please describe the bug you encountered:\n\n'
                      'Steps to reproduce:\n'
                      '1. \n'
                      '2. \n'
                      '3. \n\n'
                      'Expected behavior:\n\n'
                      'Actual behavior:\n\n'
                      'Device information:\n'
                      '- Operating System: \n'
                      '- App Version: \n',
                  subject: 'Bug Report - Gamify Todo App',
                  recipients: ['kargalarx@gmail.com'],
                );
                LogService.debug('ContactUsDialog: Sending bug report email');
                await FlutterEmailSender.send(email);
                LogService.debug('ContactUsDialog: Bug report email sent successfully');
              } catch (e) {
                LogService.error('ContactUsDialog: Could not send bug report email - $e');
                Helper().getMessage(
                  message: 'Cannot open email client. Please contact: kargalarx@gmail.com',
                  status: StatusEnum.WARNING,
                );
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(LocaleKeys.Close.tr()),
        ),
      ],
    );
  }

  Widget _contactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: AppColors.borderRadiusAll,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.panelBackground,
          borderRadius: AppColors.borderRadiusAll,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.main,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.text.withAlpha(179),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.text.withAlpha(128),
            ),
          ],
        ),
      ),
    );
  }
}
