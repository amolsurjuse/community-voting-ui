import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsevote/core/design/app_theme.dart';
import 'package:pulsevote/data/seed_data.dart';
import 'package:pulsevote/features/ballot/ballot_screen.dart';

Widget _app(Widget child,
    {ThemeMode mode = ThemeMode.light, double scale = 1}) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child,
        ),
      ),
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  // Mock repositories respond within ~700ms; avoid pumpAndSettle because the
  // screen contains repeating skeleton/live animations.
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  testWidgets('single-choice ballot: select, review and validate',
      (tester) async {
    final event = SeedData.communityAward;
    await tester.pumpWidget(_app(BallotScreen(publicId: event.publicId)));
    await _settle(tester);

    // Ballot builder visible with instructions and disabled review.
    expect(find.text('Select one option'), findsOneWidget);
    final reviewButton = find.widgetWithText(FilledButton, 'Review ballot');
    expect(tester.widget<FilledButton>(reviewButton).onPressed, isNull);

    // Select a candidate → counter updates and review enables.
    await tester.tap(find.text(event.candidates.first.name).first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('1 selected'), findsOneWidget);
    expect(tester.widget<FilledButton>(reviewButton).onPressed, isNotNull);

    // Review sheet shows finality warning.
    await tester.tap(reviewButton);
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.textContaining('After it is accepted, it cannot be changed'),
      findsOneWidget,
    );
  });

  testWidgets('ballot renders in dark theme', (tester) async {
    final event = SeedData.communityAward;
    await tester.pumpWidget(
      _app(BallotScreen(publicId: event.publicId), mode: ThemeMode.dark),
    );
    await _settle(tester);
    expect(find.text('Select one option'), findsOneWidget);
    final context = tester.element(find.byType(BallotScreen));
    expect(Theme.of(context).brightness, Brightness.dark);
  });

  testWidgets('ballot remains usable with large accessibility text',
      (tester) async {
    final event = SeedData.employeePoll;
    await tester.pumpWidget(
      _app(BallotScreen(publicId: event.publicId), scale: 1.6),
    );
    await _settle(tester);
    expect(find.textContaining('Select 1–3 options'), findsOneWidget);
  });

  testWidgets('candidate cards expose screen-reader labels', (tester) async {
    final event = SeedData.communityAward;
    await tester.pumpWidget(_app(BallotScreen(publicId: event.publicId)));
    await _settle(tester);

    final candidate = event.candidates.first;
    expect(
      find.bySemanticsLabel(
        RegExp('${candidate.name}.*${candidate.subtitle}'),
      ),
      findsWidgets,
    );
  });

  testWidgets('phone-verified event shows verification gate before ballot',
      (tester) async {
    await tester.pumpWidget(
      _app(BallotScreen(publicId: SeedData.clubElection.publicId)),
    );
    await _settle(tester);
    expect(find.text('Quick phone check'), findsOneWidget);
    // No candidate list yet.
    expect(
        find.text(SeedData.clubElection.candidates.first.name), findsNothing);
  });
}
