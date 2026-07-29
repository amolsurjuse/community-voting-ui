# PulseVote

A lightweight, privacy-conscious community voting app built with Flutter. For informal elections, contests, awards, club votes, employee polls, and ranked voting. **Not** a government-election or legally certified voting system — the UI states its verification level honestly and never claims device verification proves unique human identity.

## Quick start

Requires Flutter 3.27+ (stable channel).

```bash
flutter create . --project-name pulsevote --platforms=ios,android   # one-time: platform folders
flutter pub get
flutter run              # pick an iOS simulator or Android emulator
```

The repo ships Dart source only; `flutter create .` generates the iOS/Android host projects around it (it will not overwrite `lib/` or `pubspec.yaml` dependencies).

The app runs entirely on an in-memory mock backend with six seeded sample events (a public award, an unlisted employee poll, a phone-verified club election, a ranked-choice mural vote, a closed event with final results, and an organizer draft). No server needed.

**Demo credentials:** any registration input is accepted; every OTP field (email, phone, participant verification) accepts any 6-digit code ending in an **even** digit (e.g. `111112`). Odd-ending codes exercise the failure path. The invitation token `demo-invite-2026` resolves to the employee poll.

**Try the participant deep-link flow** without registering: tap "Explore public events" on onboarding, open an event, and vote. Routes `/e/{publicId}`, `/e/{publicId}/vote`, `/e/{publicId}/results`, and `/invite/{token}` are wired for platform deep links.

## Tests

```bash
flutter analyze
flutter test
```

Coverage includes: single/multiple/ranked ballot validation, min/max rules, ranked ordering and reordering, duplicate-ballot response, idempotent submission retry after a simulated network interruption, expired/closed event behavior, result-visibility policy, deep-link parsing, discovery visibility rules, invitation redemption, wizard draft persistence, candidate add/reorder, plus widget tests for the ballot screen (light/dark theme, large text, screen-reader labels, phone-verification gate) and the results screen (live stream, ranked rounds, after-close gating).

## Build

```bash
flutter build apk --release        # Android
flutter build ios --release        # iOS (requires signing)
```

## Project structure

```
lib/
  main.dart, app.dart          # entrypoint, theming, router wiring
  core/
    design/                    # tokens (color/spacing/radius/motion), themes
    routing/                   # GoRouter table, typed deep-link parser
    storage/                   # SecureStore abstraction (in-memory dev impl)
    utils/                     # formatters, haptics
    widgets/                   # design-system components (badges, cards,
                               #   skeletons, empty/error states, result bars)
  domain/
    models/                    # immutable models: event, candidate, ballot,
                               #   results, organizer, activity, analytics
    repositories.dart          # repository interfaces (the backend contract)
  data/
    mock_backend.dart          # shared in-memory state + ballot/tally logic
    mock_repositories.dart     # mock implementations of every repository
    ranked_choice_counter.dart # instant-runoff round computation
    seed_data.dart             # six realistic sample events
    providers.dart             # Riverpod composition root (swap point)
  features/                    # feature-first screens + controllers
    splash/ onboarding/ auth/ shell/ home/ discover/ create/ event/
    ballot/ results/ manage/ analytics/ activity/ profile/
test/                          # unit + widget tests
docs/                          # architecture & design-system docs
```

## Documentation

- `docs/ARCHITECTURE.md` — navigation map, screen inventory, state architecture, mock API contract, backend integration points.
- `docs/DESIGN_SYSTEM.md` — tokens, components, motion, accessibility rules.

## Known limitations

- Mock backend is in-memory: state resets on app restart (drafts, receipts, session). The `SecureStore` and repository interfaces are the swap points for real persistence.
- `InMemorySecureStore` must be replaced with a `flutter_secure_storage`-backed implementation before production.
- Candidate/cover images use generated gradients and emoji instead of uploads (keeps the app asset-free); the image-crop/upload flow is a UI stub.
- Score voting, organizer-approved enrollment, and bulk candidate paste are visible as "coming soon" but not implemented, per spec.
- Ranked-choice rounds are computed from synthetic ballots derived from first-preference tallies (production servers would count real ballots).
- Platform share sheet and QR render are real; email/SMS delivery, push notifications, and CSV export are simulated.
- Passwordless sign-in option is not yet implemented (password + strength meter is).
- No localization files yet; the language setting is a preference stub.

## Backend integration points

Every network concern sits behind an interface in `lib/domain/repositories.dart`: `AuthRepository`, `EventRepository`, `BallotRepository` (idempotent submit keyed by client token), `ResultsRepository` (stream — WebSocket-ready), `AnalyticsRepository`, `ActivityRepository`. Swap the providers in `lib/data/providers.dart` for real implementations (e.g. Dio-based) without touching any feature code. The mock's response shapes double as the API contract (see `docs/ARCHITECTURE.md`).
