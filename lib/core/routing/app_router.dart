import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/activity/activity_screen.dart';
import '../../features/analytics/analytics_screen.dart';
import '../../features/auth/email_verify_screen.dart';
import '../../features/auth/phone_verify_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/ballot/ballot_screen.dart';
import '../../features/ballot/confirmation_screen.dart';
import '../../features/create/create_wizard_screen.dart';
import '../../features/discover/discover_screen.dart';
import '../../features/event/event_details_screen.dart';
import '../../features/event/invite_screen.dart';
import '../../features/event/link_error_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/manage/manage_event_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/results/results_screen.dart';
import '../../features/shell/organizer_shell.dart';
import '../../features/splash/splash_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Route table.
///
/// Participant deep links (/e/..., /invite/...) resolve outside the organizer
/// shell so shared-link visitors get a focused flow with no bottom navigation.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    errorBuilder: (context, state) => const LinkErrorScreen(),
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/auth/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/auth/verify-email', builder: (_, __) => const EmailVerifyScreen()),
      GoRoute(path: '/auth/verify-phone', builder: (_, __) => const PhoneVerifyScreen()),

      // Organizer shell with bottom navigation.
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => OrganizerShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/discover', builder: (_, __) => const DiscoverScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/activity', builder: (_, __) => const ActivityScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          ]),
        ],
      ),

      // Full-screen flows above the shell.
      GoRoute(
        path: '/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) =>
            CreateWizardScreen(eventId: state.uri.queryParameters['eventId']),
      ),
      GoRoute(
        path: '/manage/:eventId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) =>
            ManageEventScreen(eventId: state.pathParameters['eventId']!),
        routes: [
          GoRoute(
            path: 'analytics',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, state) =>
                AnalyticsScreen(eventId: state.pathParameters['eventId']!),
          ),
        ],
      ),

      // Participant deep-link flow.
      GoRoute(
        path: '/e/:publicId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) =>
            EventDetailsScreen(publicId: state.pathParameters['publicId']!),
        routes: [
          GoRoute(
            path: 'vote',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, state) =>
                BallotScreen(publicId: state.pathParameters['publicId']!),
          ),
          GoRoute(
            path: 'results',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, state) =>
                ResultsScreen(publicId: state.pathParameters['publicId']!),
          ),
          GoRoute(
            path: 'confirmation',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (_, state) =>
                ConfirmationScreen(publicId: state.pathParameters['publicId']!),
          ),
        ],
      ),
      GoRoute(
        path: '/invite/:token',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) =>
            InviteScreen(token: state.pathParameters['token']!),
      ),
    ],
  );
});
