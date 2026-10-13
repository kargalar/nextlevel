import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Provider/navbar_visibility_provider.dart';

class NavbarVisibilityUtils {
  /// Get safe visible index for BottomNavigationBar
  /// Returns valid index within bounds of visible items
  static int getSafeVisibleIndex(NavbarVisibilityProvider provider, int pageIndex) {
    final visibleIndex = provider.mapPageIndexToVisibleIndex(pageIndex);

    if (visibleIndex < 0) {
      return 0;
    }

    final visibleCount = provider.getVisibleItemsCount();
    if (visibleIndex >= visibleCount) {
      return visibleCount - 1;
    }

    return visibleIndex;
  }

  /// Get list of visible navbar items based on provider settings
  static List<BottomNavigationBarItem> getVisibleNavbarItems(
    NavbarVisibilityProvider provider,
    List<BottomNavigationBarItem> allItems,
  ) {
    List<BottomNavigationBarItem> visibleItems = [];

    if (provider.showStore) visibleItems.add(allItems[0]);
    if (provider.showInbox) visibleItems.add(allItems[1]);
    if (provider.showTasks) visibleItems.add(allItems[2]);
    if (provider.showNotes) visibleItems.add(allItems[3]);
    if (provider.showProjects) visibleItems.add(allItems[4]);
    visibleItems.add(allItems[5]); // Profile is always visible

    return visibleItems;
  }

  /// Get list of visible pages for PageView
  static List<Widget> getVisiblePages(
    NavbarVisibilityProvider provider,
    List<Widget> allPages,
  ) {
    List<Widget> visiblePages = [];

    if (provider.showStore) visiblePages.add(allPages[0]);
    if (provider.showInbox) visiblePages.add(allPages[1]);
    if (provider.showTasks) visiblePages.add(allPages[2]);
    if (provider.showNotes) visiblePages.add(allPages[3]);
    if (provider.showProjects) visiblePages.add(allPages[4]);
    visiblePages.add(allPages[5]); // Profile is always visible

    return visiblePages;
  }

  /// Build navbar theme
  static ThemeData buildNavbarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      splashColor: AppColors.transparent,
      highlightColor: AppColors.transparent,
    );
  }
}
