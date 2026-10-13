import 'package:flutter/foundation.dart';
import 'package:next_level/Model/task_template_model.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Service/task_template_service.dart';
import 'package:next_level/Service/task_template_widget_service.dart';

class TaskTemplateProvider extends ChangeNotifier {
  List<TaskTemplateModel> _templates = [];
  TaskTemplateModel? _selectedTemplate;
  bool _isLoading = false;

  List<TaskTemplateModel> get templates => _templates;
  TaskTemplateModel? get selectedTemplate => _selectedTemplate;
  bool get isLoading => _isLoading;

  TaskTemplateProvider() {
    _loadTemplates();
  }

  /// Tüm template'leri yükle
  Future<void> _loadTemplates() async {
    try {
      _isLoading = true;
      notifyListeners();

      _templates = await TaskTemplateService.getAllTemplates();
      // Order'a göre sort et
      _templates.sort((a, b) => a.order.compareTo(b.order));
      LogService.debug('📦 Loaded ${_templates.length} templates');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      LogService.error('❌ Failed to load templates: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Template ekle
  Future<int> addTemplate(TaskTemplateModel template) async {
    try {
      final id = await TaskTemplateService.saveTemplate(template);
      await _loadTemplates();
      await TaskTemplateWidgetService.publish();
      LogService.debug('✅ Template added: ${template.title}');
      return id;
    } catch (e) {
      LogService.error('❌ Failed to add template: $e');
      rethrow;
    }
  }

  /// Template sil
  Future<void> deleteTemplate(int id) async {
    try {
      await TaskTemplateService.deleteTemplate(id);
      await _loadTemplates();
      await TaskTemplateWidgetService.publish();
      LogService.debug('✅ Template deleted');
    } catch (e) {
      LogService.error('❌ Failed to delete template: $e');
      rethrow;
    }
  }

  /// Template seç
  void selectTemplate(TaskTemplateModel template) {
    _selectedTemplate = template;
    LogService.debug('📌 Template selected: ${template.title}');
    notifyListeners();
  }

  /// Template seçimini kaldır
  void clearSelection() {
    _selectedTemplate = null;
    notifyListeners();
  }

  /// Tüm template'leri temizle
  Future<void> clearAllTemplates() async {
    try {
      await TaskTemplateService.clearAllTemplates();
      await _loadTemplates();
      await TaskTemplateWidgetService.publish();
      LogService.debug('✅ All templates cleared');
    } catch (e) {
      LogService.error('❌ Failed to clear templates: $e');
      rethrow;
    }
  }

  /// Template yenile
  void refreshTemplates() {
    _loadTemplates();
  }
}
