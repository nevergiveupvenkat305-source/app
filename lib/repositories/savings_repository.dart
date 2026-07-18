import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/savings_entry.dart';
import '../services/supabase_service.dart';

/// Wraps the `savings_entries` table. Every read swallows backend errors
/// (missing migration, no session, RLS denial) and returns an empty result
/// instead of throwing, so the screen can show an empty/error state rather
/// than crash — the schema in supabase/migrations/ may not be applied yet
/// wherever this runs.
class SavingsRepository {
  Future<List<SavingsEntryRow>> fetchEntries({String? shgId}) => supabaseReadOr(() async {
        var query = supabase.from('savings_entries').select('*, profiles(name)');
        if (shgId != null) query = query.eq('shg_id', shgId);
        final rows = await query.order('entry_date', ascending: false);
        return (rows as List).map((r) => SavingsEntryRow.fromRow(r as Map<String, dynamic>)).toList();
      }, <SavingsEntryRow>[], label: 'SavingsRepository.fetchEntries');

  Future<bool> addEntry({
    required String shgId,
    required String memberId,
    required double amount,
    required String mode,
    required String frequency,
    required DateTime entryDate,
  }) async {
    if (!isSupabaseConfigured) return false;
    try {
      await supabase.from('savings_entries').insert({
        'shg_id': shgId,
        'member_id': memberId,
        'amount': amount,
        'mode': mode,
        'frequency': frequency,
        'entry_date': entryDate.toIso8601String().split('T').first,
        'status': 'pending',
      });
      return true;
    } on PostgrestException catch (e) {
      debugPrint('SavingsRepository.addEntry failed: ${e.message}');
      return false;
    }
  }
}
