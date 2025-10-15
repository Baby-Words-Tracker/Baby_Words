import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_test/flutter_test.dart';

import 'firebase_mocks.mocks.dart';
import 'mock_data.dart';

/// Helper class for setting up Firebase mocks in tests
class FirebaseTestHelpers {
  static late FakeFirebaseFirestore fakeFirestore;
  static late MockFirebaseAuth mockAuth;
  static late MockUser mockUser;
  static late MockFirebaseApp mockApp;

  /// Initialize all Firebase mocks for testing
  static void setupFirebaseMocks() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockApp = MockFirebaseApp();

    // Setup default auth mocks
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('test-user-123');
    when(mockUser.email).thenReturn('test@example.com');
    when(mockUser.displayName).thenReturn('Test User');
    when(mockUser.emailVerified).thenReturn(true);
  }

  /// Setup test data in fake Firestore
  static Future<void> setupTestData() async {
    // Add mock children
    for (final child in MockData.mockChildren) {
      await fakeFirestore.collection('Child').doc(child.id).set(child.toMap());
    }

    // Add mock parents
    for (final parent in MockData.mockParents) {
      await fakeFirestore
          .collection('Parent')
          .doc(parent.id)
          .set(parent.toMap());
    }

    // Add mock words
    for (final word in MockData.mockWords) {
      await fakeFirestore.collection('Word').doc(word.word).set(word.toMap());
    }
  }

  /// Setup a mock signed-in user
  static void setupSignedInUser({
    String? uid,
    String? email,
    String? displayName,
  }) {
    when(mockUser.uid).thenReturn(uid ?? 'test-user-123');
    when(mockUser.email).thenReturn(email ?? 'test@example.com');
    when(mockUser.displayName).thenReturn(displayName ?? 'Test User');
    when(mockAuth.currentUser).thenReturn(mockUser);
  }

  /// Setup a mock signed-out user
  static void setupSignedOutUser() {
    when(mockAuth.currentUser).thenReturn(null);
  }

  /// Setup Firebase Auth sign-in success
  static void setupSignInSuccess() {
    final mockCredential = MockUserCredential();
    when(mockCredential.user).thenReturn(mockUser);
    when(mockAuth.signInWithEmailAndPassword(
      email: anyNamed('email'),
      password: anyNamed('password'),
    )).thenAnswer((_) async => mockCredential);
  }

  /// Setup Firebase Auth sign-in failure
  static void setupSignInFailure() {
    when(mockAuth.signInWithEmailAndPassword(
      email: anyNamed('email'),
      password: anyNamed('password'),
    )).thenThrow(FirebaseAuthException(
      code: 'user-not-found',
      message: 'No user found for that email.',
    ));
  }

  /// Clean up mocks between tests
  static void tearDown() {
    reset(mockAuth);
    reset(mockUser);
    reset(mockApp);
  }

  /// Create a test-specific Firestore instance with custom data
  static FakeFirebaseFirestore createCustomFirestore(
      Map<String, Map<String, dynamic>> collections) {
    final firestore = FakeFirebaseFirestore();

    collections.forEach((collectionPath, documents) async {
      documents.forEach((docId, data) async {
        await firestore.collection(collectionPath).doc(docId).set(data);
      });
    });

    return firestore;
  }

  /// Assert that Firestore document exists with expected data
  static Future<void> assertDocumentExists(
    FakeFirebaseFirestore firestore,
    String collection,
    String docId,
    Map<String, dynamic> expectedData,
  ) async {
    final doc = await firestore.collection(collection).doc(docId).get();
    expect(doc.exists, isTrue,
        reason: 'Document $collection/$docId should exist');

    expectedData.forEach((key, value) {
      expect(doc.data()?[key], equals(value),
          reason: 'Field $key should match expected value');
    });
  }

  /// Assert that Firestore collection has expected number of documents
  static Future<void> assertCollectionSize(
    FakeFirebaseFirestore firestore,
    String collection,
    int expectedSize,
  ) async {
    final querySnapshot = await firestore.collection(collection).get();
    expect(querySnapshot.docs.length, equals(expectedSize),
        reason: 'Collection $collection should have $expectedSize documents');
  }

  /// Create a test user with specific properties
  static MockUser createTestUser({
    String uid = 'test-user',
    String email = 'test@example.com',
    String? displayName,
    bool emailVerified = true,
  }) {
    final user = MockUser();
    when(user.uid).thenReturn(uid);
    when(user.email).thenReturn(email);
    when(user.displayName).thenReturn(displayName);
    when(user.emailVerified).thenReturn(emailVerified);
    return user;
  }
}
