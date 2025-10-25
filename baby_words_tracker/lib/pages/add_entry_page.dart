import 'dart:io';

import 'package:baby_words_tracker/data/models/phrase_tracker.dart';
import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:baby_words_tracker/data/services/phrase_tracker_data_service.dart';
import 'package:baby_words_tracker/data/services/word_data_service.dart';
import 'package:baby_words_tracker/data/services/word_tracker_data_service.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:baby_words_tracker/pages/shared/top_bar.dart';
import 'package:baby_words_tracker/util/current_children_service.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/text_entry_utils.dart';
import 'package:baby_words_tracker/util/ui_utils.dart';
import 'package:baby_words_tracker/video/media_storage_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

class AddEntryPage extends StatefulWidget {
  static const routeName = '/add-entry';
  final bool showChrome;

  const AddEntryPage({super.key, this.showChrome = true});

  @override
  State<AddEntryPage> createState() => _AddEntryPageState();
}

class _AddEntryPageState extends State<AddEntryPage> {
  final TextEditingController _entryController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  EntryMode _entryMode = EntryMode.word;
  String? _entryError;
  _AttachmentSelection? _attachment;
  bool _isSubmitting = false;

  List<LanguageCode> _availableLanguages = const [LanguageCode.en];
  LanguageCode? _selectedLanguage;

  late WordDataService _wordDataService;
  late WordTrackerDataService _wordTrackerDataService;
  late PhraseTrackerDataService _phraseTrackerDataService;
  late CurrentChildrenService _currentChildrenService;

  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) {
      return;
    }

    _wordDataService = context.read<WordDataService>();
    _wordTrackerDataService = context.read<WordTrackerDataService>();
    _phraseTrackerDataService = context.read<PhraseTrackerDataService>();
    _currentChildrenService = context.read<CurrentChildrenService>();

    _currentChildrenService.addListener(_handleChildContextChanged);
    _handleChildContextChanged();

    _initialised = true;
  }

  @override
  void dispose() {
    if (_initialised) {
      _currentChildrenService.removeListener(_handleChildContextChanged);
    }
    _entryController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _handleChildContextChanged() {
    final child = _currentChildrenService.getCurrChild();
    final Set<LanguageCode> permitted = {
      for (final language in child?.language ?? const <LanguageCode>[])
        if (language == LanguageCode.en || language == LanguageCode.es)
          language,
    };

    final List<LanguageCode> languages = permitted.isNotEmpty
        ? permitted.toList()
        : <LanguageCode>[LanguageCode.en];

    setState(() {
      _availableLanguages = languages;
      if (_selectedLanguage == null ||
          !_availableLanguages.contains(_selectedLanguage)) {
        _selectedLanguage = _availableLanguages.first;
      }
    });
  }

  String? _validateEntry(
    LocalizationService localization,
    String rawInput,
  ) {
    final trimmed = rawInput.trim();
    final String? validationResult = _entryMode == EntryMode.word
        ? validateWord(trimmed)
        : validatePhrase(trimmed);

    if (validationResult == null) {
      return null;
    }

    switch (validationResult) {
      case 'Please enter a word.':
        return localization.translate('validation_word_required');
      case 'Words can only include alphabetic characters.':
        return localization.translate('validation_word_letters_only');
      case 'Only single words are allowed in Word mode.':
        return localization.translate('validation_word_single');
      case 'Please enter a phrase.':
        return localization.translate('validation_phrase_required');
      case 'Phrases can include spaces but only alphabetic characters.':
        return localization.translate('validation_phrase_letters_only');
      case 'Unable to find any words in the phrase.':
        return localization.translate('validation_phrase_not_found');
      default:
        return validationResult;
    }
  }

  Future<void> _handleAttachmentSelection(
    LocalizationService localization,
  ) async {
    if (kIsWeb) {
      await showAlertIfMounted(
        context,
        localization.translate('file_not_added'),
        localization.translate('attachments_web_unsupported'),
      );
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.media,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final pickedFile = result.files.single;
      final path = pickedFile.path;
      if (path == null) {
        return;
      }

      final file = File(path);
      if (!await file.exists()) {
        return;
      }

      final sizeMb = (await file.length()) / (1024 * 1024);
      const maxSizeMb = 200.0;
      if (sizeMb > maxSizeMb) {
        await showAlertIfMounted(
          context,
          localization.translate('file_not_added'),
          localization
              .translate('attachment_too_large')
              .replaceFirst('{size}', maxSizeMb.toStringAsFixed(0)),
        );
        return;
      }

      final extension = pickedFile.extension?.toLowerCase();
      final kind = _inferAttachmentKind(extension);

      setState(() {
        _attachment = _AttachmentSelection(
          file: file,
          displayName:
              pickedFile.name.isNotEmpty ? pickedFile.name : p.basename(path),
          sizeMb: sizeMb,
          kind: kind,
        );
      });
    } catch (_) {
      await showAlertIfMounted(
        context,
        localization.translate('file_not_added'),
        localization.translate('attachment_generic_error'),
      );
    }
  }

  void _clearAttachment() {
    setState(() {
      _attachment = null;
    });
  }

  Future<String?> _storeAttachment({
    required MediaStorageService storage,
    required LocalizationService localization,
    required String childId,
    required String entryId,
  }) async {
    final attachment = _attachment;
    if (attachment == null) {
      return null;
    }

    if (!storage.isFeatureEnabled) {
      await showAlertIfMounted(
        context,
        localization.translate('file_not_added'),
        localization.translate('attachments_disabled'),
      );
      return null;
    }

    if (!storage.isReady) {
      await showAlertIfMounted(
        context,
        localization.translate('file_not_added'),
        localization.translate('video_not_ready_message'),
      );
      return null;
    }

    try {
      final saved = await storage.saveMediaForWord(
        childId: childId,
        wordId: entryId,
        sourceFile: attachment.file,
      );
      return saved?.key;
    } catch (_) {
      await showAlertIfMounted(
        context,
        localization.translate('file_not_added'),
        localization.translate('attachment_save_failed'),
      );
      return null;
    }
  }

  Future<void> _submitEntry(
    LocalizationService localization,
    MediaStorageService videoStorage,
  ) async {
    if (_isSubmitting) {
      return;
    }

    final child = _currentChildrenService.getCurrChild();
    final childId = child?.id;
    if (childId == null) {
      await showAlertIfMounted(
        context,
        localization.translate('error'),
        localization.translate('go_to_settings'),
      );
      return;
    }

    final input = _entryController.text;
    final validationError = _validateEntry(localization, input);
    if (validationError != null) {
      setState(() => _entryError = validationError);
      return;
    }

    setState(() {
      _entryError = null;
      _isSubmitting = true;
    });

    final language = _selectedLanguage ?? _availableLanguages.first;
    final note = _noteController.text.trim();

    try {
      if (_entryMode == EntryMode.word) {
        await _submitWordEntry(
          localization: localization,
          videoStorage: videoStorage,
          childId: childId,
          language: language,
          rawInput: input.trim(),
          note: note,
        );
      } else {
        await _submitPhraseEntry(
          localization: localization,
          videoStorage: videoStorage,
          childId: childId,
          language: language,
          rawInput: input.trim(),
          note: note,
        );
      }

      if (!mounted) return;

      _entryController.clear();
      _noteController.clear();
      setState(() {
        _attachment = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localization.translate('entry_saved'))),
      );
    } catch (error) {
      if (!mounted) return;
      await showAlertIfMounted(
        context,
        localization.translate('error'),
        error.toString(),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _submitWordEntry({
    required LocalizationService localization,
    required MediaStorageService videoStorage,
    required String childId,
    required LanguageCode language,
    required String rawInput,
    required String note,
  }) async {
    final normalisedWord = normaliseForDocumentId(rawInput);
    
    // Check if word already exists
    final existingWord = await _wordTrackerDataService.getWordTracker(
      childId,
      normalisedWord,
    );
    
    if (existingWord != null) {
      // Word already logged, show toast and return
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localization.translate('word_already_logged')),
          ),
        );
      }
      return;
    }
    
    await _wordDataService.queueWordForProcessing(
      wordId: normalisedWord,
      language: language,
    );

    final videoId = await _storeAttachment(
      storage: videoStorage,
      localization: localization,
      childId: childId,
      entryId: normalisedWord,
    );

    await _wordTrackerDataService.addOrUpdateWordTracker(
      childId,
      normalisedWord,
      WordTracker(
        id: normalisedWord,
        firstUtterance: DateTime.now(),
        language: language,
        note: note.isEmpty ? null : note,
        videoId: videoId,
      ),
    );
  }

  Future<void> _submitPhraseEntry({
    required LocalizationService localization,
    required MediaStorageService videoStorage,
    required String childId,
    required LanguageCode language,
    required String rawInput,
    required String note,
  }) async {
    final trimmedPhrase = rawInput.trim();
    final phraseId = normaliseForDocumentId(trimmedPhrase);
    final words = extractWords(trimmedPhrase);

    final videoId = await _storeAttachment(
      storage: videoStorage,
      localization: localization,
      childId: childId,
      entryId: phraseId,
    );

    for (final word in words) {
      // Check if word already exists
      final existingWord = await _wordTrackerDataService.getWordTracker(
        childId,
        word,
      );
      
      // Skip if word already logged (silently for phrases)
      if (existingWord != null) {
        continue;
      }
      
      await _wordDataService.queueWordForProcessing(
        wordId: word,
        language: language,
      );

      await _wordTrackerDataService.addOrUpdateWordTracker(
        childId,
        word,
        WordTracker(
          id: word,
          firstUtterance: DateTime.now(),
          language: language,
          note: note.isEmpty ? null : note,
          videoId: videoId,
          phraseId: phraseId,
          phraseText: trimmedPhrase,
        ),
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
      videoId: videoId,
    );

    await _phraseTrackerDataService.upsertPhraseTracker(phraseTracker);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocalizationService, MediaStorageService>(
      builder: (context, localization, videoStorage, _) {
        final theme = Theme.of(context);
        final entryLabel = localization.translate(
          _entryMode == EntryMode.word
              ? 'word_input_label'
              : 'phrase_input_label',
        );
        final entryHint = localization.translate(
          _entryMode == EntryMode.word
              ? 'word_input_hint'
              : 'phrase_input_hint',
        );
        final notesLabel = localization.translate('note_optional');
        final notesHint = localization.translate('note_hint');
        final attachmentsEnabled = !kIsWeb && videoStorage.isFeatureEnabled;
        final attachmentsReady = attachmentsEnabled && videoStorage.isReady;
        final outlineColor = theme.colorScheme.outlineVariant.withOpacity(0.6);
        final baseBorder = OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: outlineColor),
        );
        final focusedBorder = OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.4),
        );

        final body = SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                color: theme.colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localization.translate('entry_details_title'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        localization.translate('entry_mode_label'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<EntryMode>(
                        segments: [
                          ButtonSegment(
                            value: EntryMode.word,
                            label: Text(
                              localization.translate('word_mode'),
                            ),
                            icon: const Icon(Icons.menu_book_outlined),
                          ),
                          ButtonSegment(
                            value: EntryMode.phrase,
                            label: Text(
                              localization.translate('phrase_mode'),
                            ),
                            icon: const Icon(
                              Icons.comment_outlined,
                            ),
                          ),
                        ],
                        selected: <EntryMode>{_entryMode},
                        onSelectionChanged: (selection) {
                          if (selection.isEmpty) return;
                          setState(() {
                            _entryMode = selection.first;
                            _entryError = null;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _entryController,
                        maxLines: _entryMode == EntryMode.phrase ? 3 : 1,
                        minLines: 1,
                        decoration: InputDecoration(
                          labelText: entryLabel,
                          hintText: entryHint,
                          errorText: _entryError,
                          filled: true,
                          enabledBorder: baseBorder,
                          focusedBorder: focusedBorder,
                          errorBorder: baseBorder.copyWith(
                            borderSide: BorderSide(
                              color: theme.colorScheme.error,
                            ),
                          ),
                          focusedErrorBorder: focusedBorder.copyWith(
                            borderSide: BorderSide(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        localization.translate('select_language'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<LanguageCode>(
                        value: _selectedLanguage,
                        items: _availableLanguages
                            .map(
                              (code) => DropdownMenuItem<LanguageCode>(
                                value: code,
                                child: Text(code.displayName),
                              ),
                            )
                            .toList(),
                        onChanged: _availableLanguages.length > 1
                            ? (value) {
                                setState(() {
                                  _selectedLanguage = value;
                                });
                              }
                            : null,
                        decoration: InputDecoration(
                          filled: true,
                          enabledBorder: baseBorder,
                          focusedBorder: focusedBorder,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                color: theme.colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localization.translate('entry_extras_title'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _noteController,
                        maxLines: 3,
                        minLines: 2,
                        decoration: InputDecoration(
                          labelText: notesLabel,
                          hintText: notesHint,
                          filled: true,
                          enabledBorder: baseBorder,
                          focusedBorder: focusedBorder,
                          errorBorder: baseBorder.copyWith(
                            borderSide: BorderSide(
                              color: theme.colorScheme.error,
                            ),
                          ),
                          focusedErrorBorder: focusedBorder.copyWith(
                            borderSide: BorderSide(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                        textInputAction: TextInputAction.done,
                        keyboardType: TextInputType.text,
                        onEditingComplete: () =>
                            FocusScope.of(context).unfocus(),
                        onSubmitted: (_) => FocusScope.of(context).unfocus(),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        localization.translate('attachment_section_title'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (!attachmentsEnabled)
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            localization.translate('attachments_unavailable'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      else if (!attachmentsReady)
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  localization.translate('attachments_loading'),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_attachment == null)
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _handleAttachmentSelection(localization),
                                icon: const Icon(Icons.upload_rounded),
                                label: Text(
                                  localization
                                      .translate('attachment_pick_button'),
                                ),
                              )
                            else
                              _AttachmentPreview(
                                attachment: _attachment!,
                                onRemove: _clearAttachment,
                                localization: localization,
                              ),
                            const SizedBox(height: 12),
                            Text(
                              localization.translate('attachment_local_notice'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => _submitEntry(localization, videoStorage),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(localization.translate('submit')),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );

        if (!widget.showChrome) {
          return body;
        }

        return Scaffold(
          appBar: TopBar(
            pageName: localization.translate('add_entry_title'),
          ),
          body: body,
        );
      },
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  const _AttachmentPreview({
    required this.attachment,
    required this.onRemove,
    required this.localization,
  });

  final _AttachmentSelection attachment;
  final VoidCallback onRemove;
  final LocalizationService localization;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeLabel = _describeAttachmentKind(
      attachment.kind,
      localization,
    );

    IconData icon;
    switch (attachment.kind) {
      case _AttachmentKind.video:
        icon = Icons.play_circle_outline_rounded;
        break;
      case _AttachmentKind.image:
        icon = Icons.photo_camera_outlined;
        break;
      case _AttachmentKind.other:
        icon = Icons.insert_drive_file_outlined;
        break;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(
          attachment.displayName,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '$typeLabel • ${attachment.sizeMb.toStringAsFixed(1)} MB',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: localization.translate('attachment_remove_button'),
          onPressed: onRemove,
        ),
      ),
    );
  }
}

class _AttachmentSelection {
  _AttachmentSelection({
    required this.file,
    required this.displayName,
    required this.sizeMb,
    required this.kind,
  });

  final File file;
  final String displayName;
  final double sizeMb;
  final _AttachmentKind kind;
}

enum _AttachmentKind { video, image, other }

_AttachmentKind _inferAttachmentKind(String? extension) {
  if (extension == null) {
    return _AttachmentKind.other;
  }

  const videoExtensions = {
    'mp4',
    'mov',
    'm4v',
    'avi',
    'mkv',
    'webm',
  };

  const imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'heic',
    'heif',
    'gif',
    'bmp',
    'webp',
  };

  if (videoExtensions.contains(extension)) {
    return _AttachmentKind.video;
  }
  if (imageExtensions.contains(extension)) {
    return _AttachmentKind.image;
  }
  return _AttachmentKind.other;
}

String _describeAttachmentKind(
  _AttachmentKind kind,
  LocalizationService localization,
) {
  switch (kind) {
    case _AttachmentKind.video:
      return localization.translate('attachment_type_video');
    case _AttachmentKind.image:
      return localization.translate('attachment_type_image');
    case _AttachmentKind.other:
      return localization.translate('attachment_type_file');
  }
}
