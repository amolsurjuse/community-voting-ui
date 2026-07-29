import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/states.dart';

/// Fallback for invalid or unsupported deep links.
class LinkErrorScreen extends StatelessWidget {
  const LinkErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: EmptyState(
          icon: Icons.link_off,
          title: 'That link didn\'t work',
          message:
              'The link may be invalid, expired, or from a newer version of the app. Update the app or ask for a fresh link.',
          actionLabel: 'Go home',
          onAction: () => context.go('/home'),
        ),
      ),
    );
  }
}
