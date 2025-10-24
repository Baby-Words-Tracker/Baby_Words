import 'dart:async';

import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:baby_words_tracker/data/services/word_data_service.dart';
import 'package:baby_words_tracker/data/services/word_tracker_data_service.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:baby_words_tracker/pages/shared/bottom_bar.dart';
import 'package:baby_words_tracker/pages/shared/top_bar.dart';
import 'package:baby_words_tracker/util/current_children_service.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/string_utils.dart';
import 'package:baby_words_tracker/util/text_entry_utils.dart';
import 'package:baby_words_tracker/util/ui_utils.dart';
import 'package:baby_words_tracker/video/video_picker.dart';
import 'package:baby_words_tracker/video/video_storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  VideoSelectionResult? _selectedVideo;

  late final WordDataService _wordDataService;
  late final WordTrackerDataService _wordTrackerDataService;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _wordDataService = Provider.of<WordDataService>(context, listen: false);
      _wordTrackerDataService =
          Provider.of<WordTrackerDataService>(context, listen: false);
      _initialized = true;
      debugPrint("HomePage: Initialized ChildDataService and WordDataService");
    }
  }

  List<String> _parseCurrentWords() => extractWords(_controller.text);

  Future<void> _handleVideoSelection(
    BuildContext context,
    LocalizationService localizationService,
    VideoStorageService videoStorage,
  ) async {
    if (!videoStorage.isFeatureEnabled) {
      if (!context.mounted) return;
      await showAlertIfMounted(
        context,
        localizationService.translate("file_not_added"),
        "Video attachments are not available right now.",
      );
      return;
    }

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
      if (!context.mounted) return;
      await showAlertIfMounted(
        context,
        localizationService.translate("file_not_added"),
        error.message,
      );
    } catch (_) {
      if (!context.mounted) return;
      await showAlertIfMounted(
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

  
Future<void> _addCurrentWords(
  CurrentChildrenService currentChildrenService,
  LocalizationService localizationService,
) async {
  final child = currentChildrenService.getCurrChild();
  final childId = child?.id;

  if (childId == null) {
    if (!mounted) return;
    await showAlertIfMounted(
      context,
      localizationService.translate('error'),
      localizationService.translate('go_to_settings'),
    );
    return;
  }

  final words = _parseCurrentWords();
  if (words.isEmpty) {
    return;
  }

  final language = (child?.language.isNotEmpty == true)
      ? child!.language.first
      : localizationService.localization.languageCode;

  final videoStorage = context.read<VideoStorageService>();
  final pendingVideo = _selectedVideo;
  bool videoAttached = false;
  String? videoKey;

  if (pendingVideo != null && !videoStorage.isReady) {
    if (!mounted) return;
    await showAlertIfMounted(
      context,
      localizationService.translate('file_not_added'),
      localizationService.translate('video_not_ready_message'),
    );
  }

  final now = DateTime.now();
  int queuedCount = 0;

  for (final word in words) {
    final queued = await _wordDataService.queueWordForProcessing(
      wordId: word,
      language: language,
    );
    if (queued) {
      queuedCount++;
    }

    if (!videoAttached &&
        pendingVideo != null &&
        videoStorage.isReady) {
      try {
        final savedVideo = await videoStorage.saveVideoForWord(
          childId: childId,
          wordId: word,
          sourceFile: pendingVideo.file,
        );
        videoKey = savedVideo?.key;
        videoAttached = true;
      } catch (_) {
        if (!mounted) return;
        await showAlertIfMounted(
          context,
          localizationService.translate('file_not_added'),
          localizationService.translate('video_not_ready_message'),
        );
      }
    }

    await _wordTrackerDataService.addOrUpdateWordTracker(
      childId,
      word,
      WordTracker(
        id: word,
        firstUtterance: now,
        language: language,
        videoId: videoKey,
      ),
    );
  }

  if (!mounted) return;
  setState(() {
    _controller.clear();
  });
  _clearVideoSelection();

  final message = queuedCount > 0
      ? localizationService
          .translate('words_processing_summary')
          .replaceFirst('{count}', queuedCount.toString())
      : localizationService.translate('words_already_processed');

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocalizationService, CurrentChildrenService>(
      builder: (context, localizationService, currentChildrenService, child) {
        Child? currChild = currentChildrenService.getCurrChild();
        String childID = currChild?.id ?? "error";

        final theme = Theme.of(context);
        final videoStorage = context.watch<VideoStorageService>();

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
                                style: theme.textTheme.headlineMedium?.copyWith(
                                        color: theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.bold) ??
                                    TextStyle(
                                        color: theme.colorScheme.onSurface,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold),
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
                                                    ?.copyWith(
                                                        color: theme.colorScheme
                                                            .onSurface,
                                                        fontWeight:
                                                            FontWeight.w600) ??
                                                TextStyle(
                                                    color: theme
                                                        .colorScheme.onSurface,
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.w600),
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
                                                style: theme.textTheme
                                                        .headlineMedium
                                                        ?.copyWith(
                                                            color: theme
                                                                .colorScheme
                                                                .primary,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w700) ??
                                                    TextStyle(
                                                        color: theme.colorScheme
                                                            .primary,
                                                        fontSize: 34,
                                                        fontWeight:
                                                            FontWeight.w700),
                                              ),
                                            ),
                                          if (snapshot.connectionState !=
                                                  ConnectionState.waiting &&
                                              !snapshot.hasData)
                                            Text(
                                              "N/A",
                                              style: theme.textTheme.titleLarge
                                                      ?.copyWith(
                                                          color: theme
                                                              .colorScheme
                                                              .primary,
                                                          fontWeight: FontWeight
                                                              .w700) ??
                                                  TextStyle(
                                                      color: theme
                                                          .colorScheme.primary,
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.w700),
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
                                                    ?.copyWith(
                                                        color: theme.colorScheme
                                                            .onSurface,
                                                        fontWeight:
                                                            FontWeight.w600) ??
                                                TextStyle(
                                                    color: theme
                                                        .colorScheme.onSurface,
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.w600),
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
                                                style: theme.textTheme
                                                        .headlineMedium
                                                        ?.copyWith(
                                                            color: theme
                                                                .colorScheme
                                                                .primary,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w700) ??
                                                    TextStyle(
                                                        color: theme.colorScheme
                                                            .primary,
                                                        fontSize: 34,
                                                        fontWeight:
                                                            FontWeight.w700),
                                              ),
                                            ),
                                          if (snapshot.connectionState !=
                                                  ConnectionState.waiting &&
                                              !snapshot.hasData)
                                            Text(
                                              "N/A",
                                              style: theme.textTheme.titleLarge
                                                      ?.copyWith(
                                                          color: theme
                                                              .colorScheme
                                                              .primary,
                                                          fontWeight: FontWeight
                                                              .w700) ??
                                                  TextStyle(
                                                      color: theme
                                                          .colorScheme.primary,
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.w700),
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
                        style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold) ??
                            TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold),
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
                    if (!kIsWeb && videoStorage.isFeatureEnabled)
                      Center(
                        child: TextField(
                          controller: fileTextController,
                          readOnly: true,
                          onTap: () => _handleVideoSelection(
                            context,
                            localizationService,
                            videoStorage,
                          ),
                          decoration: InputDecoration(
                            labelText:
                                localizationService.translate("choose_file"),
                            suffixIcon: _selectedVideo != null
                                ? IconButton(
                                    icon: Icon(
                                      Icons.close,
                                      color: theme.colorScheme.primary,
                                    ),
                                    onPressed: _clearVideoSelection,
                                  )
                                : Icon(
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
                        child: Text(localizationService.translate("submit")),
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
}