import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../layout/page_header.dart';
import '../../repositories/loans_repository.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

class LoanApplyPage extends StatefulWidget {
  const LoanApplyPage({super.key});
  @override
  State<LoanApplyPage> createState() => _LoanApplyPageState();
}

class _LoanApplyPageState extends State<LoanApplyPage> {
  final _repo = LoansRepository();
  final _amount = TextEditingController(text: '20000');
  final _purpose = TextEditingController();
  final _tenure = TextEditingController(text: '12');
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
      ok = await _repo.applyForLoan(
        shgId: shgId,
        memberId: memberId,
        purpose: _purpose.text.isEmpty ? 'General purpose loan' : _purpose.text,
        amount: double.tryParse(_amount.text) ?? 0,
        tenureMonths: int.tryParse(_tenure.text) ?? 12,
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
              Container(width: 64, height: 64, decoration: const BoxDecoration(color: Brand.c50, shape: BoxShape.circle), child: Icon(Icons.check_circle_rounded, color: Brand.c600, size: 36)),
              const SizedBox(height: 20),
              Text('Application submitted!', style: AppTheme.display(20)),
              const SizedBox(height: 8),
              Text('Your request for ₹${_amount.text} has been sent to your SHG leader for approval.', textAlign: TextAlign.center, style: AppTheme.sans(13, color: Neutral.c500)),
              if (_saveFailed) ...[
                const SizedBox(height: 8),
                Text('(No backend session yet — this was not persisted to Supabase.)', textAlign: TextAlign.center, style: AppTheme.sans(11, color: Accent.amber700)),
              ],
              const SizedBox(height: 28),
              AppButton(label: 'Back to Loans', fullWidth: true, size: ButtonSize.lg, onPressed: () => context.pop()),
            ]),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const PageHeader(title: 'Apply for Loan'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text('Loan amount requested', style: AppTheme.sans(12, weight: FontWeight.w700, color: Neutral.c600)),
          const SizedBox(height: 6),
          _field(_amount, icon: Icons.currency_rupee_rounded, keyboardType: TextInputType.number),
          const SizedBox(height: 14),
          Text('Purpose of loan', style: AppTheme.sans(12, weight: FontWeight.w700, color: Neutral.c600)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Neutral.c200), borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: _purpose,
              maxLines: 3,
              decoration: const InputDecoration(border: InputBorder.none, hintText: 'e.g. Purchase of milch cow for dairy'),
              style: AppTheme.sans(14),
            ),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Tenure (months)', style: AppTheme.sans(12, weight: FontWeight.w700, color: Neutral.c600)),
              const SizedBox(height: 6),
              _field(_tenure, keyboardType: TextInputType.number),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Preferred EMI', style: AppTheme.sans(12, weight: FontWeight.w700, color: Neutral.c600)),
              const SizedBox(height: 6),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: Neutral.c100, border: Border.all(color: Neutral.c200), borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.centerLeft,
                child: Text('Auto-calculated', style: AppTheme.sans(13, color: Neutral.c400)),
              ),
            ])),
          ]),
          const SizedBox(height: 14),
          Text('Upload supporting document', style: AppTheme.sans(12, weight: FontWeight.w700, color: Neutral.c600)),
          const SizedBox(height: 6),
          AppCard(
            borderColor: Neutral.c200,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(children: [
                Icon(Icons.cloud_upload_rounded, size: 28, color: Neutral.c400),
                const SizedBox(height: 8),
                Text('Tap to upload quotation / proof', style: AppTheme.sans(12, color: Neutral.c400)),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          AppButton(label: _submitting ? 'Submitting...' : 'Submit Application', fullWidth: true, size: ButtonSize.lg, onPressed: _submitting ? null : _submit),
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, {IconData? icon, TextInputType? keyboardType}) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Neutral.c200), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        if (icon != null) ...[Icon(icon, size: 16, color: Neutral.c400), const SizedBox(width: 8)],
        Expanded(child: TextField(controller: controller, keyboardType: keyboardType, decoration: const InputDecoration(border: InputBorder.none), style: AppTheme.sans(14))),
      ]),
    );
  }
}
