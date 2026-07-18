import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/savings.dart' as mock;
import '../../data/shg.dart';
import '../../layout/page_header.dart';
import '../../models/savings_entry.dart';
import '../../repositories/savings_repository.dart';
import '../../routes/paths.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_card.dart';
import '../../widgets/icon_tile.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_card.dart';

class SavingsHomePage extends StatefulWidget {
  const SavingsHomePage({super.key});
  @override
  State<SavingsHomePage> createState() => _SavingsHomePageState();
}

class _SavingsHomePageState extends State<SavingsHomePage> {
  final _repo = SavingsRepository();
  List<SavingsEntryRow>? _entries;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final shgId = context.read<AppState>().shgId;
    final rows = await _repo.fetchEntries(shgId: shgId);
    if (mounted) setState(() => _entries = rows);
  }

  @override
  Widget build(BuildContext context) {
    final loading = _entries == null;
    final usingMock = !loading && _entries!.isEmpty;
    final recent = usingMock
        ? mock.savingsEntries
            .take(5)
            .map((m) => _DisplayEntry(name: m.memberName, date: m.date, mode: m.mode, amount: m.amount.toDouble(), status: m.status))
            .toList()
        : _entries!
            .take(5)
            .map((e) => _DisplayEntry(
                  name: e.memberName,
                  date: '${e.entryDate.day} ${_month(e.entryDate.month)} ${e.entryDate.year}',
                  mode: e.mode,
                  amount: e.amount,
                  status: e.status,
                ))
            .toList();

    return Scaffold(
      appBar: PageHeader(title: 'Savings Management', subtitle: ShgInfo.name),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(children: [
                Expanded(child: StatCard(label: 'My Savings', value: '₹48,200', tone: StatTone.brand, trend: '+₹500 this week', icon: Icons.account_balance_wallet_rounded)),
                const SizedBox(width: 12),
                Expanded(child: StatCard(label: 'Group Savings', value: '₹${(ShgInfo.totalSavings / 100000).toStringAsFixed(1)}L', tone: StatTone.gold, trend: '${ShgInfo.memberCount} members', icon: Icons.account_balance_wallet_rounded)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconTile(onTap: () => context.push(Paths.savingsEntry).then((_) => _load()), icon: Icons.add_circle_rounded, label: 'New Entry', tone: TileTone.brand),
                  IconTile(onTap: () => context.push(Paths.savingsHistory), icon: Icons.history_rounded, label: 'History', tone: TileTone.gold),
                  IconTile(onTap: () => context.push(Paths.savingsLedger), icon: Icons.menu_book_rounded, label: 'Ledger', tone: TileTone.sky),
                  IconTile(onTap: () => context.push(Paths.savingsGroupReport), icon: Icons.insert_chart_rounded, label: 'Group Report', tone: TileTone.violet),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SectionHeader(title: 'Savings Trend', subtitle: 'Last 6 months'),
                AppCard(child: SizedBox(height: 140, child: _TrendChart())),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SectionHeader(title: 'Recent Entries', action: 'View statement', onAction: () => context.push(Paths.savingsStatement)),
                if (loading)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator()))
                else
                  AppCard(
                    padded: false,
                    child: Column(
                      children: recent
                          .map((s) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.sans(12, weight: FontWeight.w700)),
                                    Text('${s.date} · ${s.mode}', style: AppTheme.sans(11, color: Neutral.c400)),
                                  ])),
                                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                    Text('+₹${s.amount.toStringAsFixed(0)}', style: AppTheme.sans(14, weight: FontWeight.w700, color: Brand.c700)),
                                    AppBadge(text: s.status, tone: s.status == 'verified' ? BadgeTone.success : BadgeTone.warning),
                                  ]),
                                ]),
                              ))
                          .toList(),
                    ),
                  ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  String _month(int m) => const ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m];
}

class _DisplayEntry {
  final String name, date, mode, status;
  final double amount;
  _DisplayEntry({required this.name, required this.date, required this.mode, required this.amount, required this.status});
}

class _TrendChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 20, getTitlesWidget: (v, meta) {
            final i = v.toInt();
            if (i < 0 || i >= mock.savingsMonthlyTrend.length) return const SizedBox();
            return Text(mock.savingsMonthlyTrend[i].$1, style: AppTheme.sans(10, color: Neutral.c500));
          })),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [for (var i = 0; i < mock.savingsMonthlyTrend.length; i++) FlSpot(i.toDouble(), mock.savingsMonthlyTrend[i].$2.toDouble())],
            isCurved: true,
            color: Brand.c600,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: Brand.c500.withValues(alpha: 0.18)),
          ),
        ],
      ),
    );
  }
}
