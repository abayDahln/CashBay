import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/report_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/app_localizations.dart';

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
    final t = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Consumer<ReportProvider>(
      builder: (context, report, _) {
        return RefreshIndicator(
          onRefresh: report.loadChartData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar.medium(title: Text(t.analytics)),
              // Year bar + tabs span the full width (no side padding).
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _yearBar(report),
                ),
              ),
              SliverToBoxAdapter(child: _seriesSelector(report)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
                sliver: SliverList.list(
                  children: [
                    if (report.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else ...[
                      if (report.error != null) ...[
                        AppCard(
                          color: scheme.errorContainer,
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: scheme.onErrorContainer,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  t.errorPrefix('${report.error}'),
                                  style: text.bodyMedium?.copyWith(
                                    color: scheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _summaryCard(report),
                      const SizedBox(height: 8),
                      _SectionHeader(t.chartCashFlow),
                      if (report.chartData.isNotEmpty)
                        _barChart(report)
                      else
                        AppCard(
                          variant: AppCardVariant.outlined,
                          padding: EdgeInsets.zero,
                          child: EmptyState(
                            icon: Icons.bar_chart_outlined,
                            message: t.noData,
                            subtitle: t.noDataPeriod,
                          ),
                        ),
                      if (report.selectedMonthTransactions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _SectionHeader(t.transactionsLabel),
                        AppCard(
                          variant: AppCardVariant.outlined,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            children: [
                              for (
                                var i = 0;
                                i < report.selectedMonthTransactions.length;
                                i++
                              ) ...[
                                if (i > 0)
                                  const Divider(height: 1, indent: 72),
                                TransactionTile(
                                  transaction:
                                      report.selectedMonthTransactions[i],
                                  showChevron: false,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _seriesSelector(ReportProvider report) {
    final t = L.of(context);
    return Row(
      children: [
        Expanded(
          child: _TabButton(
            label: t.incomeLabel,
            selected: report.series == ChartSeries.income,
            onTap: () => report.setSeries(ChartSeries.income),
          ),
        ),
        Expanded(
          child: _TabButton(
            label: t.expenseLabel,
            selected: report.series == ChartSeries.expense,
            onTap: () => report.setSeries(ChartSeries.expense),
          ),
        ),
      ],
    );
  }

  Widget _yearBar(ReportProvider report) {
    final t = L.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filled(
          tooltip: t.previousYear,
          icon: const Icon(Icons.chevron_left),
          onPressed: report.canGoPrevious
              ? () => report.shiftYear(-1)
              : null,
        ),
        Expanded(
          child: Text(
            '${report.year}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton.filled(
          tooltip: t.nextYear,
          icon: const Icon(Icons.chevron_right),
          onPressed: report.canGoNext ? () => report.shiftYear(1) : null,
        ),
      ],
    );
  }

  Widget _summaryCard(ReportProvider report) {
    final t = L.of(context);
    final finance = FinanceColors.of(context);
    final isIncome = report.series == ChartSeries.income;
    return AppCard(
      variant: AppCardVariant.outlined,
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isIncome
                ? finance.income.withValues(alpha: 0.15)
                : finance.expense.withValues(alpha: 0.15),
            foregroundColor: isIncome ? finance.income : finance.expense,
            child: Icon(
              isIncome ? Icons.trending_up : Icons.trending_down,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isIncome ? t.incomeLabel : t.expenseLabel,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    CurrencyFormatter.formatMedium(report.total),
                    maxLines: 1,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isIncome ? finance.income : finance.expense,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _tooltipLabel(ChartBarData d) {
    if (d.date == null) return d.label;
    return DateFormat(
      'MMMM yyyy',
      Localizations.localeOf(context).toLanguageTag(),
    ).format(d.date!);
  }

  Widget _barChart(ReportProvider report) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final finance = FinanceColors.of(context);
    final axisStyle = text.labelSmall?.copyWith(color: scheme.onSurfaceVariant);
    final data = report.chartData;
    final barColor = report.series == ChartSeries.income
        ? finance.income
        : finance.expense;

    double maxVal = 0;
    for (final d in data) {
      if (d.value > maxVal) maxVal = d.value;
    }
    final step = maxVal == 0 ? 2000.0 : _niceStep(maxVal);
    final actualMax = ((maxVal / step).ceil() + 1) * step;

    return AppCard(
      variant: AppCardVariant.outlined,
      padding: const EdgeInsets.fromLTRB(8, 24, 16, 16),
      child: SizedBox(
        height: 240,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Fixed comfortable bar width; scroll horizontally when the bars
            // don't fit, otherwise stretch to fill.
            const barWidth = 18.0;
            const slot = barWidth + 12;
            final n = data.length;
            final chartWidth = constraints.maxWidth - 48;
            final needed = slot * n;
            final width = needed > chartWidth ? needed : chartWidth;
            final labelEvery = (34 / slot).ceil().clamp(1, 999);

            final barGroups = <BarChartGroupData>[
              for (var i = 0; i < n; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: data[i].value,
                      color: report.selectedMonth == null ||
                              data[i].date?.month == report.selectedMonth
                          ? barColor
                          : barColor.withValues(alpha: 0.35),
                      width: barWidth,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppTheme.radiusXs),
                      ),
                    ),
                  ],
                ),
            ];

            final chart = SizedBox(
              width: width,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: barGroups,
                  maxY: actualMax,
                  minY: 0,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchCallback: (event, response) {
                      if (event is! FlTapUpEvent) return;
                      final spot = response?.spot;
                      if (spot == null) return;
                      final d = data[spot.touchedBarGroupIndex].date;
                      if (d != null) report.selectMonth(d);
                    },
                    touchTooltipData: BarTouchTooltipData(
                      tooltipRoundedRadius: AppTheme.radiusSm,
                      tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipColor: (_) => scheme.inverseSurface,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final d = data[group.x];
                        return BarTooltipItem(
                          '${_tooltipLabel(d)}\n',
                          text.labelSmall!.copyWith(
                            color: scheme.onInverseSurface,
                          ),
                          children: [
                            TextSpan(
                              text: CurrencyFormatter.formatMedium(d.value),
                              style: text.labelLarge?.copyWith(
                                color: scheme.onInverseSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (val, _) {
                          final i = val.toInt();
                          if (i < 0 || i >= data.length) {
                            return const SizedBox.shrink();
                          }
                          if (i % labelEvery != 0) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(data[i].label, style: axisStyle),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        interval: step,
                        getTitlesWidget: (val, _) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            val == 0
                                ? '0'
                                : CurrencyFormatter.formatShort(val),
                            textAlign: TextAlign.right,
                            style: axisStyle,
                          ),
                        ),
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
                    horizontalInterval: step,
                    getDrawingHorizontalLine: (val) => FlLine(
                      color: val == 0 ? scheme.outline : scheme.outlineVariant,
                      strokeWidth: 1,
                      dashArray: val == 0 ? null : [4, 4],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                ),
                duration: const Duration(milliseconds: 300),
              ),
            );

            if (needed <= chartWidth) return chart;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: chart,
            );
          },
        ),
      ),
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
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
