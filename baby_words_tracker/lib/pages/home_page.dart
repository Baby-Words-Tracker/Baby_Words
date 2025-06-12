import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/services/child_data_service.dart';
import 'package:baby_words_tracker/data/services/word_data_service.dart';
import 'package:baby_words_tracker/data/services/word_tracker_data_service.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:baby_words_tracker/pages/shared/bottom_bar.dart';
import 'package:baby_words_tracker/pages/shared/top_bar.dart';
import 'package:baby_words_tracker/util/check_and_update_word.dart';
import 'package:baby_words_tracker/util/current_children_service.dart';
import 'package:baby_words_tracker/util/string_utils.dart';
import 'package:baby_words_tracker/video/video_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  static const routeName = '/';
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController fileTextController = TextEditingController();
  List<String> parsedWords = [];

  late final ChildDataService _childDataService;
  late final WordDataService _wordDataService;
  late final WordTrackerDataService _wordTrackerDataService;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _childDataService = Provider.of<ChildDataService>(context, listen: false);
      _wordDataService = Provider.of<WordDataService>(context, listen: false);
      _wordTrackerDataService =
          Provider.of<WordTrackerDataService>(context, listen: false);
      _initialized = true;
      debugPrint("HomePage: Initialized ChildDataService and WordDataService");
    }
  }

  void _parseWords() {
    String text = _controller.text;
    String cleanedText = text
        .trim() // Remove leading and trailing whitespace
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
        .toLowerCase();
    setState(() {
      parsedWords = cleanedText.split(' ');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocalizationService, CurrentChildrenService>(
      builder: (context, localizationService, currentChildrenService, child) {
        Child? currChild = currentChildrenService.getCurrChild();
        String childID = currChild?.id ?? "error";

        return Scaffold(
          backgroundColor: const Color(0xFF828A8F),
          appBar: TopBar(pageName: localizationService.translate("word_buds")),
          bottomNavigationBar: CustomBottomBar(HomePage.routeName),
          body: Stack(children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // number of words known by child line
                    StreamBuilder<int?>(
                      stream: getNumWords(childID),
                      builder:
                          (BuildContext context, AsyncSnapshot<int?> snapshot) {
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
                    // stat cards
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 50.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // most recent word card
                          Card(
                            // most recent word
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
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting)
                                            const CircularProgressIndicator(),
                                          if (snapshot.connectionState !=
                                                  ConnectionState.waiting &&
                                              snapshot.hasData)
                                            FittedBox(
                                              fit: BoxFit.contain,
                                              child: Text(
                                                word.capitalizeOrNA(),
                                                style: const TextStyle(
                                                  color: Color(0xFF9E1B32),
                                                  fontSize: 40,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          if (snapshot.connectionState !=
                                                  ConnectionState.waiting &&
                                              !snapshot.hasData)
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
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          // words learned in past week card
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
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting)
                                            const CircularProgressIndicator(),
                                          if (snapshot.connectionState !=
                                                  ConnectionState.waiting &&
                                              snapshot.hasData)
                                            FittedBox(
                                              fit: BoxFit.contain,
                                              child: Text(
                                                "${snapshot.data ?? 0}",
                                                style: const TextStyle(
                                                  color: Color(0xFF9E1B32),
                                                  fontSize: 40,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          if (snapshot.connectionState !=
                                                  ConnectionState.waiting &&
                                              !snapshot.hasData)
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
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
                          hintText:
                              localizationService.translate("choose_file"),
                          hintStyle: const TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: const Color(0xFF9E1B32),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Center(
                        child: OutlinedButton(
                      onPressed: () async {
                        Child? currChild =
                            currentChildrenService.getCurrChild();
                        String? currChildID;
                        if (currChild != null) {
                          currChildID = currChild.id;
                        }

                        _parseWords();

                        var correctWords = 0;
                        var totalWords = 0;
                        bool videoUploaded = false;
                        String? filePath;

                        for (var word in parsedWords) {
                          totalWords++;
                          //languages != null ? await checkAndUpdateWord(word, languages: languages) : await checkAndUpdateWord(word); //languages != null ? await checkAndUpdateWord(word, languages: languages) : await checkAndUpdateWord(word); //only checks the childs selected languages
                          bool? result = await checkAndUpdateWord(
                            word,
                            _wordDataService,
                            targetLanguage:
                                localizationService.localization.languageCode,
                          );
                          if (result == true && currChildID != null) {
                            if (!videoUploaded) {
                              if (fileTextController.text != "") {
                                filePath =
                                    path.basename(fileTextController.text);
                                uploadVideo(fileTextController.text);
                              } else {
                                filePath = null;
                              }
                              videoUploaded = filePath != null &&
                                  filePath.isNotEmpty &&
                                  filePath.endsWith(
                                      '.mp4'); // FIXME: make this an actual check by updating the method
                            }

                            addWordToChild(word, _childDataService,
                                _wordDataService, _wordTrackerDataService,
                                id: currChildID, videoId: filePath);

                            correctWords++;
                          } else {
                            if (!context.mounted) {
                              debugPrint(
                                  "HomePage: context is not mounted. Error: $word was not found in dictionary.");
                              return;
                            }
                            //TODO: make this experience a lot better.
                            // This is confusing/frustrating at the moment because there is nothing users can do to fix the problem.
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
                        if (!context.mounted) {
                          debugPrint(
                              "HomePage: context is not mounted. Successfully added $correctWords words.");
                          return;
                        }
                        if (totalWords == correctWords) {
                          await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text(
                                    localizationService.translate("success")),
                                content: Text(
                                    '$correctWords ${localizationService.translate("word_success").toLowerCase()}'),
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
              ),
            ),
          ]),
        );
      },
    );
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
      .map((snapshot) =>
          snapshot.docs.isNotEmpty ? snapshot.docs.first.id : null);
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

Stream<int?> getNumWords(String childId) {
  return FirebaseFirestore.instance
      .collection('Child')
      .doc(childId)
      .snapshots()
      .map((snapshot) => snapshot.data()?['wordCount'] as int);
}
