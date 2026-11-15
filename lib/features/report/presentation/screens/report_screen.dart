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
  /// Month (1-12) under the pointer, or null. Drives the hover highlight.
  int? _hoveredMonth;

  /// Month (1-12) tapped, or null. Pins its tooltip open.
  int? _pinnedMonth;

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
                      if (report.chartData.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _SectionHeader(t.metricsTitle),
                        _metrics(report),
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

  /// Four year-level metrics: average expense, net cash, savings rate, and
  /// expense ratio. Tapping a card opens a dialog with its formula.
  Widget _metrics(ReportProvider report) {
    final t = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final finance = FinanceColors.of(context);
    final net = report.netCashFlow;
    final positive = net >= 0;
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _MetricTile(
                  label: t.burnRate,
                  value: CurrencyFormatter.formatMedium(report.burnRate),
                  color: finance.expense,
                  onTap: () => _showMetricInfo(
                    title: t.burnRate,
                    formula: t.burnRateFormula,
                    explain: t.burnRateExplain,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(
                  label: t.netCashFlow,
                  value: CurrencyFormatter.formatWithSign(
                    net,
                    showPlus: positive,
                  ),
                  color: positive ? finance.income : finance.expense,
                  onTap: () => _showMetricInfo(
                    title: t.netCashFlow,
                    formula: t.netCashFlowFormula,
                    explain: t.netCashFlowExplain,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _MetricTile(
                  label: t.savingsRate,
                  value: '${report.savingsRate.toStringAsFixed(1)}%',
                  color: scheme.primary,
                  onTap: () => _showMetricInfo(
                    title: t.savingsRate,
                    formula: t.savingsRateFormula,
                    explain: t.savingsRateExplain,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(
                  label: t.expenseRatio,
                  value: '${report.expenseRatio.toStringAsFixed(1)}%',
                  color: finance.expense,
                  onTap: () => _showMetricInfo(
                    title: t.expenseRatio,
                    formula: t.expenseRatioFormula,
                    explain: t.expenseRatioExplain,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showMetricInfo({
    required String title,
    required String formula,
    required String explain,
  }) {
    final t = L.of(context);
    showDialog<void>(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        final text = Theme.of(context).textTheme;
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.formula,
                style: text.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(formula, style: text.titleSmall),
              const SizedBox(height: 16),
              Text(explain, style: text.bodyMedium),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.close),
            ),
          ],
        );
      },
    );
  }

  String _tooltipLabel(ChartBarData d) {
    return DateFormat(
      'MMMM yyyy',
      Localizations.localeOf(context).toLanguageTag(),
    ).format(d.date);
  }

  Widget _barChart(ReportProvider report) {
    final t = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final finance = FinanceColors.of(context);
    final axisStyle = text.labelSmall?.copyWith(color: scheme.onSurfaceVariant);
    final data = report.chartData;
    final barColor = report.series == ChartSeries.income
        ? finance.income
        : finance.expense;

    // Y axis spans both series (report.maxValue) so the gridlines stay put when
    // switching tabs. Aim for twice the tallest bar so there's headroom, then
    // round down to a tidy value (e.g. peak 4.2m -> 8m, step 2m: 0/2/4/6/8m).
    final axis = _axisPlan(report.maxValue);
    final step = axis.step;
    final actualMax = axis.max;
    final shadowColor =
        (report.series == ChartSeries.income ? finance.expense : finance.income)
            .withValues(alpha: 0.35);

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
                  // Selection is shown by the tooltip only (see below), so the
                  // tapped month gets its indicator pinned open.
                  showingTooltipIndicators:
                      data[i].date.month == _pinnedMonth ? [0] : null,
                  barRods: [
                    BarChartRodData(
                      toY: data[i].value,
                      color: barColor,
                      width: barWidth,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppTheme.radiusXs),
                      ),
                      // Shadow = the opposing series in the same month:
                      // drawn behind, so only peeks out when it's taller.
                      backDrawRodData: BackgroundBarChartRodData(
                        show: data[i].shadowValue > 0,
                        toY: data[i].shadowValue,
                        color: shadowColor,
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
                  rangeAnnotations: RangeAnnotations(
                    verticalRangeAnnotations: [
                      if (_hoveredMonth != null)
                        for (var i = 0; i < n; i++)
                          if (data[i].date.month == _hoveredMonth)
                            VerticalRangeAnnotation(
                              x1: i - 0.5,
                              x2: i + 0.5,
                              color: scheme.onSurface.withValues(alpha: 0.06),
                            ),
                    ],
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    // No hover/tap tooltip bubble; the tooltip is pinned
                    // manually via showingTooltipIndicators (tapped month).
                    handleBuiltInTouches: false,
                    touchCallback: (event, response) {
                      if (event is FlPointerHoverEvent ||
                          event is FlPointerExitEvent) {
                        final spot = response?.spot;
                        final month = spot == null
                            ? null
                            : data[spot.touchedBarGroupIndex].date.month;
                        if (month != _hoveredMonth) {
                          setState(() => _hoveredMonth = month);
                        }
                        return;
                      }
                      if (event is! FlTapUpEvent) return;
                      final spot = response?.spot;
                      if (spot == null) return;
                      final month = data[spot.touchedBarGroupIndex].date.month;
                      setState(() {
                        _pinnedMonth = month == _pinnedMonth ? null : month;
                      });
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
                        final showShadow = d.shadowValue > d.value;
                        final shadowLabel = report.series == ChartSeries.income
                            ? t.expenseLabel
                            : t.incomeLabel;
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
                            // Shadow only peeks out when taller than the bar,
                            // so only then does it get its own tooltip line.
                            if (showShadow)
                              TextSpan(
                                text:
                                    '\n$shadowLabel '
                                    '${CurrencyFormatter.formatMedium(d.shadowValue)}',
                                style: text.labelSmall?.copyWith(
                                  color: scheme.onInverseSurface.withValues(
                                    alpha: 0.7,
                                  ),
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
                            child: Text(
                              DateFormat(
                                'MMM',
                                Localizations.localeOf(context).toLanguageTag(),
                              ).format(data[i].date),
                              style: axisStyle,
                            ),
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

  /// Picks a round axis max and gridline step for [peak]. The axis is set to
  /// twice the peak (headroom) rounded down to a tidy multiple, and the step is
  /// the largest round value that yields roughly four gridlines.
  static ({double max, double step}) _axisPlan(double peak) {
    if (peak <= 0) return (max: 2000, step: 1000);
    final target = peak * 2;
    final step = _niceFloor(target / 4);
    final ticks = (target / step).floor().clamp(1, 999);
    return (max: step * ticks, step: step);
  }

  /// Largest "tidy" value (1, 2, 2.5, or 5 times a power of ten) that is <=
  /// [value].
  static double _niceFloor(double value) {
    final magnitude = math
        .pow(10, (math.log(value) / math.ln10).floor())
        .toDouble();
    final normalized = value / magnitude;
    double nice;
    if (normalized >= 5) {
      nice = 5;
    } else if (normalized >= 2.5) {
      nice = 2.5;
    } else if (normalized >= 2) {
      nice = 2;
    } else {
      nice = 1;
    }
    return nice * magnitude;
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;
  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return AppCard(
      variant: AppCardVariant.outlined,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: text.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
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
