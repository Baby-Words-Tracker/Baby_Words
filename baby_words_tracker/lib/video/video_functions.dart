import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';
import 'dart:io';

Future<String?> getSignedUrl(String filename) async {
  HttpsCallable function =
      FirebaseFunctions.instance.httpsCallable("addChildToOtherParent");

  try {
    final response = await function.call({'fileName': filename});
    debugPrint('Signed URL: ${response.data['url']}');
    return response.data['url'];
  } catch (e) {
    debugPrint('Failed to get signed url with error: $e');
  }
}

Future<void> uploadVideo(String filePath) async {
  try {
    var signedUrl = await getSignedUrl(filePath);
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
