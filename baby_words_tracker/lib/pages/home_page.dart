import 'dart:async';

import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/models/data_with_id.dart';
import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:baby_words_tracker/pages/shared/top_bar.dart';
import 'package:baby_words_tracker/pages/shared/word_entry_sheets.dart';
import 'package:baby_words_tracker/util/current_children_service.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/string_utils.dart';
import 'package:baby_words_tracker/video/local_media_entry.dart';
import 'package:baby_words_tracker/video/media_storage_service.dart';
import 'package:baby_words_tracker/pages/add_entry_page.dart';
import 'package:baby_words_tracker/util/main_navigation_controller.dart';
import 'package:baby_words_tracker/util/part_of_speech.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  static const routeName = '/';
  final bool showChrome;

  const HomePage({super.key, this.showChrome = true});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DateFormat _dateFormat = DateFormat.MMMd();

  // Cache the current child ID to detect when we need to recreate streams
  String? _currentChildId;
  Stream<int>? _wordCountStream;
  Stream<List<WordTracker>>? _recentWordsStream;

  @override
  void dispose() {
    _wordCountStream = null;
    _recentWordsStream = null;
    super.dispose();
  }

  Stream<List<WordTracker>> _watchRecentWords(String childId,
      {int limit = 10}) {
    return FirebaseFirestore.instance
        .collection(Child.collectionName)
        .doc(childId)
        .collection(WordTracker.collectionName)
        .orderBy('firstUtterance', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final words = snapshot.docs
          .map((doc) {
            try {
              return WordTracker.fromDataWithId(DataWithId.fromFirestore(doc));
            } catch (e) {
              debugPrint("Error parsing word doc ${doc.id}: $e");
              return null;
            }
          })
          .whereType<WordTracker>()
          .toList();
      return words;
    }).distinct((prev, next) {
      if (prev.length != next.length) return false;
      for (int i = 0; i < prev.length; i++) {
        if (prev[i].id != next[i].id) return false;
      }
      return true;
    });
  }

  Stream<int> _watchWordCount(String childId) {
    return FirebaseFirestore.instance
        .collection(Child.collectionName)
        .doc(childId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      if (data == null) return 0;
      final value = data[Child.wordCountFieldName];
      return value is int ? value : (value is num ? value.toInt() : 0);
    }).distinct();
  }

  Future<void> _showWordDetails({
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
      builder: (context) => WordDetailSheet(
        displayWord: displayWord,
        tracker: tracker,
        languageLabel: languageLabel,
        dateLabel: _dateFormat.format(tracker.firstUtterance),
        localization: localization,
        attachment: attachment,
        onOpenAttachment:
            attachment == null ? null : () => _openAttachment(attachment),
      ),
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
        final child = currentChildrenService.getCurrChild();

        // Only recreate streams if child has changed
        if (child?.id != _currentChildId) {
          _currentChildId = child?.id;
          if (child?.id != null) {
            _wordCountStream = _watchWordCount(child!.id!);
            _recentWordsStream = _watchRecentWords(child.id!);
          } else {
            _wordCountStream = null;
            _recentWordsStream = null;
          }
        }

        final body = SafeArea(
          child: child == null || _wordCountStream == null
              ? Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: _HomeEmptyState(localization: localization),
                )
              : ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  children: [
                    _OverviewCard(
                      child: child,
                      localization: localization,
                      wordCountStream: _wordCountStream!,
                      onAddEntry: () {
                        showModalBottomSheet(
                          context: context,
                          useRootNavigator: true,
                          isScrollControlled: true,
                          backgroundColor: Colors.white,
                          builder: (context) => FractionallySizedBox(
                            heightFactor: 0.92,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(24)),
                              child: const AddEntryPage(
                                  showChrome: false, isModal: true),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _RecentWordsSection(
                      stream: _recentWordsStream!,
                      localization: localization,
                      dateFormat: _dateFormat,
                      onTap: (tracker) {
                        // Get MediaStorageService only when tapped (lazy loading)
                        final videoStorage = Provider.of<MediaStorageService>(
                            context,
                            listen: false);
                        _showWordDetails(
                          tracker: tracker,
                          localization: localization,
                          videoStorage: videoStorage,
                        );
                      },
                    ),
                  ],
                ),
        );

        if (!widget.showChrome) {
          return body;
        }

        return Scaffold(
          appBar: TopBar(
            pageName: localization.translate('home_title'),
            showPageTitle: true,
          ),
          body: body,
        );
      },
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.child,
    required this.localization,
    required this.wordCountStream,
    required this.onAddEntry,
  });

  final Child child;
  final LocalizationService localization;
  final Stream<int> wordCountStream;
  final VoidCallback onAddEntry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headline = localization
        .translate('home_child_summary_headline')
        .replaceFirst('{name}', child.name);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.85),
            theme.colorScheme.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.24),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headline,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<int>(
            stream: wordCountStream,
            builder: (context, snapshot) {
              final count = snapshot.data ?? child.wordCount;
              final detail = localization
                  .translate('home_child_summary_detail')
                  .replaceFirst('{count}', count.toString());
              return Text(
                detail,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary.withOpacity(0.85),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAddEntry,
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.onPrimary,
              foregroundColor: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.add_rounded),
            label: Text(localization.translate('home_add_entry_cta')),
          ),
        ],
      ),
    );
  }
}

class _RecentWordsSection extends StatelessWidget {
  const _RecentWordsSection({
    required this.stream,
    required this.localization,
    required this.dateFormat,
    required this.onTap,
  });

  final Stream<List<WordTracker>> stream;
  final LocalizationService localization;
  final DateFormat dateFormat;
  final ValueChanged<WordTracker> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localization.translate('home_recent_words_title'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<WordTracker>>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final words = snapshot.data ?? const <WordTracker>[];
            if (words.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    localization.translate('home_no_recent_words'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: [
                for (int index = 0; index < words.length; index++) ...[
                  if (index > 0) const SizedBox(height: 12),
                  _RecentWordTile(
                    tracker: words[index],
                    localization: localization,
                    dateFormat: dateFormat,
                    onTap: onTap,
                  ),
                ],
                const SizedBox(height: 12),
                _SeeAllCard(
                  localization: localization,
                  onTap: () {
                    // Use MainNavigationController to switch tabs (same as bottom bar)
                    // Tab index 1 is the Word Log page
                    context.read<MainNavigationController>().setIndex(1);
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SeeAllCard extends StatelessWidget {
  const _SeeAllCard({
    required this.localization,
    required this.onTap,
  });

  final LocalizationService localization;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        title: Text(
          localization.translate('home_see_all_in_logbook'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: theme.colorScheme.primary,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _RecentWordTile extends StatelessWidget {
  const _RecentWordTile({
    required this.tracker,
    required this.localization,
    required this.dateFormat,
    required this.onTap,
  });

  final WordTracker tracker;
  final LocalizationService localization;
  final DateFormat dateFormat;
  final ValueChanged<WordTracker> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayWord = tracker.id?.capitalizeOrNA() ?? '—';
    final dateLabel = dateFormat.format(tracker.firstUtterance);
    final languageLabel = tracker.language?.displayName ??
        localization.translate('language_unknown');

    String? posLabel;
    if (tracker.partOfSpeech != null) {
      try {
        posLabel =
            PartofspeechExtension.fromString(tracker.partOfSpeech!).displayName;
      } catch (_) {}
    }

    final subtitle = [
      dateLabel,
      languageLabel,
      if (posLabel != null) posLabel,
      if (tracker.phraseText != null && tracker.phraseText!.isNotEmpty)
        localization
            .translate('home_recent_from_phrase')
            .replaceFirst('{phrase}', tracker.phraseText!),
    ].join(' • ');

    final List<Widget> trailingIcons = [];
    if (tracker.note != null && tracker.note!.isNotEmpty) {
      trailingIcons.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Icon(
            Icons.sticky_note_2_outlined,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
      );
    }
    if (tracker.videoId != null && tracker.videoId!.isNotEmpty) {
      trailingIcons.add(
        Icon(
          Icons.attachment_rounded,
          color: theme.colorScheme.primary,
          size: 20,
        ),
      );
    }

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
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: trailingIcons.isEmpty
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: trailingIcons,
              ),
        onTap: () => onTap(tracker),
      ),
    );
  }
}

class _HomeEmptyState extends StatelessWidget {
  const _HomeEmptyState({required this.localization});

  final LocalizationService localization;

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
              Icons.family_restroom_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              localization.translate('home_no_child_title'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              localization.translate('home_no_child_hint'),
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
