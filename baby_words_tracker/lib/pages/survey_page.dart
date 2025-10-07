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
import 'package:flutter/foundation.dart';
// import 'dart:ui_web' as ui_web;
// import 'package:web/web.dart' as web;


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
              "New User - Survey",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              "",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height:5),
            SurveyDisplay(),
            const SizedBox(height:15),
            SurveyCheckbox(),
            const SizedBox(height:15),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;
                try {
                  final docRef = FirebaseFirestore.instance.collection('Parent').doc(user.uid);
                  await docRef.update({'preStudySurveyComplete': true});
                  Navigator.pushReplacementNamed(context, HomePage.routeName);
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

class SurveyCheckbox extends StatefulWidget {
  @override
  _SurveyCheckboxState createState() => _SurveyCheckboxState();
}

class _SurveyCheckboxState extends State<SurveyCheckbox> {
  bool checked = false;

  @override
  Widget build(BuildContext context){
    return Wrap(
      spacing: 4.0,
      runSpacing: 4.0,
      alignment: WrapAlignment.center,
      children: [
        Text('I certify that I have completed and signed the study consent form.'),
        Checkbox (
          value: checked,
          onChanged: (bool? value) {
            setState(() {
              checked = value!;
            });
          },
        ),
          ]
    );
  }
}

class SurveyDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context){
    if (kIsWeb){
      return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.circular(10)),
            child: Padding(padding: const EdgeInsets.all(8.0),
            child: SizedBox(
                width: double.infinity,
                height: 400,
                child: SizedBox(
                  height: 400,
                  child: HtmlView(),
                  ),),
                  ),
             );
    } else {
      return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(10)
              ),
              child: Padding(padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: double.infinity,
                height: 500,
                child: SizedBox(
                  height: 400,
                  child: WebViewWidget(controller: WebViewController()
                  ..setJavaScriptMode(JavaScriptMode.unrestricted)
                  ..loadRequest(Uri.parse("https://universityofalabama.az1.qualtrics.com/jfe/form/SV_5vYPatDEkugyDQy"))),),
              ),
              ),
            );
    }
  }
}

class HtmlView extends StatefulWidget {
  const HtmlView({super.key});
  @override 
  State<HtmlView> createState() => _HtmlViewState();
}

class _HtmlViewState extends State<HtmlView> {
  @override
  void initState() {
    super.initState();

    //   ui_web.platformViewRegistry.registerViewFactory(
    //   'survey-form-view',
    //   (int viewId) => web.HTMLIFrameElement()
    //     ..src = 'https://universityofalabama.az1.qualtrics.com/jfe/form/SV_5vYPatDEkugyDQy'
    //     ..style.border = 'none'
    //     ..style.width = '100%'
    //     ..style.height = '100%',
    // );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
    return const HtmlElementView(viewType: 'survey-form-view');
    }else{
      return Text('');
    }
  }
}