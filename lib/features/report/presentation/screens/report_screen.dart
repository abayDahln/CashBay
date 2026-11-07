import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/report_provider.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';

const _posColor = AppTheme.income;
const _negColor = AppTheme.expense;

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Consumer<ReportProvider>(
        builder: (context, report, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              Text(
                'Analytics',
                style: AppTypography.largeTitle.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              _modeChips(report),
              const SizedBox(height: 8),
              _filterRow(report),
              const SizedBox(height: 16),
              if (report.isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              _summaryCards(report),
              const SizedBox(height: 20),
              _sectionHeader('Grafik Arus Kas'),
              const SizedBox(height: 12),
              if (report.chartData.isNotEmpty)
                _divergingChart(report)
              else
                _emptyChart(),
              if (report.recentTransactions.isNotEmpty) ...[
                const SizedBox(height: 20),
                _sectionHeader('Transaksi Terbaru'),
                const SizedBox(height: 8),
                ...report.recentTransactions.map(_transactionTile),
              ],
              if (report.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    'Error: ${report.error}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ],
        );
      },
      ),
    );
  }

  Widget _modeChips(ReportProvider report) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ChartMode.values.map((m) {
          final selected = report.chartMode == m;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => report.setChartMode(m),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? scheme.primaryContainer
                      : scheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? scheme.primaryContainer
                        : scheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  _modeLabel(m),
                  style: AppTypography.footnote.copyWith(
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _filterRow(ReportProvider report) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _dropdown<int>(
            value: report.selectedYear,
            items: report.availableYears,
            labelBuilder: (y) => y.toString(),
            onChanged: (v) {
              if (v != null) report.setYear(v);
            },
          ),
          if (report.chartMode == ChartMode.daily) ...[
            const SizedBox(width: 8),
            _dropdown<int>(
              value: report.selectedMonth,
              items: List.generate(12, (i) => i + 1),
              labelBuilder: (m) {
                const months = [
                  'Jan',
                  'Feb',
                  'Mar',
                  'Apr',
                  'Mei',
                  'Jun',
                  'Jul',
                  'Agu',
                  'Sep',
                  'Okt',
                  'Nov',
                  'Des',
                ];
                return months[m - 1];
              },
              onChanged: (v) {
                if (v != null) report.setMonth(v);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required void Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(labelBuilder(e), style: TextStyle(fontSize: 13)),
                ),
              )
              .toList(),
          onChanged: onChanged,
          isDense: true,
        ),
      ),
    );
  }

  String _modeLabel(ChartMode m) {
    switch (m) {
      case ChartMode.daily:
        return 'Harian';
      case ChartMode.monthly:
        return 'Bulanan';
      case ChartMode.yearly:
        return 'Tahunan';
    }
  }

  Widget _summaryCards(ReportProvider report) {
    final cards = [
      _summaryCard(
        'Pendapatan',
        CurrencyFormatter.formatMedium(report.totalIncome),
        Icons.trending_up,
        _posColor,
      ),
      _summaryCard(
        'Pengeluaran',
        CurrencyFormatter.formatMedium(report.totalExpense),
        Icons.trending_down,
        _negColor,
      ),
      _summaryCard(
        'Selisih',
        CurrencyFormatter.formatMedium(report.balance),
        Icons.balance,
        report.balance >= 0 ? _posColor : _negColor,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) => GridView.count(
        crossAxisCount: constraints.maxWidth >= 720 ? 3 : 1,
        childAspectRatio: constraints.maxWidth >= 720 ? 2.2 : 4.2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: cards,
      ),
    );
  }

  Widget _summaryCard(String label, String amount, IconData icon, Color color) {
    return AppCard(
      showBorder: true,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            foregroundColor: color,
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  amount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.headline.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _emptyChart() {
    return Container(
      height: 200,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        'Tidak ada data',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 14,
        ),
      ),
    );
  }

  String _tooltipLabel(ChartBarData d, ChartMode mode) {
    if (d.date == null) return d.label;
    switch (mode) {
      case ChartMode.daily:
        final dayName = DateFormat('EEEE', 'id_ID').format(d.date!);
        final shortDate = DateFormat('dd MMM', 'id_ID').format(d.date!);
        return '$dayName, $shortDate';
      case ChartMode.monthly:
        return DateFormatter.formatMonthYear(d.date!);
      case ChartMode.yearly:
        return d.date!.year.toString();
    }
  }

  Widget _divergingChart(ReportProvider report) {
    final data = report.chartData;
    final mode = report.chartMode;
    final barGroups = <BarChartGroupData>[];
    double minVal = 0, maxVal = 0;

    for (var i = 0; i < data.length; i++) {
      final v = data[i].netBalance;
      if (v < minVal) minVal = v;
      if (v > maxVal) maxVal = v;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: v,
              color: v >= 0 ? _posColor : _negColor,
              width: 20,
              borderRadius: v >= 0
                  ? const BorderRadius.vertical(top: Radius.circular(5))
                  : const BorderRadius.vertical(bottom: Radius.circular(5)),
            ),
          ],
        ),
      );
    }

    final range = maxVal.abs() > minVal.abs() ? maxVal.abs() : minVal.abs();
    final step = range == 0 ? 2000.0 : _niceStep(range);
    final actualMax = ((maxVal / step).ceil() + 1) * step;
    final actualMin = ((minVal / step).floor() - 1) * step;

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            height: 260,
            width: (data.length * 40.0).clamp(
              MediaQuery.of(context).size.width - 32,
              double.infinity,
            ),
            padding: const EdgeInsets.fromLTRB(8, 24, 16, 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.start,
                barGroups: barGroups,
                maxY: actualMax,
                minY: actualMin,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    getTooltipColor: (_) =>
                        Theme.of(context).colorScheme.inverseSurface,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final d = data[group.x];
                      return BarTooltipItem(
                        '${_tooltipLabel(d, mode)}\n${CurrencyFormatter.formatShort(d.netBalance.abs())}',
                        TextStyle(
                          color: Theme.of(context).colorScheme.surface,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                        final i = val.toInt();
                        if (i < 0 || i >= data.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            data[i].label,
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                      reservedSize: 28,
                      interval: 1,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      interval: step,
                      getTitlesWidget: (val, _) {
                        if (val == 0) {
                          return Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Text(
                              '0',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            CurrencyFormatter.formatShort(val),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (val) => FlLine(
                    color: val == 0
                        ? Theme.of(context).colorScheme.outline
                        : Theme.of(context).colorScheme.outlineVariant,
                    strokeWidth: val == 0 ? 1.5 : 1,
                    dashArray: val == 0 ? null : [6, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
              duration: const Duration(milliseconds: 300),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _legend(),
      ],
    );
  }

  Widget _legend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(_posColor, 'Surplus'),
        const SizedBox(width: 24),
        _legendItem(_negColor, 'Defisit'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  static double _niceStep(double range) {
    final magnitude = math
        .pow(10, (math.log(range) / math.ln10).floor())
        .toDouble();
    final normalized = range / magnitude;
    double nice;
    if (normalized <= 1.5) {
      nice = 1;
    } else if (normalized <= 3.5) {
      nice = 2;
    } else if (normalized <= 7.5) {
      nice = 5;
    } else {
      nice = 10;
    }
    return nice * magnitude;
  }

  Widget _transactionTile(Transaction tx) {
    final isIncome = tx.type == 'income';
    final color = isIncome ? _posColor : _negColor;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(isIncome ? Icons.south : Icons.north, color: color),
        title: Text(
          tx.description ??
              tx.note ??
              (isIncome ? 'Pendapatan' : 'Pengeluaran'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(DateFormatter.formatDate(tx.date)),
        trailing: Text(
          '${isIncome ? '' : '-'}${CurrencyFormatter.formatMedium(tx.amount)}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color),
        ),
      ),
    );
  }
}
