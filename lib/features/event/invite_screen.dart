import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/states.dart';
import '../../data/providers.dart';
import '../../domain/models/event.dart';

final _inviteProvider =
    FutureProvider.family<VotingEvent?, String>((ref, token) {
  return ref.watch(eventRepositoryProvider).redeemInvitation(token);
});

/// Resolves /invite/{token}: valid tokens open the event; the token itself is
/// never displayed after redemption.
class InviteScreen extends ConsumerWidget {
  const InviteScreen({super.key, required this.token});

  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_inviteProvider(token));
    return Scaffold(
      appBar: AppBar(title: const Text('Invitation')),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => ErrorPanel(
            message:
                'We could not verify this invitation. Check your connection.',
            onRetry: () => ref.invalidate(_inviteProvider(token)),
          ),
          data: (event) {
            if (event == null) {
              return EmptyState(
                icon: Icons.mail_lock_outlined,
                title: 'Invitation not valid',
                message:
                    'This invitation may have expired, been revoked, or already been used. Ask the organizer for a new one.',
                actionLabel: 'Explore public events',
                onAction: () => context.go('/discover'),
              );
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                context.pushReplacement('/e/${event.publicId}');
              }
            });
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}
