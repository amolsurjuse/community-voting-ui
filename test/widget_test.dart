import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsevote/app.dart';

void main() {
  test('PulseVote application root is constructible', () {
    expect(const PulseVoteApp(), isA<ConsumerWidget>());
  });
}
