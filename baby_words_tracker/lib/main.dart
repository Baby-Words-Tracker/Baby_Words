// Data
import 'package:baby_words_tracker/data/services/child_data_service.dart';
import 'package:baby_words_tracker/data/services/general_user_service.dart';
import 'package:baby_words_tracker/data/services/parent_data_service.dart';
import 'package:baby_words_tracker/data/services/researcher_data_service.dart';
import 'package:baby_words_tracker/data/services/word_data_service.dart';
import 'package:baby_words_tracker/data/services/word_tracker_data_service.dart';
import 'package:baby_words_tracker/data/services/user_profile_service.dart';

// Auth
import 'package:baby_words_tracker/auth/authentication_service.dart';
import 'package:baby_words_tracker/auth/user_model_service.dart';
import 'package:baby_words_tracker/auth/user_profile_model_service.dart';

//L10n
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';

// Pages
import 'package:baby_words_tracker/pages/auth_gate.dart';
import 'package:baby_words_tracker/pages/new_auth_gate.dart';
import 'package:baby_words_tracker/pages/onboarding/survey_page.dart';
import 'package:baby_words_tracker/pages/profile_page.dart';
import 'package:baby_words_tracker/pages/admin_page.dart';
import 'pages/add_text.dart';
import 'pages/home_page.dart';
import 'pages/stats.dart';
import 'pages/upload_video.dart';
import 'pages/display_video_page.dart';

// Util
import 'package:baby_words_tracker/util/current_children_service.dart';
import 'package:baby_words_tracker/util/check_emulators.dart';
import 'package:baby_words_tracker/video/video_storage_service.dart';

// Firebase
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

// Flutter
import 'package:flutter/material.dart';

// Provider
import 'package:provider/provider.dart';

// Firebase Options
import 'firebase_options.dart';

import 'pages/settings.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint("Initializing Firebase");
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } else {
        Firebase.app();
      }
    } on FirebaseException catch (e) {
      if (e.code == 'duplicate-app') {
        Firebase.app();
      } else {
        rethrow;
      }
    }
    
    // Connect to Firebase Emulators in debug mode, but not for production. Uncomment for development.
    // await setupFirebaseEmulators();
    
    //can probably remove this once adding the change notifyers
    runApp(
      // Provider used for dependency injection of database functions and configurations
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ChildDataService()),
          ChangeNotifierProvider(create: (_) => ParentDataService()),
          ChangeNotifierProvider(create: (_) => ResearcherDataService()),
          ChangeNotifierProvider(create: (_) => WordDataService()),
          Provider(create: (_) => WordTrackerDataService()),
          ChangeNotifierProvider(
            create: (_) => LocalizationService(),
            lazy: false,
          ),
          Provider<GeneralUserService>(
            create: (context) => GeneralUserService(
              parentDataService:
                  Provider.of<ParentDataService>(context, listen: false),
              researcherDataService:
                  Provider.of<ResearcherDataService>(context, listen: false),
            ),
          ),
          Provider<FirebaseAuth>(
            create: (_) => FirebaseAuth.instance,
          ),
          ChangeNotifierProvider<AuthenticationService>(
            create: (context) => AuthenticationService(
                Provider.of<FirebaseAuth>(context, listen: false)),
          ),
          // NEW: UserProfile service
          ChangeNotifierProvider<UserProfileService>(
            create: (_) => UserProfileService(),
          ),
          // NEW: UserModelService using UserProfile
          ChangeNotifierProvider<UserProfileModelService>(
            create: (context) => UserProfileModelService(
              authenticationService:
                  Provider.of<AuthenticationService>(context, listen: false),
              userProfileService:
                  Provider.of<UserProfileService>(context, listen: false),
            ),
            lazy: false,
          ),
          ChangeNotifierProvider<VideoStorageService>(
            create: (context) => VideoStorageService(
              userProfileModelService:
                  Provider.of<UserProfileModelService>(context, listen: false),
            ),
            lazy: false,
          ),
          // OLD: Keep for backward compatibility during transition
          ChangeNotifierProvider<UserModelService>(
            create: (context) => UserModelService(
              authenticationService:
                  Provider.of<AuthenticationService>(context, listen: false),
              generalUserService:
                  Provider.of<GeneralUserService>(context, listen: false),
            ),
            lazy: false,
          ),
          ChangeNotifierProvider(
            create: (context) => CurrentChildrenService(
              childService:
                  Provider.of<ChildDataService>(context, listen: false),
              userService:
                  Provider.of<UserModelService>(context, listen: false),
              userProfileService:
                  Provider.of<UserProfileModelService>(context, listen: false),
            ),
            lazy: false,
          ),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    debugPrint("Error initializing Firebase: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Root widget
  @override
  Widget build(BuildContext context) {
    Provider.of<UserProfileModelService>(context, listen: false);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFD64545),
      brightness: Brightness.light,
    );
    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFD64545),
      brightness: Brightness.dark,
    );

    return MaterialApp(
        title: 'WordBuds Root',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: colorScheme,
          useMaterial3: true,
          //platform: TargetPlatform.iOS,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          textTheme: _buildTextTheme(ThemeData.light().textTheme, colorScheme),
          scaffoldBackgroundColor: colorScheme.surface,
          appBarTheme: AppBarTheme(
            backgroundColor: colorScheme.surface,
            foregroundColor: colorScheme.onSurface,
            elevation: 0,
            titleTextStyle: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          cardTheme: CardThemeData(
            color: colorScheme.surface,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8),
          ),
          navigationBarTheme: NavigationBarThemeData(
            height: 68,
            backgroundColor: colorScheme.surface,
            indicatorColor: colorScheme.primaryContainer,
            elevation: 0,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
            iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
              (states) {
                final selected = states.contains(WidgetState.selected);
                return IconThemeData(
                  size: selected ? 28 : 26,
                  color: selected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                );
              },
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              elevation: 0,
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: const StadiumBorder(),
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: colorScheme.primary, width: 1),
            ),
            hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: darkColorScheme,
          useMaterial3: true,
          platform: TargetPlatform.iOS,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          textTheme:
              _buildTextTheme(ThemeData.dark().textTheme, darkColorScheme),
          scaffoldBackgroundColor: darkColorScheme.surface,
          appBarTheme: AppBarTheme(
            backgroundColor: darkColorScheme.surface,
            foregroundColor: darkColorScheme.onSurface,
            elevation: 0,
            titleTextStyle: TextStyle(
              color: darkColorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          cardTheme: CardThemeData(
            color: darkColorScheme.surface,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: darkColorScheme.surface,
            indicatorColor: darkColorScheme.primaryContainer,
            elevation: 0,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
            iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
              (states) {
                final selected = states.contains(WidgetState.selected);
                return IconThemeData(
                  size: selected ? 34 : 30,
                  color: selected
                      ? darkColorScheme.onPrimaryContainer
                      : darkColorScheme.onSurfaceVariant,
                );
              },
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              elevation: 0,
              backgroundColor: darkColorScheme.primary,
              foregroundColor: darkColorScheme.onPrimary,
              shape: const StadiumBorder(),
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: darkColorScheme.surfaceContainerHighest,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide:
                  BorderSide(color: darkColorScheme.primary, width: 1),
            ),
            hintStyle: TextStyle(color: darkColorScheme.onSurfaceVariant),
          ),
        ),
        themeMode: ThemeMode.system, // Set light or dark mode based on system settings
        initialRoute:
            NewAuthGate.routeName, // NEW: Use new auth gate with UserProfile
        routes: {
          //Navigate app using named routes
          HomePage.routeName: (context) => const HomePage(),
          StatsPage.routeName: (context) => const StatsPage(),
          AddTextPage.routeName: (context) => const AddTextPage(),
          AuthGate.routeName: (context) => const AuthGate(), // OLD: Keep for reference
          NewAuthGate.routeName: (context) => const NewAuthGate(), // NEW
          SurveyPage.routeName: (context) => const SurveyPage(),
          DisplayVideoPage.routeName: (context) => const DisplayVideoPage(),
          ProfilePage.routeName: (context) => const ProfilePage(),
          SettingsPage.routeName: (context) => const SettingsPage(),
          UploadVideoPage.routeName: (context) => const UploadVideoPage(),
          AdminPage.routeName: (context) => const AdminPage(),
        },
        locale:
            Provider.of<LocalizationService>(context, listen: true).getLocale(),
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          FirebaseUILocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('es'),
        ]);
  }
}

TextTheme _buildTextTheme(TextTheme base, ColorScheme colorScheme) {
  return base.copyWith(
    displayLarge: base.displayLarge?.copyWith(
      fontWeight: FontWeight.w700,
      height: 1.1,
    ),
    headlineLarge: base.headlineLarge?.copyWith(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      height: 1.1,
    ),
    headlineMedium: base.headlineMedium?.copyWith(
      fontSize: 28,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: base.titleLarge?.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: base.titleMedium?.copyWith(
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: base.bodyLarge?.copyWith(
      fontSize: 17,
      height: 1.4,
    ),
    bodyMedium: base.bodyMedium?.copyWith(
      fontSize: 16,
      height: 1.4,
    ),
    labelLarge: base.labelLarge?.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    ),
  ).apply(
    bodyColor: colorScheme.onSurface,
    displayColor: colorScheme.onSurface,
  );
}
