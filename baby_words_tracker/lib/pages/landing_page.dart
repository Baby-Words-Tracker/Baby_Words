import 'package:baby_words_tracker/pages/shared/bottom_bar.dart';
import 'package:baby_words_tracker/pages/shared/top_bar.dart';
import 'package:baby_words_tracker/util/check_and_update_words.dart';
import 'package:baby_words_tracker/util/current_children_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:baby_words_tracker/data/services/child_data_service.dart';
import 'package:baby_words_tracker/data/services/word_data_service.dart';
import 'package:baby_words_tracker/data/services/word_tracker_data_service.dart';
import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:baby_words_tracker/video/video_functions.dart';
import 'package:path/path.dart' as path;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController fileTextController = TextEditingController();
  List<String> parsedWords = [];

  void _parseWords() {
    String text = _controller.text;
    String cleanedText =
        text.replaceAll(RegExp(r'[^\w\s]'), ''); // Remove punctuation
    parsedWords = cleanedText.split(' ');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
        builder: (context, localizationService, child) {
      Child? currChild = context.watch<CurrentChildrenService>().getCurrChild();
      String? currChildID;
      if (currChild != null) {
        currChildID = currChild.id;
      }
      String childID = currChildID ?? "error";

      return Scaffold(
        backgroundColor: const Color(0xFF828A8F),
        appBar: TopBar(pageName: localizationService.translate("word_buds")),
        bottomNavigationBar: bottomBar(context, "home"),
        body: Stack(children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Consumer<LocalizationService>(
              builder: (context, localizationService, child) {
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      StreamBuilder<int?>(
                        stream:
                            getNumWords(childID),
                        builder: (BuildContext context,
                            AsyncSnapshot<int?> snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: Text(
                                localizationService.translate("loading"),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 50,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          } else if (snapshot.hasData) {
                            int? numWords = snapshot.data;
                            return Padding(
                              padding: const EdgeInsets.only(top: 25.0),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "${currChild?.name} ${localizationService.translate("knows")} $numWords ${localizationService.translate("words")}!",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          } else {
                            return Center(
                              child: Text(
                                localizationService.translate("go_to_settings"),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 50.0),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                color: Colors.white,
                                elevation: 5,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    width: 150,
                                    height: 150,
                                    alignment: Alignment.center,
                                    child: StreamBuilder<String?>(
                                      stream: getRecentWordTracker(childID),
                                      builder: (BuildContext context,
                                          AsyncSnapshot<String?> snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return Center(
                                            child: Text(
                                              localizationService
                                                  .translate("loading"),
                                              style: const TextStyle(
                                                color: Color(0xFF9E1B32),
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          );
                                        } else if (snapshot.hasData) {
                                          String? word = snapshot.data;
                                          return Center(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  localizationService
                                                      .translate("most_recent"),
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: Color(0xFF9E1B32),
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                FittedBox(
                                                  fit: BoxFit.contain,
                                                  child: Text(
                                                    "$word",
                                                    style: const TextStyle(
                                                      color: Color(0xFF9E1B32),
                                                      fontSize: 40,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        } else {
                                          return Center(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(localizationService.translate("most_recent"),
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: Color(0xFF9E1B32),
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const Text(
                                                  "N/A",
                                                  style: TextStyle(
                                                    color: Color(0xFF9E1B32),
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                color: Colors.white,
                                elevation: 5,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    width: 150,
                                    height: 150,
                                    alignment: Alignment.center,
                                    child: StreamBuilder<int?>(
                                      stream: getPastWeekWordTrackers(childID),
                                      builder: (BuildContext context,
                                          AsyncSnapshot<int?> snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return Center(
                                            child: Text(
                                              localizationService
                                                  .translate("loading"),
                                              style: const TextStyle(
                                                color: Color(0xFF9E1B32),
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          );
                                        } else if (snapshot.hasData) {
                                          int? count = snapshot.data;
                                          return Center(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  localizationService.translate(
                                                      "words_in_past_week"),
                                                  style: const TextStyle(
                                                    color: Color(0xFF9E1B32),
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                FittedBox(
                                                  fit: BoxFit.contain,
                                                  child: Text(
                                                    "$count",
                                                    style: const TextStyle(
                                                      color: Color(0xFF9E1B32),
                                                      fontSize: 40,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        } else {
                                          return Center(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  localizationService.translate(
                                                      "words_in_past_week"),
                                                  style: const TextStyle(
                                                    color: Color(0xFF9E1B32),
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const Text(
                                                  "N/A",
                                                  style: TextStyle(
                                                    color: Color(0xFF9E1B32),
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ]),
                      ),
                      Center(
                        child: Text(localizationService.translate("child_said"),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.bold)),
                      ),
                      TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: localizationService.translate("enter_text"),
                          hintStyle: const TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: const Color(0xFF9E1B32),
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Center(
                        child: TextField(
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
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Center(
                          child: OutlinedButton(
                        onPressed: () async {
                          final childDataService =
                              context.read<ChildDataService>();
                          final wordDataService =
                              context.read<WordDataService>();
                          final wordTrackerDataService =
                              context.read<WordTrackerDataService>();
                          Child? currChild = context
                              .read<CurrentChildrenService>()
                              .getCurrChild();
                          String? currChildID;
                          if (currChild != null) {
                            currChildID = currChild.id;
                          }

                          _parseWords();

                          var correctWords = 0;
                          var totalWords = 0;

                          for (var word in parsedWords) {
                            totalWords++;
                            bool? result = await checkAndUpdateWords(word);
                            if (result != null &&
                                result &&
                                currChildID != null) {
                              late String? filePath;
                              if (fileTextController.text != "") {
                                filePath =
                                    path.basename(fileTextController.text);
                                uploadVideo(fileTextController.text);
                              } else {
                                filePath = null;
                              }
                              addWordToChild(word, childDataService,
                                  wordDataService, wordTrackerDataService,
                                  id: currChildID, videoId: filePath);
                              correctWords++;
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
                                          fileTextController.clear();
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
                  ),
                );
              },
            ),
          ),
        ]),
      );
    });
  }
}

Future<void> addWordToChild(String word, ChildDataService childService,
    WordDataService wordService, WordTrackerDataService trackerService,
    {String id = "gz1Qe32xJcF0oRGmhw7f", String? videoId}) async {
  final object = await trackerService.getWordTracker(id, word);
  if (object == null) {
    if (await trackerService.createWordTracker(
            id, word, DateTime.now(), videoId) ==
        null) {
      debugPrint("AddText: Error adding word to child");
    } else {
      debugPrint("AddText: Word added to child");
    }
  } else {
    if (videoId != null) {
      trackerService.setWordTracker(id, word, filePath: videoId);
      debugPrint("UpdateText: word already existed, updating file");
    }
  }
}

Future<void> addVideoToWord(
    String word, String filePath, ChildDataService childService,
    {String id = "gz1Qe32xJcF0oRGmhw7f"}) async {
  if (await childService.addVideo(id, word, path.basename(filePath)) == false) {
    debugPrint("AddVideo: Error adding video to work tracker");
  } else {
    debugPrint("AddVideo: $filePath added to $word");
  }
}

Stream<String?> getRecentWordTracker(String childId) {
  return FirebaseFirestore.instance
      .collection('Child')
      .doc(childId)
      .collection('WordTracker')
      .orderBy('firstUtterance', descending: true)
      .limit(1)
      .snapshots()
      .map((snapshot) => snapshot.docs.isNotEmpty
          ? snapshot.docs.first.id
          : null);
}

Stream<int?> getPastWeekWordTrackers(String childId) {
  final lastWeek = DateTime.now().subtract(const Duration(days: 7));

  return FirebaseFirestore.instance
      .collection('Child')
      .doc(childId)
      .collection('WordTracker')
      .orderBy('firstUtterance', descending: true)
      .where('firstUtterance', isGreaterThanOrEqualTo: lastWeek)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
}

Stream<int?> getNumWords(String childId){
  return FirebaseFirestore.instance
    .collection('Child')
    .doc(childId)
    .snapshots()
    .map((snapshot) => snapshot.data()?['wordCount'] as int);
}