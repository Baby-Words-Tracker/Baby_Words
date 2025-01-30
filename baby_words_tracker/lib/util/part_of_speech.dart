enum PartOfSpeech {
  noun,
  verb,
  adjective,
  adverb,
  pronoun,
  preposition,
  conjunction,
  arcticle,
  unknown,
}


extension PartofspeechExtension on PartOfSpeech {
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
      case PartOfSpeech.arcticle:
        return "Article";
      default:
        return "Unknown";
    }
  }
}