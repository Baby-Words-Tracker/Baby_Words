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
  Future<List<DataWithId>> queryByField(String collectionName, String field, dynamic value) async {
    final collection = database.collection(collectionName);
    final snapshot = await collection.where(field, isEqualTo: value).get();
    List<DataWithId> data = List.empty(growable: true);

    for(DocumentSnapshot doc in snapshot.docs) {
      data.add(DataWithId.fromFirestore(doc));
    }
    return data;
  }

  Future<List<DataWithId>> subQueryByField(String collectionName, String docId, String subcollection, String field, dynamic value) async {
    final collection = database.collection(collectionName).doc(docId).collection(subcollection);
    final snapshot = await collection.where(field, isEqualTo: value).get();
    List<DataWithId> data = List.empty(growable: true);

    for(DocumentSnapshot doc in snapshot.docs) {
      data.add(DataWithId.fromFirestore(doc));
    }
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
  
}