import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/savings.dart' as mock;
import '../../layout/page_header.dart';
import '../../models/savings_entry.dart';
import '../../repositories/savings_repository.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_card.dart';
import '../../widgets/avatar.dart';

class SavingsHistoryPage extends StatefulWidget {
  const SavingsHistoryPage({super.key});
  @override
  State<SavingsHistoryPage> createState() => _SavingsHistoryPageState();
}

class _SavingsHistoryPageState extends State<SavingsHistoryPage> {
  final _repo = SavingsRepository();
  List<SavingsEntryRow>? _entries;
  String _filter = 'all';

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
    if (_entries == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final usingMock = _entries!.isEmpty;
    final all = usingMock
        ? mock.savingsEntries
            .map((m) => (name: m.memberName, date: m.date, mode: m.mode, frequency: m.type, amount: m.amount.toDouble(), status: m.status))
            .toList()
        : _entries!
            .map((e) => (
                  name: e.memberName,
                  date: '${e.entryDate.day} ${_month(e.entryDate.month)} ${e.entryDate.year}',
                  mode: e.mode,
                  frequency: e.frequency,
                  amount: e.amount,
                  status: e.status,
                ))
            .toList();
    final filtered = _filter == 'all' ? all : all.where((s) => s.status == _filter).toList();

    return Scaffold(
      appBar: PageHeader(title: 'Savings History', subtitle: '${all.length} entries'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _segmented({'all': 'All', 'verified': 'Verified', 'pending': 'Pending'}, _filter, (v) => setState(() => _filter = v)),
          const SizedBox(height: 16),
          AppCard(
            padded: false,
            child: Column(
              children: filtered
                  .map((s) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(children: [
                          AppAvatar(name: s.name, size: 32),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.sans(12, weight: FontWeight.w700)),
                            Text('${s.date} · ${s.mode} · ${s.frequency}', style: AppTheme.sans(11, color: Neutral.c400)),
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
        ],
      ),
    );
  }

  String _month(int m) => const ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m];

  Widget _segmented(Map<String, String> options, String value, ValueChanged<String> onChanged) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Neutral.c100, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: options.entries.map((opt) {
          final active = opt.key == value;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(opt.key),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: active ? Colors.white : null, borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Text(opt.value, style: AppTheme.sans(12, weight: FontWeight.w700, color: active ? Brand.c700 : Neutral.c500)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
