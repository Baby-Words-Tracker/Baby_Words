import 'package:baby_words_tracker/auth/authentication_service.dart';
import 'package:baby_words_tracker/pages/shared/bottom_bar.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:baby_words_tracker/l10n/localization.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:provider/provider.dart';
import 'package:baby_words_tracker/pages/shared/top_bar.dart';

class UploadVideoPage extends StatefulWidget {
  const UploadVideoPage({super.key});

  @override
  State<UploadVideoPage> createState() => _UploadVideoPageState();
}

class _UploadVideoPageState extends State<UploadVideoPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<LocalizationService, AuthenticationService>(
        builder: (context, localizationService, authenticationService, child) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: TopBar(pageName: localizationService.translate("upload_video")),
        bottomNavigationBar: bottomBar(context, "uploadvideo"),
        body: Column(
            children: [
              const SizedBox(
                height: 70,
              ),
              Center(
              child: Text(localizationService.translate("upload_video"),
                  style: const TextStyle(
                      fontSize: 32.0,
                      color: Color(0xFF9E1B32),
                      fontWeight: FontWeight.bold)),
              ),
              const SizedBox(
                height: 60,
              ),
              //upload video button
              //record video button
            ],
          ),
      );
    });
  }
}
