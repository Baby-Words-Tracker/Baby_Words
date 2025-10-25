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
        labelKey: 'home_page',
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
        iconBuilder: (context, selected) => _AddEntryIcon(selected: selected),
        labelKey: 'add_entry',
      ),
    ];

    items.addAll([
      _NavigationItem(
        routeName: StatsPage.routeName,
        iconBuilder: (context, selected) => Icon(
          selected ? Icons.auto_graph : Icons.bar_chart_outlined,
        ),
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

class _AddEntryIcon extends StatelessWidget {
  final bool selected;

  const _AddEntryIcon({required this.selected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gradient = selected
        ? LinearGradient(
            colors: [
              colorScheme.primary,
              colorScheme.primaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [
              colorScheme.primaryContainer.withOpacity(0.4),
              colorScheme.primaryContainer.withOpacity(0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(selected ? 0.35 : 0.15),
            blurRadius: selected ? 18 : 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.add_rounded,
        size: selected ? 30 : 28,
        color: selected ? colorScheme.onPrimary : colorScheme.primary,
      ),
    );
  }
}
