import 'package:baby_words_tracker/auth/user_model_service.dart';
import 'package:baby_words_tracker/util/user_type.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;  // For checking platform

import 'home_page.dart';
import 'researcher_home_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  String _getPlatformKey() {
    if(kIsWeb) {
      return '37552098276-cmotnbdu0toapp98j9duid91fuetlgg4.apps.googleusercontent.com';  // Use this key for web
    } else if (io.Platform.isIOS) {
      return '37552098276-0okgdbhghlc9di6svkvf7losu9esrp29.apps.googleusercontent.com';  // Use this key for iOS
    } 
    return '37552098276-cmotnbdu0toapp98j9duid91fuetlgg4.apps.googleusercontent.com';  // Use this key for all other platforms
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: Provider.of<FirebaseAuth>(context).authStateChanges(),
      builder: (context, snapshot) {
        if(snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        else if (snapshot.hasError) {
          String errorMessage = snapshot.error.toString();
          return Scaffold(
            body: Center(
              child: Text('An error occurred: $errorMessage'),
            ),
          );
        }
        else if (!snapshot.hasData) {
          return SignInScreen(
            providers: [
              EmailAuthProvider(),
              GoogleProvider(clientId: _getPlatformKey()),
            ],
            headerBuilder: (context, constraints, shrinkOffset) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.asset('assets/LECS_mascot_filled.png'),
                ),
              );
            },
            subtitleBuilder: (context, action) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: action == AuthAction.signIn
                    ? const Text('Welcome to BabyWordsTracker, please sign in!')
                    : const Text('Welcome to BabyWordsTracker, please sign up!'),
              );
            },
            footerBuilder: (context, action) {
              return const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'By signing in, you agree to our terms and conditions.',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            },
            sideBuilder: (context, shrinkOffset) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.asset('assets/LECS_mascot_filled.png'),
                ),
              );
            },
          );
        }

        // Add user to database on first login
        User? user = snapshot.data;

        final userModelService = context.watch<UserModelService>(); // Listen for changes
        UserType userType = userModelService.userType;

        if (user == null) {
          throw Exception('User is null in auth_gate');
        }
        else if (userType == UserType.unauthenticated) {
          return const Center(child: CircularProgressIndicator()); // Wait until the sync is complete
        } 
        else if (userType == UserType.parent) {
          return const HomePage();
        } 
        else if (userType == UserType.researcher) {
          return const ResearcherHomePage();
        } 
        else {
          throw Exception('Unexpected user state occured');
        }
      },
    );
  }
}

