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
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                sliver: SliverList.list(
                  children: [
                    _modeSelector(report),
                    const SizedBox(height: 8),
                    _periodBar(report),
                    const SizedBox(height: 8),
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
                      _summaryCards(report),
                      const SizedBox(height: 8),
                      _SectionHeader(t.chartCashFlow),
                      if (report.chartData.isNotEmpty)
                        _divergingChart(report)
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
                      if (report.recentTransactions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _SectionHeader(t.recentTransactions),
                        AppCard(
                          variant: AppCardVariant.outlined,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            children: [
                              for (
                                var i = 0;
                                i < report.recentTransactions.length;
                                i++
                              ) ...[
                                if (i > 0)
                                  const Divider(height: 1, indent: 72),
                                TransactionTile(
                                  transaction: report.recentTransactions[i],
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

  Widget _modeSelector(ReportProvider report) {
    final t = L.of(context);
    return SegmentedButton<ChartMode>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(value: ChartMode.month, label: Text(t.modeMonthly)),
        ButtonSegment(value: ChartMode.year, label: Text(t.modeYearly)),
      ],
      selected: {report.chartMode},
      onSelectionChanged: (s) => report.setChartMode(s.first),
    );
  }

  /// Row with the period navigator (default) and a custom-range filter button.
  Widget _periodBar(ReportProvider report) {
    final t = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isMonth = report.chartMode == ChartMode.month;
    final isCustom = isMonth ? report.isMonthCustom : report.isYearCustom;

    final String label = isMonth
        ? (report.isMonthCustom
              ? _monthRangeLabel(
                  report.monthRangeStart!,
                  report.monthRangeEnd!,
                )
              : '${_monthLabel(context, report.selectedMonth)} ${report.selectedYear}')
        : (report.isYearCustom
              ? '${report.yearRangeStart} – ${report.yearRangeEnd}'
              : '${report.selectedYear}');

    return Row(
      children: [
        IconButton(
          tooltip: t.previousPeriod,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.chevron_left),
          onPressed: isCustom ? null : () => report.shiftPeriod(-1),
        ),
        Expanded(
          child: TextButton(
            onPressed: isCustom
                ? null
                : () => isMonth ? _pickMonth(report) : _pickYear(report),
            style: TextButton.styleFrom(
              foregroundColor: scheme.onSurface,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              textStyle: text.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        IconButton(
          tooltip: t.nextPeriod,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.chevron_right),
          onPressed: isCustom ? null : () => report.shiftPeriod(1),
        ),
        // Custom-range filter button (M3 tonal; filled when custom is active).
        IconButton.filledTonal(
          tooltip: t.customFilter,
          isSelected: isCustom,
          visualDensity: VisualDensity.compact,
          onPressed: () =>
              isMonth ? _showMonthRangeSheet(report) : _showYearRangeSheet(report),
          icon: const Icon(Icons.tune),
        ),
      ],
    );
  }

  String _monthRangeLabel(DateTime start, DateTime end) {
    final s = '${_monthLabel(context, start.month)} ${start.year}';
    final e = '${_monthLabel(context, end.month)} ${end.year}';
    return '$s – $e';
  }

  static String _monthLabel(BuildContext context, int month) => DateFormat(
    'MMMM',
    Localizations.localeOf(context).toLanguageTag(),
  ).format(DateTime(2000, month));

  /// Month picker modal: year stepper on top, 12-month grid below. Tapping a
  /// month returns it; there is no day step.
  Future<void> _pickMonth(ReportProvider report) async {
    final picked = await _showMonthGrid(
      initialYear: report.selectedYear,
      selected: (report.selectedYear, report.selectedMonth),
    );
    if (picked != null) {
      report.setYear(picked.$1);
      report.setMonth(picked.$2);
    }
  }

  Future<void> _pickYear(ReportProvider report) async {
    final picked = await _showYearGrid(selected: report.selectedYear);
    if (picked != null) report.setYear(picked);
  }

  /// Custom month range: two month pickers (start + end) with validation
  /// (end >= start, max [_maxRangeMonths] months).
  Future<void> _showMonthRangeSheet(ReportProvider report) async {
    final t = L.of(context);
    var start = report.monthRangeStart ??
        DateTime(report.selectedYear, report.selectedMonth);
    var end = report.monthRangeEnd ?? start;

    final result = await showModalBottomSheet<({DateTime? start, DateTime? end})>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.customRange,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _rangePickRow(
                  label: t.rangeStart,
                  value: '${_monthLabel(context, start.month)} ${start.year}',
                  onTap: () async {
                    final picked = await _showMonthGrid(
                      initialYear: start.year,
                      selected: (start.year, start.month),
                    );
                    if (picked != null) {
                      setSheetState(() => start = DateTime(picked.$1, picked.$2));
                    }
                  },
                ),
                const SizedBox(height: 8),
                _rangePickRow(
                  label: t.rangeEnd,
                  value: '${_monthLabel(context, end.month)} ${end.year}',
                  onTap: () async {
                    final picked = await _showMonthGrid(
                      initialYear: end.year,
                      selected: (end.year, end.month),
                    );
                    if (picked != null) {
                      setSheetState(() => end = DateTime(picked.$1, picked.$2));
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        // Reset clears the custom range back to the default
                        // single-month period.
                        onPressed: () => Navigator.pop(
                          context,
                          (start: null, end: null),
                        ),
                        child: Text(t.resetRange),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: _monthRangeValid(start, end)
                            ? () => Navigator.pop(
                                context,
                                (start: start, end: end),
                              )
                            : null,
                        child: Text(t.applyRange),
                      ),
                    ),
                  ],
                ),
                if (!_monthRangeValid(start, end))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _monthRangeError(t, start, end),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result == null) return; // dismissed
    if (result.start == null || result.end == null) {
      report.clearMonthRange();
    } else {
      report.setMonthRange(result.start!, result.end!);
    }
  }

  bool _monthRangeValid(DateTime start, DateTime end) {
    if (end.isBefore(start)) return false;
    return ReportProvider.monthsBetween(start, end) <=
        ReportProvider.maxRangeMonths;
  }

  String _monthRangeError(L t, DateTime start, DateTime end) {
    if (end.isBefore(start)) return t.rangeEndBeforeStart;
    return t.rangeMaxMonths;
  }

  /// Custom year range sheet (end >= start, max 12 years).
  Future<void> _showYearRangeSheet(ReportProvider report) async {
    final t = L.of(context);
    var start = report.yearRangeStart ?? report.selectedYear;
    var end = report.yearRangeEnd ?? report.selectedYear;

    final result = await showModalBottomSheet<({int? start, int? end})>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.customRange,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _rangePickRow(
                  label: t.rangeStart,
                  value: '$start',
                  onTap: () async {
                    final picked = await _showYearGrid(selected: start);
                    if (picked != null) setSheetState(() => start = picked);
                  },
                ),
                const SizedBox(height: 8),
                _rangePickRow(
                  label: t.rangeEnd,
                  value: '$end',
                  onTap: () async {
                    final picked = await _showYearGrid(selected: end);
                    if (picked != null) setSheetState(() => end = picked);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        // Reset clears the custom range back to the default
                        // single-year period.
                        onPressed: () => Navigator.pop(
                          context,
                          (start: null, end: null),
                        ),
                        child: Text(t.resetRange),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: _yearRangeValid(start, end)
                            ? () => Navigator.pop(
                                context,
                                (start: start, end: end),
                              )
                            : null,
                        child: Text(t.applyRange),
                      ),
                    ),
                  ],
                ),
                if (!_yearRangeValid(start, end))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      end < start ? t.rangeEndBeforeStart : t.rangeMaxYears,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result == null) return; // dismissed
    if (result.start == null || result.end == null) {
      report.clearYearRange();
    } else {
      report.setYearRange(result.start!, result.end!);
    }
  }

  bool _yearRangeValid(int start, int end) =>
      end >= start && (end - start + 1) <= ReportProvider.maxRangeMonths;

  Widget _rangePickRow({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }

  /// Month grid modal, returns `(year, month)` or null.
  Future<(int, int)?> _showMonthGrid({
    required int initialYear,
    required (int, int) selected,
  }) {
    final t = L.of(context);
    var year = initialYear;
    return showModalBottomSheet<(int, int)>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: t.previousYear,
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setSheetState(() => year--),
                    ),
                    Text(
                      '$year',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      tooltip: t.nextYear,
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => setSheetState(() => year++),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2.4,
                  children: [
                    for (var m = 1; m <= 12; m++)
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: SizedBox.expand(
                          child: ChoiceChip(
                            label: SizedBox(
                              width: double.infinity,
                              child: Text(
                                _monthLabel(context, m),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            selected: year == selected.$1 && m == selected.$2,
                            onSelected: (_) =>
                                Navigator.pop(context, (year, m)),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Year grid modal, returns the year or null.
  Future<int?> _showYearGrid({required int selected}) {
    final years = ReportProvider().availableYears;
    return showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.4,
            children: [
              for (final year in years.reversed)
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: SizedBox.expand(
                    child: ChoiceChip(
                      label: SizedBox(
                        width: double.infinity,
                        child: Text(
                          year.toString(),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      selected: year == selected,
                      onSelected: (_) => Navigator.pop(context, year),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _summaryCards(ReportProvider report) {
    final t = L.of(context);
    final finance = FinanceColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                label: t.incomeLabel,
                amount: report.totalIncome,
                icon: Icons.trending_up,
                container: finance.income,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryTile(
                label: t.expenseLabel,
                amount: report.totalExpense,
                icon: Icons.trending_down,
                container: finance.expense,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AppCard(
          variant: AppCardVariant.outlined,
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                child: const Icon(Icons.balance, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.difference,
                      style: text.titleSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        CurrencyFormatter.formatMedium(report.balance),
                        maxLines: 1,
                        style: text.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _tooltipLabel(ChartBarData d, ChartBucket bucket) {
    if (d.date == null) return d.label;
    final locale = Localizations.localeOf(context).toLanguageTag();
    switch (bucket) {
      case ChartBucket.day:
        final dayName = DateFormat('EEEE', locale).format(d.date!);
        final shortDate = DateFormat('dd MMM', locale).format(d.date!);
        return '$dayName, $shortDate';
      case ChartBucket.month:
        return DateFormat('MMMM yyyy', locale).format(d.date!);
      case ChartBucket.year:
        return d.date!.year.toString();
    }
  }

  Widget _divergingChart(ReportProvider report) {
    final t = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final finance = FinanceColors.of(context);
    final axisStyle = text.labelSmall?.copyWith(color: scheme.onSurfaceVariant);
    final data = report.chartData;
    final mode = report.chartBucket;
    double minVal = 0, maxVal = 0;

    for (final d in data) {
      final v = d.netBalance;
      if (v < minVal) minVal = v;
      if (v > maxVal) maxVal = v;
    }

    final range = maxVal.abs() > minVal.abs() ? maxVal.abs() : minVal.abs();
    final step = range == 0 ? 2000.0 : _niceStep(range);
    final actualMax = ((maxVal / step).ceil() + 1) * step;
    final actualMin = ((minVal / step).floor() - 1) * step;

    return AppCard(
      variant: AppCardVariant.outlined,
      padding: const EdgeInsets.fromLTRB(8, 24, 16, 16),
      child: Column(
        children: [
          SizedBox(
            height: 240,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Fit every bar in the available width; bars get thinner as
                // the count grows (e.g. up to 31 daily bars). Labels thin out
                // so they never overlap.
                final n = data.length;
                final chartWidth = constraints.maxWidth - 48;
                final slot = n == 0 ? chartWidth : chartWidth / n;
                final barWidth = (slot * 0.6).clamp(2.0, 16.0);
                final labelEvery = (30 / slot).ceil().clamp(1, 999);

                final barGroups = <BarChartGroupData>[];
                for (var i = 0; i < n; i++) {
                  final v = data[i].netBalance;
                  barGroups.add(
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: v,
                          color: v >= 0 ? finance.income : finance.expense,
                          width: barWidth,
                          borderRadius: v >= 0
                              ? const BorderRadius.vertical(
                                  top: Radius.circular(AppTheme.radiusXs),
                                )
                              : const BorderRadius.vertical(
                                  bottom: Radius.circular(AppTheme.radiusXs),
                                ),
                        ),
                      ],
                    ),
                  );
                }

                return BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    barGroups: barGroups,
                    maxY: actualMax,
                    minY: actualMin,
                    barTouchData: BarTouchData(
                      enabled: true,
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
                            '${_tooltipLabel(d, mode)}\n',
                            text.labelSmall!.copyWith(
                              color: scheme.onInverseSurface,
                            ),
                            children: [
                              TextSpan(
                                text: CurrencyFormatter.formatWithSign(
                                  d.netBalance,
                                ),
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
                            // Thin labels when bars are dense.
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
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 24,
            runSpacing: 8,
            children: [
              _legendItem(finance.income, t.surplus),
              _legendItem(finance.expense, t.deficit),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppTheme.radiusXs),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
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

class _SummaryTile extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color container;
  const _SummaryTile({
    required this.label,
    required this.amount,
    required this.icon,
    required this.container,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return AppCard(
      variant: AppCardVariant.outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: container),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.formatMedium(amount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
