import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Result of a video selection action.
class VideoSelectionResult {
  VideoSelectionResult({
    required this.file,
    required this.displayName,
    required this.sizeMb,
  });

  final File file;
  final String displayName;
  final double sizeMb;
}

class VideoSelectionException implements Exception {
  VideoSelectionException(this.message);

  final String message;

  @override
  String toString() => 'VideoSelectionException: $message';
}

/// Launches a platform file picker to select a single video file.
/// Returns `null` if the user cancels the picker.
Future<VideoSelectionResult?> pickLocalVideo({double maxSizeMb = 150}) async {
  if (kIsWeb) {
    throw VideoSelectionException(
      'Video capture is not supported on web for local storage.',
    );
  }

  final FilePickerResult? result = await FilePicker.platform.pickFiles(
    allowMultiple: false,
    type: FileType.video,
  );

  if (result == null || result.files.single.path == null) {
    return null;
  }

  final path = result.files.single.path!;
  final file = File(path);
  if (!await file.exists()) {
    return null;
  }

  final fileSizeBytes = await file.length();
  final sizeMb = fileSizeBytes / (1024 * 1024);
  if (sizeMb > maxSizeMb) {
    throw VideoSelectionException(
      'Selected video is ${sizeMb.toStringAsFixed(1)} MB but the limit is ${maxSizeMb.toStringAsFixed(0)} MB.',
    );
  }

  return VideoSelectionResult(
    file: file,
    displayName: p.basename(path),
    sizeMb: sizeMb,
  );
}
