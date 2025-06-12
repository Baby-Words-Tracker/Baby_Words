enum PartOfSpeech {
  noun,
  verb,
  adjective,
  adverb,
  pronoun,
  personal_pronoun,
  preposition,
  conjunction,
  article,
  unknown,
}

extension PartofspeechExtension on PartOfSpeech {
  static final Map<String, PartOfSpeech> _partOfSpeechMap = (() {
    final map = <String, PartOfSpeech>{};
    for (var code in PartOfSpeech.values) {
      map[code.name] = code;
    }
    map['personal pronoun'] = PartOfSpeech.personal_pronoun;
    // can add custom mappings here if needed
    return map;
  })();

  String get displayName {
    switch (this) {
      case PartOfSpeech.noun:
        return "Noun";
      case PartOfSpeech.verb:
        return "Verb";
      case PartOfSpeech.adjective:
        return "Adjective";
      case PartOfSpeech.adverb:
        return "Adverb";
      case PartOfSpeech.pronoun:
        return "Pronoun";
      case PartOfSpeech.preposition:
        return "Preposition";
      case PartOfSpeech.conjunction:
        return "Conjunction";
      case PartOfSpeech.article:
        return "Article";
      default:
        return "Unknown";
    }
  }

  static PartOfSpeech fromString(String value) {
    if (value.isEmpty) {
      return PartOfSpeech.unknown;
    }
    value = value.toLowerCase().trim();
    return _partOfSpeechMap[value] ?? PartOfSpeech.unknown;
  }
}
