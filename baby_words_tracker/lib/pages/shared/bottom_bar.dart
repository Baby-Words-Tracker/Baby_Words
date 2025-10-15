import 'package:baby_words_tracker/l10n/localization_service.dart'; //important for translation
import 'package:baby_words_tracker/pages/display_video_page.dart';
import 'package:baby_words_tracker/pages/home_page.dart';
import 'package:baby_words_tracker/pages/settings.dart';
import 'package:baby_words_tracker/pages/stats.dart';
import 'package:baby_words_tracker/util/feature_flags.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomBottomBar extends StatelessWidget {
  final String currentRoute;

  const CustomBottomBar(this.currentRoute, {super.key});

  List<_NavigationItem> _buildNavItems() {
    final items = <_NavigationItem>[
      const _NavigationItem(
        routeName: HomePage.routeName,
        icon: Icons.home,
        labelKey: 'home_page',
      ),
      const _NavigationItem(
        routeName: StatsPage.routeName,
        icon: Icons.bar_chart_outlined,
        labelKey: 'view_stats',
      ),
      const _NavigationItem(
        routeName: SettingsPage.routeName,
        icon: Icons.settings_rounded,
        labelKey: 'settings',
      ),
    ];

    if (FeatureFlags.parentLocalVideos) {
      items.insert(
        1,
        const _NavigationItem(
          routeName: DisplayVideoPage.routeName,
          icon: Icons.video_camera_front,
          labelKey: 'upload_video',
        ),
      );
    }

    return items;
  }

  int _resolveSelectedIndex(List<_NavigationItem> navItems) {
    final idx =
        navItems.indexWhere((item) => item.routeName == currentRoute);
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
