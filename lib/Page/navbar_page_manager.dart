// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:next_level/Core/helper.dart';
import 'package:next_level/Core/Enums/status_enum.dart';
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Page/Navbar/constants/navbar_constants.dart';
import 'package:next_level/Page/Navbar/constants/navbar_pages.dart';
import 'package:next_level/Page/Navbar/handlers/navbar_fab_handler.dart';
import 'package:next_level/Page/Navbar/handlers/navbar_lifecycle_handler.dart';
import 'package:next_level/Page/Navbar/utils/navbar_visibility_utils.dart';
import 'package:next_level/Page/Navbar/widgets/default_data_dialog.dart';
import 'package:next_level/Provider/navbar_provider.dart';
import 'package:next_level/Provider/navbar_visibility_provider.dart';
import 'package:next_level/Provider/store_provider.dart';
import 'package:next_level/Provider/task_provider.dart';
import 'package:next_level/Provider/trait_provider.dart';
import 'package:next_level/Service/default_data_service.dart';
import 'package:next_level/Service/analytics_service.dart';
import 'package:next_level/Service/global_timer.dart';
import 'package:next_level/Service/hive_service.dart';
import 'package:next_level/Service/home_widget_service.dart';
import 'package:next_level/Service/logging_service.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Service/notification_services.dart';

import 'package:next_level/Repository/store_repository.dart';
import 'package:next_level/Repository/trait_repository.dart';
import 'package:next_level/Repository/routine_repository.dart';
import 'package:next_level/Repository/task_repository.dart';
import 'package:provider/provider.dart';

class NavbarPageManager extends StatefulWidget {
  const NavbarPageManager({super.key});

  @override
  State<NavbarPageManager> createState() => _NavbarPageManagerState();
}

class _NavbarPageManagerState extends State<NavbarPageManager>
    with WidgetsBindingObserver {
  bool isLoading = false;
  bool _isInitialized = false;
  late NavbarFABHandler _fabHandler;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fabHandler = NavbarFABHandler(context);
    _initializeNavbar();
    _loadData();
  }

  @override
  void dispose() {
    if (_isInitialized) {
      context.read<NavbarVisibilityProvider>().removeListener(
            _handleNavbarVisibilityChanged,
          );
      context.read<NavbarProvider>().pageController.dispose();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    LogService.debug('🔄 App lifecycle state changed: $state');

    if (state == AppLifecycleState.resumed) {
      await GlobalTimer().checkActiveTimerPref();
      await NotificationService().checkNotificationPermissions();

      if (mounted) {
        await NavbarLifecycleHandler.handleResumed(context);
        setState(() {});
      }
    } else if (state == AppLifecycleState.paused) {
      if (mounted) {
        await NavbarLifecycleHandler.handlePaused(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibilityProvider = context.watch<NavbarVisibilityProvider>();
    final navbarItems = NavbarConstants.getNavbarItems();
    final allPages = NavbarPages.getAllPages();

    final visibleNavbarItems = NavbarVisibilityUtils.getVisibleNavbarItems(
        visibilityProvider, navbarItems);
    final visiblePages =
        NavbarVisibilityUtils.getVisiblePages(visibilityProvider, allPages);
    final isWideLayout = MediaQuery.sizeOf(context).width >= 840;

    return IgnorePointer(
      ignoring: !isLoading || !_isInitialized,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        extendBody: !isWideLayout,
        body: !isLoading || !_isInitialized
            ? const Center(child: CircularProgressIndicator())
            : isWideLayout
                ? _buildWideLayout(
                    visibilityProvider,
                    visibleNavbarItems,
                    visiblePages,
                  )
                : _buildPageView(visibilityProvider, visiblePages),
        floatingActionButton: _isInitialized
            ? _fabHandler.buildFAB(
                context.read<NavbarProvider>().currentIndex,
              )
            : const SizedBox.shrink(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: isWideLayout || !isLoading || !_isInitialized
            ? null
            : _buildBottomNavigationBar(
                visibilityProvider,
                visibleNavbarItems,
              ),
      ),
    );
  }

  Widget _buildWideLayout(
    NavbarVisibilityProvider provider,
    List<BottomNavigationBarItem> items,
    List<Widget> visiblePages,
  ) {
    final isExtended = MediaQuery.sizeOf(context).width >= 1180;
    final selectedIndex = NavbarVisibilityUtils.getSafeVisibleIndex(
      provider,
      context.read<NavbarProvider>().currentIndex,
    );

    return Row(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: NavigationRail(
                extended: isExtended,
                minWidth: 76,
                minExtendedWidth: 208,
                backgroundColor: AppColors.surfaceRaised,
                indicatorColor: AppColors.main.withValues(alpha: .18),
                selectedIndex: selectedIndex,
                labelType: isExtended
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.selected,
                onDestinationSelected: (index) {
                  final pageIndex = provider.mapVisibleIndexToPageIndex(index);
                  context.read<NavbarProvider>().updateIndex(pageIndex);
                },
                destinations: items
                    .map(
                      (item) => NavigationRailDestination(
                        icon: item.icon,
                        selectedIcon: item.activeIcon,
                        label: Text(item.label ?? ''),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
        Expanded(child: _buildPageView(provider, visiblePages)),
      ],
    );
  }

  Widget _buildPageView(
      NavbarVisibilityProvider provider, List<Widget> visiblePages) {
    return SizedBox.expand(
      child: PageView(
        controller: context.read<NavbarProvider>().pageController,
        onPageChanged: (visibleIndex) {
          final pageIndex = provider.mapVisibleIndexToPageIndex(visibleIndex);
          _trackNavbarPage(pageIndex);
          setState(
              () => context.read<NavbarProvider>().currentIndex = pageIndex);
        },
        children: visiblePages,
      ),
    );
  }

  Widget _buildBottomNavigationBar(
      NavbarVisibilityProvider provider, List<BottomNavigationBarItem> items) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.outlineSoft),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .24),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Theme(
          data: NavbarVisibilityUtils.buildNavbarTheme(context),
          child: BottomNavigationBar(
            currentIndex: NavbarVisibilityUtils.getSafeVisibleIndex(
              provider,
              context.read<NavbarProvider>().currentIndex,
            ),
            onTap: (index) {
              final pageIndex = provider.mapVisibleIndexToPageIndex(index);
              context.read<NavbarProvider>().updateIndex(pageIndex);
            },
            items: items,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.lightMain,
            unselectedItemColor: AppColors.textMuted,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            selectedIconTheme: const IconThemeData(size: 24),
            unselectedIconTheme: const IconThemeData(size: 22),
            showSelectedLabels: true,
            showUnselectedLabels: true,
            backgroundColor: AppColors.surfaceRaised,
            elevation: 0,
          ),
        ),
      ),
    );
  }

  Future<void> _initializeNavbar() async {
    if (_isInitialized) return;

    final visibilityProvider = context.read<NavbarVisibilityProvider>();
    await visibilityProvider.ready;

    if (!mounted || _isInitialized) return;

    final navbarProvider = context.read<NavbarProvider>();
    navbarProvider.setVisibilityProvider(visibilityProvider);
    NavigatorService().setVisibilityProvider(visibilityProvider);

    final initialPage = visibilityProvider.getFirstVisiblePageIndex();
    final initialVisibleIndex =
        visibilityProvider.mapPageIndexToVisibleIndex(initialPage);
    navbarProvider.currentIndex = initialPage;
    navbarProvider.pageController = PageController(
      initialPage: initialVisibleIndex < 0 ? 0 : initialVisibleIndex,
    );

    visibilityProvider.addListener(_handleNavbarVisibilityChanged);
    _isInitialized = true;
    LogService.debug(
      'Navbar initialized with page index: $initialPage '
      '(visible index: $initialVisibleIndex)',
    );
    _trackNavbarPage(initialPage, source: 'initial');
    setState(() {});
  }

  void _handleNavbarVisibilityChanged() {
    if (!_isInitialized || !mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isInitialized) return;

      final visibilityProvider = context.read<NavbarVisibilityProvider>();
      final navbarProvider = context.read<NavbarProvider>();
      final safePage = visibilityProvider.getSafePageIndex(
        navbarProvider.currentIndex,
      );
      final targetVisibleIndex =
          visibilityProvider.mapPageIndexToVisibleIndex(safePage);

      if (targetVisibleIndex < 0 || !navbarProvider.pageController.hasClients) {
        return;
      }

      final currentVisibleIndex = navbarProvider.pageController.page?.round();
      final pageChanged = navbarProvider.currentIndex != safePage;
      final visibleIndexChanged = currentVisibleIndex != targetVisibleIndex;

      if (!pageChanged && !visibleIndexChanged) return;

      navbarProvider.currentIndex = safePage;
      if (visibleIndexChanged) {
        navbarProvider.pageController.animateToPage(
          targetVisibleIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      setState(() {});
    });
  }

  void _trackNavbarPage(int pageIndex, {String source = 'navbar'}) {
    const pageNames = [
      'StorePage',
      'HomePage',
      'InboxPage',
      'NotesPage',
      'ProjectsPage',
      'ProfilePage',
    ];
    if (pageIndex < 0 || pageIndex >= pageNames.length) return;
    AnalyticsService().trackPageView(pageNames[pageIndex], source: source);
  }

  Future<void> _loadData() async {
    try {
      LogService.debug('📥 Loading initial data...');

      context.read<StoreProvider>().storeItemList =
          await StoreRepository().getItems();
      context.read<TraitProvider>().traitList =
          await TraitRepository().getTraits();

      // Tasks and routines are already loaded in initApp() before DailyStreakProvider
      // Just run routine task creation and timer restoration
      await HiveService().createTasksFromRoutines();
      await GlobalTimer().checkSavedTimers();

      // Initialize home widget
      try {
        await HomeWidgetService.setupHomeWidget();
        await HomeWidgetService.updateAllWidgets();
        LogService.debug('🏠 Home widget initialized successfully');
      } catch (e) {
        LogService.error('Failed to initialize home widget: $e');
      }

      isLoading = true;
      setState(() {});

      _showDefaultDataDialogIfNeeded();
    } catch (e) {
      LogService.error('❌ Failed to load initial data: $e');
      isLoading = true;
      setState(() {});
    }
  }

  Future<void> _showDefaultDataDialogIfNeeded() async {
    try {
      final isFirstLaunch = await DefaultDataService.isFirstLaunch();

      if (!isFirstLaunch || !mounted) return;

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      LogService.debug('📱 First launch detected, showing dialog...');

      final result = await DefaultDataDialog.show(context);
      await DefaultDataService.markFirstLaunchSeen();

      if (result == true && mounted) {
        await _loadDefaultData();
      } else if (result == false) {
        LogService.debug('ℹ️ User declined to load sample data');
      }
    } catch (e) {
      LogService.error('❌ Error showing default data dialog: $e');
    }
  }

  Future<void> _loadDefaultData() async {
    if (!mounted) return;

    LogService.debug('✅ User accepted to load sample data');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => DefaultDataDialog.buildLoadingDialog(),
    );

    try {
      await DefaultDataService.loadDefaultData();

      if (!mounted) return;

      context.read<StoreProvider>().storeItemList =
          await StoreRepository().getItems();
      context.read<TraitProvider>().traitList =
          await TraitRepository().getTraits();
      context.read<TaskProvider>().routineList =
          await RoutineRepository().getRoutines();
      context.read<TaskProvider>().taskList = await TaskRepository().getTasks();
      await context.read<TaskProvider>().loadCategories();

      context.read<TaskProvider>().updateItems();

      Navigator.of(context).pop();

      Helper().getMessage(message: 'Sample data loaded successfully!');

      LogService.debug('✅ Sample data loaded and UI updated');
    } catch (e) {
      LogService.error('❌ Failed to load sample data: $e');

      if (mounted) {
        Navigator.of(context).pop();

        Helper().getMessage(
            message: 'Failed to load sample data: $e',
            status: StatusEnum.WARNING);
      }
    }
  }
}
