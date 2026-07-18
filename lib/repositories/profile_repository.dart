import '../models/app_profile.dart';
import '../services/supabase_service.dart';

class ProfileRepository {
  Future<AppProfile?> fetchCurrent() async {
    final uid = currentUserId;
    if (uid == null) return null;
    final row = await supabase.from('profiles').select().eq('id', uid).maybeSingle();
    if (row == null) return null;
    return AppProfile.fromRow(row);
  }

  Future<void> upsertCurrent({required String name, String? shgId, String? role, String? village}) async {
    final uid = currentUserId;
    if (uid == null) return;
    await supabase.from('profiles').upsert({
      'id': uid,
      'name': name,
      if (shgId != null) 'shg_id': shgId,
      if (role != null) 'role': role,
      if (village != null) 'village': village,
    });
  }
}
