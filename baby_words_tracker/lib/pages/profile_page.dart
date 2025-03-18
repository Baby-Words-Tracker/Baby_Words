import 'package:baby_words_tracker/util/child_utils.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});

  final TextEditingController textcontroller1 = TextEditingController(); 
  final TextEditingController textcontroller2 = TextEditingController(); 

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
      children: [
        childAddingFeature(context, textcontroller1, textcontroller2)
      ],
    );
  }
}