import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  int aaa = 1;
  Future<bool> getSavedTheme() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getBool('isDark') ?? true;
  }

  void changeTheme() async {
    // Theme is now fixed to dark for performance reasons and AppColors is static const
    final SharedPreferences pref = await SharedPreferences.getInstance();
    pref.setBool('isDark', true);

    notifyListeners();
  }
}
