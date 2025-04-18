import 'dart:io';

import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:baby_words_tracker/data/services/child_data_service.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:baby_words_tracker/util/current_children_service.dart';
import 'package:baby_words_tracker/video/video_functions.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart' as path;
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class DisplayVideo extends StatefulWidget {
  const DisplayVideo({super.key});
  @override
  _DisplayVideoState createState() => _DisplayVideoState();
}

class _DisplayVideoState extends State<DisplayVideo> {
  String? _selectedVideoId;
  List<WordTracker> _wordList = [];
  VideoPlayerController? _controller;

  /// Fetch video metadata from Firestore
  Future<void> fetchVideos(
    BuildContext context,
    ChildDataService childService,
    CurrentChildrenService currentChildrenService,
  ) async {
    String? currentChildID = currentChildrenService.getCurrChild()?.id;
    if (currentChildID == null) {
      debugPrint("No current child ID found.");
      setState(() {
        _wordList = [];
      });
    } else {
      final wordList = await childService.getAllKnownWords(currentChildID);
      setState(() {
        _wordList = wordList.where((video) => video.videoID != null).toList();
        //debugPrint(_wordList.toString());
      });
    }
  }

  Future<File> downloadVideo(String fileName) async {
    final directory = await path
        .getTemporaryDirectory(); //this directory will be cleared by the device when needed and does not persist through bootups
    final filePath = '${directory.path}/$fileName.mp4';

    final signedUrl = await getSignedDownloadUrl(fileName);
    final response = await http.get(Uri.parse(signedUrl!));
    final file = File(filePath);
    file.writeAsBytes(response.bodyBytes);
    debugPrint("File location: ${file.path}");
    _controller = VideoPlayerController.file(File(filePath))
      ..initialize().then((_) {
        setState(() {});
        _controller!.play();
      });

    return file;
  }

  /// Initialize the Video Player
  void initializeVideoPlayer(String filename) async {
    if (_controller != null) {
      _controller!.dispose();
    }
    try {
      final signedUrl = await getSignedDownloadUrl(filename);
      //debugPrint(signedUrl);
      _controller = VideoPlayerController.networkUrl(Uri.parse(signedUrl!))
        ..initialize().then((_) {
          setState(() {});
          _controller!.play();
        });
    } catch (e) {
      debugPrint("Error: could not get signed download url.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<LocalizationService, ChildDataService,
            CurrentChildrenService>(
        builder: (context, localizationService, childService,
            currentChildrenService, child) {
      fetchVideos(context, childService, currentChildrenService);
      return Scaffold(
        appBar: AppBar(title: const Text("Select a Video")),
        body: Column(
          children: [
            DropdownButton<String>(
              value: _selectedVideoId,
              hint: const Text("Select a video"),
              items: _wordList.map((video) {
                return DropdownMenuItem<String>(
                  value: video.id,
                  child: Text(video.id!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedVideoId = value;
                });
                final selectedVideo =
                    _wordList.firstWhere((video) => video.id == value);
                downloadVideo(selectedVideo.videoID!);
                //initializeVideoPlayer(selectedVideo.videoID!);
                //_cacheAndPlayVideo(selectedVideo.videoID!);
              },
            ),
            Expanded(
              child: _controller != null && _controller!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    )
                  : const Center(child: Text("Select a video to play")),
            ),
            if (_controller != null)
              FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _controller!.value.isPlaying
                        ? _controller!.pause()
                        : _controller!.play();
                  });
                },
                child: Icon(_controller!.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow),
              ),
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
