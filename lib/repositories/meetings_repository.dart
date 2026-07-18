import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/meeting.dart';
import '../services/supabase_service.dart';

class MeetingsRepository {
  Future<List<MeetingRow>> fetchMeetings({String? shgId}) => supabaseReadOr(() async {
        var query = supabase.from('meetings').select();
        if (shgId != null) query = query.eq('shg_id', shgId);
        final rows = await query.order('meeting_date', ascending: false);
        return (rows as List).map((r) => MeetingRow.fromRow(r as Map<String, dynamic>)).toList();
      }, <MeetingRow>[], label: 'MeetingsRepository.fetchMeetings');

  Future<bool> scheduleMeeting({
    required String shgId,
    required DateTime date,
    required String time,
    required String venue,
    required String agenda,
  }) async {
    if (!isSupabaseConfigured) return false;
    try {
      await supabase.from('meetings').insert({
        'shg_id': shgId,
        'meeting_date': date.toIso8601String().split('T').first,
        'meeting_time': time,
        'venue': venue,
        'agenda': agenda,
        'status': 'upcoming',
      });
      return true;
    } on PostgrestException catch (e) {
      debugPrint('MeetingsRepository.scheduleMeeting failed: ${e.message}');
      return false;
    }
  }

  /// Upserts one attendance row per member and flips the meeting to
  /// completed with the resulting head-count.
  Future<bool> saveAttendance(String meetingId, Map<String, bool> presentByMemberId) async {
    if (!isSupabaseConfigured) return false;
    try {
      final rows = presentByMemberId.entries
          .map((e) => {'meeting_id': meetingId, 'member_id': e.key, 'present': e.value, 'marked_at': DateTime.now().toIso8601String()})
          .toList();
      await supabase.from('meeting_attendance').upsert(rows, onConflict: 'meeting_id,member_id');
      final presentCount = presentByMemberId.values.where((v) => v).length;
      await supabase.from('meetings').update({'status': 'completed'}).eq('id', meetingId);
      debugPrint('MeetingsRepository.saveAttendance: $presentCount present of ${presentByMemberId.length}');
      return true;
    } on PostgrestException catch (e) {
      debugPrint('MeetingsRepository.saveAttendance failed: ${e.message}');
      return false;
    }
  }

  Future<List<String>> fetchDecisions(String meetingId) => supabaseReadOr(() async {
        final row = await supabase.from('meeting_minutes').select('decisions').eq('meeting_id', meetingId).maybeSingle();
        return row == null ? <String>[] : List<String>.from(row['decisions'] as List);
      }, <String>[], label: 'MeetingsRepository.fetchDecisions');

  Future<List<ActionItemRow>> fetchActionItems(String meetingId) => supabaseReadOr(() async {
        final rows = await supabase.from('meeting_action_items').select('*, profiles(name)').eq('meeting_id', meetingId);
        return (rows as List).map((r) => ActionItemRow.fromRow(r as Map<String, dynamic>)).toList();
      }, <ActionItemRow>[], label: 'MeetingsRepository.fetchActionItems');
}
