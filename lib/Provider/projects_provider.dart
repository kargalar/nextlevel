import 'package:flutter/material.dart';
import 'package:next_level/Model/project_model.dart';
import 'package:next_level/Model/project_subtask_model.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Service/projects_service.dart';
import 'package:next_level/Service/project_subtasks_service.dart';
import 'package:next_level/Provider/category_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Core/Handlers/task_action_handler.dart';
import 'package:next_level/Enum/task_status_enum.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Service/logging_service.dart';

/// Projeleri yöneten Provider
class ProjectsProvider with ChangeNotifier {
  static final ProjectsProvider _instance = ProjectsProvider._internal();

  factory ProjectsProvider() {
    return _instance;
  }

  ProjectsProvider._internal() {
    loadProjects();
    loadCategories();
  }

  final ProjectsService _projectsService = ProjectsService();
  final ProjectSubtasksService _subtasksService = ProjectSubtasksService();

  // State
  List<ProjectModel> _projects = [];
  final List<CategoryModel> _categories = [];
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;
  bool _showArchivedOnly = false;
  String? _selectedCategoryId;
  int _taskCountVersion = 0;

  // Getters
  List<ProjectModel> get projects => _projects;
  List<CategoryModel> get categories => _categories;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get showArchivedOnly => _showArchivedOnly;
  String? get selectedCategoryId => _selectedCategoryId;
  int get taskCountVersion => _taskCountVersion;

  /// Kategorileri yükle (sadece project kategorileri)
  Future<void> loadCategories() async {
    try {
      LogService.debug('📡 ProjectsProvider: Loading categories');
      final categoryProvider = CategoryProvider();
      await categoryProvider.initialize();
      _categories.clear();
      // Sadece project tipindeki kategorileri al
      final projectCategories = categoryProvider.categoryList
          .where((category) => category.categoryType == CategoryType.project)
          .toList();
      _categories.addAll(projectCategories);
      LogService.debug(
          '✅ ProjectsProvider: Loaded ${_categories.length} project categories (filtered from ${categoryProvider.categoryList.length} total)');
      notifyListeners();
    } catch (e) {
      LogService.error('❌ ProjectsProvider: Error loading categories: $e');
    }
  }

  /// Kategori filtresi ayarla
  void setSelectedCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    LogService.debug(
        '🔍 ProjectsProvider: Category filter set to: $categoryId');
    notifyListeners();
  }

  /// Get category by ID
  CategoryModel? getCategoryById(String? id) {
    if (id == null) return null;
    return _categories.firstWhere(
      (category) => category.id == id,
      orElse: () =>
          CategoryModel(id: '', title: '', colorValue: Colors.grey.toARGB32()),
    );
  }

  /// Add new category
  Future<bool> addCategory(CategoryModel category) async {
    try {
      final categoryProvider = CategoryProvider();
      await categoryProvider.addCategory(category);

      // Kategoriyi listeye hemen ekle
      _categories.add(category);

      // UI'ı hemen güncelle
      notifyListeners();

      LogService.debug('✅ ProjectsProvider: Category added successfully');
      return true;
    } catch (e) {
      LogService.error('❌ ProjectsProvider: Error adding category: $e');
      return false;
    }
  }

  /// Update category
  Future<bool> updateCategory(CategoryModel category) async {
    try {
      final categoryProvider = CategoryProvider();
      categoryProvider.updateCategory(category);

      // Kategoriyi listede güncelle
      final index = _categories.indexWhere((cat) => cat.id == category.id);
      if (index != -1) {
        _categories[index] = category;
      }

      // UI'ı hemen güncelle
      notifyListeners();

      LogService.debug('✅ ProjectsProvider: Category updated successfully');
      return true;
    } catch (e) {
      LogService.error('❌ ProjectsProvider: Error updating category: $e');
      return false;
    }
  }

  /// Delete category
  Future<bool> deleteCategory(String categoryId) async {
    try {
      LogService.debug('🗑️ ProjectsProvider: Deleting category: $categoryId');

      // Bu kategoriye ait projeleri kontrol et
      final projectsInCategory = _projects
          .where((project) => project.categoryId == categoryId)
          .toList();
      if (projectsInCategory.isNotEmpty) {
        LogService.debug(
            '⚠️ ProjectsProvider: Category has ${projectsInCategory.length} projects, deleting them first');
        // Kategoriye ait tüm projeleri sil
        for (final project in projectsInCategory) {
          await deleteProject(project.id);
        }
      }

      final category = getCategoryById(categoryId);
      if (category != null) {
        final categoryProvider = CategoryProvider();
        await categoryProvider.deleteCategory(category);

        // Kategoriyi listeden hemen kaldır
        _categories.removeWhere((cat) => cat.id == categoryId);

        if (_selectedCategoryId == categoryId) {
          _selectedCategoryId = null;
        }

        // UI'ı hemen güncelle
        notifyListeners();

        LogService.debug('✅ ProjectsProvider: Category deleted successfully');
        return true;
      } else {
        LogService.debug('❌ ProjectsProvider: Category not found');
        return false;
      }
    } catch (e) {
      LogService.error('❌ ProjectsProvider: Error deleting category: $e');
      return false;
    }
  }

  /// Proje sayıları (kategori bazlı)
  Map<String, int> get projectCounts {
    final counts = <String, int>{};
    for (var category in _categories) {
      counts[category.id] = _projects
          .where((project) => project.categoryId == category.id)
          .length;
    }
    return counts;
  }

  /// Filtrelenmiş projeler
  List<ProjectModel> get filteredProjects {
    var filtered = _projects;

    // Arşiv filtreleme
    if (_showArchivedOnly) {
      filtered = filtered.where((project) => project.isArchived).toList();
    } else {
      filtered = filtered.where((project) => !project.isArchived).toList();
    }

    // Kategori filtreleme
    if (_selectedCategoryId != null) {
      filtered = filtered
          .where((project) => project.categoryId == _selectedCategoryId)
          .toList();
    }

    // Arama filtreleme
    if (_searchQuery.isNotEmpty) {
      final queryLower = _searchQuery.toLowerCase();
      filtered = filtered.where((project) {
        return project.title.toLowerCase().contains(queryLower) ||
            project.description.toLowerCase().contains(queryLower);
      }).toList();
    }

    return filtered;
  }

  /// Sabitlenmiş projeler
  List<ProjectModel> get pinnedProjects {
    final pinned =
        filteredProjects.where((project) => project.isPinned).toList();
    // sortOrder'a göre sırala (yüksek değer = üstte)
    pinned.sort((a, b) => b.sortOrder.compareTo(a.sortOrder));
    return pinned;
  }

  /// Sabitlenmemiş projeler
  List<ProjectModel> get unpinnedProjects {
    final unpinned =
        filteredProjects.where((project) => !project.isPinned).toList();
    // sortOrder'a göre sırala (yüksek değer = üstte)
    unpinned.sort((a, b) => b.sortOrder.compareTo(a.sortOrder));
    return unpinned;
  }

  /// Projeleri yükle
  Future<void> loadProjects() async {
    try {
      LogService.debug('📡 ProjectsProvider: Loading projects from Hive');
      _setLoading(true);
      _setError(null);

      await _projectsService.initialize();
      _projects = await _projectsService.getProjects();

      LogService.debug(
          '✅ ProjectsProvider: Loaded ${_projects.length} projects');
      _setLoading(false);
    } catch (e) {
      LogService.error('❌ ProjectsProvider: Error loading projects: $e');
      _setError('Projeler yüklenirken hata oluştu: $e');
      _setLoading(false);
    }
  }

  /// Yeni proje ekle
  Future<bool> addProject(ProjectModel project) async {
    try {
      LogService.debug('➕ ProjectsProvider: Adding new project');
      final success = await _projectsService.addProject(project);
      if (success) {
        await loadProjects();
        LogService.debug('✅ ProjectsProvider: Project added successfully');
      }
      return success;
    } catch (e) {
      LogService.error('❌ ProjectsProvider: Error adding project: $e');
      return false;
    }
  }

  /// Projeyi güncelle
  Future<bool> updateProject(ProjectModel project) async {
    try {
      LogService.debug('🔄 ProjectsProvider: Updating project');
      final success = await _projectsService.updateProject(project);
      if (success) {
        await loadProjects();
        LogService.debug('✅ ProjectsProvider: Project updated successfully');
      }
      return success;
    } catch (e) {
      LogService.error('❌ ProjectsProvider: Error updating project: $e');
      return false;
    }
  }

  /// Projeyi sil (subtask ve notlar ile birlikte)
  Future<bool> deleteProject(String projectId) async {
    try {
      LogService.debug('🗑️ ProjectsProvider: Deleting project and its data');

      // Önce subtaskları sil
      await _subtasksService.deleteSubtasksByProjectId(projectId);

      // Sonra projeyi sil
      final success = await _projectsService.deleteProject(projectId);
      if (success) {
        await loadProjects();
        LogService.debug('✅ ProjectsProvider: Project deleted successfully');
      }
      return success;
    } catch (e) {
      LogService.error('❌ ProjectsProvider: Error deleting project: $e');
      return false;
    }
  }

  /// Pin/unpin project
  Future<bool> togglePinProject(String projectId) async {
    try {
      LogService.debug('📌 ProjectsProvider: Toggling project pin');
      final success = await _projectsService.togglePinProject(projectId);
      if (success) {
        await loadProjects();
        LogService.debug(
            '✅ ProjectsProvider: Project pin toggled successfully');
      }
      return success;
    } catch (e) {
      LogService.error('❌ ProjectsProvider: Error toggling pin: $e');
      return false;
    }
  }

  /// Change archive filter
  void toggleArchivedFilter() {
    LogService.debug(
        '📦 ProjectsProvider: Toggling archived filter - Current: $_showArchivedOnly');
    _showArchivedOnly = !_showArchivedOnly;
    LogService.debug(
        '📦 ProjectsProvider: New archived filter state: $_showArchivedOnly');
    notifyListeners();
  }

  /// Archive/unarchive project
  Future<bool> toggleArchiveProject(String projectId) async {
    try {
      LogService.debug('📦 ProjectsProvider: Toggling project archive');
      final success = await _projectsService.toggleArchiveProject(projectId);
      if (success) {
        await loadProjects();
        LogService.debug(
            '✅ ProjectsProvider: Project archive toggled successfully');
      }
      return success;
    } catch (e) {
      LogService.error('❌ ProjectsProvider: Error toggling archive: $e');
      return false;
    }
  }

  /// Projelerin sırasını değiştir (sürükle-bırak için)
  Future<bool> reorderProjects({
    required int oldIndex,
    required int newIndex,
    required bool isPinnedList,
  }) async {
    try {
      LogService.debug(
          '🔄 ProjectsProvider: Reordering projects from $oldIndex to $newIndex (pinned: $isPinnedList)');
      _setError(null);

      // Doğru listeyi al
      final projectsList = List<ProjectModel>.from(
          isPinnedList ? pinnedProjects : unpinnedProjects);

      if (oldIndex >= projectsList.length ||
          newIndex >= projectsList.length ||
          oldIndex < 0 ||
          newIndex < 0) {
        LogService.error(
            '❌ ProjectsProvider: Invalid reorder indices - oldIndex: $oldIndex, newIndex: $newIndex, listLength: ${projectsList.length}');
        return false;
      }

      // Taşınacak projeyi listeden çıkar
      final movedProject = projectsList.removeAt(oldIndex);

      // Yeni pozisyona ekle
      projectsList.insert(newIndex, movedProject);

      LogService.debug('  📋 New order after move:');
      for (var i = 0; i < projectsList.length; i++) {
        LogService.debug(
            '    $i: Project ${projectsList[i].id} - ${projectsList[i].title}');
      }

      // Önce tüm projeleri lokal olarak güncelle (optimistik UI güncellemesi)
      final updatedProjects = <ProjectModel>[];
      for (int i = 0; i < projectsList.length; i++) {
        final project = projectsList[i];
        final newSortOrder = projectsList.length - i; // Tersten sıralama

        if (project.sortOrder != newSortOrder) {
          final updatedProject = project.copyWith(
            sortOrder: newSortOrder,
            updatedAt: DateTime.now(),
          );
          updatedProjects.add(updatedProject);

          // Lokal listeyi hemen güncelle
          final mainIndex = _projects.indexWhere((p) => p.id == project.id);
          if (mainIndex != -1) {
            _projects[mainIndex] = updatedProject;
          }

          LogService.debug(
              '  ✏️ Updated Project ${project.id}: sortOrder ${project.sortOrder} → $newSortOrder');
        }
      }

      // UI'ı hemen güncelle (kullanıcı anında değişikliği görsün)
      notifyListeners();
      LogService.debug('  🎨 UI updated immediately');

      // Ardından veritabanına kaydet (arka planda)
      for (final updatedProject in updatedProjects) {
        await _projectsService.updateProject(updatedProject);
      }

      LogService.debug(
          '✅ ProjectsProvider: Projects reordered and saved successfully');
      return true;
    } catch (e) {
      LogService.error('❌ ProjectsProvider: Error reordering projects: $e');
      _setError('Proje sıralaması değiştirilirken hata oluştu: $e');
      // Hata durumunda listeyi yeniden yükle
      await loadProjects();
      return false;
    }
  }

  /// Arama sorgusu güncelle
  void updateSearchQuery(String query) {
    LogService.debug('🔍 ProjectsProvider: Search query updated: $query');
    _searchQuery = query;
    notifyListeners();
  }

  /// Arama sorgusunu temizle
  void clearSearchQuery() {
    LogService.debug('🔍 ProjectsProvider: Search query cleared');
    _searchQuery = '';
    notifyListeners();
  }

  /// ID'ye göre proje getir
  ProjectModel? getProjectById(String projectId) {
    return _projectsService.getProjectById(projectId);
  }

  /// Projeye ait subtask'ları getir
  Future<List<ProjectSubtaskModel>> getProjectSubtasks(String projectId) async {
    return await _subtasksService.getSubtasksByProjectId(projectId);
  }

  /// Returns the regular task linked to a project subtask, if it is loaded.
  TaskModel? getLinkedTask(ProjectSubtaskModel subtask) {
    final taskId = subtask.taskId;
    if (taskId == null) return null;

    for (final task in TaskProvider().taskList) {
      if (task.id == taskId) return task;
    }
    return null;
  }

  /// Creates a regular checkbox task from a project subtask and stores the link.
  Future<bool> createTaskFromSubtask(String subtaskId) async {
    try {
      final allSubtasks = await _subtasksService.getAllSubtasks();
      final subtask = allSubtasks.firstWhere(
        (item) => item.id == subtaskId,
        orElse: () => throw StateError('Project subtask not found'),
      );

      if (getLinkedTask(subtask) != null) return false;

      // A deleted regular task can leave an old link behind. Clear it before
      // creating a replacement instead of silently creating duplicates.
      if (subtask.taskId != null) {
        subtask.taskId = null;
        await _subtasksService.updateSubtask(subtask);
      }

      final project = getProjectById(subtask.projectId);
      final task = TaskModel(
        title: subtask.title,
        description: subtask.description,
        type: TaskTypeEnum.CHECKBOX,
        isNotificationOn: false,
        isAlarmOn: false,
        status: subtask.isCompleted ? TaskStatusEnum.DONE : null,
        categoryId: project?.categoryId,
      );

      await TaskProvider().addTask(task);
      if (subtask.isCompleted) {
        // Keep XP and history consistent when converting an already completed
        // checklist item into a regular task.
        TaskProvider().completeTaskWithUndo(task, showUndo: false);
      }
      subtask.taskId = task.id;
      final success = await updateSubtask(subtask);
      if (!success) return false;

      LogService.debug(
          'Created regular task ${task.id} from project subtask ${subtask.id}');
      return true;
    } catch (e) {
      LogService.error('Error creating task from project subtask: $e');
      return false;
    }
  }

  /// Keeps a linked project subtask aligned with a regular task action.
  Future<void> syncSubtaskFromTask(TaskModel task) async {
    try {
      final linkedSubtasks = (await _subtasksService.getAllSubtasks())
          .where((subtask) => subtask.taskId == task.id)
          .toList();
      final isCompleted = task.status == TaskStatusEnum.DONE;

      for (final subtask in linkedSubtasks) {
        if (subtask.isCompleted == isCompleted) continue;
        subtask.isCompleted = isCompleted;
        await _subtasksService.updateSubtask(subtask);
      }
      if (linkedSubtasks.isNotEmpty) _incrementTaskCountVersion();
    } catch (e) {
      LogService.error('Error syncing project subtask from task: $e');
    }
  }

  /// Subtask ekle
  Future<bool> addSubtask(ProjectSubtaskModel subtask) async {
    try {
      LogService.debug('➕ ProjectsProvider: Adding subtask');
      final success = await _subtasksService.addSubtask(subtask);
      if (success) {
        LogService.debug('✅ ProjectsProvider: Subtask added successfully');
        _incrementTaskCountVersion();
      }
      return success;
    } catch (e) {
      LogService.error('❌ ProjectsProvider: Error adding subtask: $e');
      return false;
    }
  }

  /// Subtask güncelle
  Future<bool> updateSubtask(ProjectSubtaskModel subtask) async {
    try {
      LogService.debug('🔄 ProjectsProvider: Updating subtask');
      final success = await _subtasksService.updateSubtask(subtask);
      if (success) {
        LogService.debug('✅ ProjectsProvider: Subtask updated successfully');
        _incrementTaskCountVersion();
      }
      return success;
    } catch (e) {
      LogService.error('❌ ProjectsProvider: Error updating subtask: $e');
      return false;
    }
  }

  /// Change subtask completion status
  Future<bool> toggleSubtaskCompleted(String subtaskId) async {
    try {
      LogService.debug('✅ ProjectsProvider: Toggling subtask completed');
      final success = await _subtasksService.toggleSubtaskCompleted(subtaskId);
      if (success) {
        LogService.debug('✅ ProjectsProvider: Subtask toggled successfully');
        final subtask = (await _subtasksService.getAllSubtasks()).firstWhere(
          (item) => item.id == subtaskId,
        );
        final linkedTask = getLinkedTask(subtask);
        if (linkedTask != null) {
          final taskIsCompleted = linkedTask.status == TaskStatusEnum.DONE;
          if (taskIsCompleted != subtask.isCompleted) {
            await TaskActionHandler.handleTaskAction(
              linkedTask,
              showUndo: false,
            );
          }
        }
        _incrementTaskCountVersion();
      }
      return success;
    } catch (e) {
      LogService.error('❌ ProjectsProvider: Error toggling subtask: $e');
      return false;
    }
  }

  /// Subtask sil
  Future<bool> deleteSubtask(String subtaskId) async {
    try {
      LogService.debug('🗑️ ProjectsProvider: Deleting subtask');
      final success = await _subtasksService.deleteSubtask(subtaskId);
      if (success) {
        LogService.debug('✅ ProjectsProvider: Subtask deleted successfully');
        _incrementTaskCountVersion();
      }
      return success;
    } catch (e) {
      LogService.error('❌ ProjectsProvider: Error deleting subtask: $e');
      return false;
    }
  }

  // Private methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _incrementTaskCountVersion() {
    _taskCountVersion++;
    notifyListeners();
  }

  void clearAllProjects() {
    _projects.clear();
    _categories.clear();
    _selectedCategoryId = null;
    _searchQuery = '';
    _showArchivedOnly = false;
    notifyListeners();
  }

  /// Projenin alt görev toplamını ve tamamlanan alt görev sayısını hesaplar.
  ///
  /// Bağlı normal görevler aynı alt görevin temsilidir; bu nedenle ayrıca
  /// sayılmaz ve karttaki toplam iki kez şişirilmez.
  Future<Map<String, int>> getProjectTaskCounts(String projectId) async {
    try {
      // Subtask'ları getir
      final subtasks = await getProjectSubtasks(projectId);
      final subtaskCount = subtasks.length;
      final completedSubtaskCount =
          subtasks.where((subtask) => subtask.isCompleted).length;

      return {
        'total': subtaskCount,
        'completed': completedSubtaskCount,
      };
    } catch (e) {
      LogService.error('❌ Error getting project task counts: $e');
      return {'total': 0, 'completed': 0};
    }
  }
}
