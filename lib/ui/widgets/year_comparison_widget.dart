import 'package:flutter/material.dart';
import '../../data/transaction_repository.dart';
import '../../models/transaction_model.dart';
import '../../utils/currency.dart';

class YearComparisonWidget extends StatelessWidget {
  final TransactionRepository txRepo;
  final int currentYear;

  const YearComparisonWidget({
    super.key,
    required this.txRepo,
    required this.currentYear,
  });

  Map<int, MonthData> _getMonthlyData(int year) {
    final data = <int, MonthData>{};
    final entries = txRepo.getAll();

    for (int month = 1; month <= 12; month++) {
      double income = 0;
      double expense = 0;

      for (final entry in entries) {
        final date = entry.model.date;
        if (date.year == year && date.month == month) {
          if (entry.model.type == TransactionType.income) {
            income += entry.model.amount;
          } else {
            expense += entry.model.amount;
          }
        }
      }

      data[month] = MonthData(
        month: month,
        income: income,
        expense: expense,
        net: income - expense,
      );
    }

    return data;
  }

  @override
  Widget build(BuildContext context) {
    final currentYearData = _getMonthlyData(currentYear);
    final previousYearData = _getMonthlyData(currentYear - 1);

    final currentTotal = currentYearData.values.fold<MonthData>(
      MonthData(month: 0, income: 0, expense: 0, net: 0),
      (sum, data) => MonthData(
        month: 0,
        income: sum.income + data.income,
        expense: sum.expense + data.expense,
        net: sum.net + data.net,
      ),
    );

    final previousTotal = previousYearData.values.fold<MonthData>(
      MonthData(month: 0, income: 0, expense: 0, net: 0),
      (sum, data) => MonthData(
        month: 0,
        income: sum.income + data.income,
        expense: sum.expense + data.expense,
        net: sum.net + data.net,
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Year-over-Year Comparison',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Chip(
                  label: Text('$currentYear vs ${currentYear - 1}'),
                  labelStyle: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Summary comparison
            _ComparisonRow(
              label: 'Total Income',
              currentValue: currentTotal.income,
              previousValue: previousTotal.income,
              isIncome: true,
            ),
            const SizedBox(height: 8),
            _ComparisonRow(
              label: 'Total Expense',
              currentValue: currentTotal.expense,
              previousValue: previousTotal.expense,
              isIncome: false,
            ),
            const SizedBox(height: 8),
            _ComparisonRow(
              label: 'Net',
              currentValue: currentTotal.net,
              previousValue: previousTotal.net,
              isNet: true,
            ),
            
            const Divider(height: 32),
            
            // Monthly breakdown
            Text(
              'Monthly Breakdown',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            
            ...List.generate(12, (index) {
              final month = index + 1;
              final current = currentYearData[month]!;
              final previous = previousYearData[month]!;
              
              if (current.income == 0 && current.expense == 0 && 
                  previous.income == 0 && previous.expense == 0) {
                return const SizedBox.shrink();
              }
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MonthComparisonTile(
                  month: month,
                  currentData: current,
                  previousData: previous,
                  currentYear: currentYear,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final double currentValue;
  final double previousValue;
  final bool isIncome;
  final bool isNet;

  const _ComparisonRow({
    required this.label,
    required this.currentValue,
    required this.previousValue,
    this.isIncome = false,
    this.isNet = false,
  });

  @override
  Widget build(BuildContext context) {
    final diff = currentValue - previousValue;
    final percentChange = previousValue == 0
        ? (currentValue == 0 ? 0.0 : 100.0)
        : ((diff / previousValue) * 100);

    final isPositiveGood = isNet || isIncome;
    final isGoodChange = isPositiveGood ? diff > 0 : diff < 0;
    
    final changeColor = diff == 0
        ? Theme.of(context).colorScheme.outline
        : isGoodChange
            ? Colors.green
            : Colors.red;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                formatRupiah(currentValue),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                Icon(
                  diff > 0 ? Icons.arrow_upward : diff < 0 ? Icons.arrow_downward : Icons.remove,
                  size: 16,
                  color: changeColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '${percentChange.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: changeColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Text(
              formatRupiah(previousValue),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MonthComparisonTile extends StatelessWidget {
  final int month;
  final MonthData currentData;
  final MonthData previousData;
  final int currentYear;

  const _MonthComparisonTile({
    required this.month,
    required this.currentData,
    required this.previousData,
    required this.currentYear,
  });

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final diff = currentData.net - previousData.net;
    
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              _getMonthName(month),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    formatRupiah(currentData.net),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                Icon(
                  diff > 0 ? Icons.trending_up : diff < 0 ? Icons.trending_down : Icons.trending_flat,
                  size: 16,
                  color: diff > 0
                      ? Colors.green
                      : diff < 0
                          ? Colors.red
                          : Theme.of(context).colorScheme.outline,
                ),
              ],
            ),
          ),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(52, 0, 0, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Income',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${formatRupiah(currentData.income)} / ${formatRupiah(previousData.income)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Expense',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${formatRupiah(currentData.expense)} / ${formatRupiah(previousData.expense)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MonthData {
  final int month;
  final double income;
  final double expense;
  final double net;

  MonthData({
    required this.month,
    required this.income,
    required this.expense,
    required this.net,
  });
}
