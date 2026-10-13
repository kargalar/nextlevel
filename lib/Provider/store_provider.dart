import 'package:flutter/material.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/Repository/store_repository.dart';
import 'package:next_level/Repository/user_repository.dart';
import 'package:next_level/Service/global_timer.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Model/store_item_model.dart';
import 'package:next_level/General/accessible.dart';
import 'package:next_level/Provider/user_provider.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Page/Task%20Detail%20Page/view_model/task_progress_view_model.dart';
import 'package:next_level/Core/store_item_progress_policy.dart';

class StoreProvider with ChangeNotifier {
  // burayı singelton yaptım gayet de iyi oldu neden normalde de context den kullanıyoruz anlamadım. galiba "watch" için olabilir. sibelton kısmını global timer için yaptım.
  static final StoreProvider _instance = StoreProvider._internal();
  factory StoreProvider() {
    return _instance;
  }

  StoreProvider._internal();

  final StoreRepository _repository = StoreRepository();
  final Set<int> _purchaseInProgress = <int>{};

// ?? - kredi ve itemler - ye düşebilecek ama bu disipindena eksilmesine sebep oalcak
  List<ItemModel> storeItemList = [];

  void addItem(ItemModel itemModel) async {
    final int storeItemId = await _repository.addItem(itemModel);

    itemModel.id = storeItemId;

    storeItemList.add(itemModel);

    notifyListeners();
  }

  void deleteItem(int id) async {
    await _repository.deleteItem(id);

    storeItemList.removeWhere((element) => element.id == id);

    notifyListeners();
  }

  void editItem(ItemModel itemModel) async {
    await _repository.updateItem(itemModel);

    final int index =
        storeItemList.indexWhere((element) => element.id == itemModel.id);

    storeItemList[index] = itemModel;

    if (itemModel.isTimerActive != null && itemModel.isTimerActive!) {
      GlobalTimer().startStopTimer(storeItemModel: itemModel);
    }

    notifyListeners();
  }

  /// Timer countdown 0'a düştüğünde otomatik satın alım yapar.
  /// Store item widget'ından bağımsız olarak global_timer'dan çağrılabilir.
  Future<bool> autoPurchaseItem(ItemModel item) {
    return purchaseItem(
      item,
      automatic: true,
      showSuccessMessage: true,
    );
  }

  Future<bool> purchaseItem(
    ItemModel item, {
    bool automatic = false,
    bool showSuccessMessage = false,
  }) async {
    if (_purchaseInProgress.contains(item.id)) {
      LogService.debug(
        'Purchase ignored because item ${item.id} is already being processed.',
      );
      return false;
    }

    _purchaseInProgress.add(item.id);
    try {
      if (loginUser == null) {
        LogService.error('Store purchase: loginUser is null');
        return false;
      }

      if (!UserProvider().allowNegativeBalance &&
          loginUser!.userCredit < item.credit) {
        LogService.debug(
          'Store purchase blocked: insufficient credit and negative balance is disabled. Item: ${item.title}',
        );
        Helper().getMessage(
          message: automatic
              ? 'Otomatik Satın Alım İptal Edildi: Yetersiz kredi (${item.title})'
              : 'Yetersiz Kredi! Eksi kredi kullanımı ayarlardan kapalı.',
          status: StatusEnum.WARNING,
        );
        return false;
      }

      loginUser!.userCredit -= item.credit;

      dynamic value;
      if (item.type == TaskTypeEnum.TIMER) {
        final addDuration = item.addDuration ?? Duration.zero;
        // Automatic renewal starts a fresh entitlement period. Carrying a large
        // negative overrun forward could otherwise buy the same item repeatedly.
        item.currentDuration =
            StoreItemProgressPolicy.timerBalanceAfterPurchase(
          currentBalance: item.currentDuration ?? Duration.zero,
          purchasedDuration: addDuration,
          automatic: automatic,
        );
        value = addDuration;
      } else if (item.type == TaskTypeEnum.FREEZE) {
        loginUser!.freezeCount += (item.addCount ?? 1);
        value = item.addCount ?? 1;
      } else {
        item.currentCount = (item.currentCount ?? 0) + item.addCount!;
        value = item.addCount;
      }

      LogService.debug(
          'Store purchase: ${item.title} – credit cost: -${item.credit}, new value: $value, automatic=$automatic');

      await TaskProgressViewModel.addStoreItemLog(
        itemId: item.id,
        action: automatic ? 'Auto Purchase' : 'Purchase',
        value: value,
        type: item.type,
        isPurchase: true,
      );

      await UserRepository().updateUser(loginUser!);
      await StoreRepository().updateItem(item);

      UserProvider().setUser(loginUser!);
      if (showSuccessMessage) {
        Helper().getMessage(
          title: automatic ? 'Auto Purchase' : 'Purchase',
          message: automatic
              ? '${item.title} purchased automatically for ${item.credit} credit.'
              : '${item.title} purchased for ${item.credit} credit.',
          status: StatusEnum.SUCCESS,
          icon: Icons.shopping_cart_checkout_rounded,
          duration: const Duration(seconds: 3),
        );
      }
      notifyListeners();
      return true;
    } finally {
      _purchaseInProgress.remove(item.id);
    }
  }

  void setStateItems() {
    notifyListeners();
  }

  Future<void> loadItems() async {
    try {
      storeItemList = await _repository.getItems();
      notifyListeners();
    } catch (e) {
      LogService.error('❌ StoreProvider: Error loading items: $e');
    }
  }

  Future<void> reorderItems(List<ItemModel> reorderedItems) async {
    try {
      // Her item'e order index'ini ata
      for (int i = 0; i < reorderedItems.length; i++) {
        reorderedItems[i].order = i;
        LogService.debug('🔢 Item ${reorderedItems[i].title}: order = $i');
      }

      storeItemList = reorderedItems;
      await _repository.updateItemsOrder(storeItemList);
      notifyListeners();
      LogService.debug(
          '✅ StoreProvider: Items reordered successfully - ${storeItemList.length} items saved');
    } catch (e) {
      LogService.error('❌ StoreProvider: Error reordering items: $e');
      rethrow;
    }
  }
}
