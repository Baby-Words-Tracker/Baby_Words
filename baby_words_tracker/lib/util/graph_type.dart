enum GraphType {
  newWordsPerDay,
  wordsByPartOfSpeech,
}

extension GraphTypeExtension on GraphType {
  String get displayName {
    return switch (this) {
      GraphType.newWordsPerDay => "New Words Per Day",
      GraphType.wordsByPartOfSpeech =>
        "Total Number of Words by Part of Speech",
    };
  }

  String get optionName {
    return switch (this) {
      GraphType.newWordsPerDay => "Words Learned / Day",
      GraphType.wordsByPartOfSpeech => "All Words / Part of Speech",
    };
  }

  static GraphType fromDisplayName(String text) {
    for (var graphType in GraphType.values) {
      if (text == graphType.displayName) {
        return graphType;
      }
    }
    return GraphType.newWordsPerDay;
  }

  static GraphType fromOptionName(String text) {
    for (var graphType in GraphType.values) {
      if (text == graphType.optionName) {
        return graphType;
      }
    }
    return GraphType.newWordsPerDay;
  }
}
