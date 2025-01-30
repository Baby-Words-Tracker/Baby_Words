// See Wikipedia for a list of language codes: https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes

enum LanguageCode {
  en,  // English
  es,  // Spanish
  fr,  // French
  de,  // German
  it,  // Italian
  zh,  // Chinese
  ja,  // Japanese
  ko,  // Korean
  ar,  // Arabic
  ru,  // Russian
  // Add more as needed
}


extension LanguageCodeExtension on LanguageCode {
  String get displayName {
    switch (this) {
      case LanguageCode.en:
        return "English";
      case LanguageCode.es:
        return "Spanish";
      case LanguageCode.fr:
        return "French";
      case LanguageCode.de:
        return "German";
      case LanguageCode.it:
        return "Italian";
      case LanguageCode.zh:
        return "Chinese";
      case LanguageCode.ja:
        return "Japanese";
      case LanguageCode.ko:
        return "Korean";
      case LanguageCode.ar:
        return "Arabic";
      case LanguageCode.ru:
        return "Russian";
      default:
        return "Unknown";
    }
  }
}

