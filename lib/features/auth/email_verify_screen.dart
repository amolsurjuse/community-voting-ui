import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/common.dart';
import '../../data/mock_backend.dart';
import 'session_controller.dart';
import 'widgets/otp_field.dart';
import 'widgets/verification_progress.dart';

class EmailVerifyScreen extends ConsumerStatefulWidget {
  const EmailVerifyScreen({super.key});

  @override
  ConsumerState<EmailVerifyScreen> createState() => _EmailVerifyScreenState();
}

class _EmailVerifyScreenState extends ConsumerState<EmailVerifyScreen> {
  bool _submitting = false;
  bool _success = false;
  String? _error;
  int _resendSeconds = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
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

  Future<void> _verify(String code) async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(sessionControllerProvider.notifier).verifyEmail(code);
      Haptics.success();
      setState(() => _success = true);
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted) context.go('/auth/verify-phone');
    } catch (e) {
      Haptics.warning();
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _resend() async {
    await ref.read(sessionControllerProvider.notifier).resendEmailCode();
    if (!mounted) return;
    _startCountdown();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('A new code is on its way.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = ref.watch(sessionControllerProvider).organizer?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Verify your email')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Spacing.xl),
          children: [
            const VerificationProgress(currentStep: 1),
            const SizedBox(height: Spacing.xxl),
            if (_success)
              const _SuccessBlock(message: 'Email verified')
            else ...[
              Icon(Icons.mark_email_unread_outlined,
                  size: 48, color: theme.colorScheme.primary),
              const SizedBox(height: Spacing.lg),
              Text('Enter the 6-digit code', style: theme.textTheme.headlineSmall),
              const SizedBox(height: Spacing.sm),
              Text(
                'We sent a verification code to $email. It confirms you own this address before you can publish events.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Spacing.xl),
              OtpField(enabled: !_submitting, onCompleted: _verify),
              if (_error != null) ...[
                const SizedBox(height: Spacing.lg),
                InfoCallout(
                  text: _error!,
                  icon: Icons.error_outline,
                  tone: CalloutTone.danger,
                ),
              ],
              const SizedBox(height: Spacing.lg),
              const InfoCallout(text: MockCredentials.demoHint),
              const SizedBox(height: Spacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _resendSeconds == 0 ? _resend : null,
                    child: Text(
                      _resendSeconds == 0
                          ? 'Resend code'
                          : 'Resend in ${_resendSeconds}s',
                    ),
                  ),
                  Text('·', style: theme.textTheme.bodySmall),
                  TextButton(
                    onPressed: () => context.go('/auth/register'),
                    child: const Text('Change email'),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('This would open your email app.'),
                  ),
                ),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Open email app'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SuccessBlock extends StatelessWidget {
  const _SuccessBlock({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: Motion.of(context, Motion.emphasized),
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Column(
        children: [
          const SizedBox(height: Spacing.xxl),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: AppColors.success, size: 56),
          ),
          const SizedBox(height: Spacing.lg),
          Text(message, style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }
}
