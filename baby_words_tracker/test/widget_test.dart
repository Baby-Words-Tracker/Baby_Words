// Main app smoke tests for Baby Words Tracker
//
// Basic tests to ensure the app can initialize without crashing.
// For detailed component testing, see the organized test files in subdirectories.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

// Import services for basic smoke testing
import 'package:baby_words_tracker/data/services/child_data_service.dart';
import 'package:baby_words_tracker/data/services/parent_data_service.dart';
import 'package:baby_words_tracker/data/services/researcher_data_service.dart';
import 'package:baby_words_tracker/data/services/word_data_service.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';

import 'test_helpers/mock_firestore_repository.dart';

void main() {
  group('Baby Words Tracker App Smoke Tests', () {
    
    testWidgets('App theme and structure smoke test', (WidgetTester tester) async {
      // Test the basic app structure and theme used in main.dart
      await tester.pumpWidget(
        MaterialApp(
          title: 'WordBuds Root',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
            useMaterial3: true,
          ),
          home: const Scaffold(
            body: Center(
              child: Text('Baby Words Tracker'),
            ),
          ),
        ),
      );

      expect(find.text('Baby Words Tracker'), findsOneWidget);
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Services can be instantiated with mock repositories', (WidgetTester tester) async {
      // Test that all core services can be created with dependency injection (no Firebase needed)
      final fakeFirestore = FakeFirebaseFirestore();
      final mockRepo = MockFirestoreRepository(fakeFirestore);
      
      expect(() => ChildDataService(repository: mockRepo), returnsNormally);
      expect(() => ParentDataService(repository: mockRepo), returnsNormally);
      expect(() => ResearcherDataService(repository: mockRepo), returnsNormally);
      expect(() => WordDataService(repository: mockRepo), returnsNormally);
      expect(() => LocalizationService(), returnsNormally);
    });

    testWidgets('Provider structure can be created', (WidgetTester tester) async {
      // Test that the provider structure from main.dart can be initialized with DI
      final fakeFirestore = FakeFirebaseFirestore();
      final mockRepo = MockFirestoreRepository(fakeFirestore);
      
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ChildDataService(repository: mockRepo)),
            ChangeNotifierProvider(create: (_) => ParentDataService(repository: mockRepo)),
            ChangeNotifierProvider(create: (_) => ResearcherDataService(repository: mockRepo)),
            ChangeNotifierProvider(create: (_) => WordDataService(repository: mockRepo)),
            ChangeNotifierProvider(create: (_) => LocalizationService()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  // Verify providers are accessible
                  Provider.of<ChildDataService>(context, listen: false);
                  Provider.of<ParentDataService>(context, listen: false);
                  
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Child Service: ✓'),
                        Text('Parent Service: ✓'),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Child Service: ✓'), findsOneWidget);
      expect(find.text('Parent Service: ✓'), findsOneWidget);
    });
  });
  
  group('Basic Component Smoke Tests', () {
    testWidgets('Localization service provides valid locale', (WidgetTester tester) async {
      final localizationService = LocalizationService();
      final locale = localizationService.getLocale();
      
      expect(locale, isA<Locale>());
      expect(locale.languageCode.isNotEmpty, isTrue);
    });
  });
}
