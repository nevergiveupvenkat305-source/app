import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/loans.dart' as mock;
import '../../data/shg.dart';
import '../../layout/page_header.dart';
import '../../models/loan.dart';
import '../../repositories/loans_repository.dart';
import '../../routes/paths.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_card.dart';
import '../../widgets/icon_tile.dart';
import '../../widgets/progress_bar.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_card.dart';

const statusTone = <String, BadgeTone>{
  'active': BadgeTone.brand,
  'pending': BadgeTone.warning,
  'overdue': BadgeTone.danger,
  'closed': BadgeTone.success,
  'approved': BadgeTone.success,
  'rejected': BadgeTone.neutral,
};

typedef LoanDisplay = ({String id, String name, String purpose, double amount, double outstanding, double emi, String status, String? nextDueDate});

List<LoanDisplay> loanRowsToDisplay(List<LoanRow> rows) => rows
    .map((l) => (
          id: l.id,
          name: l.memberName,
          purpose: l.purpose,
          amount: l.amount,
          outstanding: l.outstanding,
          emi: l.emi,
          status: l.status,
          nextDueDate: l.nextDueDate != null ? '${l.nextDueDate!.day}/${l.nextDueDate!.month}' : null,
        ))
    .toList();

List<LoanDisplay> mockLoanDisplay() => mock.loans
    .map((l) => (
          id: l.id,
          name: l.memberName,
          purpose: l.purpose,
          amount: l.amount.toDouble(),
          outstanding: l.outstanding.toDouble(),
          emi: l.emi.toDouble(),
          status: l.status,
          nextDueDate: l.nextDueDate,
        ))
    .toList();

class LoansHomePage extends StatefulWidget {
  const LoansHomePage({super.key});
  @override
  State<LoansHomePage> createState() => _LoansHomePageState();
}

class _LoansHomePageState extends State<LoansHomePage> {
  final _repo = LoansRepository();
  List<LoanRow>? _loans;

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

  @override
  Widget build(BuildContext context) {
    final loading = _loans == null;
    final all = loading ? <LoanDisplay>[] : (_loans!.isEmpty ? mockLoanDisplay() : loanRowsToDisplay(_loans!));
    final active = all.where((l) => l.status == 'active' || l.status == 'overdue').toList();

    return Scaffold(
      appBar: PageHeader(title: 'Loan Management', subtitle: ShgInfo.name),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(children: [
                Expanded(child: StatCard(label: 'My Outstanding', value: '₹22,000', tone: StatTone.gold, trend: 'Next EMI 10 Jul', icon: Icons.account_balance_rounded)),
                const SizedBox(width: 12),
                Expanded(child: StatCard(label: 'Group Outstanding', value: '₹${(ShgInfo.totalLoans / 100000).toStringAsFixed(1)}L', tone: StatTone.ink, trend: '${active.length} active loans', icon: Icons.account_balance_rounded)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                IconTile(onTap: () => context.push(Paths.loanApply).then((_) => _load()), icon: Icons.add_circle_rounded, label: 'Apply', tone: TileTone.brand),
                IconTile(onTap: () => context.push(Paths.loanApproval).then((_) => _load()), icon: Icons.fact_check_rounded, label: 'Approvals', tone: TileTone.gold),
                IconTile(onTap: () => context.push(Paths.loanTracking), icon: Icons.radar_rounded, label: 'Tracking', tone: TileTone.sky),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SectionHeader(title: 'Active Loans', action: 'Track all', onAction: () => context.push(Paths.loanTracking)),
                if (loading)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator()))
                else
                  ...active.map((l) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          onTap: () => context.push(Paths.loanDetail(l.id)).then((_) => _load()),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(l.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.sans(14, weight: FontWeight.w700)),
                                Text(l.purpose, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.sans(12, color: Neutral.c500)),
                              ])),
                              AppBadge(text: l.status, tone: statusTone[l.status] ?? BadgeTone.neutral),
                            ]),
                            const SizedBox(height: 10),
                            Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text('₹${l.outstanding.toStringAsFixed(0)}', style: AppTheme.display(16)),
                              Text('of ₹${l.amount.toStringAsFixed(0)}', style: AppTheme.sans(12, color: Neutral.c500)),
                            ]),
                            const SizedBox(height: 6),
                            AppProgressBar(value: l.amount - l.outstanding, max: l.amount, tone: l.status == 'overdue' ? ProgressTone.danger : ProgressTone.gold),
                          ]),
                        ),
                      )),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
