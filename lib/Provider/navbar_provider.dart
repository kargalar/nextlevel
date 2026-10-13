import 'package:flutter/material.dart';
import 'package:next_level/Provider/navbar_visibility_provider.dart';
import 'package:next_level/Provider/task_provider.dart';

class NavbarProvider with ChangeNotifier {
  static final NavbarProvider _instance = NavbarProvider._internal();
  factory NavbarProvider() {
    return _instance;
  }
  NavbarProvider._internal();

  int currentIndex = 1;

  late PageController pageController;
  NavbarVisibilityProvider? _visibilityProvider;

  void setVisibilityProvider(NavbarVisibilityProvider provider) {
    _visibilityProvider = provider;
  }

  void updateIndex(int index) {
    // Ensure the index is safe (visible)
    if (_visibilityProvider != null) {
      currentIndex = _visibilityProvider!.getSafePageIndex(index);
    } else {
      currentIndex = index;
    }

    // Eğer home page'e (index 1) geçiş yapılıyorsa, selected date'i bugüne resetle
    if (currentIndex == 1) {
      TaskProvider().changeSelectedDate(DateTime.now());
    }

    // Convert page index to visible index for PageController
    int targetIndex = currentIndex;
    if (_visibilityProvider != null) {
      targetIndex =
          _visibilityProvider!.mapPageIndexToVisibleIndex(currentIndex);
      // If page is not visible, navigate to first visible page
      if (targetIndex < 0) {
        targetIndex = 0;
        currentIndex = _visibilityProvider!.getFirstVisiblePageIndex();
      }
    }

    pageController.animateToPage(
      targetIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    notifyListeners();
  }

  void goToMainPage() {
    updateIndex(_visibilityProvider?.getFirstVisiblePageIndex() ?? 1);
  }

  /// Initialize to first visible page
  void initializeToFirstVisiblePage() {
    if (_visibilityProvider != null) {
      currentIndex = _visibilityProvider!.getFirstVisiblePageIndex();
      notifyListeners();
    }
  }
}
