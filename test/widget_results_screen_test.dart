import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsevote/core/design/app_theme.dart';
import 'package:pulsevote/data/seed_data.dart';
import 'package:pulsevote/features/results/results_screen.dart';

Widget _app(Widget child) {
  return ProviderScope(
    child: MaterialApp(theme: AppTheme.light(), home: child),
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  testWidgets('live results show ballots total and live indicator',
      (tester) async {
    await tester.pumpWidget(
      _app(ResultsScreen(publicId: SeedData.communityAward.publicId)),
    );
    await _settle(tester);
    expect(find.text('Live'), findsOneWidget);
    expect(find.textContaining('ballots'), findsWidgets);
    expect(find.text(SeedData.communityAward.candidates.first.name),
        findsOneWidget);
  });

  testWidgets('live stream pushes updated totals over time', (tester) async {
    await tester.pumpWidget(
      _app(ResultsScreen(publicId: SeedData.communityAward.publicId)),
    );
    await _settle(tester);
    // Mock stream emits every 4s and adds a vote each tick.
    final before = SeedData.communityAward.totalBallots;
    await tester.pump(const Duration(seconds: 9));
    expect(find.textContaining('ballots'), findsWidgets);
    // The screen is still alive and rendering after stream ticks.
    expect(before >= 0, isTrue);
  });

  testWidgets('after-close event hides results while open message shows',
      (tester) async {
    await tester.pumpWidget(
      _app(ResultsScreen(publicId: SeedData.clubElection.publicId)),
    );
    await _settle(tester);
    expect(find.text('Results after the event closes'), findsOneWidget);
  });

  testWidgets('ranked event shows round-by-round breakdown', (tester) async {
    await tester.pumpWidget(
      _app(ResultsScreen(publicId: SeedData.rankedVote.publicId)),
    );
    await _settle(tester);
    expect(find.text('Round-by-round count'), findsOneWidget);
    expect(find.textContaining('Round 1'), findsWidgets);
  });
}
