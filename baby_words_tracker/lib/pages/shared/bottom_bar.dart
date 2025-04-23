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
              icon: const Icon(
                Icons.home,
                color: Colors.white,
                size: 40.0,
              ),
              onPressed: () {
                if (currPage != "home") Navigator.pushNamed(context, '/');
              },
            ),
            /* IconButton(
              icon: const Icon(
                Icons.chat_bubble_outlined,
                color: Colors.white,
                size: 40.0,
              ),
              onPressed: () {
                if (currPage != "addtext") {
                  Navigator.pushNamed(context, '/addtext');
                }
              },
            ), */
            IconButton(
                icon: const Icon(
                  Icons.video_camera_front,
                  color: Colors.white,
                  size: 40.0,
                ),
                onPressed: () {
                  if (currPage != "uploadvideo") {
                    Navigator.pushNamed(context, '/uploadvideo');
                  }
                }),
            IconButton(
              icon: const Icon(
                Icons.bar_chart_outlined,
                color: Colors.white,
                size: 40.0,
              ),
              onPressed: () {
                if (currPage != "stats") Navigator.pushNamed(context, '/stats');
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.settings_rounded,
                color: Colors.white,
                size: 40.0,
              ),
              onPressed: () {
                if (currPage != "settings") {
                  Navigator.pushNamed(context, '/settings');
                }
              },
            ),
          ],
        )),
  );
}
