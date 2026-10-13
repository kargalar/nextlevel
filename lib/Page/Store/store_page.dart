import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Store/Widget/store_item.dart';
import 'package:next_level/Page/Store/Widget/credit_info_dialog.dart';
import 'package:next_level/Page/Store/Widget/daily_credit_transactions.dart';
import 'package:next_level/Service/locale_keys.g.dart';
import 'package:next_level/Provider/navbar_provider.dart';
import 'package:next_level/Provider/store_provider.dart';
import 'package:next_level/Provider/user_provider.dart';
import 'package:next_level/Service/hive_service.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/store_item_model.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Page/Task%20Detail%20Page/view_model/task_progress_view_model.dart';
import 'package:provider/provider.dart';
import 'package:next_level/Widgets/Common/app_components.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreProvider>().loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final storeItems = context.watch<StoreProvider>().storeItemList;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) {
        context.read<NavbarProvider>().goToMainPage();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(LocaleKeys.Store.tr()),
          leading: // Daily credit transactions badge
              Padding(
            padding: const EdgeInsets.only(right: 4),
            child: DailyCreditTransactions(),
          ),
          leadingWidth: 150,
          actions: [
            _buildCreditDisplay(),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'reset_credit') {
                  _showResetCreditDialog();
                } else if (value == 'reset_store_progress') {
                  _showResetStoreProgressDialog();
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'reset_credit',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, color: AppColors.text),
                      const SizedBox(width: 8),
                      Text(LocaleKeys.ResetCredit.tr()),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'reset_store_progress',
                  child: Row(
                    children: [
                      Icon(Icons.shopping_cart_outlined, color: AppColors.text),
                      const SizedBox(width: 8),
                      Text(LocaleKeys.ResetStoreProgress.tr()),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: storeItems.isEmpty
            ? _buildEmptyState()
            : ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: storeItems.length,
                onReorderItem: (oldIndex, newIndex) {
                  _onReorderItems(oldIndex, newIndex, storeItems);
                },
                buildDefaultDragHandles: false,
                proxyDecorator: (child, index, animation) {
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (BuildContext context, Widget? child) {
                      final double animValue =
                          Curves.easeInOut.transform(animation.value);
                      final double scale = 1 + (0.05 * animValue);

                      return Transform.scale(
                        scale: scale,
                        child: child,
                      );
                    },
                    child: child,
                  );
                },
                itemBuilder: (context, index) {
                  final item = storeItems[index];
                  return ReorderableDelayedDragStartListener(
                    key: ValueKey(item.id),
                    index: index,
                    child: StoreItem(
                      storeItemModel: item,
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildCreditDisplay() {
    final userProvider = context.watch<UserProvider>();

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => const CreditInfoDialog(),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: AppStatusPill(
          label: userProvider.userCredit.toString(),
          color: AppColors.yellow,
          icon: Icons.monetization_on_rounded,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return AppEmptyState(
      icon: Icons.local_mall_outlined,
      title: LocaleKeys.NoItemsFound.tr(),
      description: 'Create a reward and make your progress tangible.',
      color: AppColors.main,
    );
  }

  void _showResetCreditDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(LocaleKeys.ResetCredit.tr()),
          content: Text(LocaleKeys.ResetCreditWarning.tr()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(LocaleKeys.Cancel.tr()),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _resetCredit();
              },
              child: Text(LocaleKeys.Yes.tr()),
            ),
          ],
        );
      },
    );
  }

  void _showResetStoreProgressDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(LocaleKeys.ResetStoreProgress.tr()),
          content: Text(LocaleKeys.ResetStoreProgressWarning.tr()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(LocaleKeys.Cancel.tr()),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _resetStoreProgress();
              },
              child: Text(LocaleKeys.Yes.tr()),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetCredit() async {
    try {
      final userProvider = context.read<UserProvider>();
      await userProvider.resetCredit();
      setState(() {});
      Helper().getMessage(message: LocaleKeys.ResetCreditSuccess.tr());
    } catch (e) {
      Helper().getMessage(message: "Hata: $e");
    }
  }

  Future<void> _resetStoreProgress() async {
    try {
      final storeProvider = context.read<StoreProvider>();

      // Reset all store items' progress to their initial values
      for (final item in storeProvider.storeItemList) {
        // Reset counter items
        if (item.type == TaskTypeEnum.COUNTER) {
          item.currentCount = 0;
        }
        // Reset timer items
        else if (item.type == TaskTypeEnum.TIMER) {
          item.currentDuration = Duration.zero;
          // Also stop timer if it's active
          if (item.isTimerActive == true) {
            item.isTimerActive = false;
          }
        }

        await HiveService().updateItem(item);

        // Clear logs for this item
        await TaskProgressViewModel.clearStoreItemLogs(item.id);
      }

      // Update the provider to reflect changes in UI
      storeProvider.setStateItems();
      setState(() {});

      Helper().getMessage(message: LocaleKeys.ResetStoreProgressSuccess.tr());
    } catch (e) {
      Helper().getMessage(message: "Hata: $e");
    }
  }

  void _onReorderItems(
      int oldIndex, int newIndex, List<ItemModel> storeItems) async {
    try {
      // Item'ı listeden çıkar ve yeni konuma ekle
      final ItemModel item = storeItems.removeAt(oldIndex);
      storeItems.insert(newIndex, item);

      // Provider'ı güncelle
      await context.read<StoreProvider>().reorderItems(storeItems);

      LogService.debug('✅ Store items reordered successfully');
    } catch (e) {
      LogService.error('❌ Error reordering items: $e');
      Helper().getMessage(message: "Sıralama hatası: $e");
    }
  }
}
