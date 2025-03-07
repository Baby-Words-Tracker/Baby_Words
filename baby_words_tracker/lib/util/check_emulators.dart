import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

enum EmulatorType {
  firestore,
  auth,
  functions
}

Future<dynamic> getEmulators() async {
  try {
    final response = await http.get(Uri.parse('http://localhost:4400/emulators'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
  } catch (e) {
    debugPrint("Error getting emulators: $e");
    throw Exception('Failed to get emulators');
    // Error occurred, emulator is likely not running
  }
  return false;
}

bool isEmulatorRunning(dynamic emulators, EmulatorType emulatorName) {
  return emulators.containsKey(emulatorName.name);
}

Future<void> setupFirebaseEmulators() async {
  if (!kDebugMode) return; // Only run in debug mode
  const localhost = 'localhost';
  final dynamic emulatorData;
  try{
    emulatorData = await getEmulators();
  } catch(e) {
    debugPrint('Failure to get emulator data likely indicates that no emulators are running: ${e.toString()}');
    return;
  }

  debugPrint(emulatorData.toString());

  if (isEmulatorRunning(emulatorData, EmulatorType.firestore)) {
    try {
      FirebaseFirestore.instance.useFirestoreEmulator(localhost, 8080);
      debugPrint('Connected to Firestore Emulator');
    } catch (e) {
      debugPrint('Error connecting to Firestore Emulator: $e');
    }
  } else {
    debugPrint('Firestore Emulator is not running');
  }

  if (isEmulatorRunning(emulatorData, EmulatorType.auth)) {
    try {
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      debugPrint('Connected to Auth Emulator');
    } catch (e) {
      debugPrint('Error connecting to Auth Emulator: $e');
    }
  } else {
    debugPrint('Auth Emulator is not running');
  }
}
