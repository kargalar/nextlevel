import 'package:flutter/material.dart';
import 'package:next_level/Enum/task_type_enum.dart';
import 'package:next_level/Enum/trait_type_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Model/category_model.dart';
import 'package:next_level/Model/project_model.dart';
import 'package:next_level/Model/project_subtask_model.dart';
import 'package:next_level/Model/store_item_model.dart';
import 'package:next_level/Model/subtask_model.dart';
import 'package:next_level/Model/task_model.dart';
import 'package:next_level/Model/trait_model.dart';
import 'package:next_level/Model/routine_model.dart';
import 'package:next_level/Provider/category_provider.dart';
import 'package:next_level/Provider/notes_provider.dart';
import 'package:next_level/Provider/projects_provider.dart';
import 'package:next_level/Provider/store_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/trait_provider.dart';
import 'package:next_level/Provider/user_provider.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Service/notification_services.dart';

import 'package:next_level/Repository/task_repository.dart';
import 'package:next_level/Repository/routine_repository.dart';
import 'package:next_level/Repository/user_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:next_level/General/accessible.dart';

/// İlk yüklemede varsayılan kategoriler ve görevler oluşturan servis
class DefaultDataService {
  static const String _firstLaunchKey = 'is_first_launch';
  static const String _defaultDataLoadedKey = 'default_data_loaded';

  /// İlk yükleme olup olmadığını kontrol eder
  static Future<bool> isFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstLaunch = prefs.getBool(_firstLaunchKey) ?? true;
      final defaultDataLoaded = prefs.getBool(_defaultDataLoadedKey) ?? false;

      return isFirstLaunch && !defaultDataLoaded;
    } catch (e) {
      LogService.error('❌ DefaultDataService: İlk yükleme kontrolü hatası: $e');
      return false;
    }
  }

  /// İlk yükleme bayrağını false yapar (kullanıcı dialog'u gördü)
  static Future<void> markFirstLaunchSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_firstLaunchKey, false);
      LogService.debug('✅ DefaultDataService: İlk yükleme bayrağı işaretlendi');
    } catch (e) {
      LogService.error('❌ DefaultDataService: İlk yükleme bayrağı işaretleme hatası: $e');
    }
  }

  /// Varsayılan verileri yükler (kullanıcı onayladığında)
  static Future<void> loadDefaultData() async {
    try {
      LogService.debug('🎉 DefaultDataService: Varsayılan veriler yükleniyor...');

      // Bildirim izni iste
      await _requestNotificationPermission();

      await _loadDefaultData();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_defaultDataLoadedKey, true);
      await prefs.setBool(_firstLaunchKey, false);

      LogService.debug('✅ DefaultDataService: Varsayılan veriler başarıyla yüklendi');
    } catch (e) {
      LogService.error('❌ DefaultDataService: Varsayılan veri yükleme hatası: $e');
      rethrow;
    }
  }

  /// İlk yükleme kontrolü yapar ve gerekirse varsayılan verileri yükler
  /// @deprecated Artık kullanılmıyor. Bunun yerine isFirstLaunch() ve loadDefaultData() kullanın.
  @Deprecated('Use isFirstLaunch() and loadDefaultData() instead')
  static Future<void> checkAndLoadDefaultData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstLaunch = prefs.getBool(_firstLaunchKey) ?? true;

      if (isFirstLaunch) {
        LogService.debug('🎉 DefaultDataService: İlk yükleme tespit edildi, varsayılan veriler yükleniyor...');

        // Bildirim izni iste
        await _requestNotificationPermission();

        await _loadDefaultData();
        await prefs.setBool(_firstLaunchKey, false);
        LogService.debug('✅ DefaultDataService: Varsayılan veriler başarıyla yüklendi');
      } else {
        LogService.debug('ℹ️ DefaultDataService: İlk yükleme değil, varsayılan veriler atlandı');
      }
    } catch (e) {
      LogService.error('❌ DefaultDataService: Varsayılan veri yükleme hatası: $e');
    }
  }

  /// Bildirim izni ister (ilk yüklemede)
  static Future<void> _requestNotificationPermission() async {
    try {
      LogService.debug('🔔 DefaultDataService: Bildirim izni isteniyor...');
      final notificationService = NotificationService();
      final granted = await notificationService.requestNotificationPermissions();

      if (granted) {
        LogService.debug('✅ DefaultDataService: Bildirim izni verildi');
      } else {
        LogService.debug('⚠️ DefaultDataService: Bildirim izni reddedildi');
      }
    } catch (e) {
      LogService.error('❌ DefaultDataService: Bildirim izni isteme hatası: $e');
    }
  }

  /// Varsayılan kategorileri ve görevleri yükler
  static Future<void> _loadDefaultData() async {
    try {
      // Önce kategorileri oluştur
      final categories = await _createDefaultCategories();
      LogService.debug('✅ DefaultDataService: ${categories.length} kategori oluşturuldu');

      // Traits (Attributes & Skills) oluştur
      final traits = await _createDefaultTraits();
      LogService.debug('✅ DefaultDataService: ${traits.length} trait oluşturuldu');

      // Store items oluştur
      await _createDefaultStoreItems();
      LogService.debug('✅ DefaultDataService: Store items oluşturuldu');

      // Sonra görevleri oluştur
      await _createDefaultTasks(categories);
      LogService.debug('✅ DefaultDataService: Varsayılan görevler oluşturuldu');

      // Projeler oluştur
      await _createDefaultProjects(categories);
      LogService.debug('✅ DefaultDataService: Varsayılan projeler oluşturuldu');

      // Notlar oluştur
      await _createDefaultNotes(categories);
      LogService.debug('✅ DefaultDataService: Varsayılan notlar oluşturuldu');

      // Rutinler oluştur
      await _createDefaultRoutines(categories);
      LogService.debug('✅ DefaultDataService: Varsayılan rutinler oluşturuldu');

      // Kullanıcıya başlangıç kredisi yükle
      await _addInitialCredit();
      LogService.debug('✅ DefaultDataService: Başlangıç kredisi yüklendi');
    } catch (e) {
      LogService.error('❌ DefaultDataService: _loadDefaultData hatası: $e');
      rethrow;
    }
  }

  /// Kullanıcıya başlangıç kredisi yükler
  static Future<void> _addInitialCredit() async {
    try {
      if (loginUser != null) {
        loginUser!.userCredit += 10;
        await UserRepository().updateUser(loginUser!);
        UserProvider().setUser(loginUser!);
        LogService.debug('✅ DefaultDataService: Kullanıcıya 10 kredi eklendi (Toplam: ${loginUser!.userCredit})');
      } else {
        LogService.error('❌ DefaultDataService: loginUser null, kredi eklenemedi');
      }
    } catch (e) {
      LogService.error('❌ DefaultDataService: Kredi ekleme hatası: $e');
    }
  }

  /// Varsayılan kategorileri oluşturur
  static Future<List<CategoryModel>> _createDefaultCategories() async {
    final categories = <CategoryModel>[];
    final categoryProvider = CategoryProvider();

    try {
      int categoryIdBase = DateTime.now().millisecondsSinceEpoch;

      // ============= TASK KATEGORİLERİ =============

      // İş task kategorisi
      final workCategory = CategoryModel(
        id: (categoryIdBase++).toString(),
        title: 'Work',
        colorValue: AppColors.blue.toARGB32(),
        iconCodePoint: Icons.work.codePoint,
        categoryType: CategoryType.task,
        createdAt: DateTime.now(),
      );
      await categoryProvider.addCategory(workCategory);
      categories.add(workCategory);
      LogService.debug('✅ DefaultDataService: İş task kategorisi oluşturuldu');

      // Kişisel task kategorisi
      final personalCategory = CategoryModel(
        id: (categoryIdBase++).toString(),
        title: 'Personal',
        colorValue: AppColors.green.toARGB32(),
        iconCodePoint: Icons.person.codePoint,
        categoryType: CategoryType.task,
        createdAt: DateTime.now(),
      );
      await categoryProvider.addCategory(personalCategory);
      categories.add(personalCategory);
      LogService.debug('✅ DefaultDataService: Kişisel task kategorisi oluşturuldu');

      // Sağlık task kategorisi
      final healthCategory = CategoryModel(
        id: (categoryIdBase++).toString(),
        title: 'Health',
        colorValue: AppColors.red.toARGB32(),
        iconCodePoint: Icons.favorite.codePoint,
        categoryType: CategoryType.task,
        createdAt: DateTime.now(),
      );
      await categoryProvider.addCategory(healthCategory);
      categories.add(healthCategory);
      LogService.debug('✅ DefaultDataService: Sağlık task kategorisi oluşturuldu');

      // Alışveriş task kategorisi
      final shoppingCategory = CategoryModel(
        id: (categoryIdBase++).toString(),
        title: 'Shopping',
        colorValue: AppColors.orange.toARGB32(),
        iconCodePoint: Icons.shopping_cart.codePoint,
        categoryType: CategoryType.task,
        createdAt: DateTime.now(),
      );
      await categoryProvider.addCategory(shoppingCategory);
      categories.add(shoppingCategory);
      LogService.debug('✅ DefaultDataService: Alışveriş task kategorisi oluşturuldu');

      // ============= PROJECT KATEGORİLERİ =============

      // İş projeleri kategorisi
      final workProjectCategory = CategoryModel(
        id: (categoryIdBase++).toString(),
        title: 'Work',
        colorValue: AppColors.blue.toARGB32(),
        iconCodePoint: Icons.business_center.codePoint,
        categoryType: CategoryType.project,
        createdAt: DateTime.now(),
      );
      await categoryProvider.addCategory(workProjectCategory);
      categories.add(workProjectCategory);
      LogService.debug('✅ DefaultDataService: İş projeleri kategorisi oluşturuldu');

      // Hobi projeleri kategorisi
      final hobbyProjectCategory = CategoryModel(
        id: (categoryIdBase++).toString(),
        title: 'Hobby',
        colorValue: AppColors.purple.toARGB32(),
        iconCodePoint: Icons.palette.codePoint,
        categoryType: CategoryType.project,
        createdAt: DateTime.now(),
      );
      await categoryProvider.addCategory(hobbyProjectCategory);
      categories.add(hobbyProjectCategory);
      LogService.debug('✅ DefaultDataService: Hobi projeleri kategorisi oluşturuldu');

      // ============= NOTE KATEGORİLERİ =============

      // Fikirler kategorisi
      final ideasNoteCategory = CategoryModel(
        id: (categoryIdBase++).toString(),
        title: 'Ideas',
        colorValue: AppColors.yellow.toARGB32(),
        iconCodePoint: Icons.emoji_objects.codePoint,
        categoryType: CategoryType.note,
        createdAt: DateTime.now(),
      );
      await categoryProvider.addCategory(ideasNoteCategory);
      categories.add(ideasNoteCategory);
      LogService.debug('✅ DefaultDataService: Fikirler notlar kategorisi oluşturuldu');

      // Toplantı notları kategorisi
      final meetingNoteCategory = CategoryModel(
        id: (categoryIdBase++).toString(),
        title: 'Meetings',
        colorValue: AppColors.blue.toARGB32(),
        iconCodePoint: Icons.groups.codePoint,
        categoryType: CategoryType.note,
        createdAt: DateTime.now(),
      );
      await categoryProvider.addCategory(meetingNoteCategory);
      categories.add(meetingNoteCategory);
      LogService.debug('✅ DefaultDataService: Toplantı notları kategorisi oluşturuldu');

      LogService.debug('✅ DefaultDataService: Toplam ${categories.length} kategori oluşturuldu (4 task, 3 project, 3 note)');
      return categories;
    } catch (e) {
      LogService.error('❌ DefaultDataService: Kategori oluşturma hatası: $e');
      rethrow;
    }
  }

  /// Varsayılan görevleri oluşturur
  static Future<void> _createDefaultTasks(List<CategoryModel> categories) async {
    final taskProvider = TaskProvider();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    try {
      // Task ID başlangıcı
      int taskId = DateTime.now().millisecondsSinceEpoch;

      // İş kategorisi görevleri
      if (categories.isNotEmpty) {
        final workCategory = categories[0];

        // Email kontrolü
        final emailTask = TaskModel(
          id: taskId++,
          title: 'Check emails',
          description: 'Review and respond to important emails',
          type: TaskTypeEnum.CHECKBOX,
          taskDate: today,
          isNotificationOn: false,
          isAlarmOn: false,
          status: null,
          categoryId: workCategory.id,
        );
        await TaskRepository().addTask(emailTask);
        taskProvider.taskList.add(emailTask);
        LogService.debug('✅ DefaultDataService: Email kontrolü görevi oluşturuldu');

        // Toplantıya hazırlık
        final meetingTask = TaskModel(
          id: taskId++,
          title: 'Prepare for meeting',
          description: 'Review presentation and prepare notes',
          type: TaskTypeEnum.CHECKBOX,
          taskDate: today,
          time: const TimeOfDay(hour: 14, minute: 0),
          isNotificationOn: false,
          isAlarmOn: false,
          status: null,
          priority: 1,
          categoryId: workCategory.id,
          currentDuration: Duration.zero,
          remainingDuration: const Duration(hours: 1),
          isPinned: true,
        );
        await TaskRepository().addTask(meetingTask);
        taskProvider.taskList.add(meetingTask);
        LogService.debug('✅ DefaultDataService: Toplantı hazırlık görevi oluşturuldu');
      }

      // Kişisel kategorisi görevleri
      if (categories.length > 1) {
        final personalCategory = categories[1];

        // Kitap okuma
        final readingTask = TaskModel(
          id: taskId++,
          title: 'Read book',
          type: TaskTypeEnum.TIMER,
          taskDate: today,
          isNotificationOn: false,
          isAlarmOn: false,
          status: null,
          priority: 3,
          currentCount: 0,
          remainingDuration: Duration(minutes: 30),
        );
        await TaskRepository().addTask(readingTask);
        taskProvider.taskList.add(readingTask);
        LogService.debug('✅ DefaultDataService: Kitap okuma görevi oluşturuldu');

        // Arkadaşı ara
        final callFriendTask = TaskModel(
          id: taskId++,
          title: 'Call Micheal Scott',
          description: null,
          type: TaskTypeEnum.CHECKBOX,
          taskDate: tomorrow,
          isNotificationOn: false,
          isAlarmOn: false,
          status: null,
          priority: 3,
          categoryId: personalCategory.id,
        );
        await TaskRepository().addTask(callFriendTask);
        taskProvider.taskList.add(callFriendTask);
        LogService.debug('✅ DefaultDataService: Arkadaş arama görevi oluşturuldu');
      }

      // Sağlık kategorisi görevleri
      if (categories.length > 2) {
        final healthCategory = categories[2];

        // Egzersiz
        final exerciseTask = TaskModel(
          id: taskId++,
          title: 'Morning exercise',
          description: '30 minutes cardio workout',
          type: TaskTypeEnum.TIMER,
          taskDate: today.subtract(const Duration(days: 2)),
          time: const TimeOfDay(hour: 7, minute: 0),
          isNotificationOn: false,
          isAlarmOn: false,
          status: null,
          categoryId: healthCategory.id,
          currentDuration: Duration.zero,
          remainingDuration: const Duration(minutes: 30),
        );
        await TaskRepository().addTask(exerciseTask);
        taskProvider.taskList.add(exerciseTask);
        LogService.debug('✅ DefaultDataService: Egzersiz görevi oluşturuldu');

        // Su içme
        final waterTask = TaskModel(
          id: taskId++,
          title: 'Drink water',
          description: 'Drink 8 glasses of water today',
          type: TaskTypeEnum.COUNTER,
          taskDate: today,
          isNotificationOn: false,
          isAlarmOn: false,
          status: null,
          categoryId: healthCategory.id,
          currentCount: 0,
          targetCount: 8,
        );
        await TaskRepository().addTask(waterTask);
        taskProvider.taskList.add(waterTask);
        LogService.debug('✅ DefaultDataService: Su içme görevi oluşturuldu');
      }

      // Alışveriş kategorisi görevleri
      if (categories.length > 3) {
        final shoppingCategory = categories[3];

        // Market alışverişi - subtask'larla
        final groceryTask = TaskModel(
          id: taskId++,
          title: 'Buy groceries',
          description: null,
          type: TaskTypeEnum.CHECKBOX,
          taskDate: tomorrow,
          isNotificationOn: false,
          isAlarmOn: false,
          status: null,
          priority: 2,
          categoryId: shoppingCategory.id,
          subtasks: [
            SubTaskModel(
              id: 1,
              title: 'Milk',
              isCompleted: false,
            ),
            SubTaskModel(
              id: 2,
              title: 'Bread',
              isCompleted: false,
            ),
            SubTaskModel(
              id: 3,
              title: 'Eggs',
              isCompleted: false,
            ),
            SubTaskModel(
              id: 4,
              title: 'Fruits',
              isCompleted: false,
            ),
          ],
        );
        await TaskRepository().addTask(groceryTask);
        taskProvider.taskList.add(groceryTask);
        LogService.debug('✅ DefaultDataService: Market alışverişi görevi oluşturuldu (4 subtask ile)');
      }

      LogService.debug('✅ DefaultDataService: Tüm varsayılan görevler oluşturuldu');
    } catch (e) {
      LogService.error('❌ DefaultDataService: Görev oluşturma hatası: $e');
      rethrow;
    }
  }

  /// Varsayılan traits (attributes & skills) oluşturur
  static Future<List<TraitModel>> _createDefaultTraits() async {
    final traits = <TraitModel>[];
    final traitProvider = TraitProvider();

    try {
      int traitId = DateTime.now().millisecondsSinceEpoch;

      // Attributes (Özellikler)
      final wisdomAttribute = TraitModel(
        id: traitId++,
        title: 'Wisdom',
        icon: '🦉',
        color: AppColors.blue,
        type: TraitTypeEnum.ATTRIBUTE,
      );
      traitProvider.addTrait(wisdomAttribute);
      traits.add(wisdomAttribute);
      LogService.debug('✅ DefaultDataService: Wisdom attribute oluşturuldu');

      final powerAttribute = TraitModel(
        id: traitId++,
        title: 'Power',
        icon: '💪',
        color: AppColors.red,
        type: TraitTypeEnum.ATTRIBUTE,
      );
      traitProvider.addTrait(powerAttribute);
      traits.add(powerAttribute);
      LogService.debug('✅ DefaultDataService: Power attribute oluşturuldu');

      // Skills (Yetenekler)
      final readSkill = TraitModel(
        id: traitId++,
        title: 'Read',
        icon: '�',
        color: AppColors.blue,
        type: TraitTypeEnum.SKILL,
      );
      traitProvider.addTrait(readSkill);
      traits.add(readSkill);
      LogService.debug('✅ DefaultDataService: Read skill oluşturuldu');

      final meditationSkill = TraitModel(
        id: traitId++,
        title: 'Meditation',
        icon: '🧘',
        color: AppColors.purple,
        type: TraitTypeEnum.SKILL,
      );
      traitProvider.addTrait(meditationSkill);
      traits.add(meditationSkill);
      LogService.debug('✅ DefaultDataService: Meditation skill oluşturuldu');

      return traits;
    } catch (e) {
      LogService.error('❌ DefaultDataService: Trait oluşturma hatası: $e');
      rethrow;
    }
  }

  /// Varsayılan store items oluşturur
  static Future<void> _createDefaultStoreItems() async {
    final storeProvider = StoreProvider();

    try {
      // Timer item - 1 saat oyun
      final gameHourItem = ItemModel(
        id: DateTime.now().millisecondsSinceEpoch,
        title: 'Gaming',
        description: 'Reward yourself with gaming',
        type: TaskTypeEnum.TIMER,
        addDuration: const Duration(hours: 1),
        currentDuration: Duration(minutes: 1),
        credit: 6,
      );
      storeProvider.addItem(gameHourItem);
      LogService.debug('✅ DefaultDataService: 1 Hour Gaming item oluşturuldu');

      // Checkbox item - Atıştırmalık
      final snackItem = ItemModel(
        id: DateTime.now().millisecondsSinceEpoch + 1,
        title: 'Snack',
        description: 'Enjoy your favorite snack',
        type: TaskTypeEnum.COUNTER,
        addCount: 1,
        currentCount: -1,
        credit: 4,
      );
      storeProvider.addItem(snackItem);
      LogService.debug('✅ DefaultDataService: Snack item oluşturuldu');

      // Checkbox item - Film
      final movieItem = ItemModel(
        id: DateTime.now().millisecondsSinceEpoch + 2,
        title: 'Movie',
        type: TaskTypeEnum.COUNTER,
        addDuration: const Duration(hours: 2),
        addCount: 1,
        currentCount: 2,
        credit: 5,
      );
      storeProvider.addItem(movieItem);
      LogService.debug('✅ DefaultDataService: Movie item oluşturuldu');
    } catch (e) {
      LogService.error('❌ DefaultDataService: Store item oluşturma hatası: $e');
      rethrow;
    }
  }

  /// Varsayılan projeler oluşturur
  static Future<void> _createDefaultProjects(List<CategoryModel> categories) async {
    final projectsProvider = ProjectsProvider();
    final now = DateTime.now();

    try {
      // Proje kategorilerini bul (task kategorilerinden sonra geliyorlar)
      final projectCategories = categories.where((cat) => cat.categoryType == CategoryType.project).toList();

      if (projectCategories.isEmpty) {
        LogService.debug('⚠️ DefaultDataService: Proje kategorisi bulunamadı, proje oluşturma atlandı');
        return;
      }

      // İş Projeleri kategorisinden proje
      if (projectCategories.isNotEmpty) {
        final workProject = ProjectModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Q4 Planning',
          description: 'Quarterly planning and goal setting for the last quarter',
          createdAt: now,
          updatedAt: now,
          colorIndex: 0,
          categoryId: projectCategories[0].id, // Work Projects kategorisi
        );
        await projectsProvider.addProject(workProject);
        LogService.debug('✅ DefaultDataService: Q4 Planning projesi oluşturuldu (${projectCategories[0].title})');

        // Q4 Planning projesi için subtask'lar
        await projectsProvider.addSubtask(ProjectSubtaskModel(
          id: '${workProject.id}_task_1',
          projectId: workProject.id,
          title: 'Review last quarter results',
          isCompleted: true,
          createdAt: now.subtract(const Duration(days: 2)),
          orderIndex: 0,
        ));
        await projectsProvider.addSubtask(ProjectSubtaskModel(
          id: '${workProject.id}_task_2',
          projectId: workProject.id,
          title: 'Set Q4 goals',
          isCompleted: false,
          createdAt: now.subtract(const Duration(days: 1)),
          orderIndex: 1,
        ));
        await projectsProvider.addSubtask(ProjectSubtaskModel(
          id: '${workProject.id}_task_3',
          projectId: workProject.id,
          title: 'Prepare presentation',
          isCompleted: false,
          createdAt: now,
          orderIndex: 2,
        ));
        LogService.debug('✅ DefaultDataService: Q4 Planning projesine 3 subtask eklendi');
      }

      // Kişisel Projeler kategorisinden proje
      if (projectCategories.length > 1) {
        final personalProject = ProjectModel(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          title: 'Learning Goals',
          description: 'Personal development and learning objectives',
          createdAt: now.subtract(const Duration(days: 5)),
          updatedAt: now,
          colorIndex: 1,
          isPinned: true,
        );
        await projectsProvider.addProject(personalProject);
        LogService.debug('✅ DefaultDataService: Learning Goals projesi oluşturuldu (${projectCategories[1].title})');

        // Learning Goals projesi için subtask'lar
        await projectsProvider.addSubtask(ProjectSubtaskModel(
          id: '${personalProject.id}_task_1',
          projectId: personalProject.id,
          title: 'Complete Flutter course',
          isCompleted: false,
          createdAt: now.subtract(const Duration(days: 5)),
          orderIndex: 0,
        ));
        await projectsProvider.addSubtask(ProjectSubtaskModel(
          id: '${personalProject.id}_task_2',
          projectId: personalProject.id,
          title: 'Read 2 books per month',
          isCompleted: false,
          createdAt: now.subtract(const Duration(days: 4)),
          orderIndex: 1,
        ));
        LogService.debug('✅ DefaultDataService: Learning Goals projesine 2 subtask eklendi');
      }

      // Hobi Projeleri kategorisinden proje
      if (projectCategories.length > 2) {
        final hobbyProject = ProjectModel(
          id: (DateTime.now().millisecondsSinceEpoch + 2).toString(),
          title: 'Home Garden',
          description: 'Create and maintain a beautiful home garden',
          createdAt: now.subtract(const Duration(days: 7)),
          updatedAt: now.subtract(const Duration(hours: 12)),
          colorIndex: 2,
          categoryId: projectCategories[2].id, // Hobby Projects kategorisi
        );
        await projectsProvider.addProject(hobbyProject);
        LogService.debug('✅ DefaultDataService: Home Garden projesi oluşturuldu (${projectCategories[2].title})');

        // Home Garden projesi için subtask'lar
        await projectsProvider.addSubtask(ProjectSubtaskModel(
          id: '${hobbyProject.id}_task_1',
          projectId: hobbyProject.id,
          title: 'Buy gardening tools',
          isCompleted: true,
          createdAt: now.subtract(const Duration(days: 7)),
          orderIndex: 0,
        ));
        await projectsProvider.addSubtask(ProjectSubtaskModel(
          id: '${hobbyProject.id}_task_2',
          projectId: hobbyProject.id,
          title: 'Plant spring flowers',
          isCompleted: false,
          createdAt: now.subtract(const Duration(days: 6)),
          orderIndex: 1,
        ));
        await projectsProvider.addSubtask(ProjectSubtaskModel(
          id: '${hobbyProject.id}_task_3',
          projectId: hobbyProject.id,
          title: 'Set up watering system',
          isCompleted: false,
          createdAt: now.subtract(const Duration(days: 5)),
          orderIndex: 2,
        ));
        LogService.debug('✅ DefaultDataService: Home Garden projesine 3 subtask eklendi');
      }

      LogService.debug('✅ DefaultDataService: ${projectCategories.length} proje kategorisi için toplam 3 proje oluşturuldu');
    } catch (e) {
      LogService.error('❌ DefaultDataService: Proje oluşturma hatası: $e');
      rethrow;
    }
  }

  /// Varsayılan notlar oluşturur
  static Future<void> _createDefaultNotes(List<CategoryModel> categories) async {
    final notesProvider = NotesProvider();

    try {
      // Note kategorilerini bul
      final noteCategories = categories.where((cat) => cat.categoryType == CategoryType.note).toList();

      if (noteCategories.isEmpty) {
        LogService.debug('⚠️ DefaultDataService: Note kategorisi bulunamadı, not oluşturma atlandı');
        return;
      }

      // Toplantı Notları kategorisinden not
      if (noteCategories.length > 2) {
        await notesProvider.addNote(
          title: 'Team Meeting Notes',
          content: 'Key points from today\'s team meeting:\n- New project timeline\n- Resource allocation\n- Next steps\n- Action items for next week',
          categoryId: noteCategories[2].id, // Meetings kategorisi
          colorIndex: 0,
        );
        LogService.debug('✅ DefaultDataService: Team Meeting Notes notu oluşturuldu (${noteCategories[2].title})');
      }

      // Delay ekleyerek notların farklı zamanlarda oluşturulmuş gibi görünmesini sağla
      await Future.delayed(const Duration(milliseconds: 100));

      // Fikirler kategorisinden not
      if (noteCategories.length > 1) {
        await notesProvider.addNote(
          title: 'App Ideas',
          content: 'New features to consider:\n- Dark mode improvements\n- Social sharing\n- Weekly reports\n- Team collaboration',
          categoryId: noteCategories[1].id, // Ideas kategorisi
          colorIndex: 1,
        );
        LogService.debug('✅ DefaultDataService: App Ideas notu oluşturuldu (${noteCategories[1].title})');
      }

      await Future.delayed(const Duration(milliseconds: 100));

      // Genel Notlar kategorisinden not
      if (noteCategories.isNotEmpty) {
        await notesProvider.addNote(
          title: 'Reading List',
          content: 'Books to read this year:\n1. Atomic Habits - James Clear\n2. Deep Work - Cal Newport\n3. The Pragmatic Programmer\n4. Clean Code - Robert Martin',
          colorIndex: 2,
        );
        LogService.debug('✅ DefaultDataService: Reading List notu oluşturuldu (${noteCategories[0].title})');
      }

      await Future.delayed(const Duration(milliseconds: 100));

      // Fikirler kategorisinden başka bir not
      if (noteCategories.length > 1) {
        await notesProvider.addNote(
          title: 'Weekend Plans',
          content: 'Things to do this weekend:\n- Visit the farmers market\n- Movie night with family\n- Start reading new book\n- Organize workspace',
          categoryId: noteCategories[1].id, // Ideas kategorisi
          colorIndex: 3,
        );
        LogService.debug('✅ DefaultDataService: Weekend Plans notu oluşturuldu (${noteCategories[1].title})');
      }

      await Future.delayed(const Duration(milliseconds: 100));

      // Genel Notlar kategorisinden başka bir not
      if (noteCategories.isNotEmpty) {
        await notesProvider.addNote(
          title: 'Important Contacts',
          content: 'Key contacts:\n\nDoctor: Dr. Smith - (555) 123-4567\nPlumber: Joe\'s Plumbing - (555) 234-5678\nElectrician: Bright Electric - (555) 345-6789',
          colorIndex: 4,
        );
        LogService.debug('✅ DefaultDataService: Important Contacts notu oluşturuldu (${noteCategories[0].title})');
      }

      LogService.debug('✅ DefaultDataService: ${noteCategories.length} note kategorisi için toplam 5 not oluşturuldu');
    } catch (e) {
      LogService.error('❌ DefaultDataService: Not oluşturma hatası: $e');
      rethrow;
    }
  }

  /// Varsayılan rutinleri oluşturur
  static Future<void> _createDefaultRoutines(List<CategoryModel> categories) async {
    try {
      // Task kategorilerini bul
      final taskCategories = categories.where((cat) => cat.categoryType == CategoryType.task).toList();

      if (taskCategories.isEmpty) {
        LogService.debug('⚠️ DefaultDataService: Task kategorisi bulunamadı, rutin oluşturma atlandı');
        return;
      }

      final now = DateTime.now();

      // Kişisel kategorisi - Read Book Rutini
      if (taskCategories.length > 1) {
        final personalCategory = taskCategories[1];

        final readRoutine = RoutineModel(
          title: 'Read Book',
          description: 'Daily reading habit - 30 minutes',
          type: TaskTypeEnum.TIMER,
          createdDate: now,
          startDate: now,
          time: const TimeOfDay(hour: 21, minute: 0), // 9 PM
          isNotificationOn: true,
          isAlarmOn: false,
          remainingDuration: const Duration(minutes: 30),
          repeatDays: [1, 2, 3, 4, 5, 6, 7], // Her gün
          isArchived: false,
          priority: 2,
          categoryId: personalCategory.id,
          earlyReminderMinutes: 10,
        );

        await RoutineRepository().addRoutine(readRoutine);
        LogService.debug('✅ DefaultDataService: Read Book rutini oluşturuldu (${personalCategory.title})');
      }

      // Sağlık kategorisi - Meditation Rutini
      if (taskCategories.length > 2) {
        final healthCategory = taskCategories[2];

        final meditationRoutine = RoutineModel(
          title: 'Meditation',
          description: 'Morning meditation practice',
          type: TaskTypeEnum.TIMER,
          createdDate: now,
          startDate: now,
          time: const TimeOfDay(hour: 7, minute: 30), // 7:30 AM
          isNotificationOn: true,
          isAlarmOn: false,
          remainingDuration: const Duration(minutes: 15),
          repeatDays: [1, 2, 3, 4, 5, 6, 7], // Her gün
          isArchived: false,
          priority: 1,
          categoryId: healthCategory.id,
          earlyReminderMinutes: 5,
        );

        await RoutineRepository().addRoutine(meditationRoutine);
        LogService.debug('✅ DefaultDataService: Meditation rutini oluşturuldu (${healthCategory.title})');
      }

      LogService.debug('✅ DefaultDataService: Toplam 2 rutin oluşturuldu');
    } catch (e) {
      LogService.error('❌ DefaultDataService: Rutin oluşturma hatası: $e');
      rethrow;
    }
  }

  /// Varsayılan verileri sıfırlamak için (test amaçlı)
  static Future<void> resetFirstLaunchFlag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_firstLaunchKey, true);
      await prefs.setBool(_defaultDataLoadedKey, false);
      LogService.debug('🔄 DefaultDataService: İlk yükleme bayrakları sıfırlandı');
    } catch (e) {
      LogService.error('❌ DefaultDataService: Bayrak sıfırlama hatası: $e');
    }
  }
}
