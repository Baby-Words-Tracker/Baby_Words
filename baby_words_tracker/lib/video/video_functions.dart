import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'dart:typed_data';
import 'dart:async';
import 'package:video_compress/video_compress.dart';

Future<Uint8List?> compressVideo(String inputPath) async {
  final MediaInfo? compressedVideo = await VideoCompress.compressVideo(
    inputPath,
    quality: VideoQuality.MediumQuality,
  );

  if (compressedVideo != null && compressedVideo.file != null) {
    return await compressedVideo.file!.readAsBytes(); // Load into memory
  } else {
    debugPrint("Compression failed");
    return null;
  }
}

Future<String?> getSignedUploadUrl(String filename) async {
  HttpsCallable function =
      FirebaseFunctions.instance.httpsCallable("generateSignedUploadUrl");

  try {
    debugPrint("FileName in getSignedUploadUrl: $filename");
    final response = await function.call({'fileName': filename});
    debugPrint('Signed URL: ${response.data['url']}');
    return response.data['url'];
  } catch (e) {
    debugPrint('Failed to get signed url with error: $e');
    return null;
  }
}

Future<String?> getSignedDownloadUrl(String filename) async {
  HttpsCallable function =
      FirebaseFunctions.instance.httpsCallable("generateSignedDownloadUrl");

  try {
    debugPrint("FileName in getSignedDownloadUrl: $filename");
    final response = await function.call({'fileName': filename});
    debugPrint('Signed URL: ${response.data['url']}');
    return response.data['url'];
  } catch (e) {
    debugPrint('Failed to get signed url with error: $e');
    return null;
  }
}

Future<String> selectFile(TextEditingController fileTextController) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    allowMultiple: false,
    type: FileType.video,
  );

  if (result != null && result.files.single.path != null) {
    File file = File(result.files.single.path!);
    int fileSizeInBytes = await file.length();
    double fileSizeMb = fileSizeInBytes / (1024 * 1024);

    if (fileSizeMb > 5) {
      return "Sorry! That file is to big, consider shortening the video.";
    }
    fileTextController.text = result.files.single.path!;

    debugPrint("File picked: $fileTextController.text");
    return file.path;
  }

  //the user didnt select a file
  return "Please select a 'mp4' file.";
}

Future<void> uploadVideo(String filePath) async {
  try {
    debugPrint("File for signed url: $filePath");
    final compressed = await compressVideo(filePath) as List<int>;

    var signedUrl = await getSignedUploadUrl(path.basename(filePath));
    //final File file = File(filePath);

    if (signedUrl != null /* && compressed.isNotEmpty */) {
      final request = http.Request('PUT', Uri.parse(signedUrl))
        ..headers['Content-Type'] = 'video/mp4' // Set the correct MIME type
        ..bodyBytes = compressed; //await file.readAsBytes(); //compressed

      final response = await request.send();

      if (response.statusCode == 200) {
        debugPrint('File uploaded successfully!');
      } else {
        debugPrint('Failed to upload file: ${response.statusCode}');
      }
    } else {
      debugPrint("Error: either no signed URL or no video was received.");
    }
  } catch (e) {
    debugPrint('Error during file upload: $e');
  }
}

Future<void> downloadVideo(String filePath) async {
  //TODO: do this when implementing video streaming
  return;
}
