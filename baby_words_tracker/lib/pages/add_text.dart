import 'package:baby_words_tracker/auth/authentication_service.dart';
import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:baby_words_tracker/data/services/child_data_service.dart';
import 'package:baby_words_tracker/data/type_aware_services/type_aware_child_data_service.dart';
import 'package:baby_words_tracker/data/type_aware_services/type_aware_word_data_service.dart';
import 'package:baby_words_tracker/data/type_aware_services/type_aware_word_tracker_data_service.dart';
import 'package:baby_words_tracker/pages/shared/bottom_bar.dart';
import 'package:baby_words_tracker/pages/shared/top_bar.dart';
import 'package:baby_words_tracker/util/check_and_update_word.dart';
import 'package:baby_words_tracker/util/current_children_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// baby words packages
import 'package:baby_words_tracker/video/video_functions.dart';

import 'package:baby_words_tracker/data/models/child.dart';

import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:path/path.dart' as path;

class AddTextPage extends StatefulWidget {
  static const routeName = "/addtext";

  const AddTextPage({super.key});

  @override
  State<AddTextPage> createState() => _AddTextPageState();
}

class _AddTextPageState extends State<AddTextPage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController fileTextController = TextEditingController();
  List<String> parsedWords = [];

  late final TypeAwareWordDataService _wordDataService;
  late final TypeAwareWordTrackerDataService _wordTrackerDataService;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();

    if (!_initialized) {
      _wordDataService = Provider.of<TypeAwareWordDataService>(
        context,
        listen: false,
      );
      _wordTrackerDataService = Provider.of<TypeAwareWordTrackerDataService>(
        context,
        listen: false,
      );
      _initialized = true;
    }
  }

  void _parseWords() {
    String text = _controller.text;
    String cleanedText =
        text.replaceAll(RegExp(r'[^\w\s]'), ''); // Remove punctuation
    parsedWords = cleanedText.split(' ');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    return Consumer3<LocalizationService, AuthenticationService,
            TypeAwareChildDataService>(
        builder: (context, localizationService, authenticationService,
            childService, child) {
      return Scaffold(
        backgroundColor: const Color(0xFF828A8F),
        appBar: TopBar(pageName: localizationService.translate("add_words")),
        bottomNavigationBar: CustomBottomBar(AddTextPage.routeName),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Consumer<LocalizationService>(
            builder: (context, localizationService, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(
                    height: 120,
                  ),
                  Center(
                    child: Text(localizationService.translate("add_words"),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 50,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(
                    height: 80,
                  ),
                  Text(localizationService.translate("child_said"),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold)),
                  TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: localizationService.translate("child_said"),
                      hintStyle: const TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: const Color(0xFF9E1B32),
                    ),
                  ),
                  TextField(
                    controller: fileTextController,
                    onTap: () => selectFile(fileTextController),
                    readOnly: true,
                    decoration: InputDecoration(
                      //border: OutlineInputBorder(),
                      hintText: localizationService.translate(
                          "choose_file"), //'Tap to Choose Birthday..',
                      hintStyle: const TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: const Color(0xFF9E1B32),
                    ),
                  ),
                  Center(
                      child: OutlinedButton(
                    onPressed: () async {
                      Child? currChild =
                          context.read<CurrentChildrenService>().getCurrChild();
                      String? currChildID;
                      if (currChild != null) {
                        currChildID = currChild.id;
                      }

                      /* List<LanguageCode>? maybeLanguages = currChildID != null
                          ? await childDataService.getLanguages(currChildID)
                          : [LanguageCode.en];

                      List<LanguageCode> langauges =
                          maybeLanguages ?? [LanguageCode.en]; */

                      _parseWords();

                      var correctWords = 0;
                      var totalWords = 0;

                      for (var word in parsedWords) {
                        totalWords++;
                        bool result = await checkAndUpdateWord(
                          word,
                          _wordDataService,
                          targetLanguage:
                              localizationService.localization.languageCode,
                        ); //languages != null ? await checkAndUpdateWord(word, languages: languages) : await checkAndUpdateWord(word); //languages != null ? await checkAndUpdateWord(word, languages: languages) : await checkAndUpdateWord(word); //only checks the childs selected languages
                        if (result && currChildID != null) {
                          late String? filePath;
                          if (fileTextController.text != "") {
                            filePath = path.basename(fileTextController.text);
                            uploadVideo(fileTextController.text);
                          } else {
                            filePath = null;
                          }
                          addWordToChild(
                            currChildID,
                            word,
                            _wordTrackerDataService,
                            videoId: filePath,
                          );
                          correctWords++;
                          /* addVideoToWord(
                              word, path.basename(filePath), childService,
                              id: currChildID); */
                        } else {
                          if (!context.mounted) return;
                          await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text(
                                    localizationService.translate("error")),
                                content: Text(word +
                                    localizationService
                                        .translate("words_error")),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text('OK'),
                                    onPressed: () {
                                      Navigator.of(context)
                                          .pop(); // Close the dialog
                                      _controller.clear();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                          break;
                        }
                      }
                      if (!context.mounted) return;
                      if (totalWords == correctWords) {
                        await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text(
                                  localizationService.translate("success")),
                              content: Text(localizationService
                                  .translate("word_success")),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('OK'),
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pop(); // Close the dialog
                                  },
                                ),
                              ],
                            );
                          },
                        );
                        _controller.clear();
                        fileTextController.clear();
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFF828A8F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      side: const BorderSide(color: Colors.white, width: 2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 25, vertical: 0),
                    ),
                    child: Text(localizationService.translate("submit"),
                        style: const TextStyle(fontSize: 18)),
                  )),
                ],
              );
            },
          ),
        ),
      );
    });
  }

  Future<bool> addWordToChild(
    String childId,
    String word,
    TypeAwareWordTrackerDataService trackerService, {
    String? videoId,
  }) async {
    return await trackerService.addOrUpdateWordTracker(
        childId,
        word,
        WordTracker(
          id: word,
          firstUtterance: DateTime.now(),
          videoID: videoId,
        ));
  }

  Future<void> addVideoToWord(
    String childId,
    String word,
    String filePath,
    TypeAwareChildDataService childService,
  ) async {
    if (await childService.addVideo(childId, word, path.basename(filePath)) ==
        false) {
      debugPrint("AddVideo: Error adding video to work tracker");
    } else {
      debugPrint("AddVideo: $filePath added to $word");
    }
  }
}
