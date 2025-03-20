import 'package:baby_words_tracker/pages/shared/bottom_bar.dart';
import 'package:baby_words_tracker/pages/shared/top_bar.dart';
import 'package:flutter/material.dart';
import 'package:baby_words_tracker/util/child_utils.dart';


class Settings extends StatelessWidget {
  Settings({super.key});

  final TextEditingController textcontroller1 = TextEditingController(); 
  final TextEditingController textcontroller2 = TextEditingController(); 
  final TextEditingController textcontroller3 = TextEditingController(); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: TopBar(pageName: "Settings"),
      bottomNavigationBar: bottomBar(context, "settings"),
      body: Center(
        child: Column(
          children: [
            const SizedBox(
            height : 70,
          ),
            const Text('Settings', style: TextStyle(fontSize: 32.0, color: Color(0xFF9E1B32), fontWeight: FontWeight.bold)),
            const SizedBox(
            height : 60,
          ),
          childAddingFeature(context, textcontroller1, textcontroller2),
          
          addCurrentChildToOtherParentFeature(context, textcontroller3),
          ],
        ),
      ),
    );
  }
}