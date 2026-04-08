import 'dart:convert';
import 'dart:math' as math;

import 'package:baby_words_tracker/data/models/child.dart';
import 'package:baby_words_tracker/data/models/word_tracker.dart';
import 'package:baby_words_tracker/pages/shared/bottom_bar.dart';
import 'package:baby_words_tracker/pages/shared/top_bar.dart';
import 'package:baby_words_tracker/l10n/localization_service.dart';
import 'package:baby_words_tracker/util/current_children_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

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
  Stream<List<WordTracker>>? _allWordsStream;
  late final Future<_NormCurve> _normCurveFuture;

  @override
  void initState() {
    super.initState();
    _normCurveFuture = _NormCurveLoader.load();
  }

  @override
  void dispose() {
    _pastWeekCountStream = null;
    _dailyWordCountStream = null;
    _monthlyWordCountStream = null;
    _allWordsStream = null;
    super.dispose();
  }

  Stream<List<WordTracker>> _watchAllWords(String childId) {
    return FirebaseFirestore.instance
        .collection(Child.collectionName)
        .doc(childId)
        .collection(WordTracker.collectionName)
        .orderBy('firstUtterance')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return WordTracker.fromMap(<String, dynamic>{
                ...doc.data(),
                'id': doc.id,
              });
            } catch (_) {
              return null;
            }
          })
          .whereType<WordTracker>()
          .toList();
    });
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
            _allWordsStream = _watchAllWords(child.id!);
          } else {
            _pastWeekCountStream = null;
            _dailyWordCountStream = null;
            _monthlyWordCountStream = null;
            _allWordsStream = null;
          }
        }

        final content = child == null ||
                _pastWeekCountStream == null ||
                _dailyWordCountStream == null ||
                _monthlyWordCountStream == null ||
                _allWordsStream == null
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
                    const SizedBox(height: 16),
                    _NormDevelopmentComparisonCard(
                      child: child,
                      wordsStream: _allWordsStream!,
                      normCurveFuture: _normCurveFuture,
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

class _NormDevelopmentComparisonCard extends StatelessWidget {
  const _NormDevelopmentComparisonCard({
    required this.child,
    required this.wordsStream,
    required this.normCurveFuture,
  });

  final Child child;
  final Stream<List<WordTracker>> wordsStream;
  final Future<_NormCurve> normCurveFuture;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: FutureBuilder<_NormCurve>(
        future: normCurveFuture,
        builder: (context, normSnapshot) {
          if (normSnapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (normSnapshot.hasError) {
            return _NormInfo(
              title: 'Development vs norm',
              message: normSnapshot.error.toString(),
            );
          }

          final normCurve = normSnapshot.data ?? _NormCurve.empty();
          if (normCurve.curve.isEmpty) {
            return const _NormInfo(
              title: 'Development vs norm',
              message:
                  'No usable month data found in assets/norm_words_by_month.json.',
            );
          }

          return StreamBuilder<List<WordTracker>>(
            stream: wordsStream,
            builder: (context, wordsSnapshot) {
              if (wordsSnapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final words = wordsSnapshot.data ?? const <WordTracker>[];
              final childCurve = _buildChildCurve(
                birthday: child.birthday,
                words: words,
              );

              final childAgeMonths = _monthsBetween(child.birthday, DateTime.now())
                  .clamp(0, 120);
              final expectedAtAge = normCurve.curve.cumulativeCountAt(childAgeMonths);
              final actualAtAge = childCurve.cumulativeCountAt(childAgeMonths);
              final gap = actualAtAge - expectedAtAge;

              final maxMonth = math.max(
                childAgeMonths,
                math.max(childCurve.maxMonth, normCurve.curve.maxMonth),
              );

              final normData = [
                for (int month = 0; month <= maxMonth; month++)
                  _CurvePoint(month, normCurve.curve.cumulativeCountAt(month)),
              ];
              final childData = [
                for (int month = 0; month <= maxMonth; month++)
                  _CurvePoint(month, childCurve.cumulativeCountAt(month)),
              ];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Development vs norm',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Age $childAgeMonths months • Child: $actualAtAge • Norm: $expectedAtAge',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    gap >= 0
                        ? '+$gap words compared with norm'
                        : '$gap words compared with norm',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: gap >= 0
                          ? Colors.green.shade700
                          : theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: SfCartesianChart(
                      margin: EdgeInsets.zero,
                      primaryXAxis: NumericAxis(
                        title: AxisTitle(text: 'Age (months)'),
                        interval: maxMonth > 24 ? 6 : 3,
                      ),
                      primaryYAxis: NumericAxis(
                        title: AxisTitle(text: 'Cumulative words'),
                      ),
                      legend: const Legend(isVisible: true),
                      series: <CartesianSeries<_CurvePoint, int>>[
                        LineSeries<_CurvePoint, int>(
                          name: 'Norm',
                          dataSource: normData,
                          xValueMapper: (_CurvePoint p, _) => p.month,
                          yValueMapper: (_CurvePoint p, _) => p.value,
                          color: theme.colorScheme.primary.withOpacity(0.7),
                          width: 2.5,
                        ),
                        LineSeries<_CurvePoint, int>(
                          name: child.name,
                          dataSource: childData,
                          xValueMapper: (_CurvePoint p, _) => p.month,
                          yValueMapper: (_CurvePoint p, _) => p.value,
                          color: theme.colorScheme.tertiary,
                          width: 3,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  _CumulativeCurve _buildChildCurve({
    required DateTime birthday,
    required List<WordTracker> words,
  }) {
    final monthlyCounts = <int, int>{};
    for (final word in words) {
      final month = _monthsBetween(birthday, word.firstUtterance);
      if (month < 0) {
        continue;
      }
      monthlyCounts[month] = (monthlyCounts[month] ?? 0) + 1;
    }

    final currentAgeMonths = _monthsBetween(birthday, DateTime.now()).clamp(0, 120);
    return _CumulativeCurve.fromMonthlyCounts(
      monthlyCounts,
      maxMonth: currentAgeMonths,
    );
  }
}

class _NormInfo extends StatelessWidget {
  const _NormInfo({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _CurvePoint {
  const _CurvePoint(this.month, this.value);

  final int month;
  final int value;
}

class _CumulativeCurve {
  const _CumulativeCurve(this.points);

  final List<_CurvePoint> points;

  bool get isEmpty => points.isEmpty;

  int get maxMonth => points.isEmpty ? 0 : points.last.month;

  int cumulativeCountAt(int month) {
    if (points.isEmpty) {
      return 0;
    }

    if (month <= points.first.month) {
      return points.first.value;
    }

    for (int i = points.length - 1; i >= 0; i--) {
      final point = points[i];
      if (point.month <= month) {
        return point.value;
      }
    }

    return 0;
  }

  factory _CumulativeCurve.fromMonthlyCounts(
    Map<int, int> monthlyCounts, {
    required int maxMonth,
  }) {
    if (maxMonth < 0) {
      return const _CumulativeCurve(<_CurvePoint>[]);
    }

    final points = <_CurvePoint>[];
    int cumulative = 0;
    for (int month = 0; month <= maxMonth; month++) {
      cumulative += monthlyCounts[month] ?? 0;
      points.add(_CurvePoint(month, cumulative));
    }
    return _CumulativeCurve(points);
  }
}

class _NormCurve {
  const _NormCurve({required this.curve});

  final _CumulativeCurve curve;

  factory _NormCurve.empty() {
    return const _NormCurve(curve: _CumulativeCurve(<_CurvePoint>[]));
  }
}

class _NormCurveLoader {
  static const String assetPath = 'assets/norm_words_by_month.json';

  static Future<_NormCurve> load() async {
    String jsonString;
    try {
      jsonString = await rootBundle.loadString(assetPath);
    } catch (_) {
      throw Exception(
        'Norm file not found at $assetPath. Add your JSON file and include it in pubspec assets.',
      );
    }

    final decoded = jsonDecode(jsonString);
    final monthlyCounts = <int, int>{};

    if (decoded is List) {
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) {
          continue;
        }
        final month = _extractMonth(item);
        if (month == null || month < 0) {
          continue;
        }
        monthlyCounts[month] = (monthlyCounts[month] ?? 0) + 1;
      }
    } else if (decoded is Map<String, dynamic>) {
      decoded.forEach((key, value) {
        final month = int.tryParse(key);
        if (month == null || month < 0) {
          return;
        }

        int count;
        if (value is int) {
          count = value;
        } else if (value is double) {
          count = value.round();
        } else if (value is String) {
          count = int.tryParse(value) ?? 0;
        } else {
          count = 0;
        }

        if (count > 0) {
          monthlyCounts[month] = (monthlyCounts[month] ?? 0) + count;
        }
      });
    }

    if (monthlyCounts.isEmpty) {
      return _NormCurve.empty();
    }

    final maxMonth = monthlyCounts.keys.reduce(math.max);
    return _NormCurve(
      curve: _CumulativeCurve.fromMonthlyCounts(
        monthlyCounts,
        maxMonth: maxMonth,
      ),
    );
  }

  static int? _extractMonth(Map<String, dynamic> item) {
    final monthValue = item['month'] ??
        item['ageMonth'] ??
        item['age_month'] ??
        item['learnedMonth'] ??
        item['learned_month'] ??
        item['monthLearned'] ??
        item['month_learned'];

    if (monthValue is int) {
      return monthValue;
    }
    if (monthValue is double) {
      return monthValue.round();
    }
    if (monthValue is String) {
      return int.tryParse(monthValue);
    }
    return null;
  }
}

int _monthsBetween(DateTime start, DateTime end) {
  int months = (end.year - start.year) * 12 + (end.month - start.month);
  if (end.day < start.day) {
    months -= 1;
  }
  return months;
}
