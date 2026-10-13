import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Provider/navbar_visibility_provider.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Service/logging_service.dart';

class NavbarCustomizationPage extends StatelessWidget {
  const NavbarCustomizationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.NavbarCustomization.tr()),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.panelBackground.withValues(alpha: 0.5),
                borderRadius: AppColors.borderRadiusAll,
                border: Border.all(
                  color: AppColors.text.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.main,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      LocaleKeys.NavbarCustomizationSubtitle.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.text.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Navigation items toggles
            Expanded(
              child: Consumer<NavbarVisibilityProvider>(
                builder: (context, provider, child) {
                  return ListView(
                    children: [
                      _buildNavbarToggle(
                        context: context,
                        title: LocaleKeys.ShowStore.tr(),
                        icon: Icons.store,
                        value: provider.showStore,
                        pageIndex: 0,
                        isMainPage: provider.mainPageIndex == 0,
                        onChanged: (value) {
                          provider.toggleStore();
                          LogService.debug('Navbar: Store visibility toggled');
                        },
                        onSetMain: () {
                          provider.setMainPage(0);
                          LogService.debug('Navbar: Store set as main page');
                        },
                      ),
                      _buildNavbarToggle(
                        context: context,
                        title: LocaleKeys.ShowInbox.tr(),
                        icon: Icons.list,
                        value: provider.showInbox,
                        pageIndex: 1,
                        isMainPage: provider.mainPageIndex == 1,
                        onChanged: (value) {
                          provider.toggleInbox();
                          LogService.debug('Navbar: Inbox visibility toggled');
                        },
                        onSetMain: () {
                          provider.setMainPage(1);
                          LogService.debug('Navbar: Inbox set as main page');
                        },
                      ),
                      _buildNavbarToggle(
                        context: context,
                        title: LocaleKeys.ShowTasks.tr(),
                        icon: Icons.tag,
                        value: provider.showTasks,
                        pageIndex: 2,
                        isMainPage: provider.mainPageIndex == 2,
                        onChanged: (value) {
                          provider.toggleTasks();
                          LogService.debug('Navbar: Tasks visibility toggled');
                        },
                        onSetMain: () {
                          provider.setMainPage(2);
                          LogService.debug('Navbar: Tasks set as main page');
                        },
                      ),
                      _buildNavbarToggle(
                        context: context,
                        title: LocaleKeys.ShowNotes.tr(),
                        icon: Icons.note,
                        value: provider.showNotes,
                        pageIndex: 3,
                        isMainPage: provider.mainPageIndex == 3,
                        onChanged: (value) {
                          provider.toggleNotes();
                          LogService.debug('Navbar: Notes visibility toggled');
                        },
                        onSetMain: () {
                          provider.setMainPage(3);
                          LogService.debug('Navbar: Notes set as main page');
                        },
                      ),
                      _buildNavbarToggle(
                        context: context,
                        title: LocaleKeys.ShowProjects.tr(),
                        icon: Icons.folder_outlined,
                        value: provider.showProjects,
                        pageIndex: 4,
                        isMainPage: provider.mainPageIndex == 4,
                        onChanged: (value) {
                          provider.toggleProjects();
                          LogService.debug('Navbar: Projects visibility toggled');
                        },
                        onSetMain: () {
                          provider.setMainPage(4);
                          LogService.debug('Navbar: Projects set as main page');
                        },
                      ),

                      // Profile - Always visible (disabled)
                      _buildNavbarToggle(
                        context: context,
                        title: LocaleKeys.Profile.tr(),
                        icon: Icons.person_rounded,
                        value: true,
                        onChanged: null, // Disabled
                        subtitle: 'Always visible',
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavbarToggle({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool value,
    required void Function(bool)? onChanged,
    String? subtitle,
    int? pageIndex,
    bool isMainPage = false,
    VoidCallback? onSetMain,
  }) {
    final isDisabled = onChanged == null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.panelBackground,
          borderRadius: AppColors.borderRadiusAll,
          border: Border.all(
            color: isDisabled
                ? AppColors.text.withValues(alpha: 0.1)
                : isMainPage
                    ? AppColors.main
                    : value
                        ? AppColors.main.withValues(alpha: 0.3)
                        : AppColors.text.withValues(alpha: 0.1),
            width: isDisabled
                ? 1
                : isMainPage
                    ? 3
                    : value
                        ? 2
                        : 1,
          ),
        ),
        child: InkWell(
          borderRadius: AppColors.borderRadiusAll,
          onTap: isDisabled ? null : () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDisabled
                        ? AppColors.text.withValues(alpha: 0.1)
                        : value
                            ? AppColors.main.withValues(alpha: 0.1)
                            : AppColors.text.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isDisabled
                        ? AppColors.text.withValues(alpha: 0.3)
                        : value
                            ? AppColors.main
                            : AppColors.text.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDisabled ? AppColors.text.withValues(alpha: 0.3) : AppColors.text,
                            ),
                          ),
                          if (isMainPage) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.main,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                LocaleKeys.MainPage.tr(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.text.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Set as Main button (only for non-disabled and visible items)
                if (!isDisabled && value && onSetMain != null && !isMainPage) ...[
                  InkWell(
                    onTap: onSetMain,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.main.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.main.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        LocaleKeys.SetAsMain.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.main,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Switch.adaptive(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: AppColors.main,
                  inactiveThumbColor: AppColors.text.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
