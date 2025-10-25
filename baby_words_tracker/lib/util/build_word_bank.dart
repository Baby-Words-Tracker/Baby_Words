import 'package:baby_words_tracker/data/services/word_data_service.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/text_entry_utils.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';

void buildWordBank(WordDataService wordDataService) async {
  List<String> words = List.empty(growable: true);
  final csvString = await rootBundle.loadString('assets/data.csv');

  // Parse the CSV
  final csvTable = const CsvToListConverter().convert(csvString);

  // Iterate over each row
  for (var row in csvTable) {
    words.add(row[0]);
  }

  for (String word in words) {
    await wordDataService.queueWordForProcessing(
      wordId: normaliseForDocumentId(word),
      language: LanguageCode.en,
    );
  }
}
