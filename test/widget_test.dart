import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsevote/app.dart';

void main() {
  testWidgets('PulseVote application renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PulseVoteApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
