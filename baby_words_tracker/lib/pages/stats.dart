import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:baby_words_tracker/pages/shared/bottom_bar.dart';
import 'package:baby_words_tracker/pages/shared/top_bar.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:baby_words_tracker/util/current_children_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StatsPage extends StatefulWidget {
  static const routeName = '/stats';

  final bool showChrome;

  const StatsPage({super.key, this.showChrome = true});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  String? _currentChildId;
  Stream<int>? _pastWeekCountStream;
  Stream<List<_DailyWordCount>>? _dailyWordCountStream;
  Stream<Map<DateTime, int>>? _monthlyWordCountStream;

  @override
  void dispose() {
    _pastWeekCountStream = null;
    _dailyWordCountStream = null;
    _monthlyWordCountStream = null;
    super.dispose();
  }

  Stream<int> _watchPastWeekCount(String childId) {
    final lastWeek = DateTime.now().subtract(const Duration(days: 7));

    return FirebaseFirestore.instance
        .collection(Child.collectionName)
        .doc(childId)
        .collection(WordTracker.collectionName)
        .where('firstUtterance', isGreaterThanOrEqualTo: lastWeek)
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .distinct();
  }

  Stream<List<_DailyWordCount>> _watchLast7DaysWordCounts(String childId) {
    final now = DateTime.now();
    final startDay = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));

    return FirebaseFirestore.instance
        .collection(Child.collectionName)
        .doc(childId)
        .collection(WordTracker.collectionName)
        .where('firstUtterance', isGreaterThanOrEqualTo: startDay)
        .snapshots()
        .map((snapshot) {
      final counts = <DateTime, int>{
        for (int i = 0; i < 7; i++)
          startDay.add(Duration(days: i)): 0,
      };

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final raw = data['firstUtterance'];

        DateTime? utterance;
        if (raw is Timestamp) {
          utterance = raw.toDate();
        } else if (raw is DateTime) {
          utterance = raw;
        }

        if (utterance == null) {
          continue;
        }

        final day = DateTime(
          utterance.year,
          utterance.month,
          utterance.day,
        );

        if (counts.containsKey(day)) {
          counts[day] = (counts[day] ?? 0) + 1;
        }
      }

      final sortedDays = counts.keys.toList()..sort();
      return sortedDays
          .map((day) => _DailyWordCount(
                dayLabel: _weekdayLabel(day.weekday),
                count: counts[day] ?? 0,
              ))
          .toList();
    });
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      default:
        return 'Sun';
    }
  }

  Stream<Map<DateTime, int>> _watchCurrentMonthWordCounts(String childId) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return FirebaseFirestore.instance
        .collection(Child.collectionName)
        .doc(childId)
        .collection(WordTracker.collectionName)
        .where('firstUtterance',
            isGreaterThanOrEqualTo: firstDayOfMonth,
            isLessThanOrEqualTo: lastDayOfMonth)
        .snapshots()
        .map((snapshot) {
      final counts = <DateTime, int>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final raw = data['firstUtterance'];

        DateTime? utterance;
        if (raw is Timestamp) {
          utterance = raw.toDate();
        } else if (raw is DateTime) {
          utterance = raw;
        }

        if (utterance == null) continue;

        final day = DateTime(
          utterance.year,
          utterance.month,
          utterance.day,
        );

        counts[day] = (counts[day] ?? 0) + 1;
      }

      return counts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocalizationService, CurrentChildrenService>(
      builder: (context, localization, currentChildrenService, _) {
        final child = currentChildrenService.getCurrChild();

        // Only recreate stream if child has changed
        if (child?.id != _currentChildId) {
          _currentChildId = child?.id;
          if (child?.id != null) {
            _pastWeekCountStream = _watchPastWeekCount(child!.id!);
            _dailyWordCountStream = _watchLast7DaysWordCounts(child.id!);
            _monthlyWordCountStream = _watchCurrentMonthWordCounts(child.id!);
          } else {
            _pastWeekCountStream = null;
            _dailyWordCountStream = null;
            _monthlyWordCountStream = null;
          }
        }

        final content = child == null ||
                _pastWeekCountStream == null ||
                _dailyWordCountStream == null ||
                _monthlyWordCountStream == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_graph_outlined,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withOpacity(0.6),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        localization.translate('log_no_child_selected'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        localization.translate('log_add_child_hint'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withOpacity(0.8),
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _WeeklySummaryWithBarChart(
                      weeklyStream: _pastWeekCountStream!,
                      dailyStream: _dailyWordCountStream!,
                      localization: localization,
                    ),
                    const SizedBox(height: 16),
                    _MonthlyCalendarHeatmap(
                      stream: _monthlyWordCountStream!,
                      localization: localization,
                    ),
                  ],
                ),
              );

        if (!widget.showChrome) {
          return content;
        }

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: TopBar(
            pageName: localization.translate("learning_summary"),
          ),
          body: content,
          bottomNavigationBar: const CustomBottomBar(StatsPage.routeName),
        );
      },
    );
  }
}

class _WeeklySummaryWithBarChart extends StatelessWidget {
  const _WeeklySummaryWithBarChart({
    required this.weeklyStream,
    required this.dailyStream,
    required this.localization,
  });

  final Stream<int> weeklyStream;
  final Stream<List<_DailyWordCount>> dailyStream;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StreamBuilder<int>(
            stream: weeklyStream,
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
          const SizedBox(height: 16),
          StreamBuilder<List<_DailyWordCount>>(
            stream: dailyStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final data = snapshot.data ?? const <_DailyWordCount>[];
              final highestCount = data.isEmpty
                  ? 1
                  : data
                      .map((entry) => entry.count)
                      .reduce((a, b) => a > b ? a : b)
                      .clamp(1, 1000000);

              return SizedBox(
                height: 180,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final entry in data)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                entry.count.toString(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: entry.count == 0
                                    ? 2
                                    : (entry.count / highestCount) * 100,
                                width: 18,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                entry.dayLabel,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DailyWordCount {
  const _DailyWordCount({
    required this.dayLabel,
    required this.count,
  });

  final String dayLabel;
  final int count;
}

class _MonthlyCalendarHeatmap extends StatelessWidget {
  const _MonthlyCalendarHeatmap({
    required this.stream,
    required this.localization,
  });

  final Stream<Map<DateTime, int>> stream;
  final LocalizationService localization;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;

    // Convert Dart weekday (Mon=1..Sun=7) to Sunday-first index (Sun=1..Sat=7)
    final firstWeekday = (firstDayOfMonth.weekday % 7) + 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: StreamBuilder<Map<DateTime, int>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final data = snapshot.data ?? <DateTime, int>{};
          final maxCount = data.values.isEmpty
              ? 1
              : data.values.reduce((a, b) => a > b ? a : b).clamp(1, 1000000);

          // Month name
          final monthNames = [
            'January',
            'February',
            'March',
            'April',
            'May',
            'June',
            'July',
            'August',
            'September',
            'October',
            'November',
            'December'
          ];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${monthNames[now.month - 1]} ${now.year}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              // Weekday headers
              Row(
                children: [
                  for (final day in ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                    Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Calendar grid
              _buildCalendarGrid(
                theme,
                firstWeekday,
                daysInMonth,
                data,
                maxCount,
                now,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCalendarGrid(
    ThemeData theme,
    int firstWeekday,
    int daysInMonth,
    Map<DateTime, int> data,
    int maxCount,
    DateTime now,
  ) {
    final rows = <Widget>[];
    int dayCounter = 1;

    // Build rows (weeks)
    while (dayCounter <= daysInMonth) {
      final weekCells = <Widget>[];

      // Build 7 days for this week
      for (int i = 1; i <= 7; i++) {
        if ((dayCounter == 1 && i < firstWeekday) || dayCounter > daysInMonth) {
          // Empty cell before month starts or after month ends
          weekCells.add(
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(),
              ),
            ),
          );
        } else {
          // Valid day in month
          final dayDate = DateTime(now.year, now.month, dayCounter);
          final count = data[dayDate] ?? 0;
          final isToday = dayDate.year == now.year &&
              dayDate.month == now.month &&
              dayDate.day == now.day;

          weekCells.add(
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getColorForCount(theme, count, maxCount),
                      borderRadius: BorderRadius.circular(6),
                      border: isToday
                          ? Border.all(
                              color: theme.colorScheme.primary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        dayCounter.toString(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: count > 0
                              ? Colors.white
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight:
                              count > 0 ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          dayCounter++;
        }
      }

      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: weekCells),
        ),
      );
    }

    return Column(children: rows);
  }

  Color _getColorForCount(ThemeData theme, int count, int maxCount) {
    if (count == 0) {
      return theme.colorScheme.surfaceContainerHigh;
    }

    // GitHub-style intensity levels
    final intensity = (count / maxCount).clamp(0.0, 1.0);
    final baseColor = theme.colorScheme.primary;

    if (intensity <= 0.25) {
      return baseColor.withOpacity(0.3);
    } else if (intensity <= 0.5) {
      return baseColor.withOpacity(0.5);
    } else if (intensity <= 0.75) {
      return baseColor.withOpacity(0.7);
    } else {
      return baseColor;
    }
  }
}
