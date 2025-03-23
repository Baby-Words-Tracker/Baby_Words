import 'package:baby_words_tracker/pages/shared/bottom_bar.dart';
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
      appBar: TopBar(pageName: "Home Page"),
      bottomNavigationBar: bottomBar(context, "home"),
      body: Center(
        child: Column(
          children: [
            const SizedBox(
            height : 70,
          ),
            const Text('Hello, User!', style: TextStyle(fontSize: 32.0, color: Color(0xFF9E1B32), fontWeight: FontWeight.bold)),
            const SizedBox(
            height : 40,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [ 
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
                child: const Column(
                mainAxisSize: MainAxisSize.min, 
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outlined, color: Colors.white,
                  size: 80.0,),
                  SizedBox(height: 5), 
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Add Words', style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold)),
                  ),
                ],
                            ),
                            ),
              ),
            const SizedBox(
            width : 60,
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
                child: const Column(
                mainAxisSize: MainAxisSize.min, 
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_camera_front, color: Colors.white,
                  size: 80.0,),
                  SizedBox(height: 5),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Upload Video', style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              ),
            ),
            ]
          ),
          const SizedBox(
            height : 40,
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
                child: const Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart_outlined, color: Colors.white,
                  size: 80.0,),
                  SizedBox(height: 5),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('View Stats', style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              ),
            ),
            const SizedBox(
            width : 60,
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
                child: const Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.settings_rounded, color: Colors.white,
                  size: 80.0,),
                  SizedBox(height: 5),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Settings', style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold)),
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
  }
}
