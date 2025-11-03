import 'package:flutter/material.dart';
import 'dart:math' as Math;
import 'package:fl_chart/fl_chart.dart';

import '../../data/transaction_repository.dart';
import '../../data/category_repository.dart';
import '../../data/wallet_repository.dart';
import '../../models/transaction_model.dart';
import '../../models/category_model.dart';
import '../../utils/currency.dart';
import '../../state/app_state.dart';
import '../widgets/app_bottom_bar.dart';
import 'edit_transaction_screen.dart';
import '../../data/settings_repository.dart';
import '../../utils/date_period.dart';

class ReportsScreen extends StatefulWidget {
  final TransactionRepository txRepo;
  final CategoryRepository categoryRepo;
  final WalletRepository walletRepo;
  final AppState state;

  const ReportsScreen({
    super.key,
    required this.txRepo,
    required this.categoryRepo,
    required this.walletRepo,
    required this.state,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late DateTime _now;
  late MonthPeriod _period;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    final firstDay = SettingsRepository().getFirstDayOfMonth();
    _period = computeCustomMonthPeriod(_now, firstDay);
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.txRepo.getAll();
    final daily = _buildDailySeries(entries);
    final categories = _buildCategoryBreakdown(entries);

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-add-tx',
        tooltip: 'Add transaction',
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => EditTransactionScreen(
              state: widget.state,
              categoryRepo: widget.categoryRepo,
              walletRepo: widget.walletRepo,
            ),
          ));
          if (context.mounted) setState(() {});
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: ValueListenableBuilder(
        valueListenable: SettingsRepository().listenable(),
        builder: (context, __, ___) {
          // Recompute period when settings change
          final firstDay = SettingsRepository().getFirstDayOfMonth();
          _period = computeCustomMonthPeriod(DateTime.now(), firstDay);
          return ValueListenableBuilder(
            valueListenable: widget.txRepo.listenable(),
            builder: (context, _, __) {
              final entries = widget.txRepo.getAll();
              final daily = _buildDailySeries(entries);
              final categories = _buildCategoryBreakdown(entries);
              final daysInPeriod = _period.end.difference(_period.start).inDays;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('This Month', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _Card(
                    child: _IncomeExpenseLineChart(
                      series: daily,
                      days: daysInPeriod,
                      startDate: _period.start,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Expenses by Category', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _Card(child: _CategoryPieChart(data: categories, categoryRepo: widget.categoryRepo)),
                ],
              );
            },
          );
        },
      ),
      bottomNavigationBar: AppBottomBar(
        current: AppSection.reports,
        walletRepo: widget.walletRepo,
        categoryRepo: widget.categoryRepo,
        txRepo: widget.txRepo,
        state: widget.state,
        withNotch: true,
      ),
    );
  }

  Map<int, _DailyPoint> _buildDailySeries(List<TransactionEntry> entries) {
    final Map<int, _DailyPoint> out = {};
    for (final e in entries) {
      final t = e.model;
      if (t.date.isBefore(_period.start) || !t.date.isBefore(_period.end)) continue;
      final dayIndex = t.date.difference(_period.start).inDays + 1; // 1-based index within period
      out.putIfAbsent(dayIndex, () => _DailyPoint(dayIndex, 0, 0));
      if (t.type == TransactionType.income) {
        out[dayIndex] = out[dayIndex]!.copyWith(income: out[dayIndex]!.income + t.amount);
      } else {
        out[dayIndex] = out[dayIndex]!.copyWith(expense: out[dayIndex]!.expense + t.amount);
      }
    }
    // Ensure all days exist for smooth chart
    final daysInPeriod = _period.end.difference(_period.start).inDays;
    for (int d = 1; d <= daysInPeriod; d++) {
      out.putIfAbsent(d, () => _DailyPoint(d, 0, 0));
    }
    return out;
  }

  Map<String, double> _buildCategoryBreakdown(List<TransactionEntry> entries) {
    final Map<String, double> out = {};
    for (final e in entries) {
      final t = e.model;
      if (t.type != TransactionType.expense) continue;
      if (t.date.isBefore(_period.start) || !t.date.isBefore(_period.end)) continue;
      out[t.categoryId] = (out[t.categoryId] ?? 0) + t.amount;
    }
    return out;
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }
}

class _DailyPoint {
  final int day;
  final double income;
  final double expense;
  const _DailyPoint(this.day, this.income, this.expense);
  _DailyPoint copyWith({int? day, double? income, double? expense}) =>
      _DailyPoint(day ?? this.day, income ?? this.income, expense ?? this.expense);
}

class _IncomeExpenseLineChart extends StatelessWidget {
  final Map<int, _DailyPoint> series;
  final int days; // days in current period
  final DateTime startDate;
  const _IncomeExpenseLineChart({required this.series, required this.days, required this.startDate});

  @override
  Widget build(BuildContext context) {
    final daysIdx = series.keys.toList()..sort();
    DateTime dateForIndex(int index) => startDate.add(Duration(days: index - 1));
    final incomeSpots = [
      for (final d in daysIdx) FlSpot(d.toDouble(), series[d]!.income)
    ];
    final expenseSpots = [
      for (final d in daysIdx) FlSpot(d.toDouble(), series[d]!.expense)
    ];

    final nice = _niceScale(incomeSpots, expenseSpots);
    final isEmptyData = nice.maxY <= 0.0;

    final chart = SizedBox(
      height: 240,
      child: LineChart(
        LineChartData(
          minX: daysIdx.first.toDouble(),
          maxX: daysIdx.last.toDouble(),
          minY: 0,
          maxY: isEmptyData ? 1 : nice.maxY,
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: isEmptyData ? 1 : nice.interval,
            verticalInterval: _xIntervalLocal(days),
            getDrawingHorizontalLine: (value) => FlLine(
              color: Theme.of(context).colorScheme.outlineVariant,
              strokeWidth: 1,
            ),
            getDrawingVerticalLine: (value) => FlLine(
              color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
              strokeWidth: 0.5,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                interval: isEmptyData ? 1 : nice.interval,
                getTitlesWidget: (v, meta) {
                  return Text(_compactRupiah(v), style: Theme.of(context).textTheme.bodySmall);
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: _xIntervalLocal(days),
                getTitlesWidget: (v, meta) {
                  if (v % 1 != 0) return const SizedBox.shrink();
                  final d = v.toInt();
                  final date = dateForIndex(d);
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 4,
                    child: Text(
                      date.day.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Theme.of(context).dividerColor, width: 1),
          ),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => Theme.of(context).colorScheme.surface.withOpacity(0.95),
              getTooltipItems: (items) {
                return items.map((it) {
                  final day = it.x.round();
                  final date = dateForIndex(day);
                  final label = it.barIndex == 0 ? 'Income' : 'Expense';
                  return LineTooltipItem(
                    '$label\n${date.day}/${date.month}\n${formatRupiah(it.y, includeSymbol: true)}',
                    Theme.of(context).textTheme.bodySmall!,
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: incomeSpots,
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(colors: [Colors.green.withOpacity(0.25), Colors.green.withOpacity(0.05)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              ),
            ),
            LineChartBarData(
              spots: expenseSpots,
              isCurved: true,
              color: Theme.of(context).colorScheme.error,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(colors: [Theme.of(context).colorScheme.error.withOpacity(0.2), Theme.of(context).colorScheme.error.withOpacity(0.04)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              ),
            ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _LegendDot(color: Colors.green, label: 'Income'),
            const SizedBox(width: 12),
            _LegendDot(color: Theme.of(context).colorScheme.error, label: 'Expense'),
          ],
        ),
        const SizedBox(height: 8),
        chart,
      ],
    );
  }

  double _xIntervalLocal(int daysCount) {
    if (daysCount <= 10) return 1;
    if (daysCount <= 20) return 2;
    return 5;
  }

  

  // Produce a nice Y scale with rounded max and tick interval
  _NiceScale _niceScale(List<FlSpot> a, List<FlSpot> b) {
    double maxVal = 0;
    for (final s in [...a, ...b]) {
      if (s.y > maxVal) maxVal = s.y;
    }
    if (maxVal <= 0) return const _NiceScale(0, 1);
    final exp = (maxVal == 0 ? 0 : (maxVal.log10()).floor());
    final pow10 = Math.pow(10, exp).toDouble();
    final f = maxVal / pow10;
    double niceF;
    if (f <= 1) {
      niceF = 1;
    } else if (f <= 2) {
      niceF = 2;
    } else if (f <= 5) {
      niceF = 5;
    } else {
      niceF = 10;
    }
    final niceMax = niceF * pow10;
    // aim for ~4 horizontal lines
    final intervals = [1.0, 2.0, 2.5, 5.0, 10.0];
    double base = niceMax / 4;
    // round base to nice step
    final baseExp = (base.log10()).floor();
    final basePow10 = Math.pow(10, baseExp).toDouble();
    final bf = base / basePow10;
    double chosen = intervals.first;
    for (final cand in intervals) {
      if (bf <= cand) {
        chosen = cand;
        break;
      }
    }
    final interval = chosen * basePow10;
    return _NiceScale(niceMax, interval);
  }

  String _compactRupiah(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(0)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(0)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}k';
    return v.toInt().toString();
  }
}

class _NiceScale {
  final double maxY;
  final double interval;
  const _NiceScale(this.maxY, this.interval);
}

// Small helpers because dart:math has no log10()
extension _Log10 on num {
  double log10() => Math.log(this) / Math.ln10;
}

// Ignore name shadowing with dart:math
// We alias Math to avoid confusion with Flutter's math utilities
// and to make extension above compile cleanly.

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _CategoryPieChart extends StatelessWidget {
  final Map<String, double> data; // categoryId -> amount
  final CategoryRepository categoryRepo;
  const _CategoryPieChart({required this.data, required this.categoryRepo});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('No expenses this month.')),
      );
    }

    final total = data.values.fold<double>(0, (a, b) => a + b);
    final sections = <PieChartSectionData>[];
    final colors = _palette(Theme.of(context).colorScheme);
    int i = 0;
    for (final entry in data.entries) {
      final amount = entry.value;
      final pct = amount / (total == 0 ? 1 : total);
      sections.add(PieChartSectionData(
        value: amount,
        color: colors[i % colors.length],
        title: '${(pct * 100).toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
      ));
      i++;
    }

    final legend = [
      for (final e in data.entries)
        _LegendEntry(
          color: colors[data.keys.toList().indexOf(e.key) % colors.length],
          label: categoryRepo.getById(e.key)?.name ?? 'Unknown',
          amount: e.value,
        ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 42,
                  sectionsSpace: 2,
                  pieTouchData: PieTouchData(enabled: true),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Total', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 2),
                  Text(formatRupiah(total), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            for (final l in legend)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: l.color, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('${l.label}: ${formatRupiah(l.amount)}'),
              ]),
          ],
        ),
      ],
    );
  }

  List<Color> _palette(ColorScheme cs) => [
        cs.primary,
        cs.secondary,
        cs.tertiary,
        cs.error,
        cs.primaryContainer,
        cs.secondaryContainer,
        cs.tertiaryContainer,
      ];
}

class _LegendEntry {
  final Color color;
  final String label;
  final double amount;
  _LegendEntry({required this.color, required this.label, required this.amount});
}
