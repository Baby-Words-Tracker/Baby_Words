import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:baby_words_tracker/data/listeners/i_document_listener.dart';
import 'package:baby_words_tracker/data/models/data_with_id.dart';
import 'package:baby_words_tracker/data/repositories/firestore_repository.dart';

class FirestoreDocumentListener<T> extends IDocumentListener<T> {
  final FirestoreRepository _firestoreRepository;
  late final StreamSubscription<DocumentSnapshot> _subscription;
  late Completer<void> _firstDocumentCompleter;

  FirestoreDocumentListener({
    required FirestoreRepository firestoreRepository,
    required String path,
    required T Function(DataWithId data) convertDataWithId,
  }) : _firestoreRepository = firestoreRepository {
    _firstDocumentCompleter = Completer<void>();

    _subscription =
        _firestoreRepository.getDocumentReference(path).snapshots().listen(
      (DocumentSnapshot doc) {
        // check if document exists
        if (!doc.exists) {
          data = null;
          notifyListeners();
          debugPrint(
              'FirestoreDocumentListener: (path: $path) Document does not exist');
          if (!_firstDocumentCompleter.isCompleted) {
            _firstDocumentCompleter.complete();
          }
          return;
        }
        if (doc.data() == null) {
          data = null;
          notifyListeners();
          debugPrint(
              'FirestoreDocumentListener: (path: $path) Document data is null');
          // if (!_firstDocumentCompleter.isCompleted) {
          //   _firstDocumentCompleter.complete();
          // }
          return;
        }

        data = convertDataWithId(DataWithId.fromFirestore(doc));
        debugPrint(
            'FirestoreDocumentListener: (path: $path) Document updated: $data');
        if (!_firstDocumentCompleter.isCompleted) {
          _firstDocumentCompleter.complete();
        }
        notifyListeners();
      },
      onError: (Object localError) {
        error = localError;
        debugPrint(
            "DocumentSnapshotListener: (path: $path) Error: $localError");
        data == null;
        notifyListeners();
      },
    );
  }

  // Wait for the first document to be fetched
  @override
  Future<void> waitForFirstDocument() {
    if (!_firstDocumentCompleter.isCompleted) {
      return _firstDocumentCompleter.future;
    }
    // TODO: remove
    debugPrint('FirestoreDocumentListener: First document already received');

    // If the completer is already completed, return a completed future
    // to avoid waiting for the first document again
    return Future.value();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
