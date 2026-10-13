// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:next_level/General/accessible.dart';
import 'package:next_level/Provider/store_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/user_provider.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Repository/task_repository.dart';
import 'package:next_level/Repository/user_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

class NavbarLifecycleHandler {
  static Future<void> handleResumed(BuildContext context) async {
    LogService.debug('✅ App resumed - reloading data');

    try {
      // Reload tasks and logs
      context.read<TaskProvider>().taskList = await TaskRepository().getTasks();
      await context.read<TaskProvider>().refreshOverdueStatuses(notifyOnChange: false);
      await context.read<TaskProvider>().loadCategories();
      LogService.debug('📋 Tasks reloaded');
    } catch (e) {
      LogService.error('Failed to reload tasks: $e');
    }

    try {
      // Reload user info for credit updates
      final user = await UserRepository().getUser(0);
      if (user != null && context.mounted) {
        loginUser = user;
        context.read<UserProvider>().setUser(user);
        LogService.debug('💰 User reloaded: credit=${user.userCredit}');
      }
    } catch (e) {
      LogService.error('Failed to reload user: $e');
    }

    // Refresh UI
    if (context.mounted) {
      context.read<TaskProvider>().updateItems();
    }
  }

  static Future<void> handlePaused(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toIso8601String();

    // Save active task timers
    for (var task in context.read<TaskProvider>().taskList) {
      if (task.isTimerActive == true) {
        prefs.setString('task_last_update_${task.id}', now);
        prefs.setString('task_last_progress_${task.id}', task.currentDuration!.inSeconds.toString());
      }
    }

    // Save active store item timers
    for (var item in context.read<StoreProvider>().storeItemList) {
      if (item.isTimerActive == true) {
        prefs.setString('item_last_update_${item.id}', now);
        prefs.setString('item_last_progress_${item.id}', item.currentDuration!.inSeconds.toString());
      }
    }

    LogService.debug('💾 Timer states saved');
  }
}
