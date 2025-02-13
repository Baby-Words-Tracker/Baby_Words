enum GraphType {
  newWordsPerDay,
  wordsByPartOfSpeech,
}

extension GraphTypeExtension on GraphType {
  String get displayName {
    switch (this) {
      case GraphType.newWordsPerDay:
        return "New Words / Day";
      case GraphType.wordsByPartOfSpeech:
        return "Number of Words by Part of Speech";
      default:
        return "Unknown";
    }
  }

  static GraphType fromString(String text){
    if (text == GraphType.newWordsPerDay.displayName) {
      return GraphType.newWordsPerDay;
    }
    return GraphType.newWordsPerDay;
  }
}
