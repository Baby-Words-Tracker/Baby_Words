import json
import os
import logging
from collections import Counter
from typing import Optional

WORDS_FILE_PATH = os.path.join(os.path.dirname(__file__), "3000_words.json")
WORD_DB = {}

# This maps the NLTK Universal Tags from your script directly to the Flutter app's PartOfSpeech enum format
UNIVERSAL_TAG_MAPPING = {
    "NOUN": "NOUN",
    "VERB": "VERB",
    "ADJ": "ADJECTIVE",
    "ADV": "ADVERB",
    "PRON": "PRONOUN",
    "ADP": "PREPOSITION",
    "CONJ": "CONJUNCTION",
    "DET": "ARTICLE",
    "NUM": "UNKNOWN",
    "PRT": "UNKNOWN",
    "X": "UNKNOWN",
    ".": "UNKNOWN",
    "UNKNOWN": "UNKNOWN"
}

if os.path.exists(WORDS_FILE_PATH):
    try:
        with open(WORDS_FILE_PATH, "r", encoding="utf-8") as f:
            raw_data = json.load(f)
            # Convert list to dict for O(1) lookup keyed by the word
            if isinstance(raw_data, list):
                for item in raw_data:
                    if isinstance(item, dict) and "word" in item:
                        WORD_DB[item["word"].lower()] = item
    except Exception as e:
        logging.error("Could not load or parse JSON file: %s", e)

_BROWN_WORD_POS: dict = {}
_BROWN_LOADED = False


def _load_brown_corpus() -> None:
    global _BROWN_WORD_POS, _BROWN_LOADED
    if _BROWN_LOADED:
        return
    _BROWN_LOADED = True  # Set before attempt so failures don't trigger retries
    try:
        from nltk.corpus import brown
        for w, tag in brown.tagged_words(tagset="universal"):
            w = w.lower()
            _BROWN_WORD_POS.setdefault(w, Counter())[tag] += 1
        logging.info("Brown corpus loaded with %d unique words.", len(_BROWN_WORD_POS))
    except Exception as e:
        logging.warning("Could not load Brown corpus: %s", e)


def get_pos_from_corpus(word: str) -> Optional[str]:
    """Returns POS from the NLTK Brown corpus (universal tagset), mapped to app format."""
    _load_brown_corpus()
    counts = _BROWN_WORD_POS.get(word.lower().strip())
    if not counts:
        return None
    raw_tag = counts.most_common(1)[0][0]
    return UNIVERSAL_TAG_MAPPING.get(raw_tag)


def get_pos_from_json(word: str) -> Optional[str]:
    """Returns the Part of Speech mapped to the app's format if found in the JSON."""
    normalized = word.lower().strip()
    entry = WORD_DB.get(normalized)
    
    raw_pos = None
    if isinstance(entry, str):
        raw_pos = entry.upper()
    elif isinstance(entry, dict):
        raw_pos = entry.get("part_of_speech", "").upper()
        
    if raw_pos:
        # Translate the NLTK tag to the App tag
        return UNIVERSAL_TAG_MAPPING.get(raw_pos, "UNKNOWN")
        
    return None