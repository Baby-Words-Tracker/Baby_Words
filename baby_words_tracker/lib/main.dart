import 'package:baby_words_tracker/auth/authentication_service.dart';
import 'package:baby_words_tracker/data/services/child_data_service.dart';
import 'package:baby_words_tracker/data/services/parent_data_service.dart';
import 'package:baby_words_tracker/data/services/researcher_data_service.dart';
import 'package:baby_words_tracker/data/services/word_data_service.dart';
import 'package:baby_words_tracker/data/services/word_tracker_data_service.dart';
import 'package:baby_words_tracker/auth/user_model_service.dart';

import 'package:baby_words_tracker/data/models/parent.dart';

import 'package:baby_words_tracker/pages/auth_gate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'pages/add_text.dart';
import 'pages/home_page.dart';
import 'pages/stats.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ChildDataService()),
          ChangeNotifierProvider(create: (_) => ParentDataService()),
          ChangeNotifierProvider(create: (_) => ResearcherDataService()),
          ChangeNotifierProvider(create: (_) => WordDataService()),
          ChangeNotifierProvider(create: (_) => WordTrackerDataService()),
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
              authenticationService: Provider.of<AuthenticationService>(context, listen:false)
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
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
        useMaterial3: true,
      ),
      initialRoute: '/authgate',
      routes: {
        '/': (context) => const HomePage(),
        '/stats': (context) => StatsPage(),
        '/addtext': (context) => const AddTextPage(title: "Add Text",),
        '/authgate': (context) => const AuthGate(),
      },
    );
  }
}


