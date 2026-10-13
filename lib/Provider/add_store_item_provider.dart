import 'dart:async';
import 'package:flutter/material.dart';
import 'package:next_level/Provider/store_provider.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/store_item_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddStoreItemProvider with ChangeNotifier {
  // Widget variables
  ItemModel? editItem;
  TextEditingController taskNameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  // Focus nodes for managing keyboard focus
  final FocusNode taskNameFocus = FocusNode();
  final FocusNode descriptionFocus = FocusNode();

  // Description editor timer
  Timer? _descriptionTimer;
  Duration _descriptionTimeSpent = Duration.zero;
  DateTime? _descriptionStartTime;
  bool _isDescriptionTimerActive = false;

  int addCount = 1;
  Duration taskDuration = const Duration(hours: 0, minutes: 0);
  TaskTypeEnum selectedTaskType = TaskTypeEnum.COUNTER;
  int credit = 0;

  Duration get descriptionTimeSpent => _descriptionTimeSpent;
  bool get isDescriptionTimerActive => _isDescriptionTimerActive;

  void startDescriptionTimer() async {
    if (!_isDescriptionTimerActive) {
      _isDescriptionTimerActive = true;
      _descriptionStartTime = DateTime.now();

      // Load persisted time for this store item
      await _loadDescriptionTime();
      _descriptionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_descriptionStartTime != null) {
          _descriptionTimeSpent = _descriptionTimeSpent + const Duration(seconds: 1);
          notifyListeners();

          // Save time every second as requested
          _saveDescriptionTime();
        }
      });

      notifyListeners();
    }
  }

  void pauseDescriptionTimer() {
    if (_isDescriptionTimerActive) {
      _isDescriptionTimerActive = false;
      _descriptionTimer?.cancel();
      _descriptionTimer = null;
      _descriptionStartTime = null;
      _saveDescriptionTime();
      notifyListeners();
    }
  }

  void resetDescriptionTimer() {
    _descriptionTimeSpent = Duration.zero;
    _isDescriptionTimerActive = false;
    _descriptionTimer?.cancel();
    _descriptionTimer = null;
    _descriptionStartTime = null;
    _saveDescriptionTime();
    notifyListeners();
  }

  String _getDescriptionTimerKey() {
    if (editItem != null) {
      return 'description_timer_store_${editItem!.id}';
    } else {
      return 'description_timer_new_store';
    }
  }

  Future<void> _loadDescriptionTime() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getDescriptionTimerKey();
    final savedSeconds = prefs.getInt(key) ?? 0;
    _descriptionTimeSpent = Duration(seconds: savedSeconds);
  }

  Future<void> _saveDescriptionTime() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getDescriptionTimerKey();
    await prefs.setInt(key, _descriptionTimeSpent.inSeconds);
  }

  String formatDescriptionTime() {
    final hours = _descriptionTimeSpent.inHours;
    final minutes = (_descriptionTimeSpent.inMinutes % 60);
    final seconds = (_descriptionTimeSpent.inSeconds % 60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  void addItem() {
    StoreProvider().addItem(
      ItemModel(
        title: taskNameController.text,
        description: descriptionController.text.isNotEmpty ? descriptionController.text : null,
        type: selectedTaskType,
        credit: credit,
        currentCount: selectedTaskType == TaskTypeEnum.COUNTER ? 0 : null,
        currentDuration: selectedTaskType == TaskTypeEnum.TIMER ? Duration.zero : null,
        addDuration: taskDuration,
        addCount: addCount,
        isTimerActive: selectedTaskType == TaskTypeEnum.TIMER ? false : null,
      ),
    );
    // Reset form state after adding new item so next add starts clean
    setEditItem(null);
  }

  void updateItem(ItemModel existingItem) {
    final updatedItem = ItemModel(
      id: existingItem.id,
      title: taskNameController.text,
      description: descriptionController.text.isNotEmpty ? descriptionController.text : null,
      type: selectedTaskType,
      credit: credit,
      currentCount: selectedTaskType == TaskTypeEnum.COUNTER ? existingItem.currentCount : null,
      currentDuration: selectedTaskType == TaskTypeEnum.TIMER ? existingItem.currentDuration : null,
      addDuration: taskDuration,
      addCount: addCount,
      isTimerActive: selectedTaskType == TaskTypeEnum.TIMER ? existingItem.isTimerActive : null,
    );

    // Update the editItem reference
    editItem = updatedItem;

    StoreProvider().editItem(updatedItem);
  }

  void setEditItem(ItemModel? item) {
    editItem = item;
    if (item != null) {
      taskNameController.text = item.title;
      descriptionController.text = item.description ?? '';
      credit = item.credit;
      taskDuration = item.addDuration!;
      selectedTaskType = item.type;
      addCount = item.addCount ?? 1;
    } else {
      taskNameController.clear();
      descriptionController.clear();
      credit = 0;
      taskDuration = const Duration(hours: 0, minutes: 0);
      selectedTaskType = TaskTypeEnum.COUNTER;
      addCount = 1;
    }
    notifyListeners();
  }

  void updateTargetCount(int value) {
    addCount = value;
    notifyListeners();
  }

  // Method to update selected task type and notify listeners
  void updateSelectedTaskType(TaskTypeEnum taskType) {
    selectedTaskType = taskType;
    notifyListeners();
  }

  // Credit helpers to ensure UI updates consistently
  void setCredit(int value) {
    if (value < 0) value = 0;
    credit = value;
    notifyListeners();
  }

  void incrementCredit() {
    credit += 1;
    notifyListeners();
  }

  void decrementCredit() {
    if (credit > 0) {
      credit -= 1;
      notifyListeners();
    }
  }

  // Method to unfocus all text fields
  void unfocusAll() {
    try {
      if (taskNameFocus.hashCode != 0) {
        taskNameFocus.unfocus();
      }
    } catch (e) {
      // Focus node may have issues
    }

    try {
      if (descriptionFocus.hashCode != 0) {
        descriptionFocus.unfocus();
      }
    } catch (e) {
      // Focus node may have issues
    }
  }

  // Dispose focus nodes when provider is disposed
  void disposeFocusNodes() {
    try {
      if (taskNameFocus.hashCode != 0) {
        taskNameFocus.dispose();
      }
    } catch (e) {
      // Focus node may already be disposed
    }

    try {
      if (descriptionFocus.hashCode != 0) {
        descriptionFocus.dispose();
      }
    } catch (e) {
      // Focus node may already be disposed
    }
  }

  @override
  void dispose() {
    _descriptionTimer?.cancel();

    // Dispose controllers and focus nodes safely
    try {
      taskNameController.dispose();
    } catch (e) {
      // Controller may already be disposed
    }

    disposeFocusNodes();
    super.dispose();
  }
}
