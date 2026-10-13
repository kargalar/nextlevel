import 'package:flutter/material.dart';
import 'package:next_level/Model/store_item_model.dart';
import 'package:next_level/Provider/add_store_item_provider.dart';
import 'package:next_level/Provider/add_task_provider.dart';
import 'package:next_level/Repository/task_repository.dart';
import 'package:next_level/Repository/store_repository.dart';
import 'package:next_level/Widgets/Common/description_editor.dart' as shared;
import 'package:provider/provider.dart';
import 'package:next_level/Service/logging_service.dart';

/// Wrapper for the task/store description editor
/// Uses the shared DescriptionEditor component
class DescriptionEditor extends StatefulWidget {
  const DescriptionEditor({
    super.key,
    this.isStore = false,
  });

  final bool isStore;

  @override
  State<DescriptionEditor> createState() => _DescriptionEditorState();
}

class _DescriptionEditorState extends State<DescriptionEditor> {
  late dynamic _provider;

  @override
  void initState() {
    super.initState();

    if (widget.isStore) {
      _provider = context.read<AddStoreItemProvider>();
    } else {
      _provider = context.read<AddTaskProvider>();
    }
  }

  void _autoSave(String text) {
    if (!widget.isStore) {
      // For tasks, check if we're editing an existing task
      final taskProvider = _provider as AddTaskProvider;
      if (taskProvider.editTask != null) {
        // Update the existing task's description
        taskProvider.editTask!.description = text.isNotEmpty ? text : null;
        // Save to database
        TaskRepository().updateTask(taskProvider.editTask!);
        LogService.debug('✅ Task description auto-saved: ${text.length} characters');
      }
      // For new tasks, the description will be saved when the task is created
    } else {
      // For store items, check if we're editing an existing item
      final storeProvider = _provider as AddStoreItemProvider;
      if (storeProvider.editItem != null) {
        // Create a new ItemModel with updated description since description is final
        final updatedItem = ItemModel(
          id: storeProvider.editItem!.id,
          title: storeProvider.editItem!.title,
          description: text.isNotEmpty ? text : null,
          type: storeProvider.editItem!.type,
          credit: storeProvider.editItem!.credit,
          currentCount: storeProvider.editItem!.currentCount,
          currentDuration: storeProvider.editItem!.currentDuration,
          addDuration: storeProvider.editItem!.addDuration,
          addCount: storeProvider.editItem!.addCount,
          isTimerActive: storeProvider.editItem!.isTimerActive,
        );

        // Update the editItem reference
        storeProvider.editItem = updatedItem;

        // Save to database
        StoreRepository().updateItem(updatedItem);
        LogService.debug('✅ Store item description auto-saved: ${text.length} characters');
      }
      // For new store items, the description will be saved when the item is created
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.isStore
        ? Consumer<AddStoreItemProvider>(
            builder: (context, provider, child) {
              return shared.DescriptionEditor(
                controller: provider.descriptionController,
                focusNode: provider.descriptionFocus,
                onChanged: _autoSave,
              );
            },
          )
        : Consumer<AddTaskProvider>(
            builder: (context, provider, child) {
              return shared.DescriptionEditor(
                controller: provider.descriptionController,
                focusNode: provider.descriptionFocus,
                onChanged: _autoSave,
              );
            },
          );
  }
}
