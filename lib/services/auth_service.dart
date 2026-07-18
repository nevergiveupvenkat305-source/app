import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Wraps Supabase phone-OTP auth. Actual SMS delivery requires a phone
/// provider (Twilio/MessageBird/etc.) configured in the Supabase dashboard —
/// that's an external integration to be supplied later, so calls here throw
/// a clear [AuthNotConfiguredException] until then; screens catch it and can
/// fall back to a demo flow instead of hard-failing.
class AuthNotConfiguredException implements Exception {
  final String message;
  AuthNotConfiguredException(this.message);
  @override
  String toString() => message;
}

class AuthService {
  Future<void> sendOtp(String e164Phone) async {
    if (!isSupabaseConfigured) {
      throw AuthNotConfiguredException('Supabase is not configured (missing .env.json).');
    }
    try {
      await supabase.auth.signInWithOtp(phone: e164Phone);
    } on AuthException catch (e) {
      throw AuthNotConfiguredException('OTP send failed: ${e.message}');
    }
  }

  Future<User> verifyOtp(String e164Phone, String token) async {
    if (!isSupabaseConfigured) {
      throw AuthNotConfiguredException('Supabase is not configured (missing .env.json).');
    }
    final res = await supabase.auth.verifyOTP(phone: e164Phone, token: token, type: OtpType.sms);
    final user = res.user;
    if (user == null) throw AuthNotConfiguredException('OTP verification returned no user.');
    return user;
  }

  Future<void> signOut() async {
    if (!isSupabaseConfigured) return;
    await supabase.auth.signOut();
  }

  bool get hasSession => isSupabaseConfigured && supabase.auth.currentSession != null;
}
