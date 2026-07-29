import 'package:flutter_test/flutter_test.dart';
import 'package:pulsevote/core/routing/deep_link_parser.dart';

void main() {
  group('Deep link parsing', () {
    test('parses event link', () {
      final link = DeepLink.tryParse(Uri.parse('https://pulsevote.app/e/riverside-award'));
      expect(link, isA<EventLink>());
      expect((link as EventLink).publicId, 'riverside-award');
    });

    test('parses vote and results sub-paths', () {
      expect(
        DeepLink.tryParse(Uri.parse('/e/abc-123/vote')),
        isA<EventVoteLink>(),
      );
      expect(
        DeepLink.tryParse(Uri.parse('/e/abc-123/results')),
        isA<EventResultsLink>(),
      );
    });

    test('parses invitation link', () {
      final link = DeepLink.tryParse(Uri.parse('/invite/demo-invite-2026'));
      expect(link, isA<InviteLink>());
      expect((link as InviteLink).token, 'demo-invite-2026');
    });

    test('rejects malformed links', () {
      expect(DeepLink.tryParse(Uri.parse('/e/!bad id!')), isA<InvalidLink>());
      expect(DeepLink.tryParse(Uri.parse('/e/ab')), isA<InvalidLink>());
      expect(DeepLink.tryParse(Uri.parse('/unknown/path')), isA<InvalidLink>());
      expect(DeepLink.tryParse(Uri.parse('/invite/x')), isA<InvalidLink>());
    });
  });
}
