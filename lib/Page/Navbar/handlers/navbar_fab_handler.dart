import 'package:flutter/material.dart';
import 'package:next_level/Page/Home/Add%20Task/add_task_page.dart';
import 'package:next_level/Page/Home/Widget/compact_add_task_bottom_sheet.dart';
import 'package:next_level/Page/Home/Widget/task_templates_bottom_sheet.dart';
import 'package:next_level/Page/Store/add_store_item_page.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Widgets/add_edit_item_bottom_sheet.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class NavbarFABHandler {
  final BuildContext context;

  NavbarFABHandler(this.context);

  /// Build FAB based on current tab
  Widget buildFAB(int currentIndex) {
    if (!_shouldShowFAB(currentIndex)) {
      return const SizedBox();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (currentIndex == 1 || currentIndex == 2) _buildCompactAddFAB(),
        if (currentIndex != 1 && currentIndex != 2) _buildMainFAB(currentIndex),
      ],
    );
  }

  /// Check if FAB should be shown for current tab
  bool _shouldShowFAB(int currentIndex) {
    return currentIndex == 0 ||
        currentIndex == 1 ||
        currentIndex == 2 ||
        currentIndex == 3 ||
        currentIndex == 4;
  }

  /// Build compact add FAB for Home tab
  Widget _buildCompactAddFAB() {
    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        LogService.debug('📚 Task Templates opened from long press');
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.black.withValues(alpha: .58),
          builder: (context) => const TaskTemplatesBottomSheet(),
        );
      },
      child: FloatingActionButton.extended(
        heroTag: 'quick_add_task',
        onPressed: () {
          HapticFeedback.lightImpact();
          LogService.debug('⚡ Compact Add Task FAB pressed');
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            barrierColor: Colors.black.withValues(alpha: .58),
            builder: (context) => const CompactAddTaskBottomSheet(),
          );
        },
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text('Add task'),
      ),
    );
  }

  /// Build main FAB with action based on tab
  Widget _buildMainFAB(int currentIndex) {
    return FloatingActionButton.extended(
      heroTag: 'add_item_$currentIndex',
      onPressed: () {
        HapticFeedback.lightImpact();
        _handleFABPress(currentIndex);
      },
      icon: const Icon(Icons.add_rounded, size: 22),
      label: Text(_fabLabel(currentIndex)),
    );
  }

  String _fabLabel(int currentIndex) {
    switch (currentIndex) {
      case 0:
        return 'Add reward';
      case 3:
        return 'Add note';
      case 4:
        return 'Add project';
      default:
        return 'Add';
    }
  }

  /// Handle FAB press based on current tab
  Future<void> _handleFABPress(int currentIndex) async {
    switch (currentIndex) {
      case 0:
        // Store tab
        await NavigatorService().goTo(
          const AddStoreItemPage(),
          transition: Transition.downToUp,
        );
        break;
      case 1:
      case 2:
        // Home or Inbox tab
        await NavigatorService().goTo(
          const AddTaskPage(),
          transition: Transition.downToUp,
        );
        break;
      case 3:
        // Notes tab
        _showAddItemBottomSheet(ItemType.note);
        break;
      case 4:
        // Projects tab
        _showAddItemBottomSheet(ItemType.project);
        break;
    }
  }

  /// Show add/edit item bottom sheet
  void _showAddItemBottomSheet(ItemType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditItemBottomSheet(type: type),
    );
  }
}
