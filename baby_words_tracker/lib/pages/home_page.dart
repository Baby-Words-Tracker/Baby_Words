import 'dart:async';

import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/models/word.dart';
import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:baby_words_tracker/data/services/child_data_service.dart';
import 'package:baby_words_tracker/data/services/word_data_service.dart';
import 'package:baby_words_tracker/data/services/word_tracker_data_service.dart';
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

        final theme = Theme.of(context);

        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: TopBar(pageName: localizationService.translate("word_buds")),
          bottomNavigationBar: const CustomBottomBar(HomePage.routeName),
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
                                style: theme.textTheme.headlineMedium
                                        ?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold) ??
                                    TextStyle(color: theme.colorScheme.onSurface, fontSize: 32, fontWeight: FontWeight.bold),
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
                            color: theme.colorScheme.surfaceContainerHighest,
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
                                            // TODO: translate this
                                            "Last learned word is:",
                                            textAlign: TextAlign.center,
                                            style: theme.textTheme.titleMedium
                                                    ?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600) ??
                                                TextStyle(color: theme.colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w600),
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
                                                style: theme.textTheme.headlineMedium
                                                        ?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700) ??
                                                    TextStyle(color: theme.colorScheme.primary, fontSize: 34, fontWeight: FontWeight.w700),
                                              ),
                                            ),
                                          if (snapshot.connectionState !=
                                                  ConnectionState.waiting &&
                                              !snapshot.hasData)
                                            Text(
                                              "N/A",
                                              style: theme.textTheme.titleLarge
                                                      ?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700) ??
                                                  TextStyle(color: theme.colorScheme.primary, fontSize: 20, fontWeight: FontWeight.w700),
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
                            color: theme.colorScheme.surfaceContainerHighest,
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
                                            textAlign: TextAlign.center,
                                            style: theme.textTheme.titleMedium
                                                    ?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600) ??
                                                TextStyle(color: theme.colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w600),
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
                                                style: theme.textTheme.headlineMedium
                                                        ?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700) ??
                                                    TextStyle(color: theme.colorScheme.primary, fontSize: 34, fontWeight: FontWeight.w700),
                                              ),
                                            ),
                                          if (snapshot.connectionState !=
                                                  ConnectionState.waiting &&
                                              !snapshot.hasData)
                                            Text(
                                              "N/A",
                                              style: theme.textTheme.titleLarge
                                                      ?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700) ??
                                                  TextStyle(color: theme.colorScheme.primary, fontSize: 20, fontWeight: FontWeight.w700),
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
                      child: Text(
                        localizationService.translate("child_said"),
                        style: theme.textTheme.titleLarge
                                ?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold) ??
                            TextStyle(color: theme.colorScheme.primary, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextField(
                      controller: _controller,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: localizationService.translate("child_said"),
                        hintText: localizationService.translate("enter_text"),
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
                          readOnly: true,
                          onTap: () => selectFile(fileTextController),
                          decoration: InputDecoration(
                            labelText:
                                localizationService.translate("choose_file"),
                            suffixIcon: Icon(
                              Icons.attach_file,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(
                      height: 5,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => _addCurrentWords(
                          currentChildrenService,
                          localizationService,
                        ),
                        child: Text(
                            localizationService.translate("submit")),
                      ),
                    ),
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
  WordTrackerDataService trackerService, {
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
  ChildDataService childService,
) async {
  if (await childService.addVideo(childId, word, path.basename(filePath)) ==
      false) {
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
