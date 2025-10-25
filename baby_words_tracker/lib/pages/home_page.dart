import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/models/data_with_id.dart';
import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:baby_words_tracker/pages/shared/top_bar.dart';
import 'package:baby_words_tracker/pages/shared/word_entry_sheets.dart';
import 'package:baby_words_tracker/util/current_children_service.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/string_utils.dart';
import 'package:baby_words_tracker/video/local_video_entry.dart';
import 'package:baby_words_tracker/video/video_storage_service.dart';
import 'package:baby_words_tracker/pages/add_entry_page.dart';
import 'package:baby_words_tracker/util/main_navigation_controller.dart';
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

  Stream<int> _watchPastWeekCount(String childId) {
    final lastWeek = DateTime.now().subtract(const Duration(days: 7));

    return FirebaseFirestore.instance
        .collection(Child.collectionName)
        .doc(childId)
        .collection(WordTracker.collectionName)
        .where('firstUtterance', isGreaterThanOrEqualTo: lastWeek)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<List<WordTracker>> _watchRecentWords(String childId,
      {int limit = 10}) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return FirebaseFirestore.instance
        .collection(Child.collectionName)
        .doc(childId)
        .collection(WordTracker.collectionName)
        .orderBy('firstUtterance', descending: true)
        .where('firstUtterance', isGreaterThanOrEqualTo: startOfDay)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) =>
                  WordTracker.fromDataWithId(DataWithId.fromFirestore(doc)))
              .toList(),
        );
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
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      return 0;
    });
  }

  Future<void> _showWordDetails({
    required WordTracker tracker,
    required LocalizationService localization,
    required VideoStorageService videoStorage,
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

  void _openAttachment(LocalVideoEntry entry) {
    Navigator.of(context).pop();
    Future.microtask(() => _showMediaPreview(entry));
  }

  Future<void> _showMediaPreview(LocalVideoEntry entry) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => WordMediaPreviewSheet(entry: entry),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<LocalizationService, CurrentChildrenService,
        VideoStorageService>(
      builder: (
        context,
        localization,
        currentChildrenService,
        videoStorage,
        _,
      ) {
        final theme = Theme.of(context);
        final child = currentChildrenService.getCurrChild();

        final body = SafeArea(
          child: child == null
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
                      wordCountStream: _watchWordCount(child.id!),
                      onAddEntry: () {
                        if (widget.showChrome) {
                          Navigator.of(context)
                              .pushNamed(AddEntryPage.routeName);
                        } else {
                          context.read<MainNavigationController>().setIndex(2);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    _WeeklySummaryCard(
                      stream: _watchPastWeekCount(child.id!),
                      localization: localization,
                    ),
                    const SizedBox(height: 24),
                    _RecentWordsSection(
                      stream: _watchRecentWords(child.id!),
                      localization: localization,
                      dateFormat: _dateFormat,
                      onTap: (tracker) => _showWordDetails(
                        tracker: tracker,
                        localization: localization,
                        videoStorage: videoStorage,
                      ),
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

class _WeeklySummaryCard extends StatelessWidget {
  const _WeeklySummaryCard({
    required this.stream,
    required this.localization,
  });

  final Stream<int> stream;
  final LocalizationService localization;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: StreamBuilder<int>(
        stream: stream,
        builder: (context, snapshot) {
          final count = snapshot.data ?? 0;
          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.auto_graph_rounded,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localization.translate('home_weekly_heading'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      localization
                          .translate('home_weekly_caption')
                          .replaceFirst('{count}', count.toString()),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
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
              ],
            );
          },
        ),
      ],
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

    final subtitle = [
      dateLabel,
      languageLabel,
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
