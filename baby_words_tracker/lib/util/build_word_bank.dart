import 'package:baby_words_tracker/data/models/word.dart';
import 'package:baby_words_tracker/util/check_and_update_words.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'dart:io';

void build_word_bank() async {
  List<String> words= List.empty(growable: true);
  /* final input = File('../../assests/data.csv').openRead();
  final fields = await input.transform(utf8.decoder).transform(const CsvToListConverter()).toList(); */
  final csvString = await rootBundle.loadString('assets/data.csv');

  // Parse the CSV
  final csvTable = const CsvToListConverter().convert(csvString);

  // Iterate over each row
  for (var row in csvTable) {
    words.add(row[0]); 
  }
  final wordsFound = words.length;
  print("number of words found: $wordsFound");

  int addedWords = 0;
  for (String word in words) {
    final checkedWord = checkAndUpdateWords(word);
    if (checkedWord != null) addedWords++; 
  }
  
  print(addedWords); 
}