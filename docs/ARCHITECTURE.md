# Architecture

## Layers

**Domain** (`lib/domain/`) — immutable models with hand-written `copyWith` (no codegen, so `flutter pub get && flutter run` just works) and repository interfaces. Ballot validation lives on `BallotDraft.validate` so it is testable without widgets.

**Data** (`lib/data/`) — `MockBackend` holds all in-memory state; mock repositories add realistic latency and delegate to it. `providers.dart` is the composition root: swap any provider to point at a real backend.

**Features** (`lib/features/`) — one folder per feature; screens are Riverpod `Consumer` widgets, business logic lives in `Notifier` controllers. No business logic inside visual widgets.

**Core** (`lib/core/`) — design tokens, themes, reusable components, routing, secure storage, utilities.

## Navigation map

```
/splash ──► /onboarding (first launch) ──► /auth/register ─► /auth/verify-email ─► /auth/verify-phone
        └─► shell (bottom nav)
              /home        organizer dashboard
              /discover    public search + rails
              [Create]     center button ─► /create (full-screen wizard)
              /activity    notifications feed
              /profile     settings, verification, account

Full-screen (above shell):
  /create?eventId=…                 6-step wizard (new or resume draft)
  /manage/:eventId                  organizer management
  /manage/:eventId/analytics        aggregate analytics

Participant deep links (no bottom nav — focused flow):
  /e/:publicId                      event details
  /e/:publicId/vote                 ballot (verification gate → build → review → submit)
  /e/:publicId/confirmation         receipt
  /e/:publicId/results              live/final results
  /invite/:token                    invitation resolution
  invalid links                     LinkErrorScreen (GoRouter errorBuilder)
```

`DeepLink.tryParse` (`core/routing/deep_link_parser.dart`) is the typed abstraction over inbound URIs, unit-tested independently of the router.

## Screen inventory

| # | Screen | File |
|---|--------|------|
| 1 | Splash + init/retry | `features/splash/splash_screen.dart` |
| 2 | Onboarding (3 pages) | `features/onboarding/onboarding_screen.dart` |
| 3 | Organizer registration | `features/auth/register_screen.dart` |
| 4 | Email verification | `features/auth/email_verify_screen.dart` |
| 5 | Phone verification | `features/auth/phone_verify_screen.dart` |
| 6 | Organizer home | `features/home/home_screen.dart` |
| 7 | Creation wizard (6 steps) | `features/create/…` |
| 8 | Event preview | `features/create/steps/preview_step.dart` |
| 9 | Participant event details | `features/event/event_details_screen.dart` |
| 10 | Candidate details sheet | `features/event/candidate_sheet.dart` |
| 11 | Ballot (3 ballot types) | `features/ballot/ballot_screen.dart` |
| 12 | Ballot review | `features/ballot/ballot_review_sheet.dart` |
| 13 | Submission states | in `ballot_screen.dart` (per-phase views) |
| 14 | Confirmation + receipt | `features/ballot/confirmation_screen.dart` |
| 15 | Results (+ ranked rounds) | `features/results/…` |
| 16 | Discovery | `features/discover/discover_screen.dart` |
| 17 | Event management | `features/manage/manage_event_screen.dart` |
| 18 | Analytics | `features/analytics/analytics_screen.dart` |
| 19 | Share sheet (QR/copy/native) | `features/event/share_sheet.dart` |
| 20 | Activity feed | `features/activity/activity_screen.dart` |
| 21 | Profile & settings | `features/profile/profile_screen.dart` |
| 22 | Invite / link error | `features/event/invite_screen.dart`, `link_error_screen.dart` |

## State architecture

All major states are explicit enums/sealed classes — no boolean explosion.

- **Session** (`SessionController`): `initializing → initFailed | unauthenticated | authenticated`. Splash drives `initialize()` (installation id + key alias into `SecureStore`, session restore).
- **Ballot flow** (`BallotFlowController`, family-keyed by publicId): `loading → loadError | eventNotFound | needsVerification → verifying → building → submitting → confirmingOutcome | accepted | alreadyVoted | eventClosed | verificationExpired | invalid`. An idempotency `clientToken` is generated once per attempt; `confirmingOutcome` (transport failure, unknown result) retries with the same token and is messaged as "we are confirming", never as failure. Local success is never treated as server acceptance — only a `BallotAccepted` response transitions to `accepted`.
- **Creation wizard** (`CreateWizardController`, family-keyed by draft id): step enum + `editing | saving | publishing | published | error`; per-step completeness gates Continue; settings visually lock once the event opens.
- **Async reads** use Riverpod `FutureProvider`/`StreamProvider` with `when(loading/error/data)` mapping to skeletons / `ErrorPanel` with retry / content, plus explicit empty states.
- **Results** stream from `ResultsRepository.watchResults` (mock emits every 4s; contract is WebSocket-shaped). Stream errors render a reconnect panel.

## Mock API contract

The repository interfaces define the backend contract:

```
AuthRepository
  register(fullName,email,phone,password) → Organizer
  verifyEmail(code) / verifyPhoneOtp(code) → Organizer   (throws RepositoryException)
  restoreSession() → Organizer?

EventRepository
  getByPublicId(id) → VotingEvent?          (null = not found / no access)
  saveDraft(event) / publish(id) / close(id) / archive(id) / duplicate(id)
  discover(filters, page) → [VotingEvent]   (public, non-draft only; paginated)
  trending() / closingSoon() / newlyPublished()
  redeemInvitation(token) → VotingEvent?    (null = invalid/expired; token never re-exposed)

BallotRepository
  existingReceipt(eventId) → BallotReceipt?
  submit(draft{clientToken}) → BallotAccepted | BallotAlreadyCast | BallotEventClosed
                             | BallotVerificationExpired | BallotInvalid | BallotOutcomeUnknown
      -- idempotent on clientToken: retries replay the original outcome
  recentEventIds() / rememberEvent(publicId)   (local participant history)

ResultsRepository
  watchResults(eventId) → Stream<ResultsSnapshot{tallies, rankedRounds, isFinal, belowThreshold}>

AnalyticsRepository
  summary(eventId) → EventAnalytics (aggregate only, never participant-level)
  requestExport(eventId)

ActivityRepository
  watchActivity() → Stream<[ActivityItem]> ; markAllRead()
```

## Security-aware UI rules implemented

- Receipts are random codes unrelated to selections (asserted in tests).
- `Candidate.organizerNotes` is never rendered in participant-facing widgets.
- Phone numbers are masked in `Organizer.phone`; raw numbers are never logged or persisted client-side.
- Invitation tokens are consumed by `redeemInvitation` and never displayed afterward.
- Analytics show only aggregates; platform split hides below a privacy-safe sample size.
- Installation-verification events always show: "One ballot is allowed per verified app installation for this event. This does not guarantee one ballot per individual person."
- Secure material (installation id, key alias, auth token, verification-session token) goes through the `SecureStore` interface only.

## Connectivity behavior

Submission uses explicit outcome types; a timeout yields `BallotOutcomeUnknown` → the UI shows a confirming state and retries the same idempotency token. Ballots are never silently queued offline: the flow re-validates event state (`load()`) after connectivity returns, so closed/expired events resolve to their proper terminal states instead of ghost-submitting.
