import 'package:baby_words_tracker/l10n/localization_service.dart'; //important for translation
import 'package:baby_words_tracker/pages/display_video_page.dart';
import 'package:baby_words_tracker/pages/home_page.dart';
import 'package:baby_words_tracker/pages/settings.dart';
import 'package:baby_words_tracker/pages/stats.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomBottomBar extends StatelessWidget {
  final String currentRoute;

  const CustomBottomBar(this.currentRoute, {super.key});

  static const _navItems = <_NavigationItem>[
    _NavigationItem(
      routeName: HomePage.routeName,
      icon: Icons.home,
      labelKey: 'home_page',
    ),
    _NavigationItem(
      routeName: DisplayVideoPage.routeName,
      icon: Icons.video_camera_front,
      labelKey: 'upload_video',
    ),
    _NavigationItem(
      routeName: StatsPage.routeName,
      icon: Icons.bar_chart_outlined,
      labelKey: 'view_stats',
    ),
    _NavigationItem(
      routeName: SettingsPage.routeName,
      icon: Icons.settings_rounded,
      labelKey: 'settings',
    ),
  ];

  int _resolveSelectedIndex() {
    final idx =
        _navItems.indexWhere((item) => item.routeName == currentRoute);
    return idx >= 0 ? idx : 0;
  }

  void _handleDestinationTap(BuildContext context, int index) {
    final target = _navItems[index];

    //avoids redundant navigation
    if (currentRoute == target.routeName) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(target.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localizationService, _) {
        final selectedIndex = _resolveSelectedIndex();

        return NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) =>
              _handleDestinationTap(context, index),
          destinations: _navItems
              .map(
                (item) => NavigationDestination(
                  icon: Icon(item.icon),
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
  final IconData icon;
  final String labelKey;

  const _NavigationItem({
    required this.routeName,
    required this.icon,
    required this.labelKey,
  });
}
