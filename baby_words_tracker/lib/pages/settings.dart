import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:baby_words_tracker/util/child_utils.dart';
import 'package:baby_words_tracker/l10n/localization.dart';
import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/config.dart';
import 'package:baby_words_tracker/util/user_getters.dart';
import 'package:baby_words_tracker/l10n/localization.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';


class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _AddSettingsPage();
}
class _AddSettingsPage extends State<SettingsPage> {

  final TextEditingController textcontroller1 = TextEditingController(); 
  final TextEditingController textcontroller2 = TextEditingController(); 



  @override
  Widget build(BuildContext context) {
    Parent? currParent = getCurrentParent(context);
    if (currParent == null)
    {
      return const Text("Invalid User Type");
    }

    final localizationService = context.read<LocalizationService>();
    var localization = localizationService.localization; 

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Settings"),
      ),
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
          IconButton(
            icon: const Icon(
              Icons.video_camera_front,
              color: Colors.white,
              size: 40.0,
                ),
            onPressed: () {
                Navigator.pushNamed(context, '/uploadvideo');
                }
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
          const Icon(
              Icons.settings_rounded,
              color: Colors.white,
              size: 40.0,
              ),     
  ],
)
  ),
),
      body: Center(
        child: Column(
          children: [
            const SizedBox(
            height : 70,
          ),
            const Text('Settings', style: TextStyle(fontSize: 32.0, color: Color(0xFF9E1B32), fontWeight: FontWeight.bold)),
            const SizedBox(
            height : 60,
          ),
          childAddingFeature(context, textcontroller1, textcontroller2)
          ],
        ),
      ),
    );
  }
}