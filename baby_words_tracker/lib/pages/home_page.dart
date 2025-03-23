import 'package:baby_words_tracker/auth/user_model_service.dart';
import 'package:baby_words_tracker/pages/shared/top_bar.dart';
import 'package:baby_words_tracker/pages/testing/role_testing.dart';
import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {

    //intialize localization to the parents word preferance on first visit
    //TODO: add loading screen so the whole thing doesn't glitch when parent is loaded
    Parent? parent = Provider.of<UserModelService>(context, listen: true).parent;
    if (parent != null && Provider.of<LocalizationService>(context, listen : true).getLocaleCode() != parent.language) {
      Provider.of<LocalizationService>(context, listen : false).changeLocale(parent.language);
    }

    return Scaffold(
        backgroundColor: Colors.white,
        appBar: TopBar(
            pageName: context.read<LocalizationService>().translate("home_page")),
        bottomNavigationBar: BottomAppBar(
          color: const Color(0xFF9E1B32),
          child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  const Icon(
                    Icons.home,
                    color: Colors.white,
                    size: 40.0,
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
                      }),
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
                  //TODO: remove this button when the admin page is implemented correctly
                  IconButton(
                    icon: const Icon(
                      Icons.admin_panel_settings_outlined,
                      color: Colors.white,
                      size: 40.0,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, AdminFirebasePage.routeName);
                    },
                  ),
                ],
              )),
        ),
        body: Consumer<LocalizationService>(
          builder: (context, localizationService, child) {
          return Center(
            child: Column(
              children: [
                const SizedBox(
                  height: 70,
                ),
                Text(
                    localizationService.translate("hello"),
                    style: const TextStyle(
                        fontSize: 32.0,
                        color: Color(0xFF9E1B32),
                        fontWeight: FontWeight.bold)),
                const SizedBox(
                  height: 40,
                ),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/addtext');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF828A8F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            30.0), // Change the value to adjust the roundness
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 35, vertical: 40),
                    ),
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min, // To keep the button size minimal
                      children: [
                        const Icon(
                          Icons.chat_bubble_outlined,
                          color: Colors.white,
                          size: 80.0,
                        ),
                        SizedBox(height: 5), // Spacer between icon and text
                        Text(localizationService.translate("add_words"),
                            style: const TextStyle(
                                fontSize: 24.0, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 60,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/uploadvideo');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF828A8F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            30.0), // Change the value to adjust the roundness
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 25, vertical: 40),
                    ),
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min, // To keep the button size minimal
                      children: [
                        const Icon(
                          Icons.video_camera_front,
                          color: Colors.white,
                          size: 80.0,
                        ),
                        const SizedBox(height: 5), // Spacer between icon and text
                        Text(localizationService.translate("upload_video"),
                            style: const TextStyle(
                                fontSize: 24.0, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(
                  height: 40,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/stats');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF828A8F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              30.0), // Change the value to adjust the roundness
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 37, vertical: 40),
                      ),
                      child: Column(
                        mainAxisSize:
                            MainAxisSize.min, // To keep the button size minimal
                        children: [
                          const Icon(
                            Icons.bar_chart_outlined,
                            color: Colors.white,
                            size: 80.0,
                          ),
                          const SizedBox(height: 5), // Spacer between icon and text
                          Text(localizationService.translate("view_stats"),
                              style: const TextStyle(
                                  fontSize: 24.0, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 60,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/settings');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF828A8F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              30.0), // Change the value to adjust the roundness
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 55, vertical: 40),
                      ),
                      child: Column(
                        mainAxisSize:
                            MainAxisSize.min, // To keep the button size minimal
                        children: [
                          const Icon(
                            Icons.settings_rounded,
                            color: Colors.white,
                            size: 80.0,
                          ),
                          SizedBox(height: 5), // Spacer between icon and text
                          Text(localizationService.translate("settings"),
                              style: const TextStyle(
                                  fontSize: 24.0, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }));
  }
}
