import 'package:baby_words_tracker/data/type_aware_services/type_aware_word_data_service.dart';
import 'package:baby_words_tracker/util/check_and_update_word.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

void buildWordBank(TypeAwareWordDataService wordDataService) async {
  List<String> words = List.empty(growable: true);
  final csvString = await rootBundle.loadString('assets/data.csv');

  // Parse the CSV
  final csvTable = const CsvToListConverter().convert(csvString);

  // Iterate over each row
  for (var row in csvTable) {
    words.add(row[0]);
  }

  for (String word in words) {
    await checkAndUpdateWord(word, wordDataService);
  }
}
