import 'package:hive_flutter/hive_flutter.dart';
import 'package:next_level/Model/task_template_model.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Service/data_mutation_notifier.dart';

class TaskTemplateService {
  static const String _boxName = 'task_templates';
  static late Box<TaskTemplateModel> _box;

  static Future<void> initialize() async {
    try {
      _box = await Hive.openBox<TaskTemplateModel>(_boxName);
    } catch (e) {
      LogService.error('❌ Failed to initialize TaskTemplateService: $e');
      rethrow;
    }
  }

  /// Tüm template'leri getir
  static Future<List<TaskTemplateModel>> getAllTemplates() async {
    try {
      return _box.values.toList();
    } catch (e) {
      LogService.error('❌ Failed to get all templates: $e');
      return [];
    }
  }

  /// ID'ye göre template getir
  static Future<TaskTemplateModel?> getTemplateById(int id) async {
    try {
      final templates = _box.values.toList();
      for (var template in templates) {
        if (template.id == id) {
          return template;
        }
      }
      return null;
    } catch (e) {
      LogService.error('❌ Failed to get template by id: $e');
      return null;
    }
  }

  /// Template ekle veya güncelle
  static Future<int> saveTemplate(TaskTemplateModel template) async {
    try {
      if (template.id == 0) {
        // Yeni template - yeni ID oluştur
        final allTemplates = _box.values.toList();
        template.id = allTemplates.isEmpty
            ? 1
            : (allTemplates.map((t) => t.id).reduce((a, b) => a > b ? a : b) +
                1);
      }

      // Same key varsa update, yoksa add
      final key = _getKeyForId(template.id);
      await _box.put(key, template);
      DataMutationNotifier().markDirty('task_template:save');

      LogService.debug(
          '✅ Template saved: ${template.title} (ID: ${template.id})');
      return template.id;
    } catch (e) {
      LogService.error('❌ Failed to save template: $e');
      rethrow;
    }
  }

  /// Template sil
  static Future<void> deleteTemplate(int id) async {
    try {
      final key = _getKeyForId(id);
      await _box.delete(key);
      DataMutationNotifier().markDirty('task_template:delete');
      LogService.debug('✅ Template deleted: ID $id');
    } catch (e) {
      LogService.error('❌ Failed to delete template: $e');
      rethrow;
    }
  }

  /// Tüm template'leri temizle
  static Future<void> clearAllTemplates() async {
    try {
      await _box.clear();
      DataMutationNotifier().markDirty('task_template:clear');
      LogService.debug('✅ All templates cleared');
    } catch (e) {
      LogService.error('❌ Failed to clear templates: $e');
      rethrow;
    }
  }

  /// Template count
  static int getTemplateCount() {
    return _box.length;
  }

  /// Tüm template'lerin order'ını güncelle
  static Future<void> updateTemplatesOrder(
      List<TaskTemplateModel> orderedTemplates) async {
    try {
      for (int i = 0; i < orderedTemplates.length; i++) {
        orderedTemplates[i].order = i;
        final key = _getKeyForId(orderedTemplates[i].id);
        await _box.put(key, orderedTemplates[i]);
      }
      DataMutationNotifier().markDirty('task_template:reorder');
      LogService.debug('✅ Templates order updated');
    } catch (e) {
      LogService.error('❌ Failed to update templates order: $e');
      rethrow;
    }
  }

  /// ID için Hive key'ini oluştur
  static String _getKeyForId(int id) {
    return 'template_$id';
  }
}
