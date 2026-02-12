import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/models/data_with_id.dart';
import 'package:baby_words_tracker/data/models/phrase_tracker.dart';
import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:baby_words_tracker/data/services/phrase_tracker_data_service.dart';
import 'package:baby_words_tracker/data/services/word_data_service.dart';
import 'package:baby_words_tracker/data/services/word_tracker_data_service.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:baby_words_tracker/pages/shared/bottom_bar.dart';
import 'package:baby_words_tracker/pages/shared/top_bar.dart';
import 'package:baby_words_tracker/pages/shared/word_entry_sheets.dart';
import 'package:baby_words_tracker/util/current_children_service.dart';
import 'package:baby_words_tracker/util/string_utils.dart';
import 'package:baby_words_tracker/util/text_entry_utils.dart';
import 'package:baby_words_tracker/util/ui_utils.dart';
import 'package:baby_words_tracker/video/local_media_entry.dart';
import 'package:baby_words_tracker/video/media_storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:baby_words_tracker/util/part_of_speech.dart';

class WordLogPage extends StatefulWidget {
  static const routeName = '/log';

  final bool showChrome;

  const WordLogPage({super.key, this.showChrome = true});

  @override
  State<WordLogPage> createState() => _WordLogPageState();
}

class _WordLogPageState extends State<WordLogPage> {
  final DateFormat _dateFormat = DateFormat.yMMMd();
  _LogSegment _segment = _LogSegment.words;

  Stream<List<WordTracker>> _watchWordTrackers(String childId) {
    return FirebaseFirestore.instance
        .collection(Child.collectionName)
        .doc(childId)
        .collection(WordTracker.collectionName)
        .orderBy('firstUtterance', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WordTracker.fromDataWithId(
                    DataWithId.fromFirestore(doc),
                  ))
              .toList(),
        );
  }

  Stream<List<PhraseTracker>> _watchPhraseTrackers(String childId) {
    return FirebaseFirestore.instance
        .collection(Child.collectionName)
        .doc(childId)
        .collection(PhraseTracker.collectionName)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => PhraseTracker.fromDataWithId(
                  DataWithId.fromFirestore(doc),
                  childId: childId,
                ),
              )
              .toList(),
        );
  }

  Future<void> _confirmDeleteWord({
    required String childId,
    required WordTracker tracker,
    required LocalizationService localization,
  }) async {
    final wordId = tracker.id;
    if (wordId == null) return;

    final confirmed = await showConfirmationDialog(
      context,
      localization
          .translate('log_delete_word_prompt')
          .replaceFirst('{word}', wordId.capitalizeOrNA()),
      title: localization.translate('confirm_action'),
    );

    if (!confirmed) {
      return;
    }

    final success = await context
        .read<WordTrackerDataService>()
        .deleteWordTracker(childId, wordId);

    if (!mounted) return;

    final message = success
        ? localization.translate('log_word_deleted')
        : localization.translate('log_word_delete_failed');
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmDeletePhrase({
    required String childId,
    required PhraseTracker tracker,
    required LocalizationService localization,
  }) async {
    final confirmed = await showConfirmationDialog(
      context,
      localization
          .translate('log_delete_phrase_prompt')
          .replaceFirst('{phrase}', tracker.phrase),
      title: localization.translate('confirm_action'),
    );

    if (!confirmed) {
      return;
    }

    final success =
        await context.read<PhraseTrackerDataService>().deletePhraseTracker(
              childId: childId,
              phraseId: tracker.id,
            );

    if (!mounted) return;

    final message = success
        ? localization.translate('log_phrase_deleted')
        : localization.translate('log_phrase_delete_failed');
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showWordDetails({
    required String childId,
    required WordTracker tracker,
    required LocalizationService localization,
    required MediaStorageService videoStorage,
  }) async {
    final displayWord = tracker.id?.capitalizeOrNA() ?? '—';
    final languageLabel = tracker.language?.displayName ??
        localization.translate('language_unknown');
    final attachment = tracker.videoId != null && tracker.videoId!.isNotEmpty
        ? videoStorage.entryForKey(tracker.videoId!)
        : null;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return WordDetailSheet(
          displayWord: displayWord,
          tracker: tracker,
          languageLabel: languageLabel,
          dateLabel: _dateFormat.format(tracker.firstUtterance),
          localization: localization,
          attachment: attachment,
          onOpenAttachment:
              attachment == null ? null : () => _openAttachment(attachment),
        );
      },
    );
  }

  Future<void> _editWordTracker({
    required String childId,
    required WordTracker tracker,
    required LocalizationService localization,
    required List<LanguageCode> availableLanguages,
  }) async {
    final displayWord = tracker.id?.capitalizeOrNA() ?? '';

    final result = await showModalBottomSheet<WordEditResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => WordEditSheet(
        initialWord: displayWord,
        initialLanguage: tracker.language,
        availableLanguages: availableLanguages,
        initialNote: tracker.note,
        localization: localization,
        initialPartOfSpeech: tracker.partOfSpeech,
        // We populate this with all values so the user can correct a wrong tag
        availablePartOfSpeech: PartOfSpeech.values.map((e) => e.name).toList(),
      ),
    );

    if (result == null) {
      return;
    }

    final rawWord = result.word.trim();
    if (rawWord.isEmpty) {
      return;
    }

    final normalizedId = normaliseForDocumentId(rawWord);
    final previousId = tracker.id;
    final LanguageCode? resolvedLanguage = result.language ?? tracker.language;
    final updatedTracker = tracker.copyWith(
      id: normalizedId,
      language: resolvedLanguage,
      note: result.note.isEmpty ? null : result.note,
      partOfSpeech: result.partOfSpeech,
    );

    final wordTrackerService = context.read<WordTrackerDataService>();
    final wordDataService = context.read<WordDataService>();

    if (normalizedId != previousId) {
      final queueLanguage =
          resolvedLanguage ?? tracker.language ?? LanguageCode.en;
      await wordDataService.queueWordForProcessing(
        wordId: normalizedId,
        language: queueLanguage,
      );
    }

    final success = await wordTrackerService.addOrUpdateWordTracker(
      childId,
      normalizedId,
      updatedTracker,
    );

    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localization.translate('log_word_update_failed')),
          ),
        );
      }
      return;
    }

    if (previousId != null && previousId != normalizedId) {
      await wordTrackerService.deleteWordTracker(childId, previousId);
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localization.translate('log_word_updated')),
      ),
    );
  }

  Future<void> _showPhraseDetails({
    required String childId,
    required PhraseTracker tracker,
    required LocalizationService localization,
    required MediaStorageService videoStorage,
  }) async {
    final attachment = tracker.videoId != null && tracker.videoId!.isNotEmpty
        ? videoStorage.entryForKey(tracker.videoId!)
        : null;
    final languageLabel = tracker.language.displayName ??
        localization.translate('language_unknown');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _PhraseDetailSheet(
          tracker: tracker,
          languageLabel: languageLabel,
          dateLabel: _dateFormat.format(tracker.createdAt),
          localization: localization,
          attachment: attachment,
          onOpenAttachment:
              attachment == null ? null : () => _openAttachment(attachment),
        );
      },
    );
  }

  void _openAttachment(LocalMediaEntry entry) {
    Navigator.of(context).pop();
    Future.microtask(() => _showMediaPreview(entry));
  }

  Future<void> _showMediaPreview(LocalMediaEntry entry) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => WordMediaPreviewSheet(
        entry: entry,
        displayText: entry.wordId.capitalizeOrNA(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocalizationService, CurrentChildrenService>(
      builder: (
        context,
        localization,
        currentChildrenService,
        _,
      ) {
        final theme = Theme.of(context);
        final child = currentChildrenService.getCurrChild();

        final content = SafeArea(
          child: child == null
              ? _buildEmptyState(theme, localization)
              : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localization.translate('word_log_subtitle'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<_LogSegment>(
                        segments: [
                          ButtonSegment(
                            value: _LogSegment.words,
                            label: Text(
                                localization.translate('log_segment_words')),
                            icon: const Icon(Icons.menu_book_outlined),
                          ),
                          ButtonSegment(
                            value: _LogSegment.phrases,
                            label: Text(
                              localization.translate('log_segment_phrases'),
                            ),
                            icon: const Icon(Icons.comment_outlined),
                          ),
                        ],
                        selected: {_segment},
                        onSelectionChanged: (selection) {
                          if (selection.isNotEmpty) {
                            setState(() {
                              _segment = selection.first;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _segment == _LogSegment.words
                              ? _WordListView(
                                  key: const ValueKey('word_log'),
                                  stream: _watchWordTrackers(child.id!),
                                  dateFormat: _dateFormat,
                                  localization: localization,
                                  onDelete: (tracker) => _confirmDeleteWord(
                                    childId: child.id!,
                                    tracker: tracker,
                                    localization: localization,
                                  ),
                                  onEdit: (tracker) => _editWordTracker(
                                    childId: child.id!,
                                    tracker: tracker,
                                    localization: localization,
                                    availableLanguages: child.language,
                                  ),
                                  onSelect: (tracker) {
                                    // Get MediaStorageService only when tapped (lazy loading)
                                    final videoStorage =
                                        Provider.of<MediaStorageService>(
                                      context,
                                      listen: false,
                                    );
                                    _showWordDetails(
                                      childId: child.id!,
                                      tracker: tracker,
                                      localization: localization,
                                      videoStorage: videoStorage,
                                    );
                                  },
                                )
                              : _PhraseListView(
                                  key: const ValueKey('phrase_log'),
                                  stream: _watchPhraseTrackers(child.id!),
                                  dateFormat: _dateFormat,
                                  localization: localization,
                                  onDelete: (tracker) => _confirmDeletePhrase(
                                    childId: child.id!,
                                    tracker: tracker,
                                    localization: localization,
                                  ),
                                  onSelect: (tracker) {
                                    // Get MediaStorageService only when tapped (lazy loading)
                                    final videoStorage =
                                        Provider.of<MediaStorageService>(
                                      context,
                                      listen: false,
                                    );
                                    _showPhraseDetails(
                                      childId: child.id!,
                                      tracker: tracker,
                                      localization: localization,
                                      videoStorage: videoStorage,
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
        );

        if (!widget.showChrome) {
          return content;
        }

        return Scaffold(
          appBar: TopBar(
            pageName: localization.translate('word_log_title'),
          ),
          bottomNavigationBar: const CustomBottomBar(WordLogPage.routeName),
          body: content,
        );
      },
    );
  }

  Widget _buildEmptyState(
    ThemeData theme,
    LocalizationService localization,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              localization.translate('log_no_child_selected'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              localization.translate('log_add_child_hint'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WordListView extends StatelessWidget {
  const _WordListView({
    super.key,
    required this.stream,
    required this.dateFormat,
    required this.localization,
    required this.onDelete,
    required this.onEdit,
    required this.onSelect,
  });

  final Stream<List<WordTracker>> stream;
  final DateFormat dateFormat;
  final LocalizationService localization;
  final ValueChanged<WordTracker> onDelete;
  final ValueChanged<WordTracker> onEdit;
  final ValueChanged<WordTracker> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<WordTracker>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final words = snapshot.data ?? const <WordTracker>[];
        if (words.isEmpty) {
          return _EmptyListPlaceholder(
            icon: Icons.record_voice_over_outlined,
            message: localization.translate('log_no_words'),
            hint: localization.translate('log_no_words_hint'),
          );
        }

        return ListView.separated(
          itemCount: words.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final word = words[index];
            final displayWord = word.id?.capitalizeOrNA() ?? '—';
            final dateLabel = dateFormat.format(word.firstUtterance);
            final languageLabel = word.language?.displayName ??
                localization.translate('language_unknown');

            final subtitleParts = <String>[
              dateLabel,
              languageLabel,
              if (word.phraseText != null && word.phraseText!.isNotEmpty)
                localization
                    .translate('log_from_phrase')
                    .replaceFirst('{phrase}', word.phraseText!),
            ];

            return Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ListTile(
                title: Text(
                  displayWord,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  subtitleParts.join(' • '),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (word.note != null && word.note!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.sticky_note_2_outlined,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                    if (word.videoId != null && word.videoId!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.attachment_rounded,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: localization.translate('edit'),
                      color: theme.colorScheme.primary,
                      onPressed: () => onEdit(word),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip:
                          localization.translate('log_delete_word_tooltip'),
                      color: theme.colorScheme.error,
                      onPressed: () => onDelete(word),
                    ),
                  ],
                ),
                onTap: () => onSelect(word),
              ),
            );
          },
        );
      },
    );
  }
}

class _PhraseListView extends StatelessWidget {
  const _PhraseListView({
    super.key,
    required this.stream,
    required this.dateFormat,
    required this.localization,
    required this.onDelete,
    required this.onSelect,
  });

  final Stream<List<PhraseTracker>> stream;
  final DateFormat dateFormat;
  final LocalizationService localization;
  final ValueChanged<PhraseTracker> onDelete;
  final ValueChanged<PhraseTracker> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<PhraseTracker>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final phrases = snapshot.data ?? const <PhraseTracker>[];
        if (phrases.isEmpty) {
          return _EmptyListPlaceholder(
            icon: Icons.comment_outlined,
            message: localization.translate('log_no_phrases'),
            hint: localization.translate('log_no_phrases_hint'),
          );
        }

        return ListView.separated(
          itemCount: phrases.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final phrase = phrases[index];
            final dateLabel = dateFormat.format(phrase.createdAt);
            final languageLabel = phrase.language.displayName;

            return Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ListTile(
                title: Text(
                  phrase.phrase.capitalizeOrNA(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  '$dateLabel • $languageLabel',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (phrase.note != null && phrase.note!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.sticky_note_2_outlined,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                    if (phrase.videoId != null && phrase.videoId!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.attachment_rounded,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip:
                          localization.translate('log_delete_phrase_tooltip'),
                      color: theme.colorScheme.error,
                      onPressed: () => onDelete(phrase),
                    ),
                  ],
                ),
                onTap: () => onSelect(phrase),
              ),
            );
          },
        );
      },
    );
  }
}

class _EmptyListPlaceholder extends StatelessWidget {
  const _EmptyListPlaceholder({
    required this.icon,
    required this.message,
    required this.hint,
  });

  final IconData icon;
  final String message;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _LogSegment { words, phrases }

class _PhraseDetailSheet extends StatelessWidget {
  const _PhraseDetailSheet({
    required this.tracker,
    required this.languageLabel,
    required this.dateLabel,
    required this.localization,
    this.attachment,
    this.onOpenAttachment,
  });

  final PhraseTracker tracker;
  final String languageLabel;
  final String dateLabel;
  final LocalizationService localization;
  final LocalMediaEntry? attachment;
  final VoidCallback? onOpenAttachment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '"${tracker.phrase.capitalizeOrNA()}"',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            WordDetailInfoRow(
              icon: Icons.language,
              label: localization.translate('log_details_language'),
              value: languageLabel,
            ),
            WordDetailInfoRow(
              icon: Icons.calendar_month_outlined,
              label: localization
                  .translate('log_details_recorded')
                  .replaceFirst('{date}', dateLabel),
            ),
            const SizedBox(height: 16),
            Text(
              localization.translate('log_details_phrase_words_title'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tracker.words
                  .map(
                    (word) => Chip(
                      label: Text(word.capitalizeOrNA()),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            WordNoteSection(
              note: tracker.note,
              localization: localization,
            ),
            const SizedBox(height: 16),
            WordAttachmentSection(
              attachment: attachment,
              localization: localization,
              onOpenAttachment: onOpenAttachment,
            ),
          ],
        ),
      ),
    );
  }
}
