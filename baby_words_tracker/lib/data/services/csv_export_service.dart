import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/models/word.dart';
import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:baby_words_tracker/data/repositories/firestore_repository.dart';
import 'package:baby_words_tracker/data/repositories/i_firestore_repository.dart';
import 'package:baby_words_tracker/util/download_as_csv.dart';
import 'package:flutter/foundation.dart';

/// Service for exporting word tracking data to CSV format
/// Used by admin and research roles to download full word list with all associated data
class CsvExportService {
  final IFirestoreRepository fireRepo;

  CsvExportService({IFirestoreRepository? repository})
      : fireRepo = repository ?? FirestoreRepository();

  /// Exports all words from all children to a CSV file
  /// Excludes child names for anonymity
  /// Returns true if successful, false otherwise
  Future<bool> exportAllWordsToCSV() async {
    try {
      debugPrint("CsvExportService: Starting to export all words to CSV");

      // Get all children
      final allChildren = await _getAllChildren();
      if (allChildren.isEmpty) {
        debugPrint("CsvExportService: No children found in database");
        return false;
      }

      debugPrint(
          "CsvExportService: Found ${allChildren.length} children to process");

      // Collect all word data across all children
      List<List<String>> csvData = [];

      for (final child in allChildren) {
        debugPrint("CsvExportService: Processing child ${child.id}");

        // Get all word trackers for this child
        final wordTrackers =
            await fireRepo.readAllFromSubcollection(
                Child.collectionName, child.id!, WordTracker.collectionName);

        // Convert each word tracker to CSV row
        for (final trackerData in wordTrackers) {
          final tracker = WordTracker.fromDataWithId(trackerData);

          // Get word details from the global word list
          final word = await _getWordDetails(tracker.id ?? '');

          // Get language details for the tracker's language if it has one
          String lemma = '';
          String primaryPOS = '';
          String allPOS = '';
          String primaryCategory = '';
          String allCategories = '';

          if (word != null && tracker.language != null) {
            final langDetails = word.languageDetails[tracker.language];
            if (langDetails != null) {
              lemma = langDetails.lemma ?? '';
              primaryPOS = langDetails.primaryPartOfSpeech ?? '';
              allPOS = langDetails.allPOS.join(';');
              primaryCategory = langDetails.primaryCategory ?? '';
              allCategories = langDetails.allCategories.join(';');
            }
          }

          final csvRow = [
            child.id ?? '',
            // Exclude child name for anonymity
            tracker.id ?? '', // word/lemma
            tracker.firstUtterance.toIso8601String(),
            tracker.language?.name ?? '',
            lemma,
            primaryPOS,
            allPOS,
            primaryCategory,
            allCategories,
            tracker.note ?? '',
            tracker.videoId ?? '',
            tracker.phraseId ?? '',
            tracker.phraseText ?? '',
            child.wordCount.toString(),
            (child.language).map((l) => l.name).join(';'),
            child.birthday.toIso8601String(),
            tracker.language?.name ?? '',
          ];

          csvData.add(csvRow);
        }
      }

      if (csvData.isEmpty) {
        debugPrint("CsvExportService: No word data found to export");
        return false;
      }

      debugPrint("CsvExportService: Exporting ${csvData.length} word records");

      // Create CSV header
      final csvHeader = [
        'Child_ID',
        'Word',
        'First_Utterance_DateTime',
        'Word_Language',
        'Lemma',
        'Primary_Part_Of_Speech',
        'All_Parts_Of_Speech',
        'Primary_Category',
        'All_Categories',
        'Notes',
        'Video_ID',
        'Phrase_ID',
        'Phrase_Text',
        'Child_Total_Word_Count',
        'Child_Languages',
        'Child_Birthday',
        'Utterance_Language',
      ];

      // Download CSV
      await downloadAsCSV(csvHeader, csvData, "full_word_list");

      debugPrint(
          "CsvExportService: Successfully exported ${csvData.length} words to CSV");
      return true;
    } catch (e) {
      debugPrint("CsvExportService: Error exporting to CSV: $e\n$e");
      return false;
    }
  }

  /// Gets all children from the database
  Future<List<Child>> _getAllChildren() async {
    try {
      final allChildrenData = await fireRepo.readAll(Child.collectionName);
      return allChildrenData
          .map((childData) => Child.fromDataWithId(childData))
          .toList();
    } catch (e) {
      debugPrint("CsvExportService: Error getting all children: $e");
      return [];
    }
  }

  /// Gets word details from the global word list
  Future<Word?> _getWordDetails(String wordId) async {
    try {
      final word = await fireRepo.read(Word.collectionName, wordId);
      if (word == null) return null;
      return Word.fromDataWithId(word);
    } catch (e) {
      debugPrint("CsvExportService: Error getting word details for $wordId: $e");
      return null;
    }
  }
}
