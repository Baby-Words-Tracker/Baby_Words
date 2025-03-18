import 'package:baby_words_tracker/util/child_utils.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key}); 

  @override
  Widget build(BuildContext context) {

    return ProfileScreen(
      appBar: AppBar(
          title: const Text('User Profile'),
      ),
      actions: [
        SignedOutAction((context) {
          Navigator.of(context).pop();
        })
      ],
    );
  }
}