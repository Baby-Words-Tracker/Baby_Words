import 'package:baby_words_tracker/pages/shared/bottom_bar.dart';
import 'package:baby_words_tracker/util/current_children_service.dart';
import 'package:flutter/material.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:provider/provider.dart';
import 'package:baby_words_tracker/pages/shared/top_bar.dart';
import 'package:baby_words_tracker/video/video_functions.dart';
import 'package:baby_words_tracker/util/ui_utils.dart';
import 'package:baby_words_tracker/data/services/child_data_service.dart';
import 'package:path/path.dart' as path;

class UploadVideoPage extends StatefulWidget {
  static const routeName = '/uploadvideo';
  const UploadVideoPage({super.key});

  @override
  State<UploadVideoPage> createState() => _UploadVideoPageState();
}

class _UploadVideoPageState extends State<UploadVideoPage> {
  final TextEditingController fileTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer3<LocalizationService, ChildDataService,
            CurrentChildrenService>(
        builder: (context, localizationService, childService,
            currentChildrenService, child) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: TopBar(pageName: localizationService.translate("upload_video")),
        bottomNavigationBar: CustomBottomBar(UploadVideoPage.routeName),
        body: Column(
          children: [
            const SizedBox(
              height: 70,
            ),
            Center(
              child: TextField(
                controller: fileTextController,
                onTap: () => selectFile(fileTextController),
                readOnly: true,
                decoration: InputDecoration(
                  //border: OutlineInputBorder(),
                  hintText: localizationService
                      .translate("choose_file"), //'Tap to Choose Birthday..',
                  hintStyle: const TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: const Color(0xFF9E1B32),
                ),
              ),
            ),
            const SizedBox(
              height: 60,
            ),
            //upload video button
            //record video button
            const SizedBox(height: 20.0),
            Center(
                child: OutlinedButton(
              onPressed: () {
                //add the word to the child with the id, or the default testing child if no input
                if (fileTextController.text != "") {
                  //add child
                  final String? childId =
                      currentChildrenService.getCurrChild()?.id;
                  final filePath = fileTextController.text;
                  uploadVideo(filePath);
                  childService.addVideo(
                      childId!, "test", path.basename(filePath));
                  //added indicator
                  showAlertMessage(
                      context,
                      localizationService.translate("file_added"),
                      localizationService.translate("add_file_success"));
                } else {
                  //failed to add indicator //FIXME: better error checking
                  showAlertMessage(
                      context,
                      localizationService.translate("file_not_added"),
                      localizationService.translate("there was no file"));
                }
                fileTextController.clear();
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFF828A8F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                side: const BorderSide(color: Colors.white, width: 2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 25, vertical: 0),
              ),
              child: Text(localizationService.translate("submit"),
                  style: const TextStyle(fontSize: 18)),
            ))
          ],
        ),
      );
    });
  }
}
