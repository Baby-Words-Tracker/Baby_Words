import 'package:baby_words_tracker/pages/home_page.dart';
import 'package:baby_words_tracker/pages/settings.dart';
import 'package:baby_words_tracker/pages/stats.dart';
import 'package:baby_words_tracker/pages/display_video_page.dart';
import 'package:flutter/material.dart';

// Bottom Bar Widget
// In its own file to save clutter
// Allows page name to be passed in to deactivate the button for the current page
Widget bottomBar(BuildContext context, String currPage) {
  return BottomAppBar(
    color: const Color(0xFF9E1B32),
    child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(
                Icons.home,
                color: Colors.white,
                size: 40.0,
              ),
              onPressed: () {
                if (currPage != HomePage.routeName) {
                  Navigator.pushNamed(context, HomePage.routeName);
                }
              },
            ),
            IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.video_camera_front,
                  color: Colors.white,
                  size: 40.0,
                ),
                onPressed: () {
                  if (currPage != DisplayVideoPage.routeName) {
                    Navigator.pushNamed(context, DisplayVideoPage.routeName);
                  }
                }),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(
                Icons.bar_chart_outlined,
                color: Colors.white,
                size: 40.0,
              ),
              onPressed: () {
                if (currPage != StatsPage.routeName) {
                  Navigator.pushNamed(context, StatsPage.routeName);
                }
              },
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(
                Icons.settings_rounded,
                color: Colors.white,
                size: 40.0,
              ),
              onPressed: () {
                if (currPage != "settings") {
                  Navigator.pushNamed(context, SettingsPage.routeName);
                }
              },
            ),
          ],
        )),
  );
}
