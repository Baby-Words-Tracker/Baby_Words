import 'package:baby_words_tracker/auth/user_model_service.dart';
import 'package:baby_words_tracker/data/models/parent.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:baby_words_tracker/data/services/parent_data_service.dart';


import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;  // For checking platform

import 'home_page.dart';

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

  Future<Parent> _addUserToDatabase(BuildContext context, User user) async {
    ParentDataService parentDataService = Provider.of<ParentDataService>(context, listen: false);

    if (user.email == null) {
     throw Exception('User email is null in auth_gate');
    }

    Parent? newParent = await parentDataService.getParent(user.email!);
    Researcher testResearcher = await ResearcherDataService().getResearcher(user.email!);

    newParent ??= await parentDataService.createParent(user.email!, user.displayName ?? 'New Parent', []);

    return newParent;
  }

  @override
  Widget build(BuildContext context) {
    UserModelService userModelService = Provider.of<UserModelService>(context, listen: false);

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
        
        if (user == null) {
          throw Exception('User is null in auth_gate');
        }
        
        return FutureBuilder<Parent>(
          future: _addUserToDatabase(context, user),
          builder: (context, parentSnapshot) {
            if (parentSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            } else if (parentSnapshot.hasError) {
              return Scaffold(
                body: Center(child: Text('Error: ${parentSnapshot.error}')),
              );
            }
            else if (parentSnapshot.hasData && parentSnapshot.data != null) {
              userModelService.setUserParent(parentSnapshot.data!);
            }
            else {
              userModelService.setUserByEmail(user.email);
            }

            return const HomePage();
          },
        );
      },
    );
  }
}

