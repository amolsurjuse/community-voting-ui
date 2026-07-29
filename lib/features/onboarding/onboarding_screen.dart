import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/tokens.dart';
import '../profile/settings_controller.dart';

class _Page {
  const _Page(this.icon, this.title, this.body);
  final IconData icon;
  final String title;
  final String body;
}

const _pages = [
  _Page(
    Icons.celebration_outlined,
    'Create or join community votes',
    'Awards, club elections, team polls, ranked contests — set one up in minutes or vote with a single shared link.',
  ),
  _Page(
    Icons.verified_user_outlined,
    'Pick the right verification level',
    'From simple one-ballot-per-installation checks to phone verification and invitations. Every event shows how it verifies voters.',
  ),
  _Page(
    Icons.lock_outline,
    'Vote privately, no profile needed',
    'Participants never create a permanent account. Your receipt confirms your ballot was accepted without revealing your choices.',
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish(String destination) {
    ref.read(settingsControllerProvider.notifier).completeOnboarding();
    context.go(destination);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = _page == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(Spacing.sm),
                child: TextButton(
                  onPressed: () => _finish('/home'),
                  child: const Text('Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: AppColors.coverGradientFor(i),
                            ),
                            borderRadius: BorderRadius.circular(Corners.xl),
                          ),
                          child: Icon(page.icon, size: 56, color: Colors.white),
                        ),
                        const SizedBox(height: Spacing.xxl),
                        Text(
                          page.title,
                          style: theme.textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: Spacing.lg),
                        Text(
                          page.body,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                return AnimatedContainer(
                  duration: Motion.of(context, Motion.standard),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _page ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _page
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(Corners.pill),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(Spacing.xl),
              child: Column(
                children: [
                  FilledButton(
                    onPressed: () {
                      if (isLast) {
                        _finish('/auth/register');
                      } else {
                        _controller.nextPage(
                          duration: Motion.standard,
                          curve: Motion.easing,
                        );
                      }
                    },
                    child: Text(isLast ? 'Get started' : 'Continue'),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => _finish('/auth/register'),
                        child: const Text('Sign in'),
                      ),
                      Text('·', style: theme.textTheme.bodySmall),
                      TextButton(
                        onPressed: () => _finish('/discover'),
                        child: const Text('Explore public events'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
