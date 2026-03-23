"""Cloud Function entry point for Word enrichment."""
import os
import sys
import logging
from dataclasses import dataclass
from typing import Dict, List, Optional, Set


NLTK_DATA_PATH = os.path.join(os.path.dirname(__file__), "nltk_data")

import firebase_admin
from firebase_admin import firestore
from firebase_functions import firestore_fn

try:
    from word_lookup import get_pos_from_json, get_pos_from_corpus
except ImportError:
    logging.warning("Could not import 'word_lookup.py'. The JSON word list and Brown corpus will not be used.")
    def get_pos_from_json(word: str) -> None:
        return None
    def get_pos_from_corpus(word: str) -> None:
        return None

# Initialise Firebase app once at import time.
app = firebase_admin.initialize_app()

_MODEL_CACHE = {}

_LANGUAGE_MODEL = {
    "en": "en_core_web_sm",
    "es": "es_core_news_sm",
}

_POS_MAPPING = {
    "ADJ": "adjective",
    "ADP": "preposition",
    "ADV": "adverb",
    "AUX": "verb",
    "INTJ": "interjection",
    "NOUN": "noun",
    "PROPN": "noun",
    "PRON": "pronoun",
    "VERB": "verb",
    "CCONJ": "conjunction",
    "SCONJ": "conjunction",
    "DET": "article",
}

_WORDNET_POS_LABEL = {
    "n": "NOUN",
    "v": "VERB",
    "a": "ADJECTIVE",
    "s": "ADJECTIVE",
    "r": "ADVERB",
}


@dataclass
class EnrichmentResult:
    lemma: str
    language_part_of_speech: str
    primary_part_of_speech: str
    primary_category: Optional[str]
    all_pos: List[str]
    all_categories: List[str]


def _load_model(language: str) -> "spacy.Language":
    model_name = _LANGUAGE_MODEL.get(language)
    if model_name not in _MODEL_CACHE:
        import spacy
        _MODEL_CACHE[model_name] = spacy.load(model_name)
    return _MODEL_CACHE[model_name]


def _enrich_word(word: str, language: str) -> EnrichmentResult:
    model = _load_model(language)
    doc = model(word)
    token = next((token for token in doc if token.is_alpha), None)
    if token is None:
        raise ValueError("Word contains no alphabetic characters")

    # 1. Get the spaCy guess
    part_of_speech = _POS_MAPPING.get(token.pos_, "unknown")
    spacy_primary_pos = part_of_speech.replace(" ", "_").upper()
    lemma = token.lemma_.lower()
    lang_code = "spa" if language == "es" else "eng"

    # 2. OVERRIDE with JSON lookup, then Brown corpus, then fall back to spaCy (English only)
    primary_part_of_speech = spacy_primary_pos
    if language == "en":
        json_pos = get_pos_from_json(word)
        if json_pos:
            primary_part_of_speech = json_pos
        else:
            corpus_pos = get_pos_from_corpus(word)
            if corpus_pos:
                primary_part_of_speech = corpus_pos

    categories: Set[str] = set()
    pos_labels: Set[str] = {primary_part_of_speech}

    try:
        import nltk
        nltk.data.path.insert(0, NLTK_DATA_PATH)
        os.environ.setdefault("NLTK_DATA", NLTK_DATA_PATH)
        from nltk.corpus import wordnet
        synsets = wordnet.synsets(word, lang=lang_code)
    except LookupError:
        synsets = []

    for synset in synsets:
        categories.add(synset.lexname())
        pos_label = _WORDNET_POS_LABEL.get(synset.pos())
        if pos_label:
            pos_labels.add(pos_label)

    all_categories = sorted(categories)
    primary_category = all_categories[0] if all_categories else None

    return EnrichmentResult(
        lemma=lemma,
        language_part_of_speech=part_of_speech,
        primary_part_of_speech=primary_part_of_speech,  # This will use the JSON value
        primary_category=primary_category,
        all_pos=sorted(pos_labels),
        all_categories=all_categories,
    )


def _update_document(
    snapshot: firestore.DocumentSnapshot,
    language: str,
    enrichment: EnrichmentResult,
    pending_languages: set[str],
    existing_data: Dict[str, object],
) -> None:
    remaining = sorted(pending_languages - {language})

    language_details = existing_data.get("languageDetails")
    if isinstance(language_details, dict):
        existing_detail = language_details.get(language, {})
        if not isinstance(existing_detail, dict):
            existing_detail = {}
    else:
        existing_detail = {}

    existing_all_pos = set(existing_detail.get("allPOS") or [])
    combined_all_pos = sorted(existing_all_pos.union(enrichment.all_pos))

    existing_all_categories = set(existing_detail.get("allCategories") or [])
    combined_all_categories = sorted(
        existing_all_categories.union(enrichment.all_categories)
    )

    detail_path = f"languageDetails.{language}"
    updates: Dict[str, object] = {
        f"{detail_path}.lemma": enrichment.lemma,
        f"{detail_path}.primaryPartOfSpeech": enrichment.primary_part_of_speech,
        f"{detail_path}.allPOS": combined_all_pos,
        f"{detail_path}.allCategories": combined_all_categories,
        f"{detail_path}.updatedAt": firestore.SERVER_TIMESTAMP,
        "languagesProcessed": firestore.ArrayUnion([language]),
        "languagesPending": firestore.ArrayRemove([language]),
        "needsProcessing": bool(remaining),
    }

    if enrichment.primary_category:
        updates[f"{detail_path}.primaryCategory"] = enrichment.primary_category
    else:
        updates[f"{detail_path}.primaryCategory"] = firestore.DELETE_FIELD

    if remaining:
        updates["language"] = remaining[0]
    else:
        updates["language"] = firestore.DELETE_FIELD

    snapshot.reference.update(updates)


def _propagate_pos_to_trackers(word_id: str, language: str, pos: str) -> None:
    """Updates all WordTracker documents for this word with the determined part of speech."""
    client = firestore.client()
    # Query all WordTrackers for this word.
    # IMPORTANT: This requires a Collection Group Index on 'id' for 'WordTracker'.
    # Note: Filtering by language in code to avoid requiring a composite index immediately.
    trackers = client.collection_group("WordTracker").where("id", "==", word_id).stream()

    batch = client.batch()
    count = 0
    updates_made = False

    for doc in trackers:
        data = doc.to_dict()
        # Ensure we only update trackers for the correct language
        # Relaxed check: ensure language matches if present, or update if missing
        if data.get("language") == language or data.get("language") is None:
            batch.update(doc.reference, {"partOfSpeech": pos})
            count += 1
            updates_made = True

        if count >= 400:
            batch.commit()
            batch = client.batch()
            count = 0
            updates_made = False

    if updates_made:
        logging.info("Propagating POS '%s' to %d trackers for word '%s'", pos, count, word_id)
        batch.commit()


@firestore_fn.on_document_written(document="Word/{wordId}", region="us-central1", memory=1024, timeout_sec = 540)
def process_word(event: firestore_fn.Event[firestore.DocumentSnapshot]) -> None:
    snapshot = event.data.after
    if snapshot is None or not snapshot.exists:
        return

    data = snapshot.to_dict() or {}
    if not data.get("needsProcessing"):
        return

    language = data.get("language")
    if not isinstance(language, str):
        logging.warning("Word/%s missing valid language field", snapshot.id)
        return

    pending = {
        *(data.get("languagesPending") or []),
        language,
    }

    try:
        enrichment = _enrich_word(snapshot.id, language)
    except Exception as error:  # pragma: no cover - spaCy/NLTK runtime failures
        logging.exception("Failed to enrich word %s (%s): %s", snapshot.id, language, error)
        return

    _update_document(snapshot, language, enrichment, pending, data)

    try:
        _propagate_pos_to_trackers(snapshot.id, language, enrichment.primary_part_of_speech.lower())
    except Exception as error:
        logging.warning("Failed to propagate POS to trackers for %s: %s", snapshot.id, error)
