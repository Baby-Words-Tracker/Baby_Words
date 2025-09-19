import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

// Generate mocks for Firebase Auth
@GenerateMocks([
  FirebaseAuth,
  User,
  UserCredential,
  FirebaseApp,
])
void main() {}

// This file generates mocks that can be used in tests
// Run: flutter pub run build_runner build
// to generate the firebase_mocks.mocks.dart file
