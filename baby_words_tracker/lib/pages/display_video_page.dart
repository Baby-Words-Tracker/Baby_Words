import 'dart:io';

import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:baby_words_tracker/pages/shared/bottom_bar.dart';
import 'package:baby_words_tracker/pages/shared/top_bar.dart';
import 'package:baby_words_tracker/util/current_children_service.dart';
import 'package:baby_words_tracker/video/local_video_entry.dart';
import 'package:baby_words_tracker/video/video_storage_service.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class DisplayVideoPage extends StatefulWidget {
  static const routeName = '/displayvideo';

  const DisplayVideoPage({super.key});

  @override
  State<DisplayVideoPage> createState() => _DisplayVideoPageState();
}

class _DisplayVideoPageState extends State<DisplayVideoPage> {
  String? _selectedVideoKey;
  String? _lastLoadedKey;

  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  Chewie? _playerWidget;

  bool _isInitializing = false;
  String? _initError;

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
    LocalVideoEntry entry,
    VideoStorageService videoStorage,
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
      final file =
          await videoStorage.getVideoFile(entry.childId, entry.wordId);
      if (file == null) {
        setState(() {
          _initError =
              "The video file for '${entry.wordId}' could not be found.";
        });
        return;
      }

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
    } catch (error) {
      debugPrint('DisplayVideoPage: Failed to initialise video - $error');
      setState(() {
        _initError =
            "We couldn't open that video. It may have been deleted or moved.";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  void _onVideoSelected(
    String key,
    List<LocalVideoEntry> entries,
    VideoStorageService videoStorage,
  ) {
    if (_selectedVideoKey == key) {
      return;
    }

    final entry = entries.firstWhere(
      (element) => element.key == key,
      orElse: () => entries.first,
    );

    setState(() {
      _selectedVideoKey = entry.key;
    });

    _playEntry(entry, videoStorage);
  }

  void _syncSelection(
    List<LocalVideoEntry> entries,
    VideoStorageService videoStorage,
  ) {
    if (entries.isEmpty) {
      if (_selectedVideoKey != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _disposeControllers();
          setState(() {
            _selectedVideoKey = null;
            _lastLoadedKey = null;
          });
        });
      }
      return;
    }

    final hasSelection =
        entries.any((entry) => entry.key == _selectedVideoKey);

    if (!hasSelection) {
      final firstEntry = entries.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedVideoKey = firstEntry.key;
        });
        _playEntry(firstEntry, videoStorage);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<LocalizationService, CurrentChildrenService,
        VideoStorageService>(
      builder: (context, localizationService, currentChildrenService,
          videoStorage, child) {
        final theme = Theme.of(context);
        final currentChild = currentChildrenService.getCurrChild();
        final childId = currentChild?.id;

        final entries = <LocalVideoEntry>[];
        if (childId != null && videoStorage.isReady) {
          entries.addAll(videoStorage.videosForChild(childId));
        }

        _syncSelection(entries, videoStorage);

        final selectedEntry = entries
            .where((entry) => entry.key == _selectedVideoKey)
            .cast<LocalVideoEntry?>()
            .firstWhere(
              (entry) => entry != null,
              orElse: () => null,
            );

        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar:
              TopBar(pageName: localizationService.translate("upload_video")),
          bottomNavigationBar:
              const CustomBottomBar(DisplayVideoPage.routeName),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildContent(
              theme: theme,
              localizationService: localizationService,
              videoStorage: videoStorage,
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
    required VideoStorageService videoStorage,
    required String? currentChildId,
    required List<LocalVideoEntry> entries,
    required LocalVideoEntry? selectedEntry,
  }) {
    if (!videoStorage.isFeatureEnabled || kIsWeb) {
      return _buildMessageCard(
        theme,
        title: "Video playback unavailable",
        description:
            "Local video playback is disabled by the feature flag or unsupported on this platform.",
      );
    }

    if (!videoStorage.isReady) {
      return const Center(child: CircularProgressIndicator());
    }

    if (currentChildId == null) {
      return _buildMessageCard(
        theme,
        title: localizationService.translate("file_not_added"),
        description: "Add a child to view any saved videos.",
      );
    }

    if (entries.isEmpty) {
      return _buildMessageCard(
        theme,
        title: "No videos yet",
        description:
            "Add a word with a video attachment to see it appear here.",
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedVideoKey,
          items: entries
              .map(
                (entry) => DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.wordId),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              _onVideoSelected(value, entries, videoStorage);
            }
          },
          decoration: const InputDecoration(
            labelText: "Select a video",
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

  Widget _buildPlayerArea(ThemeData theme, LocalVideoEntry? selectedEntry) {
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

    if (selectedEntry == null ||
        _controller == null ||
        _chewieController == null ||
        _playerWidget == null) {
      return const Text("Select a video to play.");
    }

    final aspectRatio = _controller!.value.aspectRatio;
    return AspectRatio(
      aspectRatio: aspectRatio == 0 ? 16 / 9 : aspectRatio,
      child: _playerWidget!,
    );
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
