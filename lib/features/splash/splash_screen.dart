import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../../core/widgets/states.dart';
import '../auth/session_controller.dart';
import '../profile/settings_controller.dart';

/// Branded splash: secure installation init + session restore, then routes to
/// onboarding or home. Deep links bypass this via direct routes.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    await ref.read(sessionControllerProvider.notifier).initialize();
    if (!mounted) return;
    final session = ref.read(sessionControllerProvider);
    if (session.phase == SessionPhase.initFailed) return; // retry UI shown
    final seenOnboarding = ref.read(settingsControllerProvider).seenOnboarding;
    if (!seenOnboarding && !session.isAuthenticated) {
      context.go('/onboarding');
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.indigo],
          ),
        ),
        child: session.phase == SessionPhase.initFailed
            ? _InitFailure(onRetry: _initialize)
            : const _Branding(),
      ),
    );
  }
}

class _Branding extends StatelessWidget {
  const _Branding();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(Corners.xl),
            ),
            child: const Icon(Icons.how_to_vote, color: Colors.white, size: 44),
          ),
          const SizedBox(height: Spacing.xl),
          const Text(
            'PulseVote',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Community voting, made simple',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: Spacing.xxl),
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _InitFailure extends StatelessWidget {
  const _InitFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(useMaterial3: true),
      child: ErrorPanel(
        title: 'Setup didn\'t finish',
        message:
            'We could not initialize the app. Check your connection and retry.',
        onRetry: onRetry,
      ),
    );
  }
}
