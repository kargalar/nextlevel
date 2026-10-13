import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:next_level/Provider/category_provider.dart';
import 'package:next_level/Model/category_model.dart';
import '../helpers/test_helpers.mocks.dart';

void main() {
  late CategoryProvider categoryProvider;
  late MockCategoryRepository mockCategoryRepository;

  setUp(() {
    mockCategoryRepository = MockCategoryRepository();
    categoryProvider = CategoryProvider();
    categoryProvider.setCategoryRepository(mockCategoryRepository);
    categoryProvider.clearAllCategories();
  });

  group('CategoryProvider Tests', () {
    test('initialize should load categories from repository', () async {
      // Arrange
      final categories = [
        CategoryModel(id: '1', title: 'Work', colorValue: 123, iconCodePoint: 456),
        CategoryModel(id: '2', title: 'Personal', colorValue: 789, iconCodePoint: 101),
      ];
      when(mockCategoryRepository.getCategories()).thenAnswer((_) async => categories);

      // Act
      await categoryProvider.initialize();

      // Assert
      expect(categoryProvider.categoryList.length, 2);
      expect(categoryProvider.categoryList, categories);
      verify(mockCategoryRepository.getCategories()).called(1);
    });

    test('addCategory should add category to list and call repository', () async {
      // Arrange
      final category = CategoryModel(id: '1', title: 'New Cat', colorValue: 111, iconCodePoint: 222);
      when(mockCategoryRepository.addCategory(any)).thenAnswer((_) async => '1');

      // Act
      await categoryProvider.addCategory(category);

      // Assert
      expect(categoryProvider.categoryList.contains(category), true);
      verify(mockCategoryRepository.addCategory(category)).called(1);
    });

    test('updateCategory should update category in list and call repository', () async {
      // Arrange
      final category = CategoryModel(id: '1', title: 'Old Cat', colorValue: 111, iconCodePoint: 222);
      categoryProvider.categoryList.add(category);

      final updatedCategory = CategoryModel(id: '1', title: 'Updated Cat', colorValue: 333, iconCodePoint: 444);
      when(mockCategoryRepository.updateCategory(any)).thenAnswer((_) async => Future.value());

      // Act
      await categoryProvider.updateCategory(updatedCategory);

      // Assert
      expect(categoryProvider.categoryList.first.title, 'Updated Cat');
      verify(mockCategoryRepository.updateCategory(updatedCategory)).called(1);
    });

    test('deleteCategory should remove category from list and call repository', () async {
      // Arrange
      final category = CategoryModel(id: '1', title: 'To Delete', colorValue: 111, iconCodePoint: 222);
      categoryProvider.categoryList.add(category);
      when(mockCategoryRepository.deleteCategory(any)).thenAnswer((_) async => Future.value());

      // Act
      await categoryProvider.deleteCategory(category);

      // Assert
      expect(categoryProvider.categoryList.isEmpty, true);
      verify(mockCategoryRepository.deleteCategory(category.id)).called(1);
    });
  });
}
