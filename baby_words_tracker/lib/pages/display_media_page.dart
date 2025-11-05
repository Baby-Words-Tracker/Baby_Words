import 'package:baby_words_tracker/data/models/data_with_id.dart';
import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/models/phrase_tracker.dart';
import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:baby_words_tracker/pages/shared/bottom_bar.dart';
import 'package:baby_words_tracker/pages/shared/top_bar.dart';
import 'package:baby_words_tracker/util/current_children_service.dart';
import 'package:baby_words_tracker/util/string_utils.dart';
import 'package:baby_words_tracker/video/local_media_entry.dart';
import 'package:baby_words_tracker/video/media_storage_service.dart';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class DisplayMediaPage extends StatefulWidget {
  static const routeName = '/displaymedia';

  const DisplayMediaPage({super.key});

  @override
  State<DisplayMediaPage> createState() => _DisplayMediaPageState();
}

class _DisplayMediaPageState extends State<DisplayMediaPage> {
  String? _selectedMediaKey;
  String? _lastLoadedKey;

  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  Chewie? _playerWidget;

  bool _isInitializing = false;
  String? _initError;
  
  // Maps for word/phrase display text lookup
  Map<String, String> _wordDisplayTexts = {};
  Map<String, String> _phraseDisplayTexts = {};

  Stream<List<WordTracker>> _watchWordTrackers(String childId) {
    return FirebaseFirestore.instance
        .collection(Child.collectionName)
        .doc(childId)
        .collection(WordTracker.collectionName)
        .orderBy('firstUtterance', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WordTracker.fromDataWithId(
                    DataWithId.fromFirestore(doc),
                  ))
              .toList(),
        );
  }

  Stream<List<PhraseTracker>> _watchPhraseTrackers(String childId) {
    return FirebaseFirestore.instance
        .collection(Child.collectionName)
        .doc(childId)
        .collection(PhraseTracker.collectionName)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => PhraseTracker.fromDataWithId(
                  DataWithId.fromFirestore(doc),
                  childId: childId,
                ),
              )
              .toList(),
        );
  }

  void _updateDisplayTexts(List<WordTracker> words, List<PhraseTracker> phrases) {
    _wordDisplayTexts.clear();
    _phraseDisplayTexts.clear();
    
    for (final word in words) {
      if (word.id != null) {
        _wordDisplayTexts[word.id!] = word.id!.capitalizeOrNA();
      }
    }
    
    for (final phrase in phrases) {
      _phraseDisplayTexts[phrase.id] = phrase.phrase.capitalizeOrNA();
    }
  }

  String _getDisplayTextForEntry(LocalMediaEntry entry) {
    // Check if it's a phrase first
    if (_phraseDisplayTexts.containsKey(entry.wordId)) {
      return _phraseDisplayTexts[entry.wordId]!;
    }
    // Then check if it's a word
    if (_wordDisplayTexts.containsKey(entry.wordId)) {
      return _wordDisplayTexts[entry.wordId]!;
    }
    // Fallback to wordId
    return entry.wordId.capitalizeOrNA();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    _controller?.dispose();
    _controller = null;
    _chewieController?.dispose();
    _chewieController = null;
    _playerWidget = null;
  }

  Future<void> _playEntry(
    LocalMediaEntry entry,
    MediaStorageService mediaStorage,
  ) async {
    if (_lastLoadedKey == entry.key && _controller != null) {
      return;
    }

    _disposeControllers();

    setState(() {
      _isInitializing = true;
      _initError = null;
    });

    try {
      final file = await mediaStorage.getMediaFile(entry.childId, entry.wordId);
      if (file == null) {
        setState(() {
          _initError =
              "The media file for '${entry.wordId}' could not be found.";
        });
        return;
      }

      final isVideo = _isVideoFile(file.path);
      final isImage = _isImageFile(file.path);

      if (isVideo) {
        final controller = VideoPlayerController.file(file);
        await controller.initialize();
        controller.play();

        final chewieController = ChewieController(
          videoPlayerController: controller,
          autoPlay: true,
          looping: false,
        );

        setState(() {
          _controller = controller;
          _chewieController = chewieController;
          _playerWidget = Chewie(controller: chewieController);
          _lastLoadedKey = entry.key;
        });
      } else if (isImage) {
        setState(() {
          _controller = null;
          _chewieController = null;
          _playerWidget = null;
          _lastLoadedKey = entry.key;
        });
      } else {
        setState(() {
          _initError = "Unsupported media type for '${entry.wordId}'.";
        });
      }
    } catch (error) {
      debugPrint('DisplayMediaPage: Failed to initialise media - $error');
      setState(() {
        _initError =
            "We couldn't open that media file. It may have been deleted or moved.";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  bool _isVideoFile(String path) {
    final extension = p.extension(path).toLowerCase();
    return ['.mp4', '.mov', '.m4v'].contains(extension);
  }

  bool _isImageFile(String path) {
    final extension = p.extension(path).toLowerCase();
    return ['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp'].contains(extension);
  }

  void _onMediaSelected(
    String key,
    List<LocalMediaEntry> entries,
    MediaStorageService mediaStorage,
  ) {
    if (_selectedMediaKey == key) {
      return;
    }

    final entry = entries.firstWhere(
      (element) => element.key == key,
      orElse: () => entries.first,
    );

    setState(() {
      _selectedMediaKey = entry.key;
    });

    _playEntry(entry, mediaStorage);
  }

  void _syncSelection(
    List<LocalMediaEntry> entries,
    MediaStorageService mediaStorage,
  ) {
    if (entries.isEmpty) {
      if (_selectedMediaKey != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _disposeControllers();
          setState(() {
            _selectedMediaKey = null;
            _lastLoadedKey = null;
          });
        });
      }
      return;
    }

    final hasSelection = entries.any((entry) => entry.key == _selectedMediaKey);

    if (!hasSelection) {
      final firstEntry = entries.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedMediaKey = firstEntry.key;
        });
        _playEntry(firstEntry, mediaStorage);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<LocalizationService, CurrentChildrenService,
        MediaStorageService>(
      builder: (context, localizationService, currentChildrenService,
          mediaStorage, child) {
        final theme = Theme.of(context);
        final currentChild = currentChildrenService.getCurrChild();
        final childId = currentChild?.id;

        final entries = <LocalMediaEntry>[];
        if (childId != null && mediaStorage.isReady) {
          entries.addAll(mediaStorage.videosForChild(childId));
        }

        _syncSelection(entries, mediaStorage);

        final selectedEntry = entries
            .where((entry) => entry.key == _selectedMediaKey)
            .cast<LocalMediaEntry?>()
            .firstWhere(
              (entry) => entry != null,
              orElse: () => null,
            );

        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar:
              TopBar(pageName: localizationService.translate("upload_video")),
          bottomNavigationBar:
              const CustomBottomBar(DisplayMediaPage.routeName),
          body: childId != null
              ? StreamBuilder<List<WordTracker>>(
                  stream: _watchWordTrackers(childId),
                  builder: (context, wordSnapshot) {
                    return StreamBuilder<List<PhraseTracker>>(
                      stream: _watchPhraseTrackers(childId),
                      builder: (context, phraseSnapshot) {
                        if (wordSnapshot.hasData && phraseSnapshot.hasData) {
                          _updateDisplayTexts(
                            wordSnapshot.data!,
                            phraseSnapshot.data!,
                          );
                        }
                        
                        return Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: _buildContent(
                            theme: theme,
                            localizationService: localizationService,
                            mediaStorage: mediaStorage,
                            currentChildId: childId,
                            entries: entries,
                            selectedEntry: selectedEntry,
                          ),
                        );
                      },
                    );
                  },
                )
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildContent(
                    theme: theme,
                    localizationService: localizationService,
                    mediaStorage: mediaStorage,
                    currentChildId: childId,
                    entries: entries,
                    selectedEntry: selectedEntry,
                  ),
                ),
        );
      },
    );
  }

  Widget _buildContent({
    required ThemeData theme,
    required LocalizationService localizationService,
    required MediaStorageService mediaStorage,
    required String? currentChildId,
    required List<LocalMediaEntry> entries,
    required LocalMediaEntry? selectedEntry,
  }) {
    if (!mediaStorage.isFeatureEnabled || kIsWeb) {
      return _buildMessageCard(
        theme,
        title: "Media playback unavailable",
        description:
            "Local media playback is disabled by the feature flag or unsupported on this platform.",
      );
    }

    if (!mediaStorage.isReady) {
      return const Center(child: CircularProgressIndicator());
    }

    if (currentChildId == null) {
      return _buildMessageCard(
        theme,
        title: localizationService.translate("file_not_added"),
        description: "Add a child to view any saved media.",
      );
    }

    if (entries.isEmpty) {
      return _buildMessageCard(
        theme,
        title: "No media yet",
        description:
            "Add a word with a media attachment to see it appear here.",
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey(_selectedMediaKey),
          value: _selectedMediaKey,
          items: entries
              .map(
                (entry) => DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(_getDisplayTextForEntry(entry)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              _onMediaSelected(value, entries, mediaStorage);
            }
          },
          decoration: const InputDecoration(
            labelText: "Select media",
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Center(
            child: _buildPlayerArea(theme, selectedEntry),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerArea(ThemeData theme, LocalMediaEntry? selectedEntry) {
    if (_isInitializing) {
      return const CircularProgressIndicator();
    }

    if (_initError != null) {
      return Text(
        _initError!,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.error,
        ),
        textAlign: TextAlign.center,
      );
    }

    if (selectedEntry == null) {
      return const Text("Select media to view.");
    }

    // Check if it's a video
    if (_controller != null && _chewieController != null && _playerWidget != null) {
      final aspectRatio = _controller!.value.aspectRatio;
      return AspectRatio(
        aspectRatio: aspectRatio == 0 ? 16 / 9 : aspectRatio,
        child: _playerWidget!,
      );
    }

    // Check if it's an image
    if (_isImageFile(selectedEntry.filePath)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          File(selectedEntry.filePath),
          fit: BoxFit.contain,
        ),
      );
    }

    return const Text("Unsupported media type.");
  }

  Widget _buildMessageCard(
    ThemeData theme, {
    required String title,
    required String description,
  }) {
    return Card(
      color: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(description),
          ],
        ),
      ),
    );
  }
}
