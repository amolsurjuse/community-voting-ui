import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/widgets/common.dart';
import 'session_controller.dart';
import 'widgets/country_code_field.dart';
import 'widgets/verification_progress.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  String _countryCode = '+1';
  bool _acceptedTerms = false;
  bool _obscure = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  double get _passwordStrength {
    final value = _password.text;
    var score = 0.0;
    if (value.length >= 8) score += 0.35;
    if (value.length >= 12) score += 0.15;
    if (RegExp(r'[A-Z]').hasMatch(value)) score += 0.15;
    if (RegExp(r'\d').hasMatch(value)) score += 0.15;
    if (RegExp(r'[^\w\s]').hasMatch(value)) score += 0.20;
    return score.clamp(0, 1);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_acceptedTerms) {
      setState(() =>
          _error = 'Please accept the Terms and Privacy Policy to continue.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(sessionControllerProvider.notifier).register(
            fullName: _name.text.trim(),
            email: _email.text.trim(),
            phone: '$_countryCode ${_phone.text.trim()}',
            password: _password.text,
          );
      if (mounted) context.go('/auth/verify-email');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create organizer account'),
        leading: BackButton(onPressed: () => context.go('/home')),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(Spacing.xl),
            children: [
              const VerificationProgress(currentStep: 0),
              const SizedBox(height: Spacing.xl),
              Text(
                'Organizers verify their email and phone so participants can trust who runs an event.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: Spacing.xl),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (v) => (v == null || v.trim().length < 2)
                    ? 'Enter your full name'
                    : null,
              ),
              const SizedBox(height: Spacing.lg),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(labelText: 'Email address'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter your email';
                  final valid =
                      RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(v.trim());
                  return valid ? null : 'Enter a valid email address';
                },
              ),
              const SizedBox(height: Spacing.lg),
              CountryCodePhoneField(
                controller: _phone,
                countryCode: _countryCode,
                onCountryChanged: (code) => setState(() => _countryCode = code),
              ),
              const SizedBox(height: Spacing.lg),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                autofillHints: const [AutofillHints.newPassword],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Password',
                  helperText: 'At least 8 characters',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    tooltip: _obscure ? 'Show password' : 'Hide password',
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) => (v == null || v.length < 8)
                    ? 'Use at least 8 characters'
                    : null,
              ),
              if (_password.text.isNotEmpty) ...[
                const SizedBox(height: Spacing.sm),
                _PasswordStrengthBar(strength: _passwordStrength),
              ],
              const SizedBox(height: Spacing.lg),
              CheckboxListTile(
                value: _acceptedTerms,
                onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  'I agree to the Terms of Service and Privacy Policy',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: Spacing.sm),
                InfoCallout(
                    text: _error!,
                    icon: Icons.error_outline,
                    tone: CalloutTone.danger),
              ],
              const SizedBox(height: Spacing.xl),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Continue'),
              ),
              const SizedBox(height: Spacing.md),
              OutlinedButton(
                onPressed: _submitting ? null : () => context.go('/discover'),
                child: const Text('Just here to vote? Explore events'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordStrengthBar extends StatelessWidget {
  const _PasswordStrengthBar({required this.strength});

  final double strength;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (strength) {
      < 0.4 => ('Weak', AppColors.danger),
      < 0.7 => ('Okay', AppColors.warning),
      _ => ('Strong', AppColors.success),
    };
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Corners.pill),
            child: LinearProgressIndicator(
              value: strength,
              minHeight: 6,
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: Spacing.md),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
