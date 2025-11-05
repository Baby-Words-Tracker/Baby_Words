import 'package:baby_words_tracker/util/language_code.dart';

/// Entry modes available on the add text screen.
enum EntryMode { word, phrase }

final RegExp _alphaWordPattern = RegExp(r'^[A-Za-zÀ-ÖØ-öø-ÿ]+$');
final RegExp _alphaPhrasePattern = RegExp(r'^[A-Za-zÀ-ÖØ-öø-ÿ ]+$');

/// Normalises a text input so it can be used as a Firestore document ID.
///
/// The text is trimmed, converted to lower case, and multiple internal spaces
/// are collapsed into single spaces. This preserves diacritics so Spanish
/// entries remain readable while still enforcing a consistent key.
String normaliseForDocumentId(String raw) {
  final collapsed = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  return collapsed.toLowerCase();
}

/// Splits a phrase into normalised words that can be stored in `/Word/{id}`.
List<String> extractWords(String phrase) {
  final cleanedParts = phrase
      .trim()
      .split(RegExp(r'\s+'))
      .map((part) => part.replaceAll(RegExp(r'[^A-Za-zÀ-ÖØ-öø-ÿ]'), ''))
      .where((part) => part.isNotEmpty)
      .toList();

  return cleanedParts.map(normaliseForDocumentId).toList();
}

/// Validates a single word entry. Returns `null` when valid or an error message.
String? validateWord(String word) {
  final trimmed = word.trim();
  if (trimmed.isEmpty) {
    return 'Please enter a word.';
  }
  if (!_alphaWordPattern.hasMatch(trimmed)) {
    return 'Words can only include alphabetic characters.';
  }
  if (trimmed.contains(' ')) {
    return 'Only single words are allowed in Word mode.';
  }
  return null;
}

/// Validates a phrase entry. Returns `null` when valid or an error message.
String? validatePhrase(String phrase) {
  final collapsed = phrase.trim();
  if (collapsed.isEmpty) {
    return 'Please enter a phrase.';
  }
  if (!_alphaPhrasePattern.hasMatch(collapsed)) {
    return 'Phrases can include spaces but only alphabetic characters.';
  }
  final pieces = extractWords(collapsed);
  if (pieces.isEmpty) {
    return 'Unable to find any words in the phrase.';
  }
  return null;
}

/// Maps a [LanguageCode] to a display string to show in the selector.
String languageDisplayName(LanguageCode code) => code.displayName;
