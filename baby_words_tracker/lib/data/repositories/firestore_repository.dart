import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:baby_words_tracker/exceptions/document_not_found_exception.dart';
import 'package:baby_words_tracker/data/listeners/firestore_document_listener.dart';
import 'package:baby_words_tracker/data/models/data_with_id.dart';
import 'package:baby_words_tracker/data/repositories/i_firestore_repository.dart';
import 'package:baby_words_tracker/util/pair.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/foundation.dart';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class FirestoreRepository implements IFirestoreRepository {
  final FirebaseFirestore database;

  FirestoreRepository({FirebaseFirestore? firestore}) 
      : database = firestore ?? FirebaseFirestore.instance {
    database.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  @override
  Future<String?> create(
      String collectionName, Map<String, dynamic> data) async {
    try {
      final collection = database.collection(collectionName);
      final docRef = await collection.add(data);
      return docRef.id;
    } catch (e) {
      debugPrint("Error creating document in $collectionName: $e");
      return null;
    }
  }

  @override
  Future<String?> createWithId(
      String collectionName, String docId, Map<String, dynamic> data,
      [bool merge = false]) async {
    try {
      final collection = database.collection(collectionName);
      await collection.doc(docId).set(data, SetOptions(merge: merge));
      return docId;
    } catch (e) {
      debugPrint("Error creating document in $collectionName: $e");
      return null;
    }
  }

  Future<String?> createSubcollectionDoc(String collectionName, String docId,
      String subcollectionName, Map<String, dynamic> data) async {
    try {
      final CollectionReference ref = database
          .collection(collectionName)
          .doc(docId)
          .collection(subcollectionName);
      final docRef = await ref.add(data);
      return docRef.id;
    } catch (e) {
      debugPrint(
          "Error creating subcollection document in $collectionName/$docId/$subcollectionName: $e");
      return null;
    }
  }

  Future<String?> createSubcollectionDocWithId(
      String collectionName,
      String docId,
      String subcollectionName,
      String subDoc,
      Map<String, dynamic> data) async {
    try {
      final collection = database
          .collection(collectionName)
          .doc(docId)
          .collection(subcollectionName);
      await collection.doc(subDoc).set(data);
      return subDoc;
    } catch (e) {
      debugPrint(
          "Error creating subcollection document with ID in $collectionName/$docId/$subcollectionName: $e");
      return null;
    }
  }

  @override
  Future<DataWithId?> read(String collectionName, String docId) async {
    try {
      final docRef = database.collection(collectionName).doc(docId);
      final doc = await docRef.get();
      if (!doc.exists) {
        debugPrint(
            "FirebaseRepository: Document $collectionName/$docId does not exist");
        return null;
      }
      return DataWithId(id: doc.id, data: doc.data() as Map<String, dynamic>);
    } catch (e) {
      debugPrint("Error reading document in $collectionName/$docId: $e");
      return null;
    }
  }

  @override
  Future<DataWithId?> readSubcollection(String collectionName, String docId,
      String subcollectionName, String subId) async {
    try {
      final docRef = database
          .collection(collectionName)
          .doc(docId)
          .collection(subcollectionName)
          .doc(subId);
      final doc = await docRef.get();
      if (!doc.exists) {
        return null;
      }
      return DataWithId(id: doc.id, data: doc.data() as Map<String, dynamic>);
    } catch (e) {
      debugPrint(
          "Error reading subcollection document in $collectionName/$docId/$subcollectionName/$subId: $e");
      return null;
    }
  }

  @override
  Future<List<DataWithId>> readMultiple(
      String collectionName, List<String> docIds) async {
    try {
      final collection = database.collection(collectionName);
      List<DataWithId> docs = List.empty(growable: true);
      final List<List<String>> idGroups = docIds.slices(10).toList();
      for (final group in idGroups) {
        final snapshot =
            await collection.where(FieldPath.documentId, whereIn: group).get();
        docs.addAll(snapshot.docs.map((doc) => DataWithId.fromFirestore(doc)));
      }
      return docs;
    } catch (e) {
      debugPrint("Error reading multiple documents in $collectionName: $e");
      return [];
    }
  }

  Future<List<DataWithId>> readMultipleSubcollectionDocs(String collectionName,
      String docId, String subcollectionName, List<String> docIds) async {
    try {
      final collection = database
          .collection(collectionName)
          .doc(docId)
          .collection(subcollectionName);
      List<DataWithId> docs = List.empty(growable: true);
      final List<List<String>> idGroups = docIds.slices(10).toList();
      for (final group in idGroups) {
        final snapshot =
            await collection.where(FieldPath.documentId, whereIn: group).get();
        docs.addAll(snapshot.docs.map((doc) => DataWithId.fromFirestore(doc)));
      }
      return docs;
    } catch (e) {
      debugPrint(
          "Error reading multiple subcollection documents in $collectionName/$docId/$subcollectionName: $e");
      return [];
    }
  }

  @override
  Future<List<DataWithId>> readAllFromSubcollection(
      String parentCollection, String parentId, String subCollection) async {
    try {
      // Reference to the subcollection
      CollectionReference subCollectionRef = database
          .collection(parentCollection)
          .doc(parentId)
          .collection(subCollection);

      // Get the snapshot of the subcollection
      QuerySnapshot snapshot = await subCollectionRef.get();

      // Map the snapshot to a list of DataWithId objects
      List<DataWithId> documents =
          snapshot.docs.map((d) => DataWithId.fromFirestore(d)).toList();

      return documents;
    } catch (e) {
      debugPrint(
          "Error reading all documents from subcollection in $parentCollection/$parentId/$subCollection: $e");
      return [];
    }
  }

  Future<Pair<DataWithId, String>?> queryMultipleCollections(
      String documentId, List<String> collectionNames,
      {String? expectedCollection}) async {
    try {
      // if the expected collection is provided, check it first
      // this is useful for cases where you expect the document to be in a specific collection
      if (expectedCollection != null) {
        DataWithId? doc = await read(expectedCollection, documentId);
        if (doc != null) {
          return Pair(doc, expectedCollection);
        }
      }

      final remainingCollections =
          collectionNames.where((name) => name != expectedCollection).toList();

      if (remainingCollections.isEmpty) {
        throw ArgumentError("Collection names cannot be empty.");
      }

      // If multiple collections are provided, query them simultaneously
      Iterable<Future<DataWithId?>> futures =
          remainingCollections.map((collectionName) async {
        return read(collectionName, documentId);
      });

      List<DataWithId?> docs = await Future.wait(futures);

      for (int i = 0; i < docs.length; i++) {
        if (docs[i] != null) {
          return Pair(docs[i]!, remainingCollections.elementAt(i));
        }
      }

      // If no document is found in any collection, return null
      debugPrint(
          "No document found with ID $documentId in collections: $collectionNames");
      return null;
    } catch (e) {
      debugPrint(
          "queryMultipleCollections: error with docId: $documentId and message: $e");
      return null;
    }
  }

  DocumentReference getDocumentReference(String path) {
    if (path.isEmpty) {
      throw ArgumentError("Firestore path cannot be empty.");
    }
    return FirebaseFirestore.instance.doc(path);
  }

  @override
  FirestoreDocumentListener<T> getDocumentListener<T>({
    required String path,
    required T Function(DataWithId) convertDataWithId,
  }) {
    return FirestoreDocumentListener<T>(
        firestoreRepository: this,
        path: path,
        convertDataWithId: convertDataWithId);
  }

  //TODO: should this return the new object or just bool?
  @override
  Future<bool> update(
      String collectionName, String docId, Map<String, dynamic> data) async {
    try {
      final docRef = database.collection(collectionName).doc(docId);
      await docRef.update(data);
      return true;
    } catch (e) {
      debugPrint("Error updating document $collectionName/$docId: $e");
      return false;
    }
  }

  Future<bool> updateField(
      String collectionName, String docId, String field, dynamic value) async {
    try {
      final docRef = database.collection(collectionName).doc(docId);
      await docRef.update({field: value});
      return true;
    } catch (e) {
      debugPrint(
          "Error updating field $field in document $collectionName/$docId: $e");
      return false;
    }
  }

  @override
  Future<bool> updateSubcollectionDocument(
      String collectionName,
      String docId,
      String subcollectionName,
      String subId,
      Map<String, dynamic> updateData) async {
    try {
      final docRef = database
          .collection(collectionName)
          .doc(docId)
          .collection(subcollectionName)
          .doc(subId);
      await docRef.update(updateData);
      return true;
    } catch (e) {
      debugPrint(
          "Error updating document in subcollection $collectionName/$docId/$subcollectionName/$subId: $e");
      return false;
    }
  }

  @override
  Future<bool> updateFieldForSubcollection(
      String collectionName,
      String subcollectionName,
      String docId,
      String subId,
      String field,
      dynamic value) async {
    try {
      final docRef = database
          .collection(collectionName)
          .doc(docId)
          .collection(subcollectionName)
          .doc(subId);
      await docRef.update({field: value});
      return true;
    } catch (e) {
      debugPrint(
          "Error updating field $field in document $collectionName/$docId/$subcollectionName/$subId: $e");
      return false;
    }
  }

  Future<bool> incrementField(
      String collectionName, String docId, String field, int value) async {
    try {
      final docRef = database.collection(collectionName).doc(docId);
      await docRef.update({field: FieldValue.increment(value)});
      return true;
    } catch (e) {
      debugPrint(
          "Error incrementing field $field in document $collectionName/$docId: $e");
      return false;
    }
  }

  @override
  Future<bool> appendToArrayField(
      String collectionName, String docID, String field, dynamic value) async {
    try {
      final docRef = database.collection(collectionName).doc(docID);
      await docRef.update({
        field: FieldValue.arrayUnion([value])
      });
      return true;
    } catch (e) {
      debugPrint(
          "Error appending to array field $field in document $collectionName/$docID: $e");
      return false;
    }
  }

  Future<bool> appendToArrayFieldForSubcollection(
      String collectionName,
      String subCollection,
      String docID,
      String subID,
      String field,
      dynamic value) async {
    try {
      final docRef = database
          .collection(collectionName)
          .doc(docID)
          .collection(subCollection)
          .doc(subID);
      await docRef.update({
        field: FieldValue.arrayUnion([value])
      });
      return true;
    } catch (e) {
      debugPrint(
          "Error appending to array field $field in document $collectionName/$docID/$subCollection/$subID: $e");
      return false;
    }
  }

  Future<bool> setObject(
      String collectionName, String docId, Map<String, dynamic> data) async {
    try {
      database
          .collection(collectionName)
          .doc(docId)
          .set(data, SetOptions(merge: true));
      return true;
    } catch (_) {
      debugPrint("Error: failed to set $collectionName/$docId with $data");
      return false;
    }
  }

  Future<bool> setObjectSubcollection(
      String collectionName,
      String subcollection,
      String docId,
      String subId,
      Map<String, dynamic> data) async {
    try {
      database
          .collection(collectionName)
          .doc(docId)
          .collection(subcollection)
          .doc(subId)
          .set(data, SetOptions(merge: true));
      return true;
    } catch (_) {
      debugPrint("Error: failed to set $collectionName/$docId with $data");
      return false;
    }
  }

  Future<bool> removeFromArrayField(
      String collectionName, String docID, String field, dynamic value) async {
    try {
      final docRef = database.collection(collectionName).doc(docID);
      await docRef.update({
        field: FieldValue.arrayRemove([value])
      });
      return true;
    } catch (e) {
      debugPrint(
          "Error removing from array field $field in document $collectionName/$docID: $e");
      return false;
    }
  }

  @override
  Future<bool> delete(String collectionName, String docId) async {
    try {
      final docRef = database.collection(collectionName).doc(docId);
      await docRef.delete();
      return true;
    } catch (e) {
      debugPrint("Error deleting document $collectionName/$docId: $e");
      return false;
    }
  }

  @override
  Future<List<DataWithId>> queryByField(
      String collectionName, String field, dynamic value,
      {int? limit}) async {
    try {
      final collection = database.collection(collectionName);
      Query query = collection.where(field, isEqualTo: value);
      if (limit != null) {
        query = query.limit(limit);
      }
      final snapshot = await query.get();
      debugPrint(
          "Query of field $field in collection $collection returned ${snapshot.docs.length} documents");
      return snapshot.docs.map((doc) => DataWithId.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint(
          "Error querying by field $field in collection $collectionName: $e");
      return [];
    }
  }

  Future<List<DataWithId>> subQueryByField(String collectionName, String docId,
      String subcollection, String field, dynamic value) async {
    try {
      final collection = database
          .collection(collectionName)
          .doc(docId)
          .collection(subcollection);
      final snapshot = await collection.where(field, isEqualTo: value).get();
      return snapshot.docs.map((doc) => DataWithId.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint(
          "Error querying subcollection by field $field in $collectionName/$docId/$subcollection: $e");
      return [];
    }
  }

  @override
  Future<List<DataWithId>> subQueryByDateRange(
      String collectionName,
      String docId,
      String subcollection,
      String field,
      DateTime startDate,
      DateTime endDate) async {
    try {
      final collection = database
          .collection(collectionName)
          .doc(docId)
          .collection(subcollection);
      final snapshot = await collection
          .where(field, isGreaterThanOrEqualTo: startDate)
          .where(field, isLessThanOrEqualTo: endDate)
          .get();
      return snapshot.docs.map((doc) => DataWithId.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint(
          "Error querying subcollection by date range in $collectionName/$docId/$subcollection: $e");
      return [];
    }
  }

  // TODO: remove this? it is hyperspecific
  Future<List<DataWithId>> fieldGreaterThan(
      String collectionName, String field, dynamic value) async {
    try {
      final collection = database.collection(collectionName);
      final querySnapshot =
          await collection.where(field, isGreaterThan: value).get();
      List<DataWithId> data = List.empty(growable: true);
      for (DocumentSnapshot doc in querySnapshot.docs) {
        data.add(DataWithId.fromFirestore(doc));
      }
      return data;
    } catch (e) {
      debugPrint(
          "Error querying field greater than $value in $collectionName: $e");
      return [];
    }
  }

  @override
  Future<List<DataWithId>> subFieldGreaterThan(String collectionName,
      String docId, String subcollection, String field, dynamic value) async {
    try {
      final collection = database
          .collection(collectionName)
          .doc(docId)
          .collection(subcollection);
      final querySnapshot =
          await collection.where(field, isGreaterThan: value).get();
      List<DataWithId> data = List.empty(growable: true);
      for (DocumentSnapshot doc in querySnapshot.docs) {
        data.add(DataWithId.fromFirestore(doc));
      }
      return data;
    } catch (e) {
      debugPrint(
          "Error querying subcollection field greater than $value in $collectionName/$docId/$subcollection: $e");
      return [];
    }
  }

  Future<String?> createWithUniqueField(String collectionName,
      Map<String, dynamic> data, String fieldName, dynamic fieldValue) async {
    try {
      final collectionRef = database.collection(collectionName);
      final querySnapshot = await collectionRef
          .where(fieldName, isEqualTo: fieldValue)
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        return null; // already exists
      }
      DocumentReference newDocRef = await collectionRef.add(data);
      return newDocRef.id;
    } catch (e) {
      debugPrint(
          "Error creating document with unique $fieldName in $collectionName: $e");
      return null;
    }
  }

  /// Helper function to create workd tracker. This is specialized so that it cannot be used elsewhere because it should not be
  Future<bool> addWordTracker(
      String collectionName,
      String childID,
      String subcollectionName,
      String wordID,
      Map<String, dynamic> data) async {
    try {
      final docRef = database.collection(collectionName).doc(childID);
      final subDocRef = docRef.collection(subcollectionName).doc(wordID);

      return await database.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          throw Exception("addWordTracker: Child document does not exist");
        }

        transaction.update(docRef, {"wordCount": FieldValue.increment(1)});
        transaction.set(subDocRef, data);

        return true;
      });
    } catch (e) {
      debugPrint("Error adding word tracker in $collectionName: $e");
      return false;
    }
  }

  /// Helper function to create workd tracker. This is specialized so that it cannot be used elsewhere because it should not be
  @override
  Future<bool> addOrUpdateWordTracker(
    String collectionName,
    String childID,
    String subcollectionName,
    String wordID,
    WordTracker wordTracker,
  ) async {
    try {
      final docRef = database.collection(collectionName).doc(childID);
      final subDocRef = docRef.collection(subcollectionName).doc(wordID);

      return await database.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          throw Exception(
              "addOrUpdateWordTracker(): Child document does not exist");
        }

        final subDocSnapshot = await transaction.get(subDocRef);
        if (subDocSnapshot.exists) {
          transaction.update(subDocRef, wordTracker.toMap());
          debugPrint(
              "addOrUpdateWordTracker(): Subdocument $wordID updated with latest data.");
        } else {
          // If the subdocument does not exist, create it
          transaction.update(
              docRef, {Child.wordCountFieldName: FieldValue.increment(1)});
          transaction.set(subDocRef, wordTracker.toMap());
          debugPrint(
              "addOrUpdateWordTracker(): Subdocument $wordID created with data: ${wordTracker.toMap()}");
        }

        return true;
      });
    } catch (e) {
      debugPrint("Error adding word tracker in $collectionName: $e");
      return false;
    }
  }

  Future<DataWithId?> moveDocumentWithoutSubcollections(
      String documentId, String fromCollection, String toCollection) async {
    try {
      // move a document from one collection to another using a transaction
      final fromDocRef = database.collection(fromCollection).doc(documentId);
      final toDocRef = database.collection(toCollection).doc(documentId);
      return await database.runTransaction((transaction) async {
        // Get the document from the source collection
        final fromDocSnapshot = await transaction.get(fromDocRef);
        if (!fromDocSnapshot.exists) {
          debugPrint("Document $documentId does not exist in $fromCollection");
          return null;
        }

        // Create a new document in the target collection with the same data
        transaction.set(toDocRef, fromDocSnapshot.data()!);

        // Delete the document from the source collection
        transaction.delete(fromDocRef);

        // Return the newly created document
        return DataWithId(id: documentId, data: fromDocSnapshot.data()!);
      });
    } catch (e) {
      debugPrint("moveDocumentWithoutSubcollections: $e");
      return null;
    }
  }

  @override
  Future<Pair<DataWithId, String>?> changeUserType(String userId,
      List<String> possibleFromCollections, String newCollectionName,
      {String? expectedCollectionName}) async {
    try {
      final currentUserDataWithIdAndCollection = await queryMultipleCollections(
          userId, possibleFromCollections,
          expectedCollection: expectedCollectionName);

      if (currentUserDataWithIdAndCollection == null) {
        debugPrint(
            "FirestoreRepository: changeUserType() no user found with ID $userId. This may be an error, or the user may not yet have a document.");
        throw DocumentNotFoundException(
            "No user found with ID $userId in collections: $possibleFromCollections");
      } else {
        if (currentUserDataWithIdAndCollection.second == newCollectionName) {
          debugPrint(
              "FirestroreRepository: changeUserType() user $userId is already in the collection $newCollectionName");
          // return the current user data
          return Pair(currentUserDataWithIdAndCollection.first,
              currentUserDataWithIdAndCollection.second);
        } else {
          // Move the document to the new collection using a transaction
          debugPrint(
              "FirestoreRepository: changeUserType() moving user $userId from ${currentUserDataWithIdAndCollection.second} to $newCollectionName with data: ${currentUserDataWithIdAndCollection.first.data}");
          final newUser = await moveDocumentWithoutSubcollections(userId,
              currentUserDataWithIdAndCollection.second, newCollectionName);

          if (newUser == null) {
            debugPrint(
                "FirestoreRepository: changeUserType() failed to move user $userId to $newCollectionName");
            return null;
          } else {
            debugPrint(
                "FirestoreRepository: changeUserType() user $userId moved successfully to $newCollectionName");
            // return the new user
            return Pair(newUser, newCollectionName);
          }
        }
      }
    } on DocumentNotFoundException {
      rethrow;
    } catch (e) {
      debugPrint("changeUserType: $e");
      return null;
    }
  }

  @override
  Future<bool> batchUpdate(Map<String, Map<String, dynamic>> updates) async {
    try {
      final batch = database.batch();
      
      for (final entry in updates.entries) {
        final parts = entry.key.split('/');
        if (parts.length >= 2) {
          final collection = parts[0];
          final docId = parts[1];
          final docRef = database.collection(collection).doc(docId);
          batch.update(docRef, entry.value);
        }
      }
      
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint("Error in batch update: $e");
      return false;
    }
  }
}
