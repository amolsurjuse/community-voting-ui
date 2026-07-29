# PulseVote Design System

Material 3 is the structural foundation; identity comes from custom tokens and components (`lib/core/design/`, `lib/core/widgets/`). The brand voice is participation, trust, momentum, clarity, inclusion — deliberately non-political so the same product fits awards, product votes, club elections, and polls.

## Color tokens (`tokens.dart` → `AppColors`)

| Token | Value | Use |
|-------|-------|-----|
| `primary` | `#0E7C6B` deep teal | brand, primary actions |
| `primaryBright` | `#14B8A0` | dark-theme primary |
| `indigo` | `#4F5DD3` | secondary, gradients |
| `coral` | `#FF7A59` | celebratory accents |
| `success / warning / danger / info` | semantic | status, callouts |
| `categorical[8]` | Okabe–Ito derived | candidate avatars & result bars — **color-blind safe**, never the sole channel of meaning (icons + labels always accompany color) |
| `coverGradients[6]` | brand gradient pairs | asset-free event artwork |

Light surfaces `#F7FAF9`/white; dark surfaces `#101817`/`#1B2523`. Both themes are generated from the same seed with high-contrast-safe text tokens; candidate avatars and result bars keep white-on-saturated fills readable in both modes.

## Typography

System font, weights 400–800. Scale: display 34/800, headlineMedium 26/800, headlineSmall 22/700, titleLarge 18/700, titleMedium 16/600, body 16/14/400, label 15/13/11. Negative letter-spacing on headings for a modern feel. Text scaling is supported up to 2.0× (clamped in `app.dart`); layouts use `Wrap`/`Expanded` so large text reflows instead of clipping.

## Spacing, radius, elevation, motion

- Spacing: 4 / 8 / 12 / 16 / 24 / 32 / 48 (`Spacing.*`)
- Radius: 8 / 12 / 16 / 24 / pill (`Corners.*`); cards 16, sheets 24 top
- Elevation: 0 / 1 (card) / 3 (raised) / 8 (overlay), soft shadows
- Motion: 150ms fast / 250ms standard / 400ms emphasized, `easeOutCubic`. `Motion.of(context, d)` returns `Duration.zero` when the OS reduced-motion preference is on — every animation in the app routes through it or checks `MediaQuery.disableAnimations` (skeleton pulse, live dot, success pops, bar fills).

## Components (`core/widgets/`)

- `VerificationBadge`, `StatusBadge`, `VisibilityBadge` — icon+label pills; screen-reader labels describe meaning, not color.
- `CandidateAvatar` / `EventCoverArt` — generated gradient identity, zero image assets.
- `EventCard` — shared across home, discovery, management.
- `ResultBar` — animated horizontal bar with count + percentage, leader/tie icons; horizontal bars are used instead of pie charts by design.
- `EmptyState`, `ErrorPanel` (retry), `SkeletonBox`/`SkeletonList` (pulse loading — no blocking spinners for content), `InfoCallout` (neutral/warning/danger/success trust messaging), `SectionHeader`, `InfoRow`, `showAppSheet` (consistent bottom sheets).
- Buttons: 52px min-height filled/outlined (theme-level), ≥44px touch targets everywhere.

## Interaction rules

- Haptics through `Haptics` only: selection ticks for choices/tabs/reorder, medium impact for success, heavy for warnings.
- Bottom sheets for candidate details, review, share, and pickers; dialogs only for destructive confirmation (leave ballot, close voting, delete account).
- Pull-to-refresh on home, discovery, event details, results.
- Back-navigation warnings only when real selections would be lost.
- Every interactive element has a semantic label; OTP entry is a single autofill-capable field rendered as digit cells; ranked items expose "Rank N, drag to reorder" labels.

## Voice & trust copy

Calm, specific, never alarming. Finality: "Review your ballot carefully. After it is accepted, it cannot be changed." Unknown outcome: "We are confirming whether your ballot was accepted" — never framed as failure. Installation verification always includes the one-ballot-per-installation honesty statement. Ranked results state the exact counting method and tie-break policy rather than implying a universal algorithm.
