import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/models/data_with_id.dart';
import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:baby_words_tracker/pages/add_entry_page.dart';
import 'package:baby_words_tracker/pages/shared/top_bar.dart';
import 'package:baby_words_tracker/util/current_children_service.dart';
import 'package:baby_words_tracker/util/language_code.dart';
import 'package:baby_words_tracker/util/string_utils.dart';
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

  Stream<List<WordTracker>> _watchRecentWords(String childId, {int limit = 5}) {
    return FirebaseFirestore.instance
        .collection(Child.collectionName)
        .doc(childId)
        .collection(WordTracker.collectionName)
        .orderBy('firstUtterance', descending: true)
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

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocalizationService, CurrentChildrenService>(
      builder: (context, localization, currentChildrenService, _) {
        final theme = Theme.of(context);
        final child = currentChildrenService.getCurrChild();

        final body = SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: child == null
                ? _HomeEmptyState(localization: localization)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _OverviewCard(
                        child: child,
                        localization: localization,
                        wordCountStream: _watchWordCount(child.id!),
                      ),
                      const SizedBox(height: 24),
                      _WeeklySummaryCard(
                        stream: _watchPastWeekCount(child.id!),
                        localization: localization,
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: _RecentWordsSection(
                          stream: _watchRecentWords(child.id!),
                          localization: localization,
                          dateFormat: _dateFormat,
                        ),
                      ),
                    ],
                  ),
          ),
        );

        if (!widget.showChrome) {
          return body;
        }

        return Scaffold(
          appBar: TopBar(
            pageName: localization.translate('word_buds'),
            showPageTitle: false,
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
  });

  final Child child;
  final LocalizationService localization;
  final Stream<int> wordCountStream;

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
            onPressed: () {
              Navigator.of(context).pushNamed(AddEntryPage.routeName);
            },
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
  });

  final Stream<List<WordTracker>> stream;
  final LocalizationService localization;
  final DateFormat dateFormat;

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
        Expanded(
          child: StreamBuilder<List<WordTracker>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final words = snapshot.data ?? const <WordTracker>[];
              if (words.isEmpty) {
                return Center(
                  child: Text(
                    localization.translate('home_no_recent_words'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }

              return ListView.separated(
                itemCount: words.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final tracker = words[index];
                  final displayWord = tracker.id?.capitalizeOrNA() ?? '—';
                  final dateLabel = dateFormat.format(tracker.firstUtterance);
                  final languageLabel = tracker.language?.displayName ??
                      localization.translate('language_unknown');

                  final subtitle = [
                    dateLabel,
                    languageLabel,
                    if (tracker.phraseText != null &&
                        tracker.phraseText!.isNotEmpty)
                      localization
                          .translate('home_recent_from_phrase')
                          .replaceFirst('{phrase}', tracker.phraseText!),
                  ].join(' • ');

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
                      trailing: tracker.note != null && tracker.note!.isNotEmpty
                          ? Chip(
                              label: Text(
                                localization.translate('home_recent_has_note'),
                              ),
                              backgroundColor:
                                  theme.colorScheme.secondaryContainer,
                              labelStyle: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            )
                          : null,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
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
