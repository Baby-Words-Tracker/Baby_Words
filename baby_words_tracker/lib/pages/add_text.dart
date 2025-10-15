import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:baby_words_tracker/data/services/word_data_service.dart';
import 'package:baby_words_tracker/data/services/word_tracker_data_service.dart';
import 'package:baby_words_tracker/pages/shared/bottom_bar.dart';
import 'package:baby_words_tracker/pages/shared/top_bar.dart';
import 'package:baby_words_tracker/util/check_and_update_word.dart';
import 'package:baby_words_tracker/util/current_children_service.dart';
import 'package:baby_words_tracker/util/ui_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// baby words packages
import 'package:baby_words_tracker/video/video_picker.dart';
import 'package:baby_words_tracker/video/video_storage_service.dart';

import 'package:baby_words_tracker/l10n/localization_service.dart';

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
  VideoSelectionResult? _selectedVideo;

  late final WordDataService _wordDataService;
  late final WordTrackerDataService _wordTrackerDataService;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();

    if (!_initialized) {
      _wordDataService = Provider.of<WordDataService>(context, listen: false);
      _wordTrackerDataService =
          Provider.of<WordTrackerDataService>(context, listen: false);
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

  Future<void> _handleVideoSelection(
    BuildContext context,
    LocalizationService localizationService,
    VideoStorageService videoStorage,
  ) async {
    try {
      final result = await pickLocalVideo();
      if (result == null) {
        return;
      }
      setState(() {
        _selectedVideo = result;
        fileTextController.text = result.displayName;
      });
    } on VideoSelectionException catch (error) {
      await showAlertMessage(
        context,
        localizationService.translate("file_not_added"),
        error.message,
      );
    } catch (error) {
      await showAlertMessage(
        context,
        localizationService.translate("file_not_added"),
        "Something went wrong while selecting the video. Please try again.",
      );
    }
  }

  void _clearVideoSelection() {
    setState(() {
      _selectedVideo = null;
      fileTextController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    return Consumer<LocalizationService>(
        builder: (context, localizationService, child) {
      final videoStorage = context.watch<VideoStorageService>();
      return Scaffold(
        backgroundColor: const Color(0xFF828A8F),
        appBar: TopBar(pageName: localizationService.translate("add_words")),
        bottomNavigationBar: const CustomBottomBar(AddTextPage.routeName),
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
                  if (!kIsWeb && videoStorage.isFeatureEnabled)
                    TextField(
                      controller: fileTextController,
                      readOnly: true,
                      onTap: () => _handleVideoSelection(
                        context,
                        localizationService,
                        videoStorage,
                      ),
                      decoration: InputDecoration(
                        hintText: localizationService.translate("choose_file"),
                        hintStyle: const TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: const Color(0xFF9E1B32),
                        suffixIcon: _selectedVideo != null
                            ? IconButton(
                                icon:
                                    const Icon(Icons.close, color: Colors.white),
                                onPressed: _clearVideoSelection,
                              )
                            : null,
                      ),
                    ),
                  Center(
                      child: OutlinedButton(
                    onPressed: () async {
                      final currentChildrenService =
                          context.read<CurrentChildrenService>();
                      final videoStorage =
                          context.read<VideoStorageService>();

                      final currChild = currentChildrenService.getCurrChild();
                      final currChildID = currChild?.id;

                      _parseWords();

                      var correctWords = 0;
                      var totalWords = 0;
                      var videoAttached = false;
                      final pendingVideo = _selectedVideo;

                      if (pendingVideo != null && !videoStorage.isReady) {
                        await showAlertMessage(
                          context,
                          localizationService.translate("file_not_added"),
                          "We couldn't store the video yet. Please try again once your profile finishes loading.",
                        );
                      }

                      for (final word in parsedWords) {
                        totalWords++;
                        final result = await checkAndUpdateWord(
                          word,
                          _wordDataService,
                          targetLanguage:
                              localizationService.localization.languageCode,
                        );

                        if (result != null && result && currChildID != null) {
                          final added = await addWordToChild(
                            currChildID,
                            word,
                            _wordTrackerDataService,
                          );

                          if (added) {
                            correctWords++;
                            if (!videoAttached &&
                                pendingVideo != null &&
                                videoStorage.isReady) {
                              try {
                                await videoStorage.saveVideoForWord(
                                  childId: currChildID,
                                  wordId: word,
                                  sourceFile: pendingVideo.file,
                                );
                                videoAttached = true;
                              } catch (error) {
                                await showAlertMessage(
                                  context,
                                  localizationService.translate("file_not_added"),
                                  "The word was saved, but we couldn't store the video locally. Please try again.",
                                );
                              }
                            }
                          }
                        } else {
                          if (!context.mounted) return;
                          await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text(
                                    localizationService.translate("error")),
                                content: Text(
                                  '$word${localizationService.translate("words_error")}',
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text('OK'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
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
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                        _controller.clear();
                        _clearVideoSelection();
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
    WordTrackerDataService trackerService,
  ) async {
    return trackerService.addOrUpdateWordTracker(
      childId,
      word,
      WordTracker(
        id: word,
        firstUtterance: DateTime.now(),
      ),
    );
  }

}
