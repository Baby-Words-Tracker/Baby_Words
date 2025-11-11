import 'dart:convert';
import 'dart:io';

import 'package:baby_words_tracker/auth/user_profile_model_service.dart';
import 'package:baby_words_tracker/util/feature_flags.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'local_media_entry.dart';

/// Manages parent-scoped, on-device media storage (videos and images).
/// Media files are copied into an application documents folder and tracked via a JSON manifest.
class MediaStorageService extends ChangeNotifier {
  MediaStorageService({
    required UserProfileModelService userProfileModelService,
  }) : _userProfileModelService = userProfileModelService {
    debugPrint("MediaStorageService: Initializing");
    _userProfileModelService.addListener(_syncParentContext);
    debugPrint("MediaStorageService: Starting initial sync");
    _syncParentContext();
  }

  final UserProfileModelService _userProfileModelService;
  final Map<String, LocalMediaEntry> _videos = {};

  Directory? _parentDirectory;
  String? _parentId;
  bool _initialised = false;
  bool _isLoading = false;

  bool get isFeatureEnabled =>
      FeatureFlags.parentLocalVideos && !_isUnsupportedPlatform;

  bool get isReady =>
      isFeatureEnabled && _initialised && !_isLoading && _parentId != null;

  bool get _isUnsupportedPlatform => kIsWeb;

  Iterable<LocalMediaEntry> videosForChild(String childId) sync* {
    for (final entry in _videos.values) {
      if (entry.childId == childId) {
        yield entry;
      }
    }
  }

  LocalMediaEntry? videoForWord(String childId, String wordId) {
    if (_parentId == null) return null;
    return _videos[LocalMediaEntry.composeKey(_parentId!, childId, wordId)];
  }

  LocalMediaEntry? entryForKey(String key) => _videos[key];

  Future<LocalMediaEntry?> saveMediaForWord({
    required String childId,
    required String wordId,
    required File sourceFile,
  }) async {
    if (!isFeatureEnabled) return null;
    if (_parentId == null || _parentDirectory == null) return null;
    if (!await sourceFile.exists()) return null;

    final key = LocalMediaEntry.composeKey(_parentId!, childId, wordId);
    final previousEntry = _videos[key];
    final extension = p.extension(sourceFile.path).isEmpty
        ? '.mp4'
        : p.extension(sourceFile.path);
    final fileName =
        '${childId}_${wordId}_${DateTime.now().millisecondsSinceEpoch}$extension';
    final destination = File(p.join(_parentDirectory!.path, fileName));

    File? copied;
    try {
      await destination.parent.create(recursive: true);
      copied = await sourceFile.copy(destination.path);

      final newEntry = LocalMediaEntry(
        parentId: _parentId!,
        childId: childId,
        wordId: wordId,
        filePath: copied.path,
        savedAt: DateTime.now(),
      );

      _videos[key] = newEntry;
      await _persistManifest();

      if (previousEntry != null &&
          previousEntry.filePath != newEntry.filePath) {
        final oldFile = File(previousEntry.filePath);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      }

      notifyListeners();
      return newEntry;
    } catch (e) {
      debugPrint('VideoStorageService: failed to save video: $e');
      if (copied != null && await copied.exists()) {
        await copied.delete();
      } else if (await destination.exists()) {
        await destination.delete();
      }

      if (previousEntry != null) {
        _videos[key] = previousEntry;
      } else {
        _videos.remove(key);
      }

      return null;
    }
  }

  Future<File?> getMediaFile(String childId, String wordId) async {
    final entry = videoForWord(childId, wordId);
    if (entry == null) return null;
    final file = File(entry.filePath);
    if (await file.exists()) {
      return file;
    }
    // File missing; clean manifest.
    _videos.remove(entry.key);
    await _persistManifest();
    notifyListeners();
    return null;
  }

  Future<File?> getVideoFile(String childId, String wordId) async {
    final entry = videoForWord(childId, wordId);
    if (entry == null) return null;
    final file = File(entry.filePath);
    if (await file.exists()) {
      return file;
    }
    // File missing; clean manifest.
    _videos.remove(entry.key);
    await _persistManifest();
    notifyListeners();
    return null;
  }

  Future<void> removeMediaForWord(String childId, String wordId) async {
    final entry = videoForWord(childId, wordId);
    if (entry == null) return;
    final file = File(entry.filePath);
    if (await file.exists()) {
      await file.delete();
    }
    _videos.remove(entry.key);
    await _persistManifest();
    notifyListeners();
  }

  Future<void> _syncParentContext() async {
    debugPrint("MediaStorageService: _syncParentContext called");
    if (!isFeatureEnabled) {
      debugPrint("MediaStorageService: Feature not enabled, skipping");
      return;
    }
    final profile = _userProfileModelService.userProfile;
    final parentId = profile != null && profile.isParent ? profile.id : null;
    debugPrint("MediaStorageService: Parent ID: $parentId");

    if (parentId == null) {
      if (_parentId != null) {
        debugPrint("MediaStorageService: Clearing parent context");
        _parentId = null;
        _parentDirectory = null;
        _videos.clear();
        _initialised = false;
        notifyListeners();
      }
      return;
    }

    if (parentId == _parentId && _initialised) {
      debugPrint("MediaStorageService: Already initialized for this parent");
      return;
    }

    _parentId = parentId;
    debugPrint("MediaStorageService: Loading media for parent $parentId");
    await _loadForParent(parentId);
  }

  Future<void> _loadForParent(String parentId) async {
    debugPrint("MediaStorageService: _loadForParent started for $parentId");
    if (_isUnsupportedPlatform) {
      debugPrint("MediaStorageService: Unsupported platform");
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      debugPrint("MediaStorageService: Getting application documents directory");
      final docsDir = await getApplicationDocumentsDirectory();
      final parentDir =
          Directory(p.join(docsDir.path, 'parents', parentId, 'videos'));
      debugPrint("MediaStorageService: Creating parent directory: ${parentDir.path}");
      await parentDir.create(recursive: true);

      _parentDirectory = parentDir;

      final manifestFile = File(p.join(parentDir.path, 'manifest.json'));
      if (await manifestFile.exists()) {
        debugPrint("MediaStorageService: Loading manifest file");
        final manifestContent = await manifestFile.readAsString();
        debugPrint("MediaStorageService: Manifest size: ${manifestContent.length} bytes");
        final decoded = jsonDecode(manifestContent);
        final Map<String, dynamic> map = decoded as Map<String, dynamic>;
        debugPrint("MediaStorageService: Found ${map.length} media entries");
        _videos
          ..clear()
          ..addEntries(map.entries.map((entry) {
            final value = Map<String, dynamic>.from(entry.value as Map);
            return MapEntry(
              entry.key,
              LocalMediaEntry.fromJson(value),
            );
          }));
        debugPrint("MediaStorageService: Successfully loaded ${_videos.length} media entries");
      } else {
        debugPrint("MediaStorageService: No manifest file found, starting fresh");
        _videos.clear();
      }
      _initialised = true;
      debugPrint("MediaStorageService: Initialization complete");
    } catch (e) {
      debugPrint('MediaStorageService: failed to load manifest: $e');
      _videos.clear();
      _initialised = false;
    } finally {
      _isLoading = false;
      debugPrint("MediaStorageService: Notifying listeners");
      notifyListeners();
    }
  }

  Future<void> _persistManifest() async {
    if (_parentDirectory == null) return;
    final manifestFile = File(p.join(_parentDirectory!.path, 'manifest.json'));
    final payload = _videos.map(
      (key, value) => MapEntry(key, value.toJson()),
    );
    await manifestFile.writeAsString(jsonEncode(payload));
  }

  @override
  void dispose() {
    _userProfileModelService.removeListener(_syncParentContext);
    super.dispose();
  }
}
