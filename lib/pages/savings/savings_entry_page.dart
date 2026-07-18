import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/members.dart' as mock;
import '../../layout/page_header.dart';
import '../../repositories/savings_repository.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

class SavingsEntryPage extends StatefulWidget {
  const SavingsEntryPage({super.key});
  @override
  State<SavingsEntryPage> createState() => _SavingsEntryPageState();
}

class _SavingsEntryPageState extends State<SavingsEntryPage> {
  final _repo = SavingsRepository();
  final _amount = TextEditingController(text: '500');
  String _member = mock.members.first.name;
  String _frequency = 'Weekly';
  String _mode = 'Cash';
  final DateTime _date = DateTime.now();
  bool _submitting = false;
  bool _submitted = false;
  bool _saveFailed = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final appState = context.read<AppState>();
    final shgId = appState.shgId;
    final memberId = appState.profile?.id;
    var ok = false;
    if (shgId != null && memberId != null) {
      ok = await _repo.addEntry(
        shgId: shgId,
        memberId: memberId,
        amount: double.tryParse(_amount.text) ?? 0,
        mode: _mode,
        frequency: _frequency,
        entryDate: _date,
      );
    }
    setState(() {
      _submitting = false;
      _submitted = true;
      _saveFailed = !ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(color: Brand.c50, shape: BoxShape.circle),
                child: Icon(Icons.check_circle_rounded, color: Brand.c600, size: 36),
              ),
              const SizedBox(height: 20),
              Text('Savings recorded!', style: AppTheme.display(20)),
              const SizedBox(height: 8),
              Text('₹${_amount.text} added for $_member via $_mode', textAlign: TextAlign.center, style: AppTheme.sans(13, color: Neutral.c500)),
              if (_saveFailed) ...[
                const SizedBox(height: 8),
                Text('(No backend session yet — this was not persisted to Supabase.)', textAlign: TextAlign.center, style: AppTheme.sans(11, color: Accent.amber700)),
              ],
              const SizedBox(height: 28),
              AppButton(label: 'Done', fullWidth: true, size: ButtonSize.lg, onPressed: () => context.pop()),
            ]),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const PageHeader(title: 'New Savings Entry'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text('Member', style: AppTheme.sans(12, weight: FontWeight.w700, color: Neutral.c600)),
          const SizedBox(height: 6),
          AppCard(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _member,
                isExpanded: true,
                items: mock.members.map((m) => DropdownMenuItem(value: m.name, child: Text(m.name, style: AppTheme.sans(14)))).toList(),
                onChanged: (v) => setState(() => _member = v ?? _member),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('Amount (INR)', style: AppTheme.sans(12, weight: FontWeight.w700, color: Neutral.c600)),
          const SizedBox(height: 6),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Neutral.c200), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(Icons.account_balance_wallet_rounded, size: 16, color: Neutral.c400),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _amount, keyboardType: TextInputType.number, decoration: const InputDecoration(border: InputBorder.none), style: AppTheme.sans(14))),
            ]),
          ),
          const SizedBox(height: 14),
          Text('Frequency', style: AppTheme.sans(12, weight: FontWeight.w700, color: Neutral.c600)),
          const SizedBox(height: 6),
          _segmented(['Daily', 'Weekly', 'Monthly'], _frequency, (v) => setState(() => _frequency = v)),
          const SizedBox(height: 14),
          Text('Payment Mode', style: AppTheme.sans(12, weight: FontWeight.w700, color: Neutral.c600)),
          const SizedBox(height: 6),
          _segmented(['Cash', 'UPI', 'Bank Transfer'], _mode, (v) => setState(() => _mode = v)),
          const SizedBox(height: 20),
          AppButton(label: _submitting ? 'Saving...' : 'Save Entry', fullWidth: true, size: ButtonSize.lg, onPressed: _submitting ? null : _submit),
        ],
      ),
    );
  }

  Widget _segmented(List<String> options, String value, ValueChanged<String> onChanged) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Neutral.c100, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: options.map((opt) {
          final active = opt == value;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(opt),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: active ? Colors.white : null, borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Text(opt, style: AppTheme.sans(12, weight: FontWeight.w700, color: active ? Brand.c700 : Neutral.c500)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
