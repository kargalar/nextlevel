import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:next_level/Service/locale_keys.g.dart';

class NavbarConstants {
  static List<BottomNavigationBarItem> getNavbarItems() {
    return [
      BottomNavigationBarItem(
        icon: const Icon(Icons.local_mall_outlined),
        activeIcon: const Icon(Icons.local_mall_rounded),
        label: StringTranslateExtension(LocaleKeys.Store).tr(),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.today_outlined),
        activeIcon: const Icon(Icons.today_rounded),
        label: StringTranslateExtension(LocaleKeys.Today).tr(),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.checklist_rounded),
        activeIcon: const Icon(Icons.playlist_add_check_circle_rounded),
        label: StringTranslateExtension(LocaleKeys.Tasks).tr(),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.sticky_note_2_outlined),
        activeIcon: const Icon(Icons.sticky_note_2_rounded),
        label: StringTranslateExtension(LocaleKeys.MyNotes).tr(),
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.folder_outlined),
        activeIcon: Icon(Icons.folder_rounded),
        label: 'Projects',
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.person_outline_rounded),
        activeIcon: const Icon(Icons.person_rounded),
        label: StringTranslateExtension(LocaleKeys.Profile).tr(),
      ),
    ];
  }
}
