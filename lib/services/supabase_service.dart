import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';

/// True once main() has called Supabase.initialize (requires SUPABASE_URL /
/// SUPABASE_ANON_KEY via --dart-define-from-file). Repositories check this
/// before querying so the app degrades gracefully instead of throwing when
/// no backend is configured (e.g. a plain `flutter run` with no env file).
bool get isSupabaseConfigured => Env.supabaseUrl.isNotEmpty && Env.supabaseAnonKey.isNotEmpty;

SupabaseClient get supabase => Supabase.instance.client;

String? get currentUserId => isSupabaseConfigured ? supabase.auth.currentUser?.id : null;

/// Runs a Supabase read with a short timeout so an unreachable/misconfigured
/// backend fails over to [fallback] in a couple of seconds instead of
/// leaving the UI on a spinner for the ~10-15s a blocked network connection
/// can take to definitively fail.
Future<T> supabaseReadOr<T>(Future<T> Function() query, T fallback, {String label = 'query'}) async {
  if (!isSupabaseConfigured) return fallback;
  try {
    return await query().timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('$label failed, using fallback: $e');
    return fallback;
  }
}
