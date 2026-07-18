import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/loan.dart';
import '../services/supabase_service.dart';

/// Wraps the `loans` (+ `loan_payments`) tables. Reads swallow backend
/// errors and return an empty list so screens fall back to mock data
/// instead of crashing when the migration/session isn't available yet.
class LoansRepository {
  Future<List<LoanRow>> fetchLoans({String? shgId}) => supabaseReadOr(() async {
        var query = supabase.from('loans').select('*, profiles(name)');
        if (shgId != null) query = query.eq('shg_id', shgId);
        final rows = await query.order('created_at', ascending: false);
        return (rows as List).map((r) => LoanRow.fromRow(r as Map<String, dynamic>)).toList();
      }, <LoanRow>[], label: 'LoansRepository.fetchLoans');

  Future<bool> applyForLoan({
    required String shgId,
    required String memberId,
    required String purpose,
    required double amount,
    required int tenureMonths,
  }) async {
    if (!isSupabaseConfigured) return false;
    try {
      await supabase.from('loans').insert({
        'shg_id': shgId,
        'member_id': memberId,
        'purpose': purpose,
        'amount': amount,
        'outstanding': amount,
        'emi': 0,
        'tenure_months': tenureMonths,
        'status': 'pending',
      });
      return true;
    } on PostgrestException catch (e) {
      debugPrint('LoansRepository.applyForLoan failed: ${e.message}');
      return false;
    }
  }

  /// Approving sets emi (amount / tenure) and disburses today; rejecting
  /// just flips status. A DB trigger could compute EMI too, but doing it
  /// here keeps the write a single round trip.
  Future<bool> decideLoan(LoanRow loan, {required bool approve}) async {
    if (!isSupabaseConfigured) return false;
    try {
      final now = DateTime.now();
      final update = approve
          ? {
              'status': 'active',
              'emi': (loan.amount / loan.tenureMonths).roundToDouble(),
              'disbursed_on': now.toIso8601String().split('T').first,
              'next_due_date': DateTime(now.year, now.month + 1, now.day).toIso8601String().split('T').first,
            }
          : {'status': 'rejected'};
      await supabase.from('loans').update(update).eq('id', loan.id);
      return true;
    } on PostgrestException catch (e) {
      debugPrint('LoansRepository.decideLoan failed: ${e.message}');
      return false;
    }
  }

  Future<bool> payEmi(LoanRow loan) async {
    if (!isSupabaseConfigured) return false;
    try {
      await supabase.from('loan_payments').insert({'loan_id': loan.id, 'amount': loan.emi});
      final newOutstanding = (loan.outstanding - loan.emi).clamp(0, loan.amount);
      await supabase.from('loans').update({
        'outstanding': newOutstanding,
        'status': newOutstanding <= 0 ? 'closed' : 'active',
      }).eq('id', loan.id);
      return true;
    } on PostgrestException catch (e) {
      debugPrint('LoansRepository.payEmi failed: ${e.message}');
      return false;
    }
  }
}
