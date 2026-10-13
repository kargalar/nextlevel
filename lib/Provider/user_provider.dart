import 'package:flutter/material.dart';
import 'package:next_level/Model/user_model.dart';
import 'package:next_level/Service/hive_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

class UserProvider with ChangeNotifier {
  static final UserProvider _instance = UserProvider._internal();

  factory UserProvider() {
    return _instance;
  }

  UserProvider._internal();

  UserModel? _currentUser;
  bool _allowNegativeBalance = false;
  bool _deductCreditOnFail = false;

  UserModel? get currentUser => _currentUser;
  bool get allowNegativeBalance => _allowNegativeBalance;
  bool get deductCreditOnFail => _deductCreditOnFail;

  int get userCredit => _currentUser?.userCredit ?? 0;
  Duration get creditProgress => _currentUser?.creditProgress ?? Duration.zero;
  String get username => _currentUser?.username ?? 'User';
  String get email => _currentUser?.email ?? '';


  void setUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _allowNegativeBalance = prefs.getBool('allowNegativeBalance') ?? false;
    _deductCreditOnFail = prefs.getBool('deductCreditOnFail') ?? false;
    notifyListeners();
  }

  Future<void> setAllowNegativeBalance(bool value) async {
    _allowNegativeBalance = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('allowNegativeBalance', value);
    notifyListeners();
  }

  Future<void> setDeductCreditOnFail(bool value) async {
    _deductCreditOnFail = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('deductCreditOnFail', value);
    notifyListeners();
  }

  Future<void> updateUserCredit(int credit) async {
    if (_currentUser != null) {
      _currentUser!.userCredit = credit;
      await HiveService().updateUser(_currentUser!);
      notifyListeners();
    }
  }

  Future<void> updateCreditProgress(Duration progress) async {
    if (_currentUser != null) {
      _currentUser!.creditProgress = progress;
      await HiveService().updateUser(_currentUser!);
      notifyListeners();
    }
  }

  Future<void> addCredit(int amount) async {
    if (_currentUser != null) {
      _currentUser!.userCredit += amount;
      await HiveService().updateUser(_currentUser!);
      notifyListeners();
    }
  }

  Future<void> resetCredit() async {
    if (_currentUser != null) {
      _currentUser!.userCredit = 0;
      _currentUser!.creditProgress = Duration.zero;
      await HiveService().updateUser(_currentUser!);
      notifyListeners();
    }
  }


}
