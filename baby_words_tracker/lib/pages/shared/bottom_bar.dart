import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:baby_words_tracker/pages/add_entry_page.dart';
import 'package:baby_words_tracker/pages/home_page.dart';
import 'package:baby_words_tracker/pages/log_page.dart';
import 'package:baby_words_tracker/pages/settings.dart';
import 'package:baby_words_tracker/pages/stats.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomBottomBar extends StatelessWidget {
  final String currentRoute;

  const CustomBottomBar(this.currentRoute, {super.key});

  List<_NavigationItem> _buildNavItems() {
    final items = <_NavigationItem>[
      _NavigationItem(
        routeName: HomePage.routeName,
        iconBuilder: (context, selected) => Icon(
          selected ? Icons.home_rounded : Icons.home_outlined,
        ),
        labelKey: 'home_title',
      ),
      _NavigationItem(
        routeName: WordLogPage.routeName,
        iconBuilder: (context, selected) => Icon(
          selected ? Icons.menu_book : Icons.menu_book_outlined,
        ),
        labelKey: 'word_log',
      ),
      _NavigationItem(
        routeName: AddEntryPage.routeName,
        iconBuilder: (context, selected) => const Icon(Icons.add_rounded),
        labelKey: 'add_entry',
      ),
    ];

    items.addAll([
      _NavigationItem(
        routeName: StatsPage.routeName,
        iconBuilder: (context, selected) =>
            const Icon(Icons.bar_chart_outlined),
        labelKey: 'view_stats',
      ),
      _NavigationItem(
        routeName: SettingsPage.routeName,
        iconBuilder: (context, selected) => Icon(
          selected ? Icons.settings_rounded : Icons.settings_outlined,
        ),
        labelKey: 'settings',
      ),
    ]);

    return items;
  }

  int _resolveSelectedIndex(List<_NavigationItem> navItems) {
    final idx = navItems.indexWhere((item) => item.routeName == currentRoute);
    return idx >= 0 ? idx : 0;
  }

  void _handleDestinationTap(
    BuildContext context,
    List<_NavigationItem> navItems,
    int index,
  ) {
    final target = navItems[index];

    //avoids redundant navigation
    if (currentRoute == target.routeName) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(target.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<LocalizationService>(
      builder: (context, localizationService, _) {
        final navItems = _buildNavItems();
        final selectedIndex = _resolveSelectedIndex(navItems);

        return NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) =>
              _handleDestinationTap(context, navItems, index),
          destinations: navItems
              .map(
                (item) => NavigationDestination(
                  icon: IconTheme(
                    data: IconThemeData(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    child: item.iconBuilder(context, false),
                  ),
                  selectedIcon: IconTheme(
                    data: IconThemeData(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    child: item.iconBuilder(context, true),
                  ),
                  label: localizationService.translate(item.labelKey),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _NavigationItem {
  final String routeName;
  final Widget Function(BuildContext context, bool selected) iconBuilder;
  final String labelKey;

  const _NavigationItem({
    required this.routeName,
    required this.iconBuilder,
    required this.labelKey,
  });
}
