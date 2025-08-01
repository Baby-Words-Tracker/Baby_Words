import 'dart:async';

import 'package:baby_words_tracker/auth/authentication_service.dart';
import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/models/word.dart';
import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:baby_words_tracker/data/type_aware_services/type_aware_child_data_service.dart';
import 'package:baby_words_tracker/data/type_aware_services/type_aware_word_data_service.dart';
import 'package:baby_words_tracker/data/type_aware_services/type_aware_word_tracker_data_service.dart';
import 'package:baby_words_tracker/exceptions/document_creation_failed_exception.dart';
import 'package:baby_words_tracker/exceptions/document_update_failed_exception.dart';
import 'package:baby_words_tracker/exceptions/network_failure_exception.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:baby_words_tracker/pages/shared/bottom_bar.dart';
import 'package:baby_words_tracker/pages/shared/top_bar.dart';
import 'package:baby_words_tracker/util/check_and_update_word.dart';
import 'package:baby_words_tracker/util/current_children_service.dart';
import 'package:baby_words_tracker/util/part_of_speech.dart';
import 'package:baby_words_tracker/util/string_utils.dart';
import 'package:baby_words_tracker/util/ui_utils.dart';
import 'package:baby_words_tracker/video/video_functions.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/foundation.dart';
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

  late final TypeAwareWordDataService _wordDataService;
  late final TypeAwareWordTrackerDataService _wordTrackerDataService;
  late final AuthenticationService _authenticationService;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _wordDataService =
          Provider.of<TypeAwareWordDataService>(context, listen: false);
      _wordTrackerDataService =
          Provider.of<TypeAwareWordTrackerDataService>(context, listen: false);
      _authenticationService =
          Provider.of<AuthenticationService>(context, listen: false);
      _initialized = true;
      debugPrint(
          "HomePage: Initialized WordDataService and WordTrackerDataService");
    }
  }

  List<String> _parseCurrentWords() {
    String text = _controller.text;
    String cleanedText = text
        .trim() // Remove leading and trailing whitespace
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
        .toLowerCase();
    return cleanedText.split(' ').where((word) => word.isNotEmpty).toList();
  }

  Future<void> _addCurrentWords(
    CurrentChildrenService currentChildrenService,
    LocalizationService localizationService,
  ) async {
    Child? currChild = currentChildrenService.getCurrChild();
    String? currChildID;
    if (currChild != null) {
      currChildID = currChild.id;
    }

    List<String> parsedWords = _parseCurrentWords();

    if (parsedWords.isEmpty ||
        (parsedWords.length == 1 && parsedWords.first == '')) {
      debugPrint("No input in parsed words. Skipping _addCurrentWords.");
      return;
    } else {
      debugPrint("List has contnet. Proceeding in _addCurrentWords.");
    }

    var correctWords = 0;
    var totalWords = 0;
    bool videoUploaded = false;
    String? filePath;
    bool networkFailure = false;

    for (var word in parsedWords) {
      totalWords++;
      bool result = false;

      try {
        result = await checkAndUpdateWord(
          word,
          _wordDataService,
          targetLanguage: localizationService.localization
              .languageCode, // TODO: need to give users the ability to select the target language if they are multilingual
        );
      } on NetworkFailureException catch (e) {
        debugPrint(
            "HomePage: Network failure while checking and updating word: $word with error message $e");
        networkFailure = true;
      } on DocumentCreationFailedException {
        debugPrint(
            "HomePage: Document creation failed while checking and updating word: $word");
        if (mounted) {
          // TODO: translate this message
          showAlertMessage(context, "Failed to Add Word",
              "The word '$word' could not be added due to a database issue. Please try again later.");
        }
        // TODO: add dialog to alert user + tell them
        // TODO: later, add the word in local storage and then try to add it again when the network is available
        continue; // Skip to the next word if creation failed
      } on DocumentUpdateFailedException catch (e) {
        debugPrint(
            "HomePage: Document update failed while checking and updating word: $word with error message $e");
        await _wordDataService.updateWord(
          word,
          Word.createUpdateMap(needsProcessing: true),
        );
        result =
            true; // The word exists, but it's data needs to be updated. It is marked for update but the next steps can proceed.
      } catch (e) {
        debugPrint(
            "HomePage: Error checking and updating word: $word. Error: $e");
        continue; // Skip to the next word if there's an error
      }

      if (!result) {
        if (mounted) {
          // TODO: handle network failure by asking if custom word should be added and updated later

          // TODO: translate this message and title
          String message = networkFailure
              ? "We couldn't find your word in the dictionary due to a network issue. Would you like to add the word '$word' as a custom word for now and try again later?"
              : "We couldn't find your word in the dictionary. Would you like to add the word '$word' as a custom word?";
          final createCustom = await showConfirmationDialog(context, message,
              title: "Word Not Found");

          // TODO: need to allow language selection for custom words
          if (createCustom) {
            debugPrint("HomePage: User chose to create custom word for: $word");
            final newWord = await _wordDataService
                .createWord(
                  Word(
                    word: word,
                    languageCodes: {
                      localizationService.localization.languageCode
                    },
                    partOfSpeech: {
                      localizationService.localization.languageCode:
                          PartOfSpeech.unknown
                    },
                    needsProcessing:
                        networkFailure, // mark as custom or mark for updates later
                  ),
                )
                .timeout(Duration(seconds: 3))
                .catchError((e) {
              debugPrint(
                  "HomePage: Timeout while creating custom word: $word. Error: $e");
              return null; // Return null if the creation fails
            });

            debugPrint("HomePage: Attempting to create custom word: $word");

            if (newWord == null) {
              debugPrint("HomePage: Failed to create custom word: $word");
              if (mounted) {
                // TODO: translate this message
                showAlertMessage(
                  context,
                  "Failed to Add Word",
                  "The word '$word' could not be added due to a database issue. Please try again later.",
                );
              }
              continue; // Skip to the next word if creation failed
            } else {
              debugPrint("HomePage: Custom word created successfully: $word");
              result = true; // Custom word created successfully
            }
          } else {
            debugPrint(
                "HomePage: User chose not to create custom word for: $word");
            // If the user doesn't want to create a custom word, skip to the next word
            continue;
          }
        } else {
          debugPrint(
              "HomePage: Error: context is not mounted. Skipping word: $word");
          continue;
        }
      }

      if (result == true && currChildID != null) {
        if (!videoUploaded && fileTextController.text != "") {
          filePath = path.basename(fileTextController.text);
          videoUploaded = await uploadVideo(fileTextController
              .text); // Might need to add a loading indicator here
        }

        bool success = await addWordToChild(
          currChildID,
          word,
          _wordTrackerDataService,
          videoId: filePath,
        );

        if (!success) {
          debugPrint("HomePage: Failed to add word tracker for $word");
          continue; // Skip to the next word if adding failed
        }

        correctWords++;
      } else {
        if (!mounted) {
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
              title: Text(localizationService.translate("error")),
              content:
                  Text(word + localizationService.translate("words_error")),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
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

    if (!mounted) {
      debugPrint(
          "HomePage: context is not mounted. Successfully added $correctWords words.");
      return;
    } else if (totalWords == correctWords) {
      // await showDialog(
      //   context: context,
      //   builder: (BuildContext context) {
      //     return AlertDialog(
      //       title: Text(
      //           localizationService.translate("success")),
      //       content: Text(
      //           '$correctWords ${localizationService.translate("word_success").toLowerCase()}'),
      //       actions: <Widget>[
      //         TextButton(
      //           child: const Text('OK'),
      //           onPressed: () {
      //             Navigator.of(context)
      //                 .pop(); // Close the dialog
      //           },
      //         ),
      //       ],
      //     );
      //   },
      // );
      debugPrint("HomePage: Successfully added all $correctWords words.");
      _controller.clear();
    } else {
      debugPrint(
          "HomePage: Successfully added $correctWords out of $totalWords words.");
      if (mounted) {
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Partial Success"), // TODO: translate
              content: Text(
                  '$correctWords/$totalWords ${localizationService.translate("word_success").toLowerCase()}'),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'), // TODO: Translate
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                    _controller.clear();
                    fileTextController.clear();
                  },
                ),
              ],
            );
          },
        );
      }
    }
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
                      stream: getNumWords(
                        childID,
                        _authenticationService,
                      ),
                      builder:
                          (BuildContext context, AsyncSnapshot<int?> snapshot) {
                        String message;
                        int? numWords;

                        if (snapshot.hasData) {
                          numWords = snapshot.data;
                        }

                        if (currentChildrenService.getCurrChild() == null) {
                          message = "Please add a child in settings.";
                        } else {
                          message =
                              "${currChild?.name} ${localizationService.translate("knows")} ${numWords ?? "Loading"} ${localizationService.translate("words")}!";
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 25.0),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                message,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
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
                                  stream: getRecentWordTracker(
                                    childID,
                                    _authenticationService,
                                  ),
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
                                            // TODO: translate this
                                            "Last learned word is:",
                                            // localizationService
                                            //     .translate("most_recent"),
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
                                  stream: getPastWeekWordTrackers(
                                    childID,
                                    _authenticationService,
                                  ),
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
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.black),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.black,
                            width: 1.5,
                          ),
                        ),
                        // hoverColor: Colors.white,
                      ),
                      onSubmitted: (_) => _addCurrentWords(
                        currentChildrenService,
                        localizationService,
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    if (!kIsWeb)
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
                      onPressed: () => _addCurrentWords(
                        currentChildrenService,
                        localizationService,
                      ),
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
    ),
  );
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

// TODO: change this to use a data service instead of collection names directly?
//  (could be overly complex for these specific cases)
Stream<String?> getRecentWordTracker(
  String childId,
  AuthenticationService authenticationService,
) {
  return FirebaseFirestore.instance
      .collection(
        Child.collectionName
            .demoAwareCollectionName(authenticationService.isDemoUser),
      )
      .doc(childId)
      .collection(
        WordTracker.collectionName
            .demoAwareCollectionName(authenticationService.isDemoUser),
      )
      .orderBy('firstUtterance', descending: true)
      .limit(1)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.isNotEmpty ? snapshot.docs.first.id : null);
}

Stream<int?> getPastWeekWordTrackers(
  String childId,
  AuthenticationService authenticationService,
) {
  final lastWeek = DateTime.now().subtract(const Duration(days: 7));

  return FirebaseFirestore.instance
      .collection(
        Child.collectionName
            .demoAwareCollectionName(authenticationService.isDemoUser),
      )
      .doc(childId)
      .collection(
        WordTracker.collectionName
            .demoAwareCollectionName(authenticationService.isDemoUser),
      )
      .orderBy('firstUtterance', descending: true)
      .where('firstUtterance', isGreaterThanOrEqualTo: lastWeek)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
}

Stream<int?> getNumWords(
  String childId,
  AuthenticationService authenticationService,
) {
  return FirebaseFirestore.instance
      .collection(
        Child.collectionName
            .demoAwareCollectionName(authenticationService.isDemoUser),
      )
      .doc(childId)
      .snapshots()
      .map((snapshot) => snapshot.data()?['wordCount'] as int);
}
