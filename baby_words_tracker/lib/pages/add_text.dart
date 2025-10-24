import 'package:baby_words_tracker/data/models/phrase_tracker.dart';
import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:baby_words_tracker/data/services/phrase_tracker_data_service.dart';
import 'package:baby_words_tracker/data/services/word_data_service.dart';
import 'package:baby_words_tracker/data/services/word_tracker_data_service.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:baby_words_tracker/pages/shared/bottom_bar.dart';
import 'package:baby_words_tracker/pages/shared/top_bar.dart';
import 'package:baby_words_tracker/util/current_children_service.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/text_entry_utils.dart';
import 'package:baby_words_tracker/util/ui_utils.dart';
import 'package:baby_words_tracker/video/video_picker.dart';
import 'package:baby_words_tracker/video/video_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// baby words packages

class AddTextPage extends StatefulWidget {
  static const routeName = "/addtext";

  const AddTextPage({super.key});

  @override
  State<AddTextPage> createState() => _AddTextPageState();
}

class _AddTextPageState extends State<AddTextPage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController fileTextController = TextEditingController();

  VideoSelectionResult? _selectedVideo;
  EntryMode _entryMode = EntryMode.word;
  List<LanguageCode> _availableLanguages = const [LanguageCode.en];
  LanguageCode? _selectedLanguage;
  bool _isSubmitting = false;
  String? _statusMessage;

  late final WordDataService _wordDataService;
  late final WordTrackerDataService _wordTrackerDataService;
  late final PhraseTrackerDataService _phraseTrackerDataService;
  late final CurrentChildrenService _currentChildrenService;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();

    if (!_initialized) {
      _wordDataService = Provider.of<WordDataService>(context, listen: false);
      _wordTrackerDataService =
          Provider.of<WordTrackerDataService>(context, listen: false);
      _phraseTrackerDataService =
          Provider.of<PhraseTrackerDataService>(context, listen: false);
      _currentChildrenService =
          Provider.of<CurrentChildrenService>(context, listen: false);
      _currentChildrenService.addListener(_handleChildContextChanged);
      _handleChildContextChanged();
      _initialized = true;
    }
  }

  void _handleChildContextChanged() {
    final child = _currentChildrenService.getCurrChild();
    final List<LanguageCode> languages =
        List<LanguageCode>.from(child?.language ?? const <LanguageCode>[]);
    languages.removeWhere((value) => value == LanguageCode.unknown);
    final uniqueLanguages = languages.isNotEmpty
        ? languages.toSet().toList()
        : <LanguageCode>[LanguageCode.en];

    setState(() {
      _availableLanguages = uniqueLanguages;
      if (_selectedLanguage == null ||
          !_availableLanguages.contains(_selectedLanguage)) {
        _selectedLanguage = _availableLanguages.first;
      }
    });
  }

  Future<void> _handleVideoSelection(
    BuildContext context,
    LocalizationService localizationService,
    VideoStorageService videoStorage,
  ) async {
    try {
      final result = await pickLocalVideo();
      if (result == null) {
        return;
      }
      setState(() {
        _selectedVideo = result;
        fileTextController.text = result.displayName;
      });
    } on VideoSelectionException catch (error) {
      if (!context.mounted) return;
      await showAlertIfMounted(
        context,
        localizationService.translate("file_not_added"),
        error.message,
      );
    } catch (error) {
      if (!context.mounted) return;
      await showAlertIfMounted(
        context,
        localizationService.translate("file_not_added"),
        "Something went wrong while selecting the video. Please try again.",
      );
    }
  }

  void _clearVideoSelection() {
    setState(() {
      _selectedVideo = null;
      fileTextController.clear();
    });
  }

  @override
  void dispose() {
    if (_initialized) {
      _currentChildrenService.removeListener(_handleChildContextChanged);
    }
    _controller.dispose();
    _noteController.dispose();
    fileTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localizationService, child) {
        final videoStorage = context.watch<VideoStorageService>();
        final theme = Theme.of(context);
        final isPhraseMode = _entryMode == EntryMode.phrase;
        final selectedLanguageName =
            _selectedLanguage?.displayName ?? 'English';

        return Scaffold(
          backgroundColor: const Color(0xFF828A8F),
          appBar: TopBar(pageName: localizationService.translate('add_words')),
          bottomNavigationBar: const CustomBottomBar(AddTextPage.routeName),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                Center(
                  child: Text(
                    localizationService.translate('add_words'),
                    style: theme.textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ) ??
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  localizationService.translate('entry_mode_label'),
                  style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ) ??
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                ToggleButtons(
                  isSelected: EntryMode.values
                      .map((mode) => _entryMode == mode)
                      .toList(),
                  onPressed: (index) {
                    setState(() {
                      _entryMode = EntryMode.values[index];
                    });
                  },
                  color: Colors.white,
                  selectedColor: Colors.white,
                  fillColor: const Color(0xFF9E1B32),
                  borderRadius: BorderRadius.circular(20),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child:
                          Text(localizationService.translate('word_mode')),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child:
                          Text(localizationService.translate('phrase_mode')),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  localizationService.translate('select_language'),
                  style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ) ??
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _showLanguageSelector(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    backgroundColor: const Color(0xFF9E1B32),
                  ),
                  icon: const Icon(Icons.language),
                  label: Text(selectedLanguageName),
                ),
                const SizedBox(height: 24),
                Text(
                  isPhraseMode
                      ? localizationService.translate('phrase_input_label')
                      : localizationService.translate('word_input_label'),
                  style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ) ??
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _controller,
                  maxLines: isPhraseMode ? null : 1,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: isPhraseMode
                        ? localizationService.translate('phrase_input_hint')
                        : localizationService.translate('word_input_hint'),
                    hintStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF9E1B32),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 24),
                Text(
                  localizationService.translate('note_optional'),
                  style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ) ??
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: localizationService.translate('note_hint'),
                    hintStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF9E1B32),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 24),
                if (!kIsWeb && videoStorage.isFeatureEnabled) ...[
                  Text(
                    localizationService.translate('video_optional'),
                    style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ) ??
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: fileTextController,
                    readOnly: true,
                    onTap: () => _handleVideoSelection(
                      context,
                      localizationService,
                      videoStorage,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          localizationService.translate('choose_file'),
                      hintStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF9E1B32),
                      suffixIcon: _selectedVideo != null
                          ? IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: _clearVideoSelection,
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                ],
                if (_statusMessage != null) ...[
                  Text(
                    _statusMessage!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Align(
                  child: FilledButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => _submit(
                              context,
                              localizationService,
                              videoStorage,
                            ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF9E1B32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 36,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            localizationService.translate('submit'),
                            style: const TextStyle(fontSize: 18),
                          ),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showLanguageSelector(BuildContext context) async {
    if (_availableLanguages.length == 1) {
      return;
    }

    final selected = await showModalBottomSheet<LanguageCode>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView.builder(
            itemCount: _availableLanguages.length,
            itemBuilder: (context, index) {
              final language = _availableLanguages[index];
              final isSelected = language == _selectedLanguage;
              return ListTile(
                title: Text(language.displayName),
                trailing: isSelected ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop(language),
              );
            },
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedLanguage = selected;
      });
    }
  }

  Future<void> _submit(
    BuildContext context,
    LocalizationService localizationService,
    VideoStorageService videoStorage,
  ) async {
    if (_isSubmitting) return;

    final child = _currentChildrenService.getCurrChild();
    final childId = child?.id;
    if (childId == null) {
      await showAlertIfMounted(
        context,
        localizationService.translate('error'),
        localizationService.translate('go_to_settings'),
      );
      return;
    }

    final language = _selectedLanguage ?? _availableLanguages.first;
    final input = _controller.text.trim();
    final note = _noteController.text.trim();

    String? validationMessage;
    if (_entryMode == EntryMode.word) {
      validationMessage = validateWord(input);
    } else {
      validationMessage = validatePhrase(input);
    }

    if (validationMessage != null) {
      await showAlertIfMounted(
        context,
        localizationService.translate('error'),
        validationMessage,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _statusMessage = localizationService.translate('processing_state');
    });

    try {
      if (_entryMode == EntryMode.word) {
        await _submitWord(
          context,
          localizationService,
          videoStorage,
          childId,
          language,
          input,
          note,
        );
      } else {
        await _submitPhrase(
          context,
          localizationService,
          videoStorage,
          childId,
          language,
          input,
          note,
        );
      }

      if (!mounted) return;
      setState(() {
        _controller.clear();
        _noteController.clear();
      });
      _clearVideoSelection();
    } catch (error) {
      if (!mounted) return;
      await showAlertIfMounted(
        context,
        localizationService.translate('error'),
        error.toString(),
      );
      setState(() {
        _statusMessage = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _submitWord(
    BuildContext context,
    LocalizationService localizationService,
    VideoStorageService videoStorage,
    String childId,
    LanguageCode language,
    String rawInput,
    String note,
  ) async {
    final normalisedWord = normaliseForDocumentId(rawInput);
    final queued = await _wordDataService.queueWordForProcessing(
      wordId: normalisedWord,
      language: language,
    );

    String? videoKey;
    final pendingVideo = _selectedVideo;

    if (pendingVideo != null) {
      if (!videoStorage.isReady) {
        await showAlertIfMounted(
          context,
          localizationService.translate('file_not_added'),
          localizationService.translate('video_not_ready_message'),
        );
      } else {
        final savedVideo = await videoStorage.saveVideoForWord(
          childId: childId,
          wordId: normalisedWord,
          sourceFile: pendingVideo.file,
        );
        videoKey = savedVideo?.key;
      }
    }

    await _saveWordTracker(
      childId: childId,
      wordId: normalisedWord,
      language: language,
      note: note.isEmpty ? null : note,
      videoId: videoKey,
    );

    if (mounted) {
      setState(() {
        _statusMessage = queued
            ? localizationService.translate('word_processing_queued')
                .replaceFirst('{word}', normalisedWord)
            : localizationService.translate('word_already_processed')
                .replaceFirst('{word}', normalisedWord);
      });
    }
  }

  Future<void> _submitPhrase(
    BuildContext context,
    LocalizationService localizationService,
    VideoStorageService videoStorage,
    String childId,
    LanguageCode language,
    String rawInput,
    String note,
  ) async {
    final trimmedPhrase = rawInput.trim();
    final phraseId = normaliseForDocumentId(trimmedPhrase);
    final words = extractWords(trimmedPhrase);
    String? videoKey;
    final pendingVideo = _selectedVideo;
    if (pendingVideo != null) {
      if (!videoStorage.isReady) {
        await showAlertIfMounted(
          context,
          localizationService.translate('file_not_added'),
          localizationService.translate('video_not_ready_message'),
        );
      } else {
        final savedVideo = await videoStorage.saveVideoForWord(
          childId: childId,
          wordId: phraseId,
          sourceFile: pendingVideo.file,
        );
        videoKey = savedVideo?.key;
      }
    }

    final List<String> newlyQueued = [];

    for (final word in words) {
      final queued = await _wordDataService.queueWordForProcessing(
        wordId: word,
        language: language,
      );
      if (queued) {
        newlyQueued.add(word);
      }

      await _saveWordTracker(
        childId: childId,
        wordId: word,
        language: language,
        note: note.isEmpty ? null : note,
        videoId: videoKey,
        phraseId: phraseId,
        phraseText: trimmedPhrase,
      );
    }

    final phraseTracker = PhraseTracker(
      id: phraseId,
      childId: childId,
      phrase: trimmedPhrase,
      words: words,
      createdAt: DateTime.now(),
      needsProcessing: true,
      language: language,
      note: note.isEmpty ? null : note,
      videoId: videoKey,
    );

    await _phraseTrackerDataService.upsertPhraseTracker(phraseTracker);

    if (mounted) {
      setState(() {
        final message = newlyQueued.isEmpty
            ? localizationService.translate('phrase_already_processed')
            : localizationService.translate('phrase_processing_queued')
                .replaceFirst('{count}', newlyQueued.length.toString());
        _statusMessage = message;
      });
    }
  }

  Future<bool> _saveWordTracker({
    required String childId,
    required String wordId,
    required LanguageCode language,
    String? note,
    String? videoId,
    String? phraseId,
    String? phraseText,
  }) {
    return _wordTrackerDataService.addOrUpdateWordTracker(
      childId,
      wordId,
      WordTracker(
        id: wordId,
        firstUtterance: DateTime.now(),
        language: language,
        note: note,
        videoId: videoId,
        phraseId: phraseId,
        phraseText: phraseText,
      ),
    );
  }
}
