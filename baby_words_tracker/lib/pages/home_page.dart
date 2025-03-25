import 'package:baby_words_tracker/pages/shared/bottom_bar.dart';
import 'package:baby_words_tracker/auth/user_model_service.dart';
import 'package:baby_words_tracker/pages/shared/top_bar.dart';
import 'package:baby_words_tracker/pages/testing/role_testing.dart';
import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    //intialize localization to the parents word preferance on first visit and display loading screen until parent is received
    Parent? parent =
        Provider.of<UserModelService>(context, listen: true).parent;
    LanguageCode language =
        Provider.of<LocalizationService>(context, listen: true).getLocaleCode();
    if (parent != null && language != parent.language) {
      Provider.of<LocalizationService>(context, listen: false)
          .changeLocale(parent.language);
      return const Center(child: CircularProgressIndicator());
    } else if (parent == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Consumer<LocalizationService>(
        builder: (context, localizationService, child) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: TopBar(pageName: localizationService.translate("home_page")),
        bottomNavigationBar: bottomBar(context, "home"),
        body: Center(
          child: Column(
            children: [
              const SizedBox(
                height: 70,
              ),
              Text(localizationService.translate("hello"),
                  style: const TextStyle(
                      fontSize: 32.0,
                      color: Color(0xFF9E1B32),
                      fontWeight: FontWeight.bold)),
              const SizedBox(
                height: 40,
              ),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/addtext');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF828A8F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outlined,
                          color: Colors.white,
                          size: 80.0,
                        ),
                        const SizedBox(height: 5),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                              localizationService.translate("add_words"),
                              style: const TextStyle(
                                  fontSize: 24.0, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  width: 60,
                ),
                SizedBox(
                  width: 150,
                  height: 150,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/uploadvideo');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF828A8F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.video_camera_front,
                          color: Colors.white,
                          size: 80.0,
                        ),
                        const SizedBox(height: 5),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                              localizationService.translate("upload_video"),
                              style: const TextStyle(
                                  fontSize: 24.0, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
              const SizedBox(
                height: 40,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 150,
                    width: 150,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/stats');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF828A8F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.bar_chart_outlined,
                            color: Colors.white,
                            size: 80.0,
                          ),
                          const SizedBox(height: 5),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                                localizationService.translate("view_stats"),
                                style: const TextStyle(
                                    fontSize: 24.0,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 60,
                  ),
                  SizedBox(
                    height: 150,
                    width: 150,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/settings');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF828A8F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.settings_rounded,
                            color: Colors.white,
                            size: 80.0,
                          ),
                          const SizedBox(height: 5),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                                localizationService.translate("settings"),
                                style: const TextStyle(
                                    fontSize: 24.0,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}
