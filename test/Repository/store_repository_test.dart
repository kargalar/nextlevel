import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:next_level/Repository/store_repository.dart';
import 'package:next_level/Model/store_item_model.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/test_helpers.mocks.dart';

void main() {
  late StoreRepository storeRepository;
  late MockHiveService mockHiveService;

  setUp(() {
    SharedPreferences.setMockInitialValues({'last_item_id': 0});
    mockHiveService = MockHiveService();

    storeRepository = StoreRepository();
    storeRepository.setHiveService(mockHiveService);
  });

  group('StoreRepository Tests', () {
    test('addItem should add item with generated ID and update prefs', () async {
      // Arrange
      final item = ItemModel(
        id: 0,
        title: 'Test Item',
        credit: 100,
        type: TaskTypeEnum.CHECKBOX,
      );

      when(mockHiveService.addItem(any)).thenAnswer((_) async => Future.value());

      // Act
      final newId = await storeRepository.addItem(item);

      // Assert
      expect(newId, 1);
      expect(item.id, 1);
      verify(mockHiveService.addItem(item)).called(1);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('last_item_id'), 1);
    });

    test('updateItem should call hive service', () async {
      final item = ItemModel(
        id: 1,
        title: 'Updated Item',
        credit: 150,
        type: TaskTypeEnum.CHECKBOX,
      );

      when(mockHiveService.updateItem(any)).thenAnswer((_) async => Future.value());

      await storeRepository.updateItem(item);

      verify(mockHiveService.updateItem(item)).called(1);
    });

    test('deleteItem should call hive service', () async {
      const itemId = 1;
      when(mockHiveService.deleteItem(any)).thenAnswer((_) async => Future.value());

      await storeRepository.deleteItem(itemId);

      verify(mockHiveService.deleteItem(itemId)).called(1);
    });

    test('updateItemsOrder should call hive service for each item', () async {
      final items = [
        ItemModel(id: 1, title: 'Item 1', credit: 100, type: TaskTypeEnum.CHECKBOX),
        ItemModel(id: 2, title: 'Item 2', credit: 200, type: TaskTypeEnum.CHECKBOX),
      ];

      when(mockHiveService.updateItem(any)).thenAnswer((_) async => Future.value());

      await storeRepository.updateItemsOrder(items);

      verify(mockHiveService.updateItem(any)).called(2);
    });
  });
}
