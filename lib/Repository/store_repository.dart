import 'package:flutter/foundation.dart';
import 'package:next_level/Model/store_item_model.dart';
import 'package:next_level/Service/hive_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:next_level/Service/data_mutation_notifier.dart';

class StoreRepository {
  static final StoreRepository _instance = StoreRepository._internal();
  factory StoreRepository() => _instance;
  StoreRepository._internal();

  HiveService _hiveService = HiveService();

  @visibleForTesting
  void setHiveService(HiveService service) {
    _hiveService = service;
  }

  Future<List<ItemModel>> getItems() async {
    return await _hiveService.getItems();
  }

  Future<int> addItem(ItemModel itemModel) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final int lastId = prefs.getInt("last_item_id") ?? 0;

    // Set ID
    itemModel.id = lastId + 1;

    // Save locally first
    await _hiveService.addItem(itemModel);

    // Update ID
    await prefs.setInt("last_item_id", itemModel.id);
    DataMutationNotifier().markDirty('store:add');

    return itemModel.id;
  }

  Future<void> updateItem(ItemModel itemModel) async {
    await _hiveService.updateItem(itemModel);
    DataMutationNotifier().markDirty('store:update');
  }

  Future<void> deleteItem(int id) async {
    await _hiveService.deleteItem(id);
    DataMutationNotifier().markDirty('store:delete');
  }

  Future<void> updateItemsOrder(List<ItemModel> items) async {
    try {
      // Save all items locally to preserve order
      for (final item in items) {
        await _hiveService.updateItem(item);
      }
      DataMutationNotifier().markDirty('store:reorder');
    } catch (e) {
      rethrow;
    }
  }
}
