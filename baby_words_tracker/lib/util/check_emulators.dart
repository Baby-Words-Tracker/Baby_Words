import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:http/http.dart' as http;

enum EmulatorType { firestore, auth, functions }

Future<dynamic> getEmulators() async {
  try {
    final response =
        await http.get(Uri.parse('http://localhost:4400/emulators'));
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

String getEmulatorHost() {
  if (kIsWeb) {
    debugPrint("Web platform detected, using localhost");
    return 'localhost';
  } else if (Platform.isAndroid) {
    return '10.0.2.2'; // Android emulator
  } else if (Platform.isIOS) {
    return '127.0.0.1'; // iOS simulator
  } else {
    return 'localhost'; // macOS, Windows, Linux
  }
}

bool isEmulatorRunning(dynamic emulators, EmulatorType emulatorName) {
  return emulators.containsKey(emulatorName.name);
}

Future<void> setupFirebaseEmulators() async {
  if (!kDebugMode) return; // Only run in debug mode

  late final dynamic emulatorData;
  try {
    emulatorData = await getEmulators();
  } catch (e) {
    debugPrint(
        'Failure to get emulator data likely indicates that no emulators are running: ${e.toString()}');
    return;
  }

  final localhost = getEmulatorHost();

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
      await FirebaseAuth.instance.useAuthEmulator(localhost, 9099);
      debugPrint('Connected to Auth Emulator');
    } catch (e) {
      debugPrint('Error connecting to Auth Emulator: $e');
    }
  } else {
    debugPrint('Auth Emulator is not running');
  }

  if (isEmulatorRunning(emulatorData, EmulatorType.functions)) {
    try {
      FirebaseFunctions.instance.useFunctionsEmulator(localhost, 5001);
      debugPrint('Connected to Functions Emulator');
    } catch (e) {
      debugPrint('Error connecting to Functions Emulator: $e');
    }
  } else {
    debugPrint('Functions Emulator is not running');
  }
}
