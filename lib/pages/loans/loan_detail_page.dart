import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/loans.dart' as mock;
import '../../layout/page_header.dart';
import '../../models/loan.dart';
import '../../repositories/loans_repository.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/progress_bar.dart';
import 'loans_home_page.dart' show statusTone;

class LoanDetailPage extends StatefulWidget {
  final String loanId;
  const LoanDetailPage({super.key, required this.loanId});
  @override
  State<LoanDetailPage> createState() => _LoanDetailPageState();
}

class _LoanDetailPageState extends State<LoanDetailPage> {
  final _repo = LoansRepository();
  LoanRow? _loan;
  bool _loading = true;
  bool _paid = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await _repo.fetchLoans();
    final match = rows.where((l) => l.id == widget.loanId);
    if (mounted) setState(() {
      _loan = match.isNotEmpty ? match.first : null;
      _loading = false;
    });
  }

  Future<void> _payEmi() async {
    if (_loan != null) await _repo.payEmi(_loan!);
    setState(() => _paid = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Fall back to mock data (by id) so the detail screen stays demoable
    // before the migration is applied to a live project.
    final mockMatch = mock.loans.where((l) => l.id == widget.loanId);
    final name = _loan?.memberName ?? (mockMatch.isNotEmpty ? mockMatch.first.memberName : null);
    final purpose = _loan?.purpose ?? mockMatch.firstOrNull?.purpose;
    final amount = _loan?.amount ?? mockMatch.firstOrNull?.amount.toDouble();
    final outstanding = _loan?.outstanding ?? mockMatch.firstOrNull?.outstanding.toDouble();
    final emi = _loan?.emi ?? mockMatch.firstOrNull?.emi.toDouble() ?? 0;
    final tenureMonths = _loan?.tenureMonths ?? mockMatch.firstOrNull?.tenureMonths;
    final disbursedOn = _loan?.disbursedOn != null ? '${_loan!.disbursedOn!.day}/${_loan!.disbursedOn!.month}/${_loan!.disbursedOn!.year}' : mockMatch.firstOrNull?.disbursedOn;
    final status = _loan?.status ?? mockMatch.firstOrNull?.status;

    if (name == null || purpose == null || amount == null || outstanding == null || tenureMonths == null || status == null) {
      return Scaffold(
        appBar: const PageHeader(title: 'Loan'),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
          child: Center(child: Text('Loan not found', style: AppTheme.sans(14, color: Neutral.c500))),
        ),
      );
    }

    if (_paid) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 64, height: 64, decoration: const BoxDecoration(color: Brand.c50, shape: BoxShape.circle), child: Icon(Icons.check_circle_rounded, color: Brand.c600, size: 36)),
              const SizedBox(height: 20),
              Text('EMI paid successfully!', style: AppTheme.display(20)),
              const SizedBox(height: 8),
              Text('₹${emi.toStringAsFixed(0)} received. Digital receipt sent by SMS & the loan ledger has been updated.', textAlign: TextAlign.center, style: AppTheme.sans(13, color: Neutral.c500)),
              const SizedBox(height: 28),
              AppButton(label: 'Done', fullWidth: true, size: ButtonSize.lg, onPressed: () => context.pop()),
            ]),
          ),
        ),
      );
    }

    final paidInstallments = (((amount - outstanding) / amount) * tenureMonths).round();
    final schedule = List.generate(tenureMonths, (i) => (n: i + 1, paid: i < paidInstallments, amount: emi > 0 ? emi : (amount / tenureMonths).roundToDouble()));

    return Scaffold(
      appBar: PageHeader(title: 'Loan Details', subtitle: name),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(purpose, style: AppTheme.sans(12, color: Neutral.c500)),
                  const SizedBox(height: 4),
                  Text('₹${outstanding.toStringAsFixed(0)}', style: AppTheme.display(22)),
                  Text('outstanding of ₹${amount.toStringAsFixed(0)}', style: AppTheme.sans(12, color: Neutral.c500)),
                ])),
                AppBadge(text: status, tone: statusTone[status] ?? BadgeTone.neutral),
              ]),
              const SizedBox(height: 12),
              AppProgressBar(value: amount - outstanding, max: amount, tone: status == 'overdue' ? ProgressTone.danger : ProgressTone.gold),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _stat('₹${emi.toStringAsFixed(0)}', 'EMI')),
                _divider(),
                Expanded(child: _stat('${tenureMonths}mo', 'Tenure')),
                _divider(),
                Expanded(child: _stat(disbursedOn ?? 'Pending', 'Disbursed')),
              ]),
            ]),
          ),
          if (status != 'pending') ...[
            const SizedBox(height: 20),
            Text('EMI Schedule', style: AppTheme.display(15)),
            const SizedBox(height: 12),
            AppCard(
              padded: false,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView(
                  shrinkWrap: true,
                  children: schedule
                      .map((s) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text('Installment ${s.n}', style: AppTheme.sans(12, color: Neutral.c600)),
                              Text('₹${s.amount.toStringAsFixed(0)}', style: AppTheme.sans(12, weight: FontWeight.w700)),
                              AppBadge(text: s.paid ? 'Paid' : 'Due', tone: s.paid ? BadgeTone.success : BadgeTone.neutral),
                            ]),
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
          if (status == 'active' || status == 'overdue') ...[
            const SizedBox(height: 20),
            AppButton(label: 'Pay EMI ₹${emi.toStringAsFixed(0)}', fullWidth: true, size: ButtonSize.lg, onPressed: _payEmi),
          ],
        ],
      ),
    );
  }

  Widget _stat(String value, String label) => Column(children: [
        Text(value, style: AppTheme.sans(14, weight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: AppTheme.sans(10, color: Neutral.c500)),
      ]);

  Widget _divider() => Container(width: 1, height: 32, color: Neutral.c100);
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
