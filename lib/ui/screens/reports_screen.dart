import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../data/transaction_repository.dart';
import '../../data/category_repository.dart';
import '../../models/transaction_model.dart';
import '../../models/category_model.dart';
import '../../utils/currency.dart';

class ReportsScreen extends StatefulWidget {
  final TransactionRepository txRepo;
  final CategoryRepository categoryRepo;

  const ReportsScreen({super.key, required this.txRepo, required this.categoryRepo});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late DateTime _now;
  late DateTime _monthStart;
  late DateTime _nextMonth;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _monthStart = DateTime(_now.year, _now.month);
    _nextMonth = DateTime(_now.year, _now.month + 1);
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.txRepo.getAll();
    final daily = _buildDailySeries(entries);
    final categories = _buildCategoryBreakdown(entries);

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('This Month', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _Card(child: _IncomeExpenseLineChart(series: daily)),
          const SizedBox(height: 16),
          Text('Expenses by Category', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _Card(child: _CategoryPieChart(data: categories, categoryRepo: widget.categoryRepo)),
        ],
      ),
    );
  }

  Map<int, _DailyPoint> _buildDailySeries(List<TransactionEntry> entries) {
    final Map<int, _DailyPoint> out = {};
    for (final e in entries) {
      final t = e.model;
      if (t.date.isBefore(_monthStart) || !t.date.isBefore(_nextMonth)) continue;
      final day = DateTime(t.date.year, t.date.month, t.date.day).day;
      out.putIfAbsent(day, () => _DailyPoint(day, 0, 0));
      if (t.type == TransactionType.income) {
        out[day] = out[day]!.copyWith(income: out[day]!.income + t.amount);
      } else {
        out[day] = out[day]!.copyWith(expense: out[day]!.expense + t.amount);
      }
    }
    // Ensure all days exist for smooth chart
    final daysInMonth = DateUtils.getDaysInMonth(_monthStart.year, _monthStart.month);
    for (int d = 1; d <= daysInMonth; d++) {
      out.putIfAbsent(d, () => _DailyPoint(d, 0, 0));
    }
    return out;
  }

  Map<String, double> _buildCategoryBreakdown(List<TransactionEntry> entries) {
    final Map<String, double> out = {};
    for (final e in entries) {
      final t = e.model;
      if (t.type != TransactionType.expense) continue;
      if (t.date.isBefore(_monthStart) || !t.date.isBefore(_nextMonth)) continue;
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
  const _IncomeExpenseLineChart({required this.series});

  @override
  Widget build(BuildContext context) {
    final days = series.keys.toList()..sort();
    final incomeSpots = [
      for (final d in days) FlSpot(d.toDouble(), series[d]!.income)
    ];
    final expenseSpots = [
      for (final d in days) FlSpot(d.toDouble(), series[d]!.expense)
    ];

    final maxY = _maxY(incomeSpots, expenseSpots);

    final chart = SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minX: days.first.toDouble(),
          maxX: days.last.toDouble(),
          minY: 0,
          maxY: maxY == 0 ? 1 : maxY,
          gridData: FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44, getTitlesWidget: (v, meta) {
              return Text(formatRupiah(v, includeSymbol: false), style: Theme.of(context).textTheme.bodySmall);
            })),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 5, getTitlesWidget: (v, meta) {
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(v.toInt().toString(), style: Theme.of(context).textTheme.bodySmall),
              );
            })),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: incomeSpots,
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              dotData: const FlDotData(show: false),
            ),
            LineChartBarData(
              spots: expenseSpots,
              isCurved: true,
              color: Theme.of(context).colorScheme.error,
              barWidth: 3,
              dotData: const FlDotData(show: false),
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

  double _maxY(List<FlSpot> a, List<FlSpot> b) {
    double m = 0;
    for (final s in [...a, ...b]) {
      if (s.y > m) m = s.y;
    }
    // Add a little headroom
    return m * 1.2;
  }
}

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
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
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
