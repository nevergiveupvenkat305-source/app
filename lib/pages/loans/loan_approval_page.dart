import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/loans.dart' as mock;
import '../../layout/page_header.dart';
import '../../models/loan.dart';
import '../../repositories/loans_repository.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/avatar.dart';

class LoanApprovalPage extends StatefulWidget {
  const LoanApprovalPage({super.key});
  @override
  State<LoanApprovalPage> createState() => _LoanApprovalPageState();
}

class _LoanApprovalPageState extends State<LoanApprovalPage> {
  final _repo = LoansRepository();
  List<LoanRow>? _loans;
  final Map<String, String> _decided = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final shgId = context.read<AppState>().shgId;
    final rows = await _repo.fetchLoans(shgId: shgId);
    if (mounted) setState(() => _loans = rows);
  }

  Future<void> _decide(LoanRow loan, bool approve) async {
    setState(() => _decided[loan.id] = approve ? 'approved' : 'rejected');
    await _repo.decideLoan(loan, approve: approve);
  }

  @override
  Widget build(BuildContext context) {
    if (_loans == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final usingMock = _loans!.isEmpty;

    if (usingMock) {
      final pending = mock.loans.where((l) => l.status == 'pending').toList();
      return Scaffold(
        appBar: PageHeader(title: 'Loan Approvals', subtitle: '${pending.length} pending requests'),
        body: pending.isEmpty
            ? _empty()
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: pending
                    .map((l) => _card(
                          id: l.id,
                          name: l.memberName,
                          purpose: l.purpose,
                          amount: l.amount.toDouble(),
                          tenureMonths: l.tenureMonths,
                          onDecide: (approve) => setState(() => _decided[l.id] = approve ? 'approved' : 'rejected'),
                        ))
                    .toList(),
              ),
      );
    }

    final pending = _loans!.where((l) => l.status == 'pending' || _decided.containsKey(l.id)).toList();
    return Scaffold(
      appBar: PageHeader(title: 'Loan Approvals', subtitle: '${pending.where((l) => !_decided.containsKey(l.id)).length} pending requests'),
      body: pending.isEmpty
          ? _empty()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: pending
                  .map((l) => _card(
                        id: l.id,
                        name: l.memberName,
                        purpose: l.purpose,
                        amount: l.amount,
                        tenureMonths: l.tenureMonths,
                        onDecide: (approve) => _decide(l, approve),
                      ))
                  .toList(),
            ),
    );
  }

  Widget _empty() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
        child: Column(children: [
          Icon(Icons.inbox_rounded, size: 40, color: Neutral.c300),
          const SizedBox(height: 12),
          Text('No pending requests', style: AppTheme.sans(14, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('All loan applications have been reviewed.', textAlign: TextAlign.center, style: AppTheme.sans(12, color: Neutral.c500)),
        ]),
      );

  Widget _card({required String id, required String name, required String purpose, required double amount, required int tenureMonths, required void Function(bool) onDecide}) {
    final decision = _decided[id];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            AppAvatar(name: name),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.sans(14, weight: FontWeight.w700)),
              Text(purpose, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.sans(12, color: Neutral.c500)),
            ])),
            Text('₹${amount.toStringAsFixed(0)}', style: AppTheme.display(14)),
          ]),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Tenure: $tenureMonths months', style: AppTheme.sans(11, color: Neutral.c500)),
            Text('Est. EMI: ₹${(amount / tenureMonths).round()}', style: AppTheme.sans(11, color: Neutral.c500)),
          ]),
          const SizedBox(height: 12),
          if (decision != null)
            AppBadge(text: decision == 'approved' ? 'Approved · disbursed' : 'Rejected', tone: decision == 'approved' ? BadgeTone.success : BadgeTone.danger)
          else
            Row(children: [
              Expanded(child: AppButton(label: 'Reject', variant: ButtonVariant.danger, size: ButtonSize.sm, icon: Icons.close_rounded, onPressed: () => onDecide(false))),
              const SizedBox(width: 8),
              Expanded(child: AppButton(label: 'Approve', size: ButtonSize.sm, icon: Icons.check_rounded, onPressed: () => onDecide(true))),
            ]),
        ]),
      ),
    );
  }
}
