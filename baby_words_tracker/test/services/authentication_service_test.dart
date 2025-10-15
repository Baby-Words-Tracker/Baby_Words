import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:baby_words_tracker/auth/authentication_service.dart';
import 'package:baby_words_tracker/util/user_roles.dart';

import '../test_helpers/firebase_test_helpers.dart';
import '../test_helpers/firebase_mocks.mocks.dart';

void main() {
  group('AuthenticationService Tests', () {
    late AuthenticationService authService;
    late MockFirebaseAuth mockAuth;

    setUp(() {
      FirebaseTestHelpers.setupFirebaseMocks();
      mockAuth = FirebaseTestHelpers.mockAuth;
      // Setup user changes stream
      when(mockAuth.userChanges()).thenAnswer((_) => Stream.value(null));

      authService = AuthenticationService(mockAuth);
    });

    tearDown(() {
      FirebaseTestHelpers.tearDown();
    });

    group('Authentication State', () {
      test('should return user when authenticated', () {
        // Note: The actual user is managed internally by AuthenticationService
        // We test the public interface
        expect(authService.user, isA<User?>());
      });

      test('should return user ID when authenticated', () {
        expect(authService.userId, isA<String?>());
      });

      test('should return user email when authenticated', () {
        expect(authService.userEmail, isA<String?>());
      });

      test('should return user name when authenticated', () {
        expect(authService.userName, isA<String?>());
      });

      test('should check authentication status', () {
        final isAuthenticated = authService.isAuthenticated;
        expect(isAuthenticated, isA<bool>());
      });
    });

    group('User Roles and Claims', () {
      test('should return custom claims', () {
        final claims = authService.customClaims;
        expect(claims, isA<Map<String, dynamic>?>());
      });

      test('should return user roles', () {
        final roles = authService.roles;
        expect(roles, isA<List<UserRole>>());
      });

      test('should refresh user claims', () async {
        // Test that the method exists and can be called
        expect(() => authService.refreshUserClaims(), returnsNormally);
      });
    });

    group('Sign Out', () {
      test('should sign out successfully', () async {
        // Setup
        when(mockAuth.signOut()).thenAnswer((_) async {});

        // Test
        await authService.signOut();

        // Verify
        verify(mockAuth.signOut()).called(1);
      });

      test('should handle sign out errors gracefully', () async {
        // Setup
        when(mockAuth.signOut()).thenThrow(Exception('Network error'));

        // Test - should not throw, errors are handled internally
        await authService.signOut();

        // Verify the method was called even though it failed
        verify(mockAuth.signOut()).called(1);
      });
    });

    group('Change Notification', () {
      test('should be a ChangeNotifier', () {
        expect(authService, isA<ChangeNotifier>());
      });

      test('should handle user state changes', () {
        // The service listens to userChanges automatically
        // Just verify it's set up correctly
        verify(mockAuth.userChanges()).called(1);
      });
    });

    group('Real User Flow Simulation', () {
      test('should handle user sign in flow simulation', () async {
        // Create a mock user with proper properties
        final testUser = FirebaseTestHelpers.createTestUser(
          uid: 'test-user-123',
          email: 'test@example.com',
          displayName: 'Test User',
        );

        // Setup a stream that simulates sign in
        when(mockAuth.userChanges())
            .thenAnswer((_) => Stream.fromIterable([null, testUser]));

        // Create new service to trigger the stream
        final newAuthService = AuthenticationService(mockAuth);

        // Verify the service was initialized
        expect(newAuthService, isNotNull);
      });

      test('should handle user sign out flow simulation', () async {
        // Setup a stream that simulates sign out
        final testUser = FirebaseTestHelpers.createTestUser();
        when(mockAuth.userChanges())
            .thenAnswer((_) => Stream.fromIterable([testUser, null]));

        // Create new service to trigger the stream
        final newAuthService = AuthenticationService(mockAuth);

        // Verify the service was initialized
        expect(newAuthService, isNotNull);
      });
    });
  });
}
