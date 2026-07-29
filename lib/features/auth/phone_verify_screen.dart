import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/common.dart';
import '../../data/mock_backend.dart';
import 'session_controller.dart';
import 'widgets/country_code_field.dart';
import 'widgets/otp_field.dart';
import 'widgets/verification_progress.dart';

const _maxAttempts = 5;

class PhoneVerifyScreen extends ConsumerStatefulWidget {
  const PhoneVerifyScreen({super.key});

  @override
  ConsumerState<PhoneVerifyScreen> createState() => _PhoneVerifyScreenState();
}

class _PhoneVerifyScreenState extends ConsumerState<PhoneVerifyScreen> {
  final _phone = TextEditingController();
  String _countryCode = '+1';
  bool _codeSent = false;
  bool _submitting = false;
  bool _success = false;
  int _attempts = 0;
  int _resendSeconds = 0;
  Timer? _timer;
  String? _error;

  @override
  void dispose() {
    _timer?.cancel();
    _phone.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _resendSeconds = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendSeconds <= 1) {
        t.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  Future<void> _sendCode() async {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7) {
      setState(() => _error = 'Enter a valid phone number first.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(sessionControllerProvider.notifier)
          .sendPhoneOtp('$_countryCode ${_phone.text.trim()}');
      setState(() => _codeSent = true);
      _startCountdown();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _verify(String code) async {
    if (_attempts >= _maxAttempts) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(sessionControllerProvider.notifier).verifyPhoneOtp(code);
      Haptics.success();
      setState(() => _success = true);
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      if (mounted) context.go('/home');
    } catch (e) {
      Haptics.warning();
      setState(() {
        _attempts++;
        _error = _attempts >= _maxAttempts
            ? 'Too many attempts. Wait for the countdown and request a new code.'
            : '$e (${_maxAttempts - _attempts} attempts left)';
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify your phone'),
        actions: [
          TextButton(
            onPressed: () => context.go('/home'),
            child: const Text('Later'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Spacing.xl),
          children: [
            const VerificationProgress(currentStep: 2),
            const SizedBox(height: Spacing.xxl),
            if (_success)
              _SuccessAnimation(theme: theme)
            else if (!_codeSent) ...[
              Icon(Icons.sms_outlined, size: 48, color: theme.colorScheme.primary),
              const SizedBox(height: Spacing.lg),
              Text('Add your phone number', style: theme.textTheme.headlineSmall),
              const SizedBox(height: Spacing.sm),
              Text(
                'We\'ll text you a one-time code. Phone verification unlocks phone-verified events and helps keep results credible.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Spacing.xl),
              Form(
                child: CountryCodePhoneField(
                  controller: _phone,
                  countryCode: _countryCode,
                  onCountryChanged: (c) => setState(() => _countryCode = c),
                ),
              ),
              const SizedBox(height: Spacing.lg),
              const InfoCallout(
                icon: Icons.lock_outline,
                text: 'Your number is used only for verification and duplicate-ballot '
                    'prevention. It is never shown to participants or organizers, '
                    'and never sold or shared.',
              ),
              if (_error != null) ...[
                const SizedBox(height: Spacing.lg),
                InfoCallout(text: _error!, icon: Icons.error_outline, tone: CalloutTone.danger),
              ],
              const SizedBox(height: Spacing.xl),
              FilledButton(
                onPressed: _submitting ? null : _sendCode,
                child: _submitting
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Send code'),
              ),
            ] else ...[
              Icon(Icons.sms, size: 48, color: theme.colorScheme.primary),
              const SizedBox(height: Spacing.lg),
              Text('Enter the code we texted', style: theme.textTheme.headlineSmall),
              const SizedBox(height: Spacing.sm),
              Text(
                'Sent to $_countryCode ${_phone.text.trim()}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Spacing.xl),
              OtpField(
                enabled: !_submitting && _attempts < _maxAttempts,
                onCompleted: _verify,
              ),
              if (_error != null) ...[
                const SizedBox(height: Spacing.lg),
                InfoCallout(text: _error!, icon: Icons.error_outline, tone: CalloutTone.danger),
              ],
              const SizedBox(height: Spacing.lg),
              const InfoCallout(text: MockCredentials.demoHint),
              const SizedBox(height: Spacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _resendSeconds == 0 && !_submitting
                        ? () {
                            setState(() => _attempts = 0);
                            _sendCode();
                          }
                        : null,
                    child: Text(
                      _resendSeconds == 0
                          ? 'Resend code'
                          : 'Resend in ${_resendSeconds}s',
                    ),
                  ),
                  Text('·', style: theme.textTheme.bodySmall),
                  TextButton(
                    onPressed: () => setState(() {
                      _codeSent = false;
                      _error = null;
                      _attempts = 0;
                    }),
                    child: const Text('Change number'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SuccessAnimation extends StatelessWidget {
  const _SuccessAnimation({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: Spacing.xxl),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.5, end: 1),
          duration: Motion.of(context, Motion.emphasized),
          curve: Curves.elasticOut,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified, color: AppColors.success, size: 60),
          ),
        ),
        const SizedBox(height: Spacing.lg),
        Text('You\'re verified!', style: theme.textTheme.headlineSmall),
        const SizedBox(height: Spacing.sm),
        Text(
          'You can now create and publish events.',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
