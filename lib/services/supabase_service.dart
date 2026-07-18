import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';

/// True once main() has called Supabase.initialize (requires SUPABASE_URL /
/// SUPABASE_ANON_KEY via --dart-define-from-file). Repositories check this
/// before querying so the app degrades gracefully instead of throwing when
/// no backend is configured (e.g. a plain `flutter run` with no env file).
bool get isSupabaseConfigured => Env.supabaseUrl.isNotEmpty && Env.supabaseAnonKey.isNotEmpty;

SupabaseClient get supabase => Supabase.instance.client;

String? get currentUserId => isSupabaseConfigured ? supabase.auth.currentUser?.id : null;
