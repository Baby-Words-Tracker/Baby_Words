# Word & Phrase Enrichment Data Model

This document summarises the Firestore collections that support the enhanced word/phrase enrichment flow and the expected schema for each document.

## Collections

### `/Word/{wordId}`

Global wordbank entry keyed by the normalised word string.

| Field | Type | Notes |
|-------|------|-------|
| `language` | `string` | Language currently queued for processing (`en`, `es`). Removed when queue is empty. |
| `needsProcessing` | `bool` | `true` when at least one language requires enrichment. |
| `languageCodes` | `array<string>` | Set of languages where the word has been observed. |
| `languagesPending` | `array<string>` | Languages awaiting processing. Maintained client-side when queueing. |
| `languagesProcessed` | `array<string>` | Languages successfully enriched. |
| `languageDetails` | `map` | Per-language enrichment output keyed by ISO code (`en`, `es`, ...). |
| `createdAt` / `updatedAt` | `timestamp` | Basic audit fields. |

Within `languageDetails.{language}`:

| Field | Type | Notes |
|-------|------|-------|
| `lemma` | `string` | Lemma returned by spaCy. |
| `primaryPartOfSpeech` | `string` | Uppercase tag chosen as the primary POS (e.g. `NOUN`). |
| `allPOS` | `array<string>` | Unique POS tags gathered across all WordNet synsets for the word. |
| `primaryCategory` | `string` | Primary WordNet lexname for the word (e.g. `noun.animal`). |
| `allCategories` | `array<string>` | All lexnames observed across WordNet synsets. |
| `requestedAt` | `timestamp` | Set when processing was requested for this language. |
| `updatedAt` | `timestamp` | Last successful enrichment for the language. |

The Python Cloud Function updates the relevant `languageDetails.{language}` entry (lemma, POS, categories), appends the language to `languagesProcessed`, clears `language` when done, and toggles `needsProcessing` accordingly.

### `/Child/{childId}/WordTracker/{word}`

Per-child record of the first time the word was logged.

| Field | Type | Notes |
|-------|------|-------|
| `firstUtterance` | `timestamp` | When the parent recorded the word. |
| `language` | `string` | Language selected when the parent logged the word. |
| `note` | `string` | Optional contextual note. |
| `videoId` | `string` | Reference to the parent-scoped local video key. |
| `phraseId` | `string` | Optional link to the phrase tracker entry. |
| `phraseText` | `string` | The original phrase text when the word came from a phrase submission. |

### `/Child/{childId}/PhraseTracker/{phrase}`

Child-specific phrase entry. Phrases are stored using a normalised identifier (lower-case, collapsed whitespace).

| Field | Type | Notes |
|-------|------|-------|
| `phrase` | `string` | Original phrase text as entered by the parent. |
| `words` | `array<string>` | Normalised word identifiers derived client-side. |
| `language` | `string` | Language selected for the phrase. |
| `needsProcessing` | `bool` | Reserved for future phrase-level enrichment. |
| `createdAt` | `timestamp` | When the phrase was logged. |
| `note` | `string` | Optional note shared with the associated words. |
| `videoId` | `string` | Optional local video key reused by the words. |

## Security Rule Expectations

- Word documents remain globally readable/writable for authenticated users. Clients are expected to provide `language`, `needsProcessing`, and update the language tracking arrays appropriately.
- Under `/Child/{childId}` both `WordTracker` and `PhraseTracker` subcollections permit read/write for parents linked to the child and read-only access for researchers. Deletions remain disallowed.
- Researchers retain read-only access to words and trackers; writes continue to require parent authentication.

## Client Responsibilities

1. Normalise words/phrases before constructing document IDs (trim, lower case, collapse whitespace).
2. Queue words by calling `queueWordForProcessing`, which merges `languageCodes`, sets `needsProcessing`, and keeps the pending language list in sync.
3. Populate optional `note` and `videoId` consistently across both the word tracker and phrase tracker when the user attaches context or media.
4. Use the selected child’s configured languages when presenting the language selector (default to English if none are configured).

## Cloud Function Behaviour

The `process_word` Cloud Function listens for `/Word/{word}` writes with `needsProcessing == true`. It:

1. Loads the appropriate spaCy model (`en_core_web_sm` or `es_core_news_sm`).
2. Extracts lemma and part-of-speech for the word.
3. Uses WordNet (English or Multilingual) to derive a broad semantic category.
4. Writes the results back to the document and advances/removes the pending language queue.
5. Leaves `needsProcessing` untouched if an exception occurs so the word can be retried.

Unit tests for the Cloud Function live in `firebase-project/functions_python/tests/`.
