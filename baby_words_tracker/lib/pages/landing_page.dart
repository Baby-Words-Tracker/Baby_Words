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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
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
                      FutureBuilder<Child?>(
                        future:
                            context.read<ChildDataService>().getChild(childID),
                        builder: (BuildContext context,
                            AsyncSnapshot<Child?> snapshot) {
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
                            Child? child = snapshot.data;
                            return Padding(
                              padding: const EdgeInsets.only(top: 25.0),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "${child?.name} ${localizationService.translate("knows")} ${child?.wordCount} ${localizationService.translate("words")}!",
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
                            return const Center(
                              child: Text(
                                "N/A",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 50,
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
                                    child: FutureBuilder<String?>(
                                      future: getRecentWordTracker(childID),
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
                                                Text(
                                                  "$word",
                                                  style: const TextStyle(
                                                    color: Color(0xFF9E1B32),
                                                    fontSize: 40,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        } else {
                                          return const Center(
                                            child: Text(
                                              "N/A",
                                              style: TextStyle(
                                                color: Color(0xFF9E1B32),
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
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
                                    child: FutureBuilder<int?>(
                                      future: getPastWeekWordTrackers(childID),
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
                                                Text(
                                                  "$count",
                                                  style: const TextStyle(
                                                    color: Color(0xFF9E1B32),
                                                    fontSize: 40,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        } else {
                                          return const Center(
                                            child: Text(
                                              "No data available",
                                              style: TextStyle(
                                                color: Color(0xFF9E1B32),
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
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
                            bool? result = await checkAndUpdateWords(
                                word);
                            if (result != null &&
                                result &&
                                currChildID != null) {
                              addWordToChild(word, childDataService,
                                  wordDataService, wordTrackerDataService,
                                  id: currChildID);
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

  Future<void> addWordToChild(String word, ChildDataService childService,
      WordDataService wordService, WordTrackerDataService trackerService,
      {String id = "gz1Qe32xJcF0oRGmhw7f"}) async {
    if (await trackerService.createWordTracker(id, word, DateTime.now()) ==
        null) {
      debugPrint("AddText: Error adding word to child");
    } else {
      debugPrint("AddText: Word added to child");
    }
  }
}

Future<String?> getRecentWordTracker(String childId) async {
  QuerySnapshot word = await FirebaseFirestore.instance
      .collection('Child')
      .doc(childId)
      .collection('WordTracker')
      .orderBy('firstUtterance', descending: true)
      .limit(1)
      .get();

  String? wordName = 'N/A';
  for (var wordDoc in word.docs) {
    wordName = wordDoc.id;
  }
  return wordName;
}

Future<int?> getPastWeekWordTrackers(String childId) async {
  DateTime lastWeek = DateTime.now().subtract(const Duration(days: 7));

  QuerySnapshot words = await FirebaseFirestore.instance
      .collection('Child')
      .doc(childId)
      .collection('WordTracker')
      .orderBy('firstUtterance', descending: true)
      .where('firstUtterance', isGreaterThanOrEqualTo: lastWeek)
      .get();

  return words.docs.length;
}
