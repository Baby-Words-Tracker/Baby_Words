import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:baby_words_tracker/data/services/word_tracker_data_service.dart';
import 'package:baby_words_tracker/data/type_aware_services/i_type_aware_data_service.dart';

class TypeAwareWordTrackerDataService extends ITypeAwareDataService {
  final WordTrackerDataService _wordTrackerDataService;

  TypeAwareWordTrackerDataService({
    required super.userModelService,
    required WordTrackerDataService wordTrackerDataService,
  }) : _wordTrackerDataService = wordTrackerDataService;

  Future<WordTracker?> createWordTracker(
    String childId,
    String word,
    WordTracker tracker,
  ) {
    return _wordTrackerDataService.createWordTracker(
      childId,
      word,
      tracker,
      isDemoType,
    );
  }

  Future<bool> updateWordTracker(
    String childId,
    String wordID, {
    DateTime? firstUtterance,
    String? videoID,
  }) {
    return _wordTrackerDataService.updateWordTracker(
      childId,
      wordID,
      isDemoType,
      firstUtterance: firstUtterance,
      videoID: videoID,
    );
  }

  Future<bool> addOrUpdateWordTracker(
    String childId,
    String wordId,
    WordTracker wordTracker,
  ) {
    return _wordTrackerDataService.addOrUpdateWordTracker(
      childId,
      wordId,
      wordTracker,
      isDemoType,
    );
  }

  Future<WordTracker?> getWordTracker(String childId, String id) {
    return _wordTrackerDataService.getWordTracker(
      childId,
      id,
      isDemoType,
    );
  }

  Future<List<WordTracker>> getWordsFromTime(
    String childId,
    DateTime time,
  ) {
    return _wordTrackerDataService.getWordsFromTime(
      childId,
      time,
      isDemoType,
    );
  }

  Future<List<WordTracker>> getWordsFromDate(
    String childId,
    DateTime date,
  ) {
    return _wordTrackerDataService.getWordsFromDate(
      childId,
      date,
      isDemoType,
    );
  }

  Future<List<WordTracker>> getWordsFromDateRange(
    String childId,
    DateTime date,
    int range,
  ) {
    return _wordTrackerDataService.getWordsFromDateRange(
      childId,
      date,
      range,
      isDemoType,
    );
  }
}
