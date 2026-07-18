import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../layout/page_header.dart';
import '../../models/loan.dart';
import '../../repositories/loans_repository.dart';
import '../../routes/paths.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_card.dart';
import '../../widgets/avatar.dart';
import '../../widgets/progress_bar.dart';
import 'loans_home_page.dart' show statusTone, loanRowsToDisplay, mockLoanDisplay;

class LoanTrackingPage extends StatefulWidget {
  const LoanTrackingPage({super.key});
  @override
  State<LoanTrackingPage> createState() => _LoanTrackingPageState();
}

class _LoanTrackingPageState extends State<LoanTrackingPage> {
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
    if (_loans == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final source = _loans!.isEmpty ? mockLoanDisplay() : loanRowsToDisplay(_loans!);

    final tracked = source.where((l) => l.status == 'active' || l.status == 'overdue').toList();
    final overdue = tracked.where((l) => l.status == 'overdue').toList();

    return Scaffold(
      appBar: PageHeader(title: 'Loan Tracking', subtitle: '${tracked.length} loans being tracked'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          if (overdue.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AppCard(
                color: Accent.red50,
                borderColor: Accent.red100,
                child: Row(children: [
                  Container(width: 40, height: 40, decoration: BoxDecoration(color: Accent.red100, borderRadius: BorderRadius.circular(12)), child: Icon(Icons.warning_rounded, color: Accent.red600, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Defaulter Alert', style: AppTheme.sans(14, weight: FontWeight.w700, color: Accent.red700)),
                    Text('${overdue.map((l) => l.name).join(', ')} — EMI overdue', style: AppTheme.sans(12, color: Accent.red500)),
                  ])),
                ]),
              ),
            ),
          ...tracked.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  onTap: () => context.push(Paths.loanDetail(l.id)).then((_) => _load()),
                  child: Row(children: [
                    AppAvatar(name: l.name, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Expanded(child: Text(l.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.sans(12, weight: FontWeight.w700))),
                          AppBadge(text: l.status, tone: statusTone[l.status] ?? BadgeTone.neutral),
                        ]),
                        const SizedBox(height: 6),
                        Row(children: [
                          Expanded(child: AppProgressBar(value: l.amount - l.outstanding, max: l.amount, tone: l.status == 'overdue' ? ProgressTone.danger : ProgressTone.gold)),
                          const SizedBox(width: 8),
                          Text('₹${l.outstanding.toStringAsFixed(0)}', style: AppTheme.sans(11, color: Neutral.c500)),
                        ]),
                        const SizedBox(height: 4),
                        Text('Next EMI ₹${l.emi.toStringAsFixed(0)} · ${l.nextDueDate}', style: AppTheme.sans(11, color: Neutral.c400)),
                      ]),
                    ),
                  ]),
                ),
              )),
        ],
      ),
    );
  }
}
