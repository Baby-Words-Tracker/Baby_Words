import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'package:baby_words_tracker/auth/authentication_service.dart';

import 'package:flutter/material.dart';

import 'dart:io';

Future<String?> getSignedUrl(String fileName, AuthenticationService authenticationService) async {
  //final user = FirebaseAuth.instance.currentUser;
  final idToken = authenticationService.userId; //is the user id that same as the user auth token??

  final response = await http.post(
    //TODO: deploy cloud function and add url
    Uri.parse('https:// <<our function url - has not been deployed>>'),
    headers: {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
    },
    body: '{"fileName": "$fileName"}',
  );

  if (response.statusCode == 200) {
    debugPrint('Signed URL: ${response.body}');
    return response.body; 
  } else {
    debugPrint('Error: ${response.body}');
    return null;
  }
}

Future<void> uploadVideo(String filePath, AuthenticationService authenticationService) async {

    try {
      var signedUrl = await getSignedUrl(filePath, authenticationService);
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