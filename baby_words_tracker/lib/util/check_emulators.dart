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
    final host = getEmulatorHost();
    final response =
        await http.get(Uri.parse('http://$host:4000/emulators'));
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

  final localhost = getEmulatorHost();
  debugPrint('Setting up Firebase Emulators with host: $localhost');

  // Try to connect to each emulator
  // If emulator is not running, these will fail silently or throw errors that we catch
  
  try {
    FirebaseFirestore.instance.useFirestoreEmulator(localhost, 8080);
    debugPrint('✅ Connected to Firestore Emulator at $localhost:8080');
  } catch (e) {
    debugPrint('⚠️ Could not connect to Firestore Emulator: $e');
  }

  try {
    await FirebaseAuth.instance.useAuthEmulator(localhost, 9099);
    debugPrint('✅ Connected to Auth Emulator at $localhost:9099');
  } catch (e) {
    debugPrint('⚠️ Could not connect to Auth Emulator: $e');
  }

  try {
    FirebaseFunctions.instance.useFunctionsEmulator(localhost, 5001);
    debugPrint('✅ Connected to Functions Emulator at $localhost:5001');
  } catch (e) {
    debugPrint('⚠️ Could not connect to Functions Emulator: $e');
  }
}
