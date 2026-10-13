import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Repository/category_repository.dart';
import 'package:next_level/Service/logging_service.dart';

class CategoryProvider extends ChangeNotifier {
  static final CategoryProvider _instance = CategoryProvider._internal();

  factory CategoryProvider() {
    return _instance;
  }

  CategoryProvider._internal();

  CategoryRepository _categoryRepository = CategoryRepository();

  @visibleForTesting
  void setCategoryRepository(CategoryRepository repo) {
    _categoryRepository = repo;
  }

  List<CategoryModel> categoryList = [];

  Future<void> initialize() async {
    try {
      categoryList = await _categoryRepository.getCategories();
      LogService.debug('✅ CategoryProvider: Loaded ${categoryList.length} categories');
    } catch (e) {
      LogService.error('⚠️ CategoryProvider: Error loading categories: $e');
      // Repository handles the fallout/clearing if needed, or returns empty list.
      // We can rely on repo's behavior or re-fetch.
      categoryList = [];
    }
    notifyListeners();
  }

  Future<void> addCategory(CategoryModel categoryModel) async {
    try {
      // Repository handles ID generation if needed, or we pass it.
      // The current repo impl generates ID if not present or just adds it.
      await _categoryRepository.addCategory(categoryModel);

      // Add to local list
      categoryList.add(categoryModel);

      LogService.debug('✅ CategoryProvider: Added category ${categoryModel.title} (ID: ${categoryModel.id}) to list. Total categories: ${categoryList.length}');

      notifyListeners();
    } catch (e) {
      LogService.error('❌ CategoryProvider: Error adding category ${categoryModel.title}: $e');
      rethrow;
    }
  }

  Future<void> updateCategory(CategoryModel categoryModel) async {
    try {
      await _categoryRepository.updateCategory(categoryModel);

      final index = categoryList.indexWhere((category) => category.id == categoryModel.id);
      if (index != -1) {
        categoryList[index] = categoryModel;
      }

      notifyListeners();
    } catch (e) {
      LogService.error('❌ CategoryProvider: Error updating category: $e');
    }
  }

  Future<void> deleteCategory(CategoryModel categoryModel) async {
    LogService.debug('🗑️ CategoryProvider: Deleting category ${categoryModel.id}');

    try {
      await _categoryRepository.deleteCategory(categoryModel.id);

      categoryList.removeWhere((category) => category.id == categoryModel.id);

      LogService.debug('✅ CategoryProvider: Category deleted, remaining: ${categoryList.length}');

      notifyListeners();
    } catch (e) {
      LogService.error('❌ CategoryProvider: Error deleting category: $e');
    }
  }

  Future<void> archiveCategory(CategoryModel categoryModel) async {
    categoryModel.isArchived = true;
    await updateCategory(categoryModel);
  }

  CategoryModel? getCategoryById(String? categoryId) {
    if (categoryId == null) return null;

    try {
      return categoryList.firstWhere((category) => category.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  List<CategoryModel> getActiveCategories() {
    return categoryList.where((category) => !category.isArchived).toList();
  }

  void clearAllCategories() {
    categoryList.clear();
    notifyListeners();
  }

  void notifyCategoryUpdate() {
    notifyListeners();
  }
}
