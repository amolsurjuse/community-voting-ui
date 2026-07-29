import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/design/tokens.dart';
import '../../core/widgets/candidate_avatar.dart';
import '../../core/widgets/common.dart';
import '../../domain/models/event.dart';

const _baseUrl = 'https://pulsevote.app';

String shareUrlFor(VotingEvent event) => '$_baseUrl/e/${event.publicId}';

/// Share sheet: preview card, copy link, QR code, native share
/// (WhatsApp / email / messages come free via the system sheet).
Future<void> showShareSheet(BuildContext context, VotingEvent event) {
  return showAppSheet(context, child: _ShareSheet(event: event));
}

class _ShareSheet extends StatelessWidget {
  const _ShareSheet({required this.event});

  final VotingEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = shareUrlFor(event);
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Share event', style: theme.textTheme.headlineSmall),
          const SizedBox(height: Spacing.lg),
          // Share preview card.
          Container(
            padding: const EdgeInsets.all(Spacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Corners.lg),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                EventCoverArt(
                  coverSeed: event.coverSeed,
                  emoji: event.coverEmoji,
                  height: 52,
                  borderRadius: BorderRadius.circular(Corners.md),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: theme.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        url,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.xl),
          Center(
            child: Container(
              padding: const EdgeInsets.all(Spacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Corners.lg),
              ),
              child: QrImageView(
                data: url,
                size: 180,
                semanticsLabel: 'QR code linking to ${event.title}',
              ),
            ),
          ),
          const SizedBox(height: Spacing.xl),
          FilledButton.icon(
            onPressed: () {
              // Native system share sheet (WhatsApp, Messages, Mail, …).
              Share.share(
                'Vote in "${event.title}" on PulseVote: $url',
                subject: event.title,
              );
            },
            icon: const Icon(Icons.ios_share),
            label: const Text('Share…'),
          ),
          const SizedBox(height: Spacing.md),
          OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied to clipboard')),
                );
              }
            },
            icon: const Icon(Icons.link),
            label: const Text('Copy link'),
          ),
        ],
      ),
    );
  }
}
