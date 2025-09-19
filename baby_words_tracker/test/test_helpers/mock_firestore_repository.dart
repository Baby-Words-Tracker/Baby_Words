import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:baby_words_tracker/data/repositories/i_firestore_repository.dart';
import 'package:baby_words_tracker/data/repositories/firestore_repository.dart';
import 'package:baby_words_tracker/data/models/data_with_id.dart';
import 'package:baby_words_tracker/data/listeners/firestore_document_listener.dart';
import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:baby_words_tracker/util/pair.dart';
import 'package:flutter/foundation.dart';

/// Mock implementation of IFirestoreRepository using FakeFirebaseFirestore
/// This allows us to test services with realistic Firestore operations without hitting real Firebase
class MockFirestoreRepository implements IFirestoreRepository {
  final FakeFirebaseFirestore fakeFirestore;

  MockFirestoreRepository(this.fakeFirestore);

  @override
  Future<String?> create(String collectionName, Map<String, dynamic> data) async {
    try {
      final docRef = await fakeFirestore.collection(collectionName).add(data);
      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String?> createWithId(String collectionName, String docId, Map<String, dynamic> data, [bool merge = false]) async {
    try {
      await fakeFirestore.collection(collectionName).doc(docId).set(data);
      return docId;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<DataWithId?> read(String collectionName, String documentId) async {
    try {
      final doc = await fakeFirestore.collection(collectionName).doc(documentId).get();
      if (doc.exists && doc.data() != null) {
        return DataWithId(id: doc.id, data: doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<DataWithId>> readMultiple(String collectionName, List<String> documentIds) async {
    final results = <DataWithId>[];
    
    for (final id in documentIds) {
      final data = await read(collectionName, id);
      if (data != null) {
        results.add(data);
      }
    }
    
    return results;
  }

  @override
  Future<bool> update(String collectionName, String documentId, Map<String, dynamic> data) async {
    try {
      await fakeFirestore.collection(collectionName).doc(documentId).update(data);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> delete(String collectionName, String documentId) async {
    try {
      await fakeFirestore.collection(collectionName).doc(documentId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<DataWithId>> queryByField(String collectionName, String field, dynamic value, {int? limit}) async {
    try {
      var query = fakeFirestore.collection(collectionName).where(field, isEqualTo: value);
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => DataWithId(
        id: doc.id,
        data: doc.data(),
      )).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<bool> updateFieldForSubcollection(String collectionName, String subcollectionName, 
      String docId, String subDocId, String field, dynamic value) async {
    try {
      await fakeFirestore
          .collection(collectionName)
          .doc(docId)
          .collection(subcollectionName)
          .doc(subDocId)
          .update({field: value});
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<DataWithId>> readAllFromSubcollection(String collectionName, String docId, String subcollectionName) async {
    try {
      final snapshot = await fakeFirestore
          .collection(collectionName)
          .doc(docId)
          .collection(subcollectionName)
          .get();
      
      return snapshot.docs.map((doc) => DataWithId(
        id: doc.id,
        data: doc.data(),
      )).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<bool> batchUpdate(Map<String, Map<String, dynamic>> updates) async {
    try {
      // For fake firestore, we'll just do individual operations
      for (final entry in updates.entries) {
        final parts = entry.key.split('/');
        if (parts.length >= 2) {
          final collection = parts[0];
          final docId = parts[1];
          await update(collection, docId, entry.value);
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> appendToArrayField(String collectionName, String docID, String field, dynamic value) async {
    try {
      final doc = await fakeFirestore.collection(collectionName).doc(docID).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        final currentArray = (data[field] as List<dynamic>?) ?? [];
        if (!currentArray.contains(value)) {
          currentArray.add(value);
          await fakeFirestore.collection(collectionName).doc(docID).update({field: currentArray});
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  FirestoreDocumentListener<T> getDocumentListener<T>({
    required String path,
    required T Function(DataWithId) convertDataWithId,
  }) {
    // For testing, we'll create a basic listener that doesn't cause Settings issues
    // In real testing scenarios, you might want to implement a more functional listener
    try {
      return FirestoreDocumentListener<T>(
        firestoreRepository: this as FirestoreRepository,
        path: path,
        convertDataWithId: convertDataWithId,
      );
    } catch (e) {
      // If there's an issue with the listener, create a minimal mock
      // This is a placeholder that satisfies the interface
      throw UnimplementedError('Document listener creation failed in test: $e');
    }
  }

  // User type management operations (used by GeneralUserService)
  @override
  Future<Pair<DataWithId, String>?> changeUserType(String userId,
      List<String> fromCollections, String toCollection,
      {String? expectedCollectionName}) async {
    // Mock implementation - simulate user type change
    try {
      // Find user in fromCollections
      for (String collection in fromCollections) {
        final userData = await read(collection, userId);
        if (userData != null) {
          // Move user to new collection
          await createWithId(toCollection, userId, userData.data);
          await delete(collection, userId);
          return Pair(userData, toCollection);
        }
      }
      return null;
    } catch (e) {
      debugPrint('MockFirestoreRepository.changeUserType error: $e');
      return null;
    }
  }
  
  // Word tracker operations (used by WordTrackerDataService)
  @override
  Future<bool> addOrUpdateWordTracker(
      String collectionName, String docId, String subcollectionName, 
      String subDocId, WordTracker wordTracker) async {
    try {
      // Mock implementation - add/update in subcollection
      final path = '$collectionName/$docId/$subcollectionName';
      await fakeFirestore.collection(path).doc(subDocId).set(wordTracker.toMap());
      return true;
    } catch (e) {
      debugPrint('MockFirestoreRepository.addOrUpdateWordTracker error: $e');
      return false;
    }
  }

  @override
  Future<bool> updateSubcollectionDocument(
      String collectionName, String docId, String subcollectionName,
      String subDocId, Map<String, dynamic> data) async {
    try {
      final path = '$collectionName/$docId/$subcollectionName';
      
      // For testing: If document doesn't exist, create it instead of failing
      // This makes our update tests more realistic
      final docRef = fakeFirestore.collection(path).doc(subDocId);
      final doc = await docRef.get();
      
      if (doc.exists) {
        await docRef.update(data);
      } else {
        // Create the document with the update data if it doesn't exist
        await docRef.set(data);
      }
      return true;
    } catch (e) {
      debugPrint('MockFirestoreRepository.updateSubcollectionDocument error: $e');
      return false;
    }
  }

  @override
  Future<DataWithId?> readSubcollection(String collectionName, String docId,
      String subcollectionName, String subDocId) async {
    try {
      final path = '$collectionName/$docId/$subcollectionName';
      final doc = await fakeFirestore.collection(path).doc(subDocId).get();
      if (doc.exists && doc.data() != null) {
        return DataWithId(id: doc.id, data: doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('MockFirestoreRepository.readSubcollection error: $e');
      return null;
    }
  }

  @override
  Future<List<DataWithId>> subFieldGreaterThan(String collectionName,
      String docId, String subcollection, String field, dynamic value) async {
    try {
      // Mock implementation - simplified query
      final results = <DataWithId>[];
      // This is a simplified mock - in reality we'd need to query the subcollection
      return results;
    } catch (e) {
      debugPrint('MockFirestoreRepository.subFieldGreaterThan error: $e');
      return [];
    }
  }

  @override
  Future<List<DataWithId>> subQueryByDateRange(
      String collectionName, String docId, String subcollection, String field,
      DateTime startDate, DateTime endDate) async {
    try {
      // Mock implementation - simplified query
      final results = <DataWithId>[];
      // This is a simplified mock - in reality we'd need to query by date range
      return results;
    } catch (e) {
      debugPrint('MockFirestoreRepository.subQueryByDateRange error: $e');
      return [];
    }
  }

}
