import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

/*
 * WordbankService (Firebase Version)
 * * This class fetches all necessary WordBank analytical data from Firestore.
 * It caches the large, static data (norms/categories) locally after the first fetch
 * to ensure subsequent lookups are instant and cost-free.
 * * Collections accessed in Firestore:
 * - vocab_production_percentiles (Doc per age: "18", "24", etc.)
 * - vocab_comprehension_percentiles (Doc per age: "18", "24", etc.)
 * - word_norms (Single large doc: 'norm_map')
 * - word_to_category (Single large doc: 'category_map')
 */

class WordbankService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Static cache for large, infrequently changing maps (word norms/categories)
  Map<String, dynamic> _wordNormsCache = {};
  Map<String, dynamic> _wordCategoryCache = {};

  bool get isReady => _wordNormsCache.isNotEmpty && _wordCategoryCache.isNotEmpty;

  /// Loads the two largest, most complex data maps (Norms and Categories)
  /// from their single-document storage location in Firestore into local memory.
  Future<void> loadStaticData() async {
    if (isReady) return;

    try {
      // 1. Fetch Word Norms (from the single 'norm_map' document)
      final normDoc = await _db.collection('word_norms').doc('norm_map').get();
      if (normDoc.exists && normDoc.data() != null) {
        _wordNormsCache = normDoc.data()!;
      } else {
        print('ERROR: Word norms document not found (word_norms/norm_map).');
      }

      // 2. Fetch Word Categories (from the single 'category_map' document)
      final categoryDoc = await _db.collection('word_to_category').doc('category_map').get();
      if (categoryDoc.exists && categoryDoc.data() != null) {
        // The data is the map we need
        _wordCategoryCache = categoryDoc.data()!;
      } else {
        print('ERROR: Word category document not found (word_to_category/category_map).');
      }

    } catch (e) {
      print('CRITICAL ERROR loading Wordbank static data from Firestore: $e');
    }
  }

  // --- Insight 1: Vocabulary Size Percentiles (Production and Comprehension) ---

  Future<String> _getVocabularyPercentile(
      int childAgeInMonths, int wordCount, String collectionName, String measureType) async {
    final ageKey = childAgeInMonths.toString();
    
    try {
      // Direct document read by age ID
      final doc = await _db.collection(collectionName).doc(ageKey).get();

      if (!doc.exists || doc.data() == null) {
        return "No $measureType percentile data available for age $ageKey months.";
      }

      final norms = doc.data()!;
      
      // Compare from the top down
      if (wordCount > (norms['90'] as num).toInt()) {
        return "Your child $measureType $wordCount words, which is in the top 10% (above 90th percentile) for $ageKey-month-olds.";
      }
      if (wordCount > (norms['75'] as num).toInt()) {
        return "Your child $measureType $wordCount words, which is in the 75th-90th percentile for $ageKey-month-olds.";
      }
      // if (wordCount > (norms['50'] as num).toInt()) {
      //   return "Your child $measureType $wordCount words, which is in the 50th-75th percentile for $ageKey-month-olds.";
      // }
      // if (wordCount > (norms['25'] as num).toInt()) {
      //   return "Your child $measureType $wordCount words, which is in the 25th-50th percentile for $ageKey-month-olds.";
      // }
      
      return "Your child $measureType $wordCount words";
      
    } catch (e) {
      print("Error fetching $measureType percentile data: $e");
      return "Could not load $measureType vocabulary insights right now.";
    }
  }

  Future<String> getProductionPercentile(int age, int count) => 
      _getVocabularyPercentile(age, count, 'vocab_production_percentiles', 'says');
      
  Future<String> getComprehensionPercentile(int age, int count) => 
      _getVocabularyPercentile(age, count, 'vocab_comprehension_percentiles', 'understands');


  // --- Insight 2: Vocabulary by Category ---

  String getVocabularyByCategory(List<String> loggedWords) {
    if (_wordCategoryCache.isEmpty) {
      return "Category Breakdown:\n  - Analytical data not loaded yet.";
    }
    
    final categoryCounts = <String, int>{};
    final totalWords = loggedWords.length;
    
    if (totalWords == 0) {
      return "Category Breakdown:\n  - No words logged yet.";
    }

    for (final word in loggedWords) {
      final standardizedWord = word.toLowerCase().trim();
      
      // Look up the category in the local cache
      // The cache is a Map<String, dynamic> where value is the category name (e.g., "People")
      final category = _wordCategoryCache[standardizedWord] as String? ?? "Uncategorized";
      
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }
    
    // Format the results for display
    var output = "Category Breakdown:\n";
    final sortedCounts = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedCounts) {
      final percentage = (entry.value / totalWords * 100).round();
      output += "  - ${entry.key}: ${entry.value} words (${percentage}% of total)\n";
    }
        
    return output;
  }

  // --- Insight 3 & 4: Word Norms and Suggested Words ---

  String getWordSpecificInsight(String word, int age) {
    if (_wordNormsCache.isEmpty) {
      return "Word Insight: Analytical data not loaded yet.";
    }
    
    final ageKey = age.toString();
    final standardizedWord = word.toLowerCase().trim();
    
    // Word data is a nested map: {"word": {"age": proportion}}
    final wordData = _wordNormsCache[standardizedWord] as Map<String, dynamic>?;
    
    if (wordData == null) {
      return "Word Insight: '$word' is a unique word not in the dataset.";
    }
    
    if (!wordData.containsKey(ageKey)) {
      return "Word Insight: No specific data for '$word' at $age months.";
    }
    
    final proportion = (wordData[ageKey] as num).toDouble();
    final percentage = (proportion * 100).round();

    return "Word Insight: At $age months, $percentage% of children also know '$word'.";
  }


  String getSuggestedWords(List<String> loggedWords, int age, {int limit = 4}) {
    if (_wordNormsCache.isEmpty) {
      return "Words to Listen For: Analytical data not loaded yet.";
    }
    
    final ageKey = age.toString();
    final suggestions = <MapEntry<String, double>>[];
    final loggedSet = loggedWords.map((w) => w.toLowerCase().trim()).toSet();

    // 1. Iterate over the entire word norm database (the cached map)
    _wordNormsCache.forEach((word, ageMap) {
      
      // Skip if the child already knows it
      if (loggedSet.contains(word)) return;
      
      // Check for the proportion at the child's age
      if (ageMap is Map<String, dynamic> && ageMap.containsKey(ageKey)) {
        final proportion = (ageMap[ageKey] as num).toDouble();
        
        // CRITERIA: Suggest words known by 50-75% of children
        if (0.50 < proportion && proportion <= 0.75) {
          suggestions.add(MapEntry(word, proportion));
        }
      }
    });
                
    // 2. Sort by the highest proportion first (most likely to be learned next)
    suggestions.sort((a, b) => b.value.compareTo(a.value));
    
    var output = "Words to Listen For (Aged $age months):\n";
    if (suggestions.isEmpty) {
        output += "  - Your child is logging all the common words! Keep up the great work.";
        return output;
    }

    // 3. Limit the output list
    for (final entry in suggestions.take(limit)) {
        final percentage = (entry.value * 100).round();
        output += "  - ${entry.key} (${percentage}% of $age-month-olds know this)\n";
    }
        
    return output;
  }
}