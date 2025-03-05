import 'package:baby_words_tracker/auth/authentication_service.dart';
import 'package:baby_words_tracker/data/services/child_data_service.dart';
import 'package:baby_words_tracker/data/services/general_user_service.dart';
import 'package:baby_words_tracker/data/services/parent_data_service.dart';
import 'package:baby_words_tracker/data/services/researcher_data_service.dart';
import 'package:baby_words_tracker/data/services/word_data_service.dart';
import 'package:baby_words_tracker/data/services/word_tracker_data_service.dart';
import 'package:baby_words_tracker/auth/user_model_service.dart';

import 'package:baby_words_tracker/pages/auth_gate.dart';
import 'package:baby_words_tracker/pages/profile_page.dart';
import 'package:baby_words_tracker/util/config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_functions/firebase_functions.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'pages/add_text.dart';
import 'pages/home_page.dart';
import 'pages/stats.dart';
import 'pages/upload_video.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint("Initializing Firebase");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Error initializing Firebase: $e");
  }

  if (FirebaseAuth.instance.app.name == '[DEFAULT]') {
    FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    debugPrint("Using Auth emulator");
  }

  if (FirebaseFirestore.instance.app.name == '[DEFAULT]') {
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    debugPrint("Using Firestore emulator");
  }

  runApp(
    MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ChildDataService()),
          ChangeNotifierProvider(create: (_) => ParentDataService()),
          ChangeNotifierProvider(create: (_) => ResearcherDataService()),
          ChangeNotifierProvider(create: (_) => WordDataService()),
          ChangeNotifierProvider(create: (_) => WordTrackerDataService()),
          ChangeNotifierProvider(create: (_) => Config()),
          Provider<GeneralUserService>(
            create: (context) => GeneralUserService(
              parentDataService: Provider.of<ParentDataService>(context, listen: false),
              researcherDataService: Provider.of<ResearcherDataService>(context, listen: false),
            ),
          ),
          Provider<FirebaseAuth>(
            create: (_) => FirebaseAuth.instance,
          ),
          ChangeNotifierProvider<AuthenticationService>(
            create: (context) => AuthenticationService(
              Provider.of<FirebaseAuth>(context, listen: false)
            ),
          ),
          ChangeNotifierProvider<UserModelService>(
            create: (context) => UserModelService(
              parentDataService: Provider.of<ParentDataService>(context, listen:false), 
              researcherDataService: Provider.of<ResearcherDataService>(context, listen:false), 
              authenticationService: Provider.of<AuthenticationService>(context, listen:false),
              generalUserService: Provider.of<GeneralUserService>(context, listen:false),
              ),
          ),
        ],
        child: const MyApp(),
      ),
    );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    Provider.of<UserModelService>(context, listen: false);

    
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
        useMaterial3: true,
      ),
      initialRoute: '/authgate',
      routes: {
        '/': (context) => const HomePage(),
        '/stats': (context) => const StatsPage(),
        '/addtext': (context) => const AddTextPage(),
        '/authgate': (context) => const AuthGate(),
        '/uploadvideo': (context) => const UploadVideoPage(),
        '/profilepage': (context) => ProfilePage(),
        
      },
    );
  }
}


