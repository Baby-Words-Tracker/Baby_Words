import 'dart:io';
import 'package:baby_words_tracker/pages/shared/bottom_bar.dart';
import 'package:baby_words_tracker/pages/shared/top_bar.dart';
import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:baby_words_tracker/data/services/child_data_service.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:baby_words_tracker/util/current_children_service.dart';
import 'package:baby_words_tracker/video/video_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart' as path;
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class DisplayVideoPage extends StatefulWidget {
  static const routeName = '/displayvideo';

  const DisplayVideoPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _DisplayVideoPageState createState() => _DisplayVideoPageState();
}

class _DisplayVideoPageState extends State<DisplayVideoPage> {
  String? _selectedVideoId;
  List<WordTracker> _wordList = [];
  VideoPlayerController? _controller;

  /// Fetch video metadata from Firestore
  Future<void> fetchVideos(
    ChildDataService childService,
    CurrentChildrenService currentChildrenService,
  ) async {
    setState(() {
      _isLoading = true;
    });
    debugPrint("Fetching videos for current child...");
    // Get the current child ID
    String? currentChildID = currentChildrenService.getCurrChild()?.id;
    if (currentChildID == null) {
      debugPrint("No current child ID found.");
      setState(() {
        _wordList = [];
        _isLoading = false;
      });
    } else {
      try {
        final wordList = await childService.getAllKnownWords(currentChildID);
        setState(() {
          _wordList = wordList.where((video) => video.videoID != null).toList();
          //debugPrint(_wordList.toString());
        });
      } catch (e) {
        debugPrint("Error fetching videos: $e");
        setState(() {
          _wordList = [];
        });
      } finally {
        debugPrint("Videos fetched: ${_wordList.length}");
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _lastChildId;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final childService = context.read<ChildDataService>();
    final currentChildService = context.read<CurrentChildrenService>();
    final currentChild = context.watch<CurrentChildrenService>().getCurrChild();

    if (currentChild != null && currentChild.id != _lastChildId) {
      _lastChildId = currentChild.id;
      Future.microtask(() => fetchVideos(childService, currentChildService));
    }
  }

  Future<File?> downloadVideo(String fileName) async {
    if (_controller != null) {
      _controller!.dispose();
      _controller = null;
      debugPrint("Disposed of previous video controller.");
    }

    final signedUrl = await getSignedDownloadUrl(fileName);
    final response = await http.get(Uri.parse(signedUrl!));
    debugPrint("Response length: ${response.bodyBytes.length} bytes");

    final tempDirectory = await path
        .getTemporaryDirectory(); //this directory will be cleared by the device when needed and does not persist through bootups

    final filePath = '${tempDirectory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);

    debugPrint("File location: ${file.path}");
    debugPrint("File size: ${await file.length()} bytes");

    // Uncomment the next line to debug print the file contents only if you suspect they are a string
    // debugPrint("File contents: ${await file.readAsString()}");

    if (!(await file.exists())) {
      debugPrint("Error: File was not saved correctly");
      return null;
    }
    debugPrint("File saved successfully at: ${file.path}");

    debugPrint("opening file: $filePath");
    try {
      await file.open(mode: FileMode.read);
      debugPrint("File opened successfully.");
    } catch (e) {
      debugPrint("Error opening file: $e");
      return null;
    }

    try {
      _controller = VideoPlayerController.file(
        file,
      )..initialize().then((_) {
          setState(() {});
          _controller!.play();
        });
      debugPrint("Video Player Controller created with file: $filePath");
    } catch (e) {
      debugPrint("Error initializing video player: $e");
    }
    return file;
  }

  /// Initialize the Video Player
  void initializeVideoPlayer(String filename) async {
    if (_controller != null) {
      _controller!.dispose();
      _controller = null;
      debugPrint("Disposed of previous video controller.");
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
        // fetchVideos(context, childService, currentChildrenService);
        return Scaffold(
          backgroundColor: const Color(0xFF828A8F),
          appBar: TopBar(pageName: localizationService.translate("add_words")),
          bottomNavigationBar: bottomBar(context, DisplayVideoPage.routeName),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: Column(
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
                        onChanged: (value) async {
                          setState(() {
                            _selectedVideoId = value;
                          });
                          final selectedVideo = _wordList
                              .firstWhere((video) => video.id == value);
                          if (kIsWeb) {
                            initializeVideoPlayer(selectedVideo.videoID!);
                          } else {
                            downloadVideo(selectedVideo.videoID!);
                          }

                          // _cacheAndPlayVideo(selectedVideo.videoID!);
                        },
                      ),
                      Expanded(
                        child: _controller != null &&
                                _controller!.value.isInitialized
                            ? AspectRatio(
                                aspectRatio: _controller!.value.aspectRatio,
                                child: VideoPlayer(_controller!),
                              )
                            : const Center(
                                child: Text("Select a video to play")),
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
                ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
