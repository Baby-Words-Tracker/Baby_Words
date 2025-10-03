import 'package:baby_words_tracker/auth/user_model_service.dart';
import 'package:baby_words_tracker/pages/shared/bottom_bar.dart';
import 'package:baby_words_tracker/pages/shared/top_bar.dart';
import 'package:baby_words_tracker/pages/home_page.dart';
import 'package:baby_words_tracker/util/current_children_service.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';


class SurveyPage extends StatelessWidget {
  static const routeName = '/survey'; // Route name for navigation
  const SurveyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(
            pageName: context
                .read<LocalizationService>()
                .translate("")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "New User Survey",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              "Description text",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height:20),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(10)
              ),
              child: Padding(padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: double.infinity,
                height: 600,
                child: SizedBox(
                  height: 600,
                  child: WebViewWidget(controller: WebViewController()
                  ..setJavaScriptMode(JavaScriptMode.unrestricted)
                  ..loadRequest(Uri.parse("https://forms.gle/2Z9DpNMYR2Ly1dEW8"))),),
              ),
              ),
            ),
            const SizedBox(height:15),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;
                try {
                  final docRef = FirebaseFirestore.instance.collection('Parent').doc(user.uid);
                  await docRef.update({'preStudySurveyComplete': true});
                } catch (e) {
                  print("Error: $e");
                }
              },
              child: const Text("Submit"),
            )
          ],
        ),
      ),
    );
  }
}
