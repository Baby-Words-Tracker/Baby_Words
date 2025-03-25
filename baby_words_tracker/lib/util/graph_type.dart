enum StatType {
  newWordsPerDay,
  wordsByPartOfSpeech,
  numWordsInTop3000
}

extension StatTypeExtension on StatType {
  String get displayName {
    switch (this) {
      case StatType.newWordsPerDay:
        return "New Words Per Day";
      case StatType.wordsByPartOfSpeech:
        return "Total Number of Words by Part of Speech";
      case StatType.numWordsInTop3000:
        return "Number of Top 3000 Most Common English Words Learned";
      default:
        return "Unknown";
    }
  }
  
  String get optionName {
    switch (this) {
      case StatType.newWordsPerDay:
        return "Words Learned / Day";
      case StatType.wordsByPartOfSpeech:
        return "All Words / Part of Speech";
      case StatType.numWordsInTop3000:
        return "Number of Top 300 Words";
      default:
        return "Unknown";
    }
  }

  static StatType fromDisplayName(String text){
    for (var statType in StatType.values) {
      if (text == statType.displayName) {
        return statType;
      }
    }
    return StatType.newWordsPerDay;
  }

  static StatType fromOptionName(String text){
    for (var statType in StatType.values) {
      if (text == statType.optionName) {
        return statType;
      }
    }
    return StatType.newWordsPerDay;
  }
}
