import 'package:baby_words_tracker/data/models/data_with_id.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:collection/collection.dart';

class FirestoreRepository {
  static final database = FirebaseFirestore.instance;

  FirestoreRepository();

  Future<String> create(String collectionName, Map<String, dynamic> data) async {
    final collection = database.collection(collectionName);
    final docRef = await collection.add(data);
    return docRef.id;
  }

  Future<String> createWithId(String collectionName, String docId, Map<String, dynamic> data) async {
    final collection = database.collection(collectionName);
    await collection.doc(docId).set(data);
    return docId; 
  }

  Future<String> createSubcollectionDoc(String collectionName, String docId, String subcollectionName, Map<String, dynamic> data) async{
      final CollectionReference ref = database.collection(collectionName).doc(docId).collection(subcollectionName);
      final docRef = await ref.add(data);
      return docRef.id; 
  }

  Future<String> createSubcollectionDocWithId(String collectionName, String docId, String subcollectionName, String subDoc, Map<String, dynamic> data) async {
    final collection = database.collection(collectionName).doc(docId).collection(subcollectionName);
    await collection.doc(subDoc).set(data);
    return subDoc; 
  }

  Future<DataWithId?> read(String collectionName, String docId) async {
    final docRef = database.collection(collectionName).doc(docId);
    final doc = await docRef.get();
    if (!doc.exists) {
      return null;
    }
    return DataWithId(id: doc.id, data: doc.data() as Map<String, dynamic>);
  }

  Future<DataWithId?> readSubcollection(String collectionName, String docId, String subcollectionName, String subId) async {
    final docRef = database.collection(collectionName).doc(docId).collection(subcollectionName).doc(subId);
    final doc = await docRef.get();
    if(!doc.exists) {
      return null;
    }
    return DataWithId(id: doc.id, data : doc.data() as Map<String, dynamic>);
  }

  Future<List<DataWithId>> readMultiple(String collectionName, List<String> docIds) async {
    final collection = database.collection(collectionName);

    List<DataWithId> docs = List.empty(growable: true);
    
    final List<List<String>> idGroups = docIds.slices(10).toList(); 

    for (final group in idGroups) {
      final snapshot = await collection.where(FieldPath.documentId, whereIn: group).get();
      docs.addAll(snapshot.docs.map((doc) => DataWithId.fromFirestore(doc)));
    }

    return docs;
  }

  Future<List<DataWithId>> readMultipleSubcollectionDocs(String collectionName, String docId, String subcollectionName, List<String> docIds) async {
    final collection = database.collection(collectionName).doc(docId).collection(subcollectionName);

    List<DataWithId> docs = List.empty(growable: true);
    
    final List<List<String>> idGroups = docIds.slices(10).toList(); 

    for (final group in idGroups) {
      final snapshot = await collection.where(FieldPath.documentId, whereIn: group).get();
      docs.addAll(snapshot.docs.map((doc) => DataWithId.fromFirestore(doc)));
    }

    return docs;
  }

  Future<List<DataWithId>> readAllFromSubcollection(String parentCollection, String parentId, String subCollection) async {
    CollectionReference subCollectionRef = database.collection(parentCollection).doc(parentId).collection(subCollection);
    QuerySnapshot snapshot = await subCollectionRef.get();

    List<DataWithId> documents = List.empty(growable: true);
    snapshot.docs.forEach((doc) {
      documents.add(DataWithId.fromFirestore(doc));
    });

    for (DocumentSnapshot doc in snapshot.docs) {
      documents.add(DataWithId.fromFirestore(doc));
    }
    return documents;
}

  Future<void> update(String collectionName, String docId, Map<String, dynamic> data) async {
    final docRef = database.collection(collectionName).doc(docId);
    await docRef.update(data);
  }

  Future<void> updateField(String collectionName, String docId, String field, dynamic value) async {
    final docRef = database.collection(collectionName).doc(docId);
    await docRef.update({field: value});
  }

  Future<void> incrementField(String collectionName, String docId, String field, int value) async {
    final docRef = database.collection(collectionName).doc(docId);
    await docRef.update({field: FieldValue.increment(value)});
  }

  Future<void> appendToArrayField(String collectionName, String docID, String field, dynamic value) async {
    final docRef = database.collection(collectionName).doc(docID);
    await docRef.update({field: FieldValue.arrayUnion([value])});
  }

  Future<void> removeFromArrayField(String collectionName, String docID, String field, dynamic value) async {
    final docRef = database.collection(collectionName).doc(docID);
    await docRef.update({field: FieldValue.arrayRemove([value])});
  }

  Future<void> delete(String collectionName, String docId) async {
    final docRef = database.collection(collectionName).doc(docId);
    await docRef.delete();
  }

  //isEqualTo
  Future<List<DataWithId>> queryByField(String collectionName, String field, dynamic value, {int? limit}) async {
    final collection = database.collection(collectionName);

    Query query = collection.where(field, isEqualTo: value);

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();

    return snapshot.docs.map((doc) => DataWithId.fromFirestore(doc)).toList();
  }

  Future<List<DataWithId>> subQueryByField(String collectionName, String docId, String subcollection, String field, dynamic value) async {
    final collection = database.collection(collectionName).doc(docId).collection(subcollection);
    final snapshot = await collection.where(field, isEqualTo: value).get();
    return snapshot.docs.map((doc) => DataWithId.fromFirestore(doc)).toList();
  }

  Future<List<DataWithId>> subQueryByDateRange(
  String collectionName,
  String docId,
  String subcollection,
  String field,
  DateTime startDate,
  DateTime endDate
  ) async {
    final collection = database.collection(collectionName).doc(docId).collection(subcollection);
    final snapshot = await collection
        .where(field, isGreaterThanOrEqualTo: startDate)
        .where(field, isLessThanOrEqualTo: endDate)
        .get();

    List<DataWithId> data = snapshot.docs.map((doc) => DataWithId.fromFirestore(doc)).toList();
    
    return data;
  }

  Future<List<DataWithId>> fieldGreaterThan(String collectionName, String field, dynamic value) async {
    final collection = database.collection(collectionName);
    final querySnapshot = await collection.where(field, isGreaterThan: value).get();
    List<DataWithId> data = List.empty(growable: true);

    for(DocumentSnapshot doc in querySnapshot.docs) {
      data.add(DataWithId.fromFirestore(doc));
    }
    return data;
  }

  Future<List<DataWithId>> subFieldGreaterThan(String collectionName, String docId, String subcollection, String field, dynamic value) async {
    final collection = database.collection(collectionName).doc(docId).collection(subcollection);
    final querySnapshot = await collection.where(field, isGreaterThan: value).get();
    List<DataWithId> data = List.empty(growable: true);

    for(DocumentSnapshot doc in querySnapshot.docs) {
      data.add(DataWithId.fromFirestore(doc));
    }
    return data;
  }

  Future<String?> createWithUniqueField(String collectionName, Map<String, dynamic> data, String fieldName, dynamic fieldValue) async {
    final collectionRef = FirebaseFirestore.instance.collection(collectionName);

    return await FirebaseFirestore.instance.runTransaction((transaction) async {
      final querySnapshot = await collectionRef
          .where(fieldName, isEqualTo: fieldValue)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        throw Exception("Field: $fieldName already exists in collection $collectionName!");
      }

      final newDocRef = collectionRef.doc(); // Random ID
      transaction.set(newDocRef, data);
      return newDocRef.id;
    });
  }
  
}