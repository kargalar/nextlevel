import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:next_level/Service/logging_service.dart';

class NavbarVisibilityProvider with ChangeNotifier {
  late final Future<void> ready;

  // Navbar item visibility states (profile is always visible)
  bool _showStore = true;
  bool _showInbox = true;
  bool _showTasks = true;
  bool _showNotes = true;
  bool _showProjects = false;

  // Main page index (default is Inbox = 1)
  int _mainPageIndex = 1;

  bool get showStore => _showStore;
  bool get showInbox => _showInbox;
  bool get showTasks => _showTasks;
  bool get showNotes => _showNotes;
  bool get showProjects => _showProjects;
  int get mainPageIndex => _mainPageIndex;

  // SharedPreferences keys
  static const String _keyShowStore = 'navbar_show_store';
  static const String _keyShowInbox = 'navbar_show_inbox';
  static const String _keyShowTasks = 'navbar_show_tasks';
  static const String _legacyKeyShowCategories = 'navbar_show_categories';
  static const String _keyShowNotes = 'navbar_show_notes';
  static const String _keyShowProjects = 'navbar_show_projects';
  static const String _keyMainPageIndex = 'navbar_main_page_index';

  NavbarVisibilityProvider() {
    ready = _loadSettings();
  }

  /// Load visibility settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _showStore = prefs.getBool(_keyShowStore) ?? true;
      _showInbox = prefs.getBool(_keyShowInbox) ?? true;
      _showTasks = prefs.getBool(_keyShowTasks) ??
          prefs.getBool(_legacyKeyShowCategories) ??
          true;
      _showNotes = prefs.getBool(_keyShowNotes) ?? true;
      _showProjects = prefs.getBool(_keyShowProjects) ?? false;
      _mainPageIndex = prefs.getInt(_keyMainPageIndex) ?? 1;

      LogService.debug('NavbarVisibility: Settings loaded successfully');
      notifyListeners();
    } catch (e) {
      LogService.error('NavbarVisibility: Error loading settings: $e');
    }
  }

  /// Toggle Store visibility
  Future<void> toggleStore() async {
    try {
      _showStore = !_showStore;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyShowStore, _showStore);
      LogService.debug(
          'NavbarVisibility: Store visibility toggled to $_showStore');
      notifyListeners();
    } catch (e) {
      LogService.error('NavbarVisibility: Error toggling Store: $e');
    }
  }

  /// Toggle Inbox visibility
  Future<void> toggleInbox() async {
    try {
      _showInbox = !_showInbox;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyShowInbox, _showInbox);
      LogService.debug(
          'NavbarVisibility: Inbox visibility toggled to $_showInbox');
      notifyListeners();
    } catch (e) {
      LogService.error('NavbarVisibility: Error toggling Inbox: $e');
    }
  }

  /// Toggle task list visibility.
  Future<void> toggleTasks() async {
    try {
      _showTasks = !_showTasks;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyShowTasks, _showTasks);
      LogService.debug(
          'NavbarVisibility: Tasks visibility toggled to $_showTasks');
      notifyListeners();
    } catch (e) {
      LogService.error('NavbarVisibility: Error toggling Tasks: $e');
    }
  }

  /// Toggle Notes visibility
  Future<void> toggleNotes() async {
    try {
      _showNotes = !_showNotes;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyShowNotes, _showNotes);
      LogService.debug(
          'NavbarVisibility: Notes visibility toggled to $_showNotes');
      notifyListeners();
    } catch (e) {
      LogService.error('NavbarVisibility: Error toggling Notes: $e');
    }
  }

  /// Toggle Projects visibility
  Future<void> toggleProjects() async {
    try {
      _showProjects = !_showProjects;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyShowProjects, _showProjects);
      LogService.debug(
          'NavbarVisibility: Projects visibility toggled to $_showProjects');
      notifyListeners();
    } catch (e) {
      LogService.error('NavbarVisibility: Error toggling Projects: $e');
    }
  }

  /// Set main page index
  Future<void> setMainPage(int pageIndex) async {
    try {
      // Ensure the page is visible before setting as main
      if (!isPageVisible(pageIndex)) {
        LogService.debug(
            'NavbarVisibility: Cannot set hidden page as main page');
        return;
      }

      _mainPageIndex = pageIndex;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyMainPageIndex, _mainPageIndex);
      LogService.debug(
          'NavbarVisibility: Main page set to index $_mainPageIndex');
      notifyListeners();
    } catch (e) {
      LogService.error('NavbarVisibility: Error setting main page: $e');
    }
  }

  /// Get count of visible navbar items
  int getVisibleItemsCount() {
    int count = 1; // Profile is always visible
    if (_showStore) count++;
    if (_showInbox) count++;
    if (_showTasks) count++;
    if (_showNotes) count++;
    if (_showProjects) count++;
    return count;
  }

  /// Get list of visible item indices
  List<int> getVisibleIndices() {
    List<int> indices = [];
    int currentIndex = 0;

    if (_showStore) {
      indices.add(currentIndex);
      currentIndex++;
    }
    if (_showInbox) {
      indices.add(currentIndex);
      currentIndex++;
    }
    if (_showTasks) {
      indices.add(currentIndex);
      currentIndex++;
    }
    if (_showNotes) {
      indices.add(currentIndex);
      currentIndex++;
    }
    if (_showProjects) {
      indices.add(currentIndex);
      currentIndex++;
    }
    // Profile is always last
    indices.add(currentIndex);

    return indices;
  }

  /// Map visible index to actual page index
  int mapVisibleIndexToPageIndex(int visibleIndex) {
    int visibleCount = 0;

    if (_showStore) {
      if (visibleCount == visibleIndex) return 0;
      visibleCount++;
    }
    if (_showInbox) {
      if (visibleCount == visibleIndex) return 1;
      visibleCount++;
    }
    if (_showTasks) {
      if (visibleCount == visibleIndex) return 2;
      visibleCount++;
    }
    if (_showNotes) {
      if (visibleCount == visibleIndex) return 3;
      visibleCount++;
    }
    if (_showProjects) {
      if (visibleCount == visibleIndex) return 4;
      visibleCount++;
    }
    // Profile
    if (visibleCount == visibleIndex) return 5;

    return 5; // Default to profile
  }

  /// Map actual page index to visible index
  int mapPageIndexToVisibleIndex(int pageIndex) {
    int visibleIndex = 0;

    // Store
    if (pageIndex == 0) return _showStore ? visibleIndex : -1;
    if (_showStore) visibleIndex++;

    // Inbox
    if (pageIndex == 1) return _showInbox ? visibleIndex : -1;
    if (_showInbox) visibleIndex++;

    // Tasks
    if (pageIndex == 2) return _showTasks ? visibleIndex : -1;
    if (_showTasks) visibleIndex++;

    // Notes
    if (pageIndex == 3) return _showNotes ? visibleIndex : -1;
    if (_showNotes) visibleIndex++;

    // Projects
    if (pageIndex == 4) return _showProjects ? visibleIndex : -1;
    if (_showProjects) visibleIndex++;

    // Profile
    if (pageIndex == 5) return visibleIndex;

    return visibleIndex; // Default to last visible item
  }

  /// Get the first visible page index (excluding profile if possible)
  /// Returns the main page if visible, otherwise first enabled navbar item, or profile (5) if all are disabled
  int getFirstVisiblePageIndex() {
    // If main page is visible, return it
    if (isPageVisible(_mainPageIndex)) {
      return _mainPageIndex;
    }

    // Otherwise return first visible page
    if (_showStore) return 0;
    if (_showInbox) return 1;
    if (_showTasks) return 2;
    if (_showNotes) return 3;
    if (_showProjects) return 4;
    return 5; // Profile as fallback
  }

  /// Check if a page index is visible
  bool isPageVisible(int pageIndex) {
    switch (pageIndex) {
      case 0:
        return _showStore;
      case 1:
        return _showInbox;
      case 2:
        return _showTasks;
      case 3:
        return _showNotes;
      case 4:
        return _showProjects;
      case 5:
        return true; // Profile is always visible
      default:
        return false;
    }
  }

  /// Get a safe page index - if the given index is hidden, return the first visible page
  int getSafePageIndex(int pageIndex) {
    if (isPageVisible(pageIndex)) {
      return pageIndex;
    }
    return getFirstVisiblePageIndex();
  }
}
