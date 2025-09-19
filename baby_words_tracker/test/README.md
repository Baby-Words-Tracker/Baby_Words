# Baby Words Tracker - Testing Guide

Comprehensive testing for the Baby Words Tracker Flutter/Firebase app.

## Test Types

### 🧪 **Unit Tests** (`/models/`, `/services/`, `/utils/`)
Test individual classes and functions in isolation.
```
test/models/child_test.dart           # Data model tests
test/services/child_data_service_test.dart  # Business logic tests  
test/utils/language_code_test.dart    # Utility function tests
```

### 🎨 **Widget Tests** (`/widgets/`)
Test UI components and user interactions.
```
test/widgets/shared/bottom_bar_test.dart  # UI component tests
```

### 🔄 **Integration Tests** (`/integration/`)
Test complete workflows end-to-end.
```
test/integration/firestore_integration_test.dart  # Full data flow tests
```

## Running Tests

### Basic Commands
```bash
# All tests
flutter test

# Specific categories
flutter test test/services/          # All service tests
flutter test test/models/            # All model tests

# Individual test file
flutter test test/services/child_data_service_test.dart

# With coverage report
flutter test --coverage
```

## Firebase Testing

We use **dependency injection** with mocked Firebase for testing without live connections.

### Setup
These packages handle Firebase mocking:
```yaml
dev_dependencies:
  fake_cloud_firestore: ^3.1.0  # Mock Firestore
  mockito: ^5.4.4               # Mock Firebase Auth
  build_runner: ^2.4.8          # Generate mocks
```

### Test Structure with DI
```dart
// Example service test
test('should create child successfully', () async {
  // ✅ Setup Firebase mocks
  FirebaseTestHelpers.setupFirebaseMocks();
  final fakeFirestore = FirebaseTestHelpers.fakeFirestore;
  
  // ✅ Inject mock repository into service
  final mockRepo = MockFirestoreRepository(fakeFirestore);
  final service = ChildDataService(repository: mockRepo);
  
  // ✅ Test real business logic with fake Firebase
  final child = await service.createChild(/*...*/);
  
  // ✅ Verify results
  expect(child, isNotNull);
  expect(child!.name, equals('Test Child'));
});
```

## Test Helpers

### Firebase Helpers (`/test_helpers/`)

**`firebase_test_helpers.dart`** - Main utilities:
```dart
FirebaseTestHelpers.setupFirebaseMocks()  # Initialize all mocks
FirebaseTestHelpers.fakeFirestore         # Access fake Firestore
FirebaseTestHelpers.tearDown()            # Clean up after tests
```

**`mock_firestore_repository.dart`** - Repository implementation:
```dart
MockFirestoreRepository(fakeFirestore)    # Injectable mock repository
```

**`mock_data.dart`** - Test data:
```dart
MockData.createMockChild(name: 'Test')    # Pre-built test objects
MockData.createMockParent()               # Consistent test data
```

### Example: Full Service Test
```dart
void main() {
  group('ChildDataService with DI', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirestoreRepository mockRepo;
    late ChildDataService service;

    setUp(() async {
      FirebaseTestHelpers.setupFirebaseMocks();
      fakeFirestore = FirebaseTestHelpers.fakeFirestore;
      mockRepo = MockFirestoreRepository(fakeFirestore);
      service = ChildDataService(repository: mockRepo);  // ✅ DI
    });

    tearDown(() {
      FirebaseTestHelpers.tearDown();
    });

    test('should create and retrieve child', () async {
      // Test actual business logic!
      final child = await service.createChild(/*...*/);
      final retrieved = await service.getChild(child!.id!);
      
      expect(retrieved!.name, equals(child.name));
    });
  });
}
```

## Generating New Mocks

### 1. Add to Mock Definitions
In `test/test_helpers/firebase_mocks.dart`:
```dart
@GenerateMocks([
  FirebaseAuth,
  User,
  YourNewService,  // ← Add here
])
```

### 2. Regenerate
```bash
flutter pub run build_runner build
```

### 3. Use in Tests
```dart
import '../test_helpers/firebase_mocks.mocks.dart';

// Now MockYourNewService is available
```

## Adding New Tests

### For New Services
1. Create `test/services/your_service_test.dart`
2. Use DI pattern with `MockFirestoreRepository`
3. Test business logic with fake Firebase

### For New Models
1. Create `test/models/your_model_test.dart`
2. Test serialization (`toMap()`, `fromMap()`)
3. Test validation and equality

### For New Widgets
1. Create `test/widgets/your_widget_test.dart`
2. Use `testWidgets()` for UI tests
3. Mock any service dependencies

## Debugging Tests

### Verbose Output
```bash
flutter test --reporter=verbose
```

### Run Specific Test
```bash
flutter test test/services/child_data_service_test.dart --plain-name="should create child"
```

### Debug Test Issues
```bash
# See detailed error output
flutter test --reporter=expanded

# Run in debug mode
flutter test --debug
```

### Common Issues
- **Firebase not initialized**: Use `FirebaseTestHelpers.setupFirebaseMocks()`
- **DI errors**: Inject `MockFirestoreRepository` into services
- **Test isolation**: Call `tearDown()` to clean up between tests

