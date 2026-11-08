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

const _monthNames = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

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
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Consumer<ReportProvider>(
      builder: (context, report, _) {
        return RefreshIndicator(
          onRefresh: report.loadChartData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverAppBar.medium(title: Text('Analytics')),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                sliver: SliverList.list(
                  children: [
                    _modeSelector(report),
                    const SizedBox(height: 8),
                    _periodNavigator(report),
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
                                  'Error: ${report.error}',
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
                      const _SectionHeader('Grafik Arus Kas'),
                      if (report.chartData.isNotEmpty)
                        _divergingChart(report)
                      else
                        const AppCard(
                          variant: AppCardVariant.outlined,
                          padding: EdgeInsets.zero,
                          child: EmptyState(
                            icon: Icons.bar_chart_outlined,
                            message: 'Tidak ada data',
                            subtitle: 'Belum ada transaksi pada periode ini',
                          ),
                        ),
                      if (report.recentTransactions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const _SectionHeader('Transaksi Terbaru'),
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
    return SegmentedButton<ChartMode>(
      showSelectedIcon: false,
      segments: [
        for (final m in ChartMode.values)
          ButtonSegment(value: m, label: Text(_modeLabel(m))),
      ],
      selected: {report.chartMode},
      onSelectionChanged: (s) => report.setChartMode(s.first),
    );
  }

  /// Compact period navigator: `< November 2026 >`, adapting to the tab.
  /// Hidden entirely on the yearly tab, where every year is shown at once.
  Widget _periodNavigator(ReportProvider report) {
    if (report.chartMode == ChartMode.yearly) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isDaily = report.chartMode == ChartMode.daily;
    final label = isDaily
        ? '${_monthNames[report.selectedMonth - 1]} ${report.selectedYear}'
        : '${report.selectedYear}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Sebelumnya',
          icon: const Icon(Icons.chevron_left),
          onPressed: () => report.shiftPeriod(-1),
        ),
        TextButton(
          onPressed: () =>
              isDaily ? _pickMonth(report) : _pickYear(report),
          style: TextButton.styleFrom(
            foregroundColor: scheme.onSurface,
            textStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          child: Text(label),
        ),
        IconButton(
          tooltip: 'Berikutnya',
          icon: const Icon(Icons.chevron_right),
          onPressed: () => report.shiftPeriod(1),
        ),
      ],
    );
  }

  /// Month picker modal: year stepper on top, 12-month grid below. Tapping a
  /// month returns it; there is no day step.
  Future<void> _pickMonth(ReportProvider report) async {
    var year = report.selectedYear;
    final picked = await showModalBottomSheet<(int, int)>(
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
                      tooltip: 'Tahun sebelumnya',
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
                      tooltip: 'Tahun berikutnya',
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
                                _monthNames[m - 1],
                                textAlign: TextAlign.center,
                              ),
                            ),
                            selected:
                                year == report.selectedYear &&
                                m == report.selectedMonth,
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
    if (picked != null) {
      report.setYear(picked.$1);
      report.setMonth(picked.$2);
    }
  }

  Future<void> _pickYear(ReportProvider report) async {
    final years = report.availableYears;
    final picked = await showModalBottomSheet<int>(
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
                      selected: year == report.selectedYear,
                      onSelected: (_) => Navigator.pop(context, year),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) report.setYear(picked);
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
                label: 'Pendapatan',
                amount: report.totalIncome,
                icon: Icons.trending_up,
                container: finance.income,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryTile(
                label: 'Pengeluaran',
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
                      'Selisih',
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
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final finance = FinanceColors.of(context);
    final axisStyle = text.labelSmall?.copyWith(color: scheme.onSurfaceVariant);
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
              color: v >= 0 ? finance.income : finance.expense,
              width: 16,
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

    final range = maxVal.abs() > minVal.abs() ? maxVal.abs() : minVal.abs();
    final step = range == 0 ? 2000.0 : _niceStep(range);
    final actualMax = ((maxVal / step).ceil() + 1) * step;
    final actualMin = ((minVal / step).floor() - 1) * step;

    return AppCard(
      variant: AppCardVariant.outlined,
      padding: const EdgeInsets.fromLTRB(8, 24, 16, 16),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                height: 240,
                width: math.max(constraints.maxWidth, data.length * 40.0),
                child: BarChart(
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
                              val == 0 ? '0' : CurrencyFormatter.formatShort(val),
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
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 24,
            runSpacing: 8,
            children: [
              _legendItem(finance.income, 'Surplus'),
              _legendItem(finance.expense, 'Defisit'),
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
