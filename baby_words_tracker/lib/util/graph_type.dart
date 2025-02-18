enum GraphType {
  newWordsPerDay,
  wordsByPartOfSpeech,
}

extension GraphTypeExtension on GraphType {
  String get displayName {
    switch (this) {
      case GraphType.newWordsPerDay:
        return "New Words Per Day";
      case GraphType.wordsByPartOfSpeech:
        return "Total Number of Words by Part of Speech";
      default:
        return "Unknown";
    }
  }
  String get optionName {
    switch (this) {
      case GraphType.newWordsPerDay:
        return "Words Learned / Day";
      case GraphType.wordsByPartOfSpeech:
        return "All Words / Part of Speech";
      default:
        return "Unknown";
    }
  }

  static GraphType fromDisplayName(String text){
    for (var graphType in GraphType.values) {
      if (text == graphType.displayName) {
        return graphType;
      }
    }
    return GraphType.newWordsPerDay;
  }

  static GraphType fromOptionName(String text){
    for (var graphType in GraphType.values) {
      if (text == graphType.optionName) {
        return graphType;
      }
    }
    return GraphType.newWordsPerDay;
  }
}
