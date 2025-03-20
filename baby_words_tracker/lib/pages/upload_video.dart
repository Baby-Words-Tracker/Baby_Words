import 'package:baby_words_tracker/pages/shared/bottom_bar.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';


class UploadVideoPage extends StatelessWidget {
  const UploadVideoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Upload Video"),
      ),
      bottomNavigationBar: bottomBar(context, "uploadvideo"),
      body: const Center(
        child: Column(
          children: [
            SizedBox(
            height : 70,
          ),
            Text('Upload Videos', style: TextStyle(fontSize: 32.0, color: Color(0xFF9E1B32), fontWeight: FontWeight.bold)),
            SizedBox(
            height : 60,
          ),
          ],
        ),
      ),
    );
  }
}