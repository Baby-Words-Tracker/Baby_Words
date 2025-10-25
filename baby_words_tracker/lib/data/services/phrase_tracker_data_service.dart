import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/models/phrase_tracker.dart';
import 'package:baby_words_tracker/data/repositories/firestore_repository.dart';
import 'package:baby_words_tracker/data/repositories/i_firestore_repository.dart';
import 'package:flutter/foundation.dart';

class PhraseTrackerDataService {
  PhraseTrackerDataService({IFirestoreRepository? repository})
      : _fireRepo = repository ?? FirestoreRepository();

  final IFirestoreRepository _fireRepo;

  Future<PhraseTracker?> upsertPhraseTracker(
    PhraseTracker phrase,
  ) async {
    final success = await _fireRepo.setSubcollectionDocument(
      Child.collectionName,
      phrase.childId,
      PhraseTracker.collectionName,
      phrase.id,
      phrase.toMap(),
      merge: true,
    );

    if (!success) {
      debugPrint(
          'PhraseTrackerDataService: Failed to upsert phrase tracker ${phrase.id}');
      return null;
    }

    return phrase;
  }

  Future<bool> deletePhraseTracker({
    required String childId,
    required String phraseId,
  }) async {
    final success = await _fireRepo.deleteSubcollectionDocument(
      Child.collectionName,
      childId,
      PhraseTracker.collectionName,
      phraseId,
    );

    if (!success) {
      debugPrint(
        'PhraseTrackerDataService: Failed to delete phrase tracker $phraseId',
      );
    }

    return success;
  }
}
