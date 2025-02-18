import 'package:baby_words_tracker/data/models/data_with_id.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/foundation.dart';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class FirestoreRepository {
  static final database = FirebaseFirestore.instance;

  FirestoreRepository();

  Future<String?> create(String collectionName, Map<String, dynamic> data) async {
    try {
      final collection = database.collection(collectionName);
      final docRef = await collection.add(data);
      return docRef.id;
    } catch (e) {
      debugPrint("Error creating document in $collectionName: $e");
      return null;
    }
  }

  Future<String?> createWithId(String collectionName, String docId, Map<String, dynamic> data) async {
    try {
      final collection = database.collection(collectionName);
      await collection.doc(docId).set(data);
      return docId;
    } catch (e) {
      debugPrint("Error creating document in $collectionName: $e");
      return null;
    }
  }

  Future<String?> createSubcollectionDoc(String collectionName, String docId, String subcollectionName, Map<String, dynamic> data) async {
    try {
      final CollectionReference ref = database.collection(collectionName).doc(docId).collection(subcollectionName);
      final docRef = await ref.add(data);
      return docRef.id;
    } catch (e) {
      debugPrint("Error creating subcollection document in $collectionName/$docId/$subcollectionName: $e");
      return null;
    }
  }

  Future<String?> createSubcollectionDocWithId(String collectionName, String docId, String subcollectionName, String subDoc, Map<String, dynamic> data) async {
    try {
      final collection = database.collection(collectionName).doc(docId).collection(subcollectionName);
      await collection.doc(subDoc).set(data);
      return subDoc;
    } catch (e) {
      debugPrint("Error creating subcollection document with ID in $collectionName/$docId/$subcollectionName: $e");
      return null;
    }
  }

  Future<DataWithId?> read(String collectionName, String docId) async {
    try {
      final docRef = database.collection(collectionName).doc(docId);
      final doc = await docRef.get();
      if (!doc.exists) {
        return null;
      }
      return DataWithId(id: doc.id, data: doc.data() as Map<String, dynamic>);
    } catch (e) {
      debugPrint("Error reading document in $collectionName/$docId: $e");
      return null;
    }
  }

  Future<DataWithId?> readSubcollection(String collectionName, String docId, String subcollectionName, String subId) async {
    try {
      final docRef = database.collection(collectionName).doc(docId).collection(subcollectionName).doc(subId);
      final doc = await docRef.get();
      if (!doc.exists) {
        return null;
      }
      return DataWithId(id: doc.id, data: doc.data() as Map<String, dynamic>);
    } catch (e) {
      debugPrint("Error reading subcollection document in $collectionName/$docId/$subcollectionName/$subId: $e");
      return null;
    }
  }

  Future<List<DataWithId>> readMultiple(String collectionName, List<String> docIds) async {
    try {
      final collection = database.collection(collectionName);
      List<DataWithId> docs = List.empty(growable: true);
      final List<List<String>> idGroups = docIds.slices(10).toList();
      for (final group in idGroups) {
        final snapshot = await collection.where(FieldPath.documentId, whereIn: group).get();
        docs.addAll(snapshot.docs.map((doc) => DataWithId.fromFirestore(doc)));
      }
      return docs;
    } catch (e) {
      debugPrint("Error reading multiple documents in $collectionName: $e");
      return [];
    }
  }

  Future<List<DataWithId>> readMultipleSubcollectionDocs(String collectionName, String docId, String subcollectionName, List<String> docIds) async {
    try {
      final collection = database.collection(collectionName).doc(docId).collection(subcollectionName);
      List<DataWithId> docs = List.empty(growable: true);
      final List<List<String>> idGroups = docIds.slices(10).toList();
      for (final group in idGroups) {
        final snapshot = await collection.where(FieldPath.documentId, whereIn: group).get();
        docs.addAll(snapshot.docs.map((doc) => DataWithId.fromFirestore(doc)));
      }
      return docs;
    } catch (e) {
      debugPrint("Error reading multiple subcollection documents in $collectionName/$docId/$subcollectionName: $e");
      return [];
    }
  }

  Future<List<DataWithId>> readAllFromSubcollection(String parentCollection, String parentId, String subCollection) async {
    try {
      // Reference to the subcollection
      CollectionReference subCollectionRef = 
          database.collection(parentCollection).doc(parentId).collection(subCollection);

      // Get the snapshot of the subcollection
      QuerySnapshot snapshot = await subCollectionRef.get();

      // Map the snapshot to a list of DataWithId objects
      List<DataWithId> documents = snapshot.docs
          .map((d) => DataWithId.fromFirestore(d))
          .toList();

      return documents;
    } catch (e) {
      debugPrint("Error reading all documents from subcollection in $parentCollection/$parentId/$subCollection: $e");
      return [];
    }
  }

  //TODO: should this return the new object or just bool?
  Future<bool> update(String collectionName, String docId, Map<String, dynamic> data) async {
    try {
      final docRef = database.collection(collectionName).doc(docId);
      await docRef.update(data);
      return true;
    } catch (e) {
      debugPrint("Error updating document $collectionName/$docId: $e");
      return false;
    }
  }

  Future<bool> updateField(String collectionName, String docId, String field, dynamic value) async {
    try {
      final docRef = database.collection(collectionName).doc(docId);
      await docRef.update({field: value});
      return true;
    } catch (e) {
      debugPrint("Error updating field $field in document $collectionName/$docId: $e");
      return false;
    }
  }

  Future<bool> incrementField(String collectionName, String docId, String field, int value) async {
    try {
      final docRef = database.collection(collectionName).doc(docId);
      await docRef.update({field: FieldValue.increment(value)});
      return true;
    } catch (e) {
      debugPrint("Error incrementing field $field in document $collectionName/$docId: $e");
      return false;
    }
  }

  Future<bool> appendToArrayField(String collectionName, String docID, String field, dynamic value) async {
    try {
      final docRef = database.collection(collectionName).doc(docID);
      await docRef.update({field: FieldValue.arrayUnion([value])});
      return true;
    } catch (e) {
      debugPrint("Error appending to array field $field in document $collectionName/$docID: $e");
      return false;
    }
  }

  Future<bool> removeFromArrayField(String collectionName, String docID, String field, dynamic value) async {
    try {
      final docRef = database.collection(collectionName).doc(docID);
      await docRef.update({field: FieldValue.arrayRemove([value])});
      return true;
    } catch (e) {
      debugPrint("Error removing from array field $field in document $collectionName/$docID: $e");
      return false;
    }
  }

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

  Future<List<DataWithId>> queryByField(String collectionName, String field, dynamic value, {int? limit}) async {
    try {
      final collection = database.collection(collectionName);
      Query query = collection.where(field, isEqualTo: value);
      if (limit != null) {
        query = query.limit(limit);
      }
      final snapshot = await query.get();
      debugPrint("Query of field $field in collection $collection returned ${snapshot.docs.length} documents");
      return snapshot.docs.map((doc) => DataWithId.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint("Error querying by field $field in collection $collectionName: $e");
      return [];
    }
  }

  Future<List<DataWithId>> subQueryByField(String collectionName, String docId, String subcollection, String field, dynamic value) async {
    try {
      final collection = database.collection(collectionName).doc(docId).collection(subcollection);
      final snapshot = await collection.where(field, isEqualTo: value).get();
      return snapshot.docs.map((doc) => DataWithId.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint("Error querying subcollection by field $field in $collectionName/$docId/$subcollection: $e");
      return [];
    }
  }

  Future<List<DataWithId>> subQueryByDateRange(
    String collectionName,
    String docId,
    String subcollection,
    String field,
    DateTime startDate,
    DateTime endDate) async {
    try {
      final collection = database.collection(collectionName).doc(docId).collection(subcollection);
      final snapshot = await collection
          .where(field, isGreaterThanOrEqualTo: startDate)
          .where(field, isLessThanOrEqualTo: endDate)
          .get();
      return snapshot.docs.map((doc) => DataWithId.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint("Error querying subcollection by date range in $collectionName/$docId/$subcollection: $e");
      return [];
    }
  }

  // TODO: remove this? it is hyperspecific
  Future<List<DataWithId>> fieldGreaterThan(String collectionName, String field, dynamic value) async {
    try {
      final collection = database.collection(collectionName);
      final querySnapshot = await collection.where(field, isGreaterThan: value).get();
      List<DataWithId> data = List.empty(growable: true);
      for (DocumentSnapshot doc in querySnapshot.docs) {
        data.add(DataWithId.fromFirestore(doc));
      }
      return data;
    } catch (e) {
      debugPrint("Error querying field greater than $value in $collectionName: $e");
      return [];
    }
  }

  Future<List<DataWithId>> subFieldGreaterThan(String collectionName, String docId, String subcollection, String field, dynamic value) async {
    try {
      final collection = database.collection(collectionName).doc(docId).collection(subcollection);
      final querySnapshot = await collection.where(field, isGreaterThan: value).get();
      List<DataWithId> data = List.empty(growable: true);
      for (DocumentSnapshot doc in querySnapshot.docs) {
        data.add(DataWithId.fromFirestore(doc));
      }
      return data;
    } catch (e) {
      debugPrint("Error querying subcollection field greater than $value in $collectionName/$docId/$subcollection: $e");
      return [];
    }
  }

  Future<String?> createWithUniqueField(String collectionName, Map<String, dynamic> data, String fieldName, dynamic fieldValue) async {
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
      debugPrint("Error creating document with unique $fieldName in $collectionName: $e");
      return null;
    }
  }

  /// Helper function to create workd tracker. This is specialized so that it cannot be used elsewhere because it should not be
  Future<String?> addWordTracker(String collectionName, String childID, String wordID, Map<String, dynamic> data) async {
    try {
      final docRef = database.collection(collectionName).doc(childID);
      final subDocRef = docRef.collection("WordTracker").doc(wordID);

      return database.runTransaction((transaction)  async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          throw Exception("addWordTracker: Child document does not exist");
        }

        transaction.update(docRef, {"wordCount": FieldValue.increment(1)});
        transaction.set(subDocRef, data);

        return wordID;
      });
    } catch (e) {
      debugPrint("Error adding word tracker in $collectionName: $e");
      return null;
    }
  }
    
}