import 'package:cloud_firestore/cloud_firestore.dart';


class FirestoreRepository {
  final database = FirebaseFirestore.instance;

  FirestoreRepository();

  Future<String> create(String collectionName, Map<String, dynamic> data) async {
    final collection = database.collection(collectionName);
    final docRef = await collection.add(data);
    return docRef.id;
  }

  //TODO: add create function that allows docId as argument

  Future<String> createSubcollection(String collectionName, String docId, String subcollectionName, Map<String, dynamic> data) async{
      final CollectionReference ref = database.collection(collectionName).doc(docId).collection(subcollectionName);
      final docRef = await ref.add(data);
      return docRef.id; 
  }

  Future<Map<String, dynamic>> read(String collectionName, String docId) async {
    final docRef = database.collection(collectionName).doc(docId);
    final doc = await docRef.get();
    if (!doc.exists) {
      throw Exception('Document not found');
    }
    return doc.data() as Map<String, dynamic>;
  }

  Future<void> update(String collectionName, String docId, Map<String, dynamic> data) async {
    final docRef = database.collection(collectionName).doc(docId);
    await docRef.update(data);
  }

  Future<void> delete(String collectionName, String docId) async {
    final docRef = database.collection(collectionName).doc(docId);
    await docRef.delete();
  }

  //isEqualTo
  Future<List<Map<String, dynamic>>> query(String collectionName, String field, dynamic value) async {
    final collection = database.collection(collectionName);
    final snapshot = await collection.where(field, isEqualTo: value).get();
    if (snapshot.docs.isEmpty) {
      throw Exception('No matching documents.');
    }
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }
  
}