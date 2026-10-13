import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Service/hive_service.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:uuid/uuid.dart';
import 'package:next_level/Service/data_mutation_notifier.dart';

class CategoryRepository {
  static final CategoryRepository _instance = CategoryRepository._internal();
  factory CategoryRepository() => _instance;
  CategoryRepository._internal();

  final HiveService _hiveService = HiveService();

  Future<List<CategoryModel>> getCategories() async {
    try {
      return await _hiveService.getCategories();
    } catch (e) {
      LogService.error('⚠️ CategoryRepository: Error loading categories: $e');
      await _hiveService.clearCategoryBox();
      return [];
    }
  }

  Future<String> addCategory(CategoryModel categoryModel) async {
    final String id = const Uuid().v4();
    categoryModel.id = id;
    await _hiveService.addCategory(categoryModel);
    DataMutationNotifier().markDirty('category:add');
    return categoryModel.id;
  }

  Future<void> updateCategory(CategoryModel categoryModel) async {
    await _hiveService.updateCategory(categoryModel);
    DataMutationNotifier().markDirty('category:update');
  }

  Future<void> deleteCategory(String id) async {
    await _hiveService.deleteCategory(id);
    DataMutationNotifier().markDirty('category:delete');
  }
}
