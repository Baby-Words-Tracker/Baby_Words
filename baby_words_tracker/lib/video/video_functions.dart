import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

Future<String?> getSignedUrl(String filename) async {
  HttpsCallable function =
      FirebaseFunctions.instance.httpsCallable("generateSignedUrl");

  try {
    debugPrint("FileName in getSignedUrl: $filename");
    final response = await function.call({'fileName': filename});
    debugPrint('Signed URL: ${response.data['url']}');
    return response.data["serviceConfig"]!['uri'];
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
    var signedUrl = await getSignedUrl(path.basename(filePath));
    final File file = File(filePath);

    if (signedUrl != null) {
      final request = http.Request('PUT', Uri.parse(signedUrl))
        ..headers['Content-Type'] = 'video/mp4' // Set the correct MIME type
        ..bodyBytes = await file.readAsBytes();

      final response = await request.send();

      if (response.statusCode == 200) {
        debugPrint('File uploaded successfully!');
      } else {
        debugPrint('Failed to upload file: ${response.statusCode}');
      }
    } else {
      debugPrint("Error: no signed URL was received.");
    }
  } catch (e) {
    debugPrint('Error during file upload: $e');
  }
}

Future<void> downloadVideo(String filePath) async {
  //TODO: do this when implementing video streaming
  return;
}
