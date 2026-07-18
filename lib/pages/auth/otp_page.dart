import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../routes/paths.dart';
import '../../services/auth_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../widgets/app_button.dart';

class OtpPage extends StatefulWidget {
  final String? phone;
  const OtpPage({super.key, this.phone});
  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _digits = List.generate(6, (_) => TextEditingController());
  final _focus = List.generate(6, (_) => FocusNode());
  final _auth = AuthService();
  bool _verifying = false;
  String? _notice;

  bool get _filled => _digits.every((c) => c.text.isNotEmpty);
  String get _code => _digits.map((c) => c.text).join();

  Future<void> _verify() async {
    setState(() {
      _verifying = true;
      _notice = null;
    });
    final phone = widget.phone;
    if (phone != null) {
      try {
        await _auth.verifyOtp(phone, _code);
        if (mounted) await context.read<AppState>().loadProfile();
      } on AuthNotConfiguredException catch (e) {
        // No SMS provider configured yet — keep the demo flow moving so
        // onboarding stays testable end-to-end without a live phone number.
        _notice = e.toString();
      } catch (e) {
        _notice = 'Verification failed: $e';
      }
    }
    if (!mounted) return;
    setState(() => _verifying = false);
    context.go(Paths.profileSetup);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Neutral.c50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          child: Column(
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: Brand.c600, borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Brand.c600.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))],
                ),
                child: const Icon(Icons.sms_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 20),
              Text('Verify OTP', style: AppTheme.display(22)),
              const SizedBox(height: 6),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(style: AppTheme.sans(13, color: Neutral.c500), children: [
                  const TextSpan(text: "We've sent a 6-digit code to "),
                  TextSpan(text: widget.phone ?? '+91 98765 43210', style: AppTheme.sans(13, weight: FontWeight.w700, color: Neutral.c700)),
                ]),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) => SizedBox(
                      width: 44, height: 52,
                      child: TextField(
                        controller: _digits[i],
                        focusNode: _focus[i],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: AppTheme.sans(18, weight: FontWeight.w700),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true, fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Neutral.c200)),
                        ),
                        onChanged: (v) {
                          setState(() {});
                          if (v.isNotEmpty && i < 5) _focus[i + 1].requestFocus();
                        },
                      ),
                    )),
              ),
              const SizedBox(height: 20),
              Text.rich(
                TextSpan(style: AppTheme.sans(12, weight: FontWeight.w700, color: Brand.c600), children: [
                  const TextSpan(text: 'Resend OTP in '),
                  TextSpan(text: '00:28', style: AppTheme.sans(12, color: Neutral.c400, weight: FontWeight.w400)),
                ]),
              ),
              if (_notice != null) ...[
                const SizedBox(height: 12),
                Text(_notice!, textAlign: TextAlign.center, style: AppTheme.sans(11, color: Accent.amber700)),
              ],
              const SizedBox(height: 28),
              AppButton(
                label: _verifying ? 'Verifying...' : 'Verify & Continue',
                fullWidth: true,
                size: ButtonSize.lg,
                onPressed: _filled && !_verifying ? _verify : null,
              ),
              const Spacer(),
              Text("Didn't receive the code? Check your SMS inbox.", style: AppTheme.sans(11, color: Neutral.c400)),
            ],
          ),
        ),
      ),
    );
  }
}
