import 'package:baby_words_tracker/data/models/data_with_id.dart';
import 'package:baby_words_tracker/data/listeners/firestore_document_listener.dart';
import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:baby_words_tracker/util/pair.dart';

/// Abstract interface for Firestore operations
/// This allows us to inject different implementations (real Firebase vs fake for testing)
abstract class IFirestoreRepository {
  // Core CRUD operations used by services
  Future<String?> create(String collectionName, Map<String, dynamic> data);
  Future<String?> createWithId(
      String collectionName, String docId, Map<String, dynamic> data,
      [bool merge = false]);
  Future<DataWithId?> read(String collectionName, String documentId);
  Future<List<DataWithId>> readMultiple(
      String collectionName, List<String> documentIds);
  Future<bool> update(
      String collectionName, String documentId, Map<String, dynamic> data);
  Future<bool> delete(String collectionName, String documentId);

  // Query operations used by services
  Future<List<DataWithId>> queryByField(
      String collectionName, String field, dynamic value,
      {int? limit});
  
  // Get all documents from a collection (used by CsvExportService)
  Future<List<DataWithId>> readAll(String collectionName);

  // Array operations (used by ParentDataService)
  Future<bool> appendToArrayField(
      String collectionName, String docID, String field, dynamic value);

  // Document listeners (used by ParentDataService and ResearcherDataService)
  FirestoreDocumentListener<T> getDocumentListener<T>({
    required String path,
    required T Function(DataWithId) convertDataWithId,
  });

  // Subcollection operations (used by ChildDataService)
  Future<bool> updateFieldForSubcollection(
      String collectionName,
      String subcollectionName,
      String docId,
      String subDocId,
      String field,
      dynamic value);
  Future<List<DataWithId>> readAllFromSubcollection(
      String collectionName, String docId, String subcollectionName);

  // User type management operations (used by GeneralUserService)
  Future<Pair<DataWithId, String>?> changeUserType(
      String userId, List<String> fromCollections, String toCollection,
      {String? expectedCollectionName});

  // Word tracker operations (used by WordTrackerDataService)
  Future<bool> addOrUpdateWordTracker(String collectionName, String docId,
      String subcollectionName, String subDocId, WordTracker wordTracker);
  Future<bool> updateSubcollectionDocument(String collectionName, String docId,
      String subcollectionName, String subDocId, Map<String, dynamic> data);
  Future<bool> setSubcollectionDocument(
    String collectionName,
    String docId,
    String subcollectionName,
    String subDocId,
    Map<String, dynamic> data, {
    bool merge = false,
  });
  Future<bool> deleteSubcollectionDocument(String collectionName, String docId,
      String subcollectionName, String subDocId);
  Future<bool> deleteWordTrackerDocument(String collectionName, String docId,
      String subcollectionName, String subDocId);
  Future<DataWithId?> readSubcollection(String collectionName, String docId,
      String subcollectionName, String subDocId);
  Future<List<DataWithId>> subFieldGreaterThan(String collectionName,
      String docId, String subcollection, String field, dynamic value);
  Future<List<DataWithId>> subQueryByDateRange(
      String collectionName,
      String docId,
      String subcollection,
      String field,
      DateTime startDate,
      DateTime endDate);

  // Batch operations (if needed)
  Future<bool> batchUpdate(Map<String, Map<String, dynamic>> updates);
}
