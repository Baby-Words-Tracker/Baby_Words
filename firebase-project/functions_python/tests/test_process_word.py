import types
import unittest
from pathlib import Path
from unittest import mock

import os
import sys
import types as modtypes

project_root = Path(__file__).resolve().parents[2]
sys.path.append(str(project_root))

os.environ.setdefault("NLTK_PREFETCH_DISABLE", "1")

# Stub firebase_admin
firebase_admin_module = modtypes.ModuleType("firebase_admin")
firestore_module = modtypes.ModuleType("firebase_admin.firestore")
firestore_module.ArrayUnion = lambda items: ("ArrayUnion", items)
firestore_module.ArrayRemove = lambda items: ("ArrayRemove", items)
firestore_module.DELETE_FIELD = object()
firestore_module.SERVER_TIMESTAMP = object()
firestore_module.DocumentSnapshot = object
firebase_admin_module.initialize_app = lambda: None
firebase_admin_module.firestore = firestore_module
sys.modules.setdefault("firebase_admin", firebase_admin_module)
sys.modules.setdefault("firebase_admin.firestore", firestore_module)

# Stub firebase_functions
firebase_functions_module = modtypes.ModuleType("firebase_functions")
firestore_fn_module = modtypes.ModuleType("firebase_functions.firestore_fn")

def _identity_trigger(*_, **__):
    def decorator(func):
        return func

    return decorator

firestore_fn_module.on_document_written = _identity_trigger
class _DummyEvent:
    def __class_getitem__(cls, _item):
        return cls


firestore_fn_module.Event = _DummyEvent
firebase_functions_module.firestore_fn = firestore_fn_module
sys.modules.setdefault("firebase_functions", firebase_functions_module)
sys.modules.setdefault("firebase_functions.firestore_fn", firestore_fn_module)

# Stub nltk + wordnet
wordnet_module = modtypes.ModuleType("nltk.corpus.wordnet")
wordnet_module.NOUN = "n"
wordnet_module.VERB = "v"
wordnet_module.ADJ = "a"
wordnet_module.ADV = "r"
wordnet_module.synsets = lambda *_, **__: []

nltk_module = modtypes.ModuleType("nltk")
nltk_data_namespace = modtypes.SimpleNamespace(find=lambda *_, **__: None)
nltk_data_namespace.path = []
nltk_module.data = nltk_data_namespace
nltk_module.download = lambda *_: None
nltk_module.corpus = modtypes.SimpleNamespace(wordnet=wordnet_module)

sys.modules.setdefault("nltk", nltk_module)
sys.modules.setdefault("nltk.corpus", modtypes.SimpleNamespace(wordnet=wordnet_module))
sys.modules.setdefault("nltk.corpus.wordnet", wordnet_module)

# Stub spacy
spacy_module = modtypes.ModuleType("spacy")
spacy_module.load = lambda *_: None
sys.modules.setdefault("spacy", spacy_module)

from functions_python import main


class DummyToken:
    def __init__(self, text: str, pos: str, lemma: str):
        self.text = text
        self.pos_ = pos
        self.lemma_ = lemma
        self.is_alpha = text.isalpha()


class DummyDoc(list):
    def __init__(self, token: DummyToken):
        super().__init__([token])


def make_mock_model(token: DummyToken):
    def _call(_):
        return DummyDoc(token)

    return _call


class DummySynset:
    def __init__(self, lexname: str, pos: str):
        self._lexname = lexname
        self._pos = pos

    def lexname(self):
        return self._lexname

    def pos(self):
        return self._pos


class ProcessWordTests(unittest.TestCase):
    def test_enrich_word_maps_pos(self):
        token = DummyToken("gatos", "NOUN", "gato")
        synsets = [
            DummySynset("noun.animal", "n"),
            DummySynset("verb.cognition", "v"),
        ]
        with mock.patch.object(main, "_load_model", return_value=make_mock_model(token)), \
                mock.patch.object(main.wordnet, "synsets", return_value=synsets):
            result = main._enrich_word("gatos", "es")

        self.assertEqual(result.lemma, "gato")
        self.assertEqual(result.language_part_of_speech, "noun")
        self.assertEqual(result.primary_part_of_speech, "NOUN")
        self.assertEqual(result.primary_category, "noun.animal")
        self.assertIn("NOUN", result.all_pos)
        self.assertIn("VERB", result.all_pos)
        self.assertIn("noun.animal", result.all_categories)
        self.assertIn("verb.cognition", result.all_categories)

    def test_update_document_clears_language(self):
        reference = mock.Mock()
        snapshot = mock.Mock()
        snapshot.reference = reference

        enrichment = main.EnrichmentResult(
            lemma="cat",
            language_part_of_speech="noun",
            primary_part_of_speech="NOUN",
            primary_category="noun.animal",
            all_pos=["NOUN"],
            all_categories=["noun.animal"],
        )

        existing = {
            "languageDetails": {
                "en": {
                    "allPOS": ["ADJ"],
                    "allCategories": ["adj.all"],
                }
            }
        }

        main._update_document(snapshot, "en", enrichment, {"en"}, existing)

        update_payload = reference.update.call_args.kwargs or reference.update.call_args.args[0]
        self.assertEqual(
            update_payload["languageDetails.en.lemma"], "cat"
        )
        self.assertEqual(
            update_payload["languageDetails.en.primaryPartOfSpeech"], "NOUN"
        )
        self.assertEqual(
            update_payload["languageDetails.en.primaryCategory"], "noun.animal"
        )
        self.assertEqual(
            update_payload["languageDetails.en.allPOS"], ["ADJ", "NOUN"]
        )
        self.assertEqual(
            update_payload["languageDetails.en.allCategories"],
            ["adj.all", "noun.animal"],
        )
        self.assertFalse(update_payload["needsProcessing"])
        self.assertIs(update_payload["language"], main.firestore.DELETE_FIELD)

    def test_process_word_noop_when_not_flagged(self):
        snapshot = mock.Mock()
        snapshot.exists = True
        snapshot.to_dict.return_value = {"needsProcessing": False}
        snapshot.reference.update.side_effect = AssertionError("Should not update")

        event = types.SimpleNamespace(data=types.SimpleNamespace(after=snapshot))

        main.process_word(event)

    def test_process_word_updates(self):
        snapshot = mock.Mock()
        snapshot.exists = True
        snapshot.id = "hola"
        snapshot.to_dict.return_value = {
            "needsProcessing": True,
            "language": "es",
            "languagesPending": ["en", "es"],
        }

        event = types.SimpleNamespace(data=types.SimpleNamespace(after=snapshot))

        enrichment = main.EnrichmentResult(
            lemma="hola",
            language_part_of_speech="interjection",
            primary_part_of_speech="INTERJECTION",
            primary_category=None,
            all_pos=["INTERJECTION"],
            all_categories=[],
        )

        with mock.patch.object(main, "_enrich_word", return_value=enrichment) as enrich_mock, \
                mock.patch.object(main, "_update_document") as update_mock:
            main.process_word(event)

        enrich_mock.assert_called_once_with("hola", "es")
        update_mock.assert_called_once()


if __name__ == "__main__":
    unittest.main()
