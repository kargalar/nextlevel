import 'package:flutter/material.dart';
import 'package:next_level/Provider/navbar_provider.dart';
import 'package:next_level/Provider/navbar_visibility_provider.dart';
import 'package:get/route_manager.dart';
import 'package:next_level/Service/analytics_service.dart';

class NavigatorService {
  static final NavigatorService _instance = NavigatorService._internal();
  factory NavigatorService() => _instance;
  NavigatorService._internal();

  NavbarVisibilityProvider? _visibilityProvider;

  void setVisibilityProvider(NavbarVisibilityProvider provider) {
    _visibilityProvider = provider;
  }

  Future<dynamic> goTo(
    Widget page, {
    Transition? transition,
  }) async {
    AnalyticsService().trackPageView(page.runtimeType.toString());
    await Get.to(
      page,
      transition: transition ?? Transition.native,
      fullscreenDialog: true,
    );
  }

  void back() {
    Get.back();
  }

  void goBackNavbar({bool isHome = false, bool isDialog = false}) {
    if (isDialog) {
      Get.back();
    }

    Get.until((route) {
      // NavbarPageManager veya root route'a ulaşınca dur
      if (route.settings.name == "/NavbarPageManager") {
        return true;
      } else if (route.settings.name == "/" || route.settings.name == null) {
        return true;
      }
      return false;
    });

    if (isHome) {
      // Go to main page (or first visible page if main is not set/visible)
      int targetIndex = 1; // Default to inbox
      if (_visibilityProvider != null) {
        targetIndex = _visibilityProvider!.getFirstVisiblePageIndex();
      }
      NavbarProvider().updateIndex(targetIndex);
    }
  }
}

// ! veri gönder
// Get.toNamed('/second', arguments: {
//   'name': 'Joseph Onalo',
//   'age': 24,
// });

// ! veri al
// class SecondScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final name = Get.arguments['name'];
//     final age = Get.arguments['age'];

// Get.to('/second');
// Get.to(()=>const SecondScreen());

// Get.back();

// Belirli bir rotaya gitme
// Get.offAllNamed('/first');

// Mevcut rotanın üzerine yeni bir rota itme
// Get.toNamed('/third');

// Bilinen mevcut rotanın üzerine yeni bir rota itme
// Get.toNamed('/second/third');

// Get.to(NextScreen());
// Navigate to new screen with name. See more details on named routes here

// Get.toNamed('/details');
// To close snackbars, dialogs, bottomsheets, or anything you would normally close with    NavigatorService().goBack();

// Get.back();
// To go to the next screen and no option to go back to the previous screen (for use in SplashScreens, login screens, etc.)

// Get.off(NextScreen());
// To go to the next screen and cancel all previous routes (useful in shopping carts, polls, and tests)

// Get.offAll(NextScreen());
