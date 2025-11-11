import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:baby_words_tracker/pages/add_entry_page.dart';
import 'package:baby_words_tracker/pages/home_page.dart';
import 'package:baby_words_tracker/pages/log_page.dart';
import 'package:baby_words_tracker/pages/settings.dart';
import 'package:baby_words_tracker/pages/shared/top_bar.dart';
import 'package:baby_words_tracker/pages/wip_page.dart';
// import 'package:baby_words_tracker/pages/stats.dart'; // Disabled temporarily
import 'package:baby_words_tracker/util/main_navigation_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ParentDashboard extends StatefulWidget {
  static const routeName = HomePage.routeName;

  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  late final List<_DashboardTab> _tabs;
  final PageStorageBucket _bucket = PageStorageBucket();

  @override
  void initState() {
    super.initState();
    debugPrint("ParentDashboard: initState called");
    _tabs = [
      _DashboardTab(
        labelKey: 'home_title',
        showTitle: true,
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        child: const HomePage(showChrome: false),
      ),
      _DashboardTab(
        labelKey: 'word_log_title',
        showTitle: true,
        icon: Icons.menu_book_outlined,
        selectedIcon: Icons.menu_book_rounded,
        child: const WordLogPage(showChrome: false),
      ),
      _DashboardTab(
        labelKey: 'add_entry',
        showTitle: true,
        icon: Icons.add_rounded,
        selectedIcon: Icons.add_rounded,
        child: const AddEntryPage(showChrome: false),
      ),
      _DashboardTab(
        labelKey: 'view_stats',
        showTitle: true,
        icon: Icons.bar_chart_outlined,
        selectedIcon: Icons.bar_chart_outlined,
        child: const WorkInProgressPage(featureName: 'Statistics'),
      ),
      _DashboardTab(
        labelKey: 'settings',
        showTitle: true,
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings_rounded,
        child: const SettingsPage(showChrome: false),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("ParentDashboard: build() called");
    final localization = context.watch<LocalizationService>();
    final navigation = context.watch<MainNavigationController>();
    final theme = Theme.of(context);

    final currentIndex = navigation.index.clamp(0, _tabs.length - 1);
    debugPrint("ParentDashboard: Current tab index: $currentIndex");
    final currentTab = _tabs[currentIndex];
    final String? pageTitle = currentTab.showTitle
        ? localization.translate(currentTab.labelKey)
        : null;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: TopBar(
        pageName: pageTitle ?? '',
        showPageTitle: currentTab.showTitle,
      ),
      body: PageStorage(
        bucket: _bucket,
        // Use IndexedStack to keep widgets alive between tab switches
        child: IndexedStack(
          index: currentIndex,
          children: _tabs
              .map(
                (tab) => KeyedSubtree(
                  key: PageStorageKey<String>(tab.labelKey),
                  child: tab.child,
                ),
              )
              .toList(),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 74,
        selectedIndex: currentIndex,
        onDestinationSelected: navigation.setIndex,
        destinations: _tabs
            .map(
              (tab) => NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.selectedIcon),
                label: '',
              ),
            )
            .toList(),
      ),
    );
  }
}

class _DashboardTab {
  const _DashboardTab({
    required this.labelKey,
    required this.showTitle,
    required this.icon,
    required this.selectedIcon,
    required this.child,
  });

  final String labelKey;
  final bool showTitle;
  final IconData icon;
  final IconData selectedIcon;
  final Widget child;
}
