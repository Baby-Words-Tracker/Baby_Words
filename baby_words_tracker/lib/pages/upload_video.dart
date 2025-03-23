import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:baby_words_tracker/l10n/localization.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:provider/provider.dart';
import 'package:baby_words_tracker/pages/shared/top_bar.dart';


class UploadVideoPage extends StatelessWidget {
  const UploadVideoPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: TopBar(pageName: context.read<LocalizationService>().translate("upload_video")),
      bottomNavigationBar: BottomAppBar(
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
                Navigator.pushNamed(context, '/');
                },
              ),
          IconButton(
            icon: const Icon(
                Icons.chat_bubble_outlined,
                color: Colors.white,
                size: 40.0,
            ),
            onPressed: () {
                  Navigator.pushNamed(context, '/addtext');
                  },
          ),
          const Icon(
              Icons.video_camera_front,
              color: Colors.white,
              size: 40.0,
              ),
          IconButton(
            icon: const Icon(
                Icons.bar_chart_outlined,
                color: Colors.white,
                size: 40.0,
            ),
            onPressed: () {
                  Navigator.pushNamed(context, '/stats');
                  },
          ),
          IconButton(
            icon: const Icon(
              Icons.settings_rounded,
              color: Colors.white,
              size: 40.0,
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
                },
              ),
  ],
)
  ),
),
      body: Center(
        child: Consumer<LocalizationService>(
          builder: (context, localizationService, child) {
            return Column(
          children: [
            const SizedBox(
            height : 70,
          ),
            Text(localizationService.translate("upload_video"), style: const TextStyle(fontSize: 32.0, color: Color(0xFF9E1B32), fontWeight: FontWeight.bold)),
            const SizedBox(
            height : 60,
          ),
          ],
        );
        },
      ),
    )
    );
  }
}