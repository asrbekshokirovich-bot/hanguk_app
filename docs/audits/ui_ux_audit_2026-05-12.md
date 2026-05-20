# UI / UX deep audit — 2026-05-12

> Investigation-only pass over every screen and widget in
> `lib/features/*/presentation/` plus the cross-cutting design system
> (`lib/design_system/`), router (`lib/core/router/`), entry point
> (`lib/main.dart`), and `lib/l10n/` ARB files. Findings are paired
> with research into current mobile UI/UX best practice (Material
> Design 3, Apple HIG, WCAG 2.2, Korean conventions, voice & AI
> patterns) and rolled up into a prioritized P0/P1/P2 backlog at the
> bottom.
>
> The prior audits closed scope-specific issues (training, map +
> walkaround, KakaoTalk integration, store-readiness). This audit
> looks at the whole *surface* of the app from the user's POV —
> consistency of look-and-feel, accessibility, dark-mode parity,
> i18n adoption across screens, performance pitfalls, and the unique
> AI / voice / 360-tour surfaces. It deliberately overlaps with the
> prior audits where a UI symptom traces to a finding that was
> closed at the code/data layer but still has a visible follow-on.
>
> Auditor: Claude (build sandbox)
> Sister audits:
> - `docs/audits/training_audit_2026-05-10.md`
> - `docs/audits/map_walkaround_audit_2026-05-11.md`
> - `docs/audits/kakaotalk_audit_2026-05-11.md`
> - `docs/audits/store_readiness_audit_2026-05-12.md`

---

## Executive summary

The app has a coherent visual identity — dark-mode-only, glassmorphic
navy gradient, lime accent — and recent audits closed most of the
hard correctness bugs. From a UI/UX standpoint the surface is *built*,
but the gap between the current build and a polished, accessible,
internationalized store-grade app is wider than any single prior
audit captured. The headline issues are: (1) **the new
`AccountScreen` is unreachable** — no route, no entry point in the
nav or app bars; (2) **i18n adoption is ~5% of strings** — full
infra is wired but every screen still hardcodes English; (3)
**accessibility coverage is near zero** — three `Semantics()` calls
across the whole `lib/`, no tooltips on most icon-only buttons, no
`autofillHints` anywhere, hit targets routinely <48 dp; (4)
**`withOpacity` is used 141 times** — silently deprecated in
Flutter 3.27 and slated for removal, every call site is a future-bug
sink; (5) **the bottom-nav is the legacy Material-2 widget** in
the only screen that uses it, despite a working M3
`AdaptiveBottomNavigation` already living in `lib/design_system/`.

The app is dark-mode-only with no light theme, which is legitimate as
a brand choice but means the contrast story has to be carried entirely
by the dark palette — and `Colors.white38` (38% white on
near-black) is below WCAG 2.2 AA 4.5:1 contrast in many text spots.
Dynamic Type is not respected anywhere (no `MediaQuery.textScaler`
honoring; every `TextStyle` is hardcoded). The Kakao Roadview and
Pannellum 360 surfaces have a clean state-driven overlay (recent map
audit P0 work) but no keyboard-/screen-reader path to operate the
panorama. The Vapi-driven Interview Active view has no live waveform
or speaking-indicator beyond a text string. The "ChatGPT-style"
`AdvancedDraftingWorkspace` has ghost text + grammar highlighting
(good) but no visible affordance for *how* to accept it on a phone
(the Tab key is wired, but mobile keyboards don't show Tab).

| metric | value |
|---|---|
| Source LOC under `lib/features/*/presentation` | 10,896 across ~50 files |
| Screens covered in this audit | 24 |
| `withOpacity(...)` call-sites (deprecated, removal slated) | **141 across 27 files** |
| `Semantics(...)` widgets across `lib/` | **3 total** (all in `map_tab.dart`) |
| `tooltip:` attribute on IconButton/TextButton-like | 47 sites — but ~150 such buttons exist (~30% covered) |
| `autofillHints:` declarations | **0** |
| `keyboardType:` overrides | **0** |
| `textInputAction:` overrides | **1** (chat_tab) |
| `cached_network_image` usage | **0** — every logo refetches every rebuild |
| `Image.network(...)` direct call-sites | 4 |
| Hardcoded `TextStyle(fontSize:)` literals | 51 across 15 files — no shared type scale |
| `useMaterial3: true` | yes |
| Light theme defined | **no** |
| `AppTheme.cupertinoTheme` consumed by `MaterialApp` | **no** (defined, not wired) |
| `BottomNavigationBar` (M2 legacy) vs `NavigationBar` (M3) | M2 in `home_screen.dart:83`; M3 in unused `AdaptiveBottomNavigation` |
| `AccountScreen` route registrations | **0** — defined but unreachable |
| ARB locales declared | 5 (en, ko, ru, uz, vi) |
| Non-English ARB content translated | en filled; ko/ru/uz/vi seeded with English placeholders + `TODO: translate` markers |

### Headline findings (top 10)

1. **`AccountScreen` is unreachable.** `account_screen.dart` is fully implemented (sign-out, data export, irreversible deletion with `DELETE`-typed confirmation), but `app_router.dart` has **no `/account` route** and **no widget references `AccountScreen`** (verified via grep). The only sign-out path is the small `Icons.logout` icon on Applications' `SliverAppBar` — which calls `signOut()` directly with no confirmation. The required-by-Apple-and-Play account deletion flow exists in code but cannot be invoked. **P0.**
2. **Bottom navigation is on the legacy widget, with hardcoded English labels.** `home_screen.dart:83` uses `BottomNavigationBar` (M2-era) with labels `['Home', 'Map', 'Docs', 'Training']`. M3's `NavigationBar` already exists in the codebase via unused `AdaptiveBottomNavigation`. "Home" is a misnomer — that tab is **Applications**. **P1.**
3. **141 `withOpacity` calls are on a deprecated API.** Flutter 3.27 deprecated `Color.withOpacity` in favor of `Color.withValues(alpha: ...)` to fix wide-gamut precision. Half-migrated state. **P1.**
4. **i18n is wired but not adopted.** `main.dart:102` mounts all delegates, 5 ARBs exist, but only ~25 keys defined; every screen hardcodes English. A Korean user opening any tab sees English. **P0.**
5. **Accessibility is effectively absent.** 3 `Semantics()` widgets in the whole `lib/`. No tooltips, no labels, hit targets <48 dp, no Dynamic Type. WCAG 2.2 AA fails on multiple criteria. **P0.**
6. **`Image.network` instead of `cached_network_image`.** Every university logo re-downloads on every rebuild — 4 call-sites across Applications + Map. Visible flicker on scroll. **P1.**
7. **"Coming Soon" buttons are tappable dead-ends.** `welcome_screen.dart:175` and `login_screen.dart:356` ship full-width buttons with `onPressed: () {}` — they ripple and do nothing. **P1.**
8. **Hit targets below platform minimum on multiple critical controls.** Map list/map toggle is 40 dp (below 48 dp Material / 44 pt iOS). Document slot "Upload" button is 36 dp. Welcome's logo tap area is undefined. **P1.**
9. **Splash + Welcome + Home each fire `checkForUpdates`; `UpdateGate` then fires again.** Three concurrent calls on cold start. The Splash also uses a hardcoded purple indicator that doesn't match the lime brand. **P2.**
10. **No Korean / multi-script font is bundled.** Hangul falls through to system default — Latin renders in Roboto/SF, Hangul in the system fallback, with different baselines mid-word. Korean apps overwhelmingly bundle Pretendard or Noto Sans KR. **P1.**

---

## Section 1 — what exists today

### 1.0 Cross-cutting plumbing

#### `lib/main.dart` (84 LOC)

  - `MaterialApp.router` with `useMaterial3` via theme.
  - **No `light` theme** — `theme: AppTheme.materialTheme` only; no `darkTheme:`, no `themeMode:`. Dark always.
  - `localizationsDelegates` and `supportedLocales` correctly wired (audit close from training L1/L3).
  - Supabase URL and anon key **hardcoded in source** (`main.dart:29-31`). Anon keys are publishable but checking them in next to the env file is a credential-rotation hazard.
  - `_SplashApp` paints `Color(0xFF0A0A1A)` background and a `Color(0xFF6C63FF)` (purple) progress indicator. Neither in `AppColors`. First paint is off-brand.

#### `lib/design_system/theme/app_theme.dart` (108 LOC)

  - `useMaterial3: true` ✅.
  - `colorScheme: ColorScheme.dark(...)` constructed manually — not `fromSeed`, so M3 tonal surfaces (`surfaceContainerHighest`, `secondaryContainer`, etc.) fall back to defaults. `document_slot.dart:35` reads `surfaceContainerHighest` so those surfaces are *whatever the default dark scheme picks*, not the Hanguk palette.
  - `AppBarTheme.iconTheme` is `vibrantLime`; `centerTitle: true`; transparent background. Looks fine on `HangukScaffold`, inconsistent against `home_screen` slivers.
  - `InputDecorationTheme.hintStyle: Colors.white38` (38% white) — fails WCAG 2.2 AA 4.5:1 against glass fill.
  - **No `textTheme`** — M3 type scale (`displayLarge` → `bodySmall`) left at defaults; 51 hand-rolled `TextStyle(fontSize:...)` literals elsewhere.
  - `vibrantLime` (#D4E94C) text on `vibrantLime.withOpacity(0.1)` background (pervasive chip pattern) is **~2.5:1** — fails AA.

#### `lib/design_system/theme/app_colors.dart` (36 LOC)

  - Clean palette. `error: #DC2626` flagged by the store audit for contrast.
  - `borderGlass: Color(0x1AFFFFFF)` — 10% white. At 0.5 px width (`HangukCard` default) on a dark background it's **~1.3:1** non-text contrast — invisible.

#### `lib/design_system/adaptive/`

Seven files, partial adoption.

  - **`adaptive_bottom_navigation.dart`** — `Platform.isIOS` switch between `CupertinoTabBar` and M3 `NavigationBar`. **Never used.** `Platform.isIOS` throws on web; needs `kIsWeb` guard.
  - **`adaptive_scaffold.dart`**, **`adaptive_text_field.dart`**, **`adaptive_button.dart`** — defined but unused.
  - **`hanguk_card.dart`** — used pervasively. No `splashColor` passed; ink ripple is framework default (white at 30%), looks white-on-white on lime.
  - **`hanguk_scaffold.dart`** — top-bottom gradient + transparent Scaffold. Fixed-direction; on landscape tablets the gradient compresses to bands.
  - **`empty_state.dart`** — reusable empty-state widget. Used in a handful of places; most empty surfaces render bare text instead.

#### `lib/core/router/app_router.dart` (253 LOC)

  - `GoRouter` with `/`, `/welcome`, `/login` + map deeplinks + uni_db flag-gated routes.
  - **No `/account` route.**
  - Redirect blob handles auth-gating but doesn't surface "Session expired" — silent teleport to `/welcome`.
  - `_RouteMissingShell:124` hardcodes `Color(0xFF0F1626)` — off-palette.
  - `LoginRoute` consumes `state.extra as Map<String, dynamic>?` — won't survive cold deep links; a query param would be safer.

#### `lib/l10n/*.arb` (5 files)

  - English: ~25 keys covering training start/end labels, walkaround state, apply CTAs. **Everything else is hardcoded.**
  - ko/ru/uz/vi: each is a copy of en with values prefixed `TODO: translate`.
  - No plurals declared.
  - All `Padding.fromLTRB` is direction-fixed (not `EdgeInsetsDirectional`); RTL would require a rework. Today's locales are all LTR — non-blocking but flagged.

---

### 1.1 Welcome / Splash

#### `welcome_screen.dart` (187 LOC)

  - **Layout:** `Scaffold` → vertical-gradient `Container` → `SafeArea` → `Column` (header + Spacer + hero + Spacer(flex:2)).
  - **Logo:** JPEG wrapped in a white square to blend on the gradient. Should be PNG/transparent or SVG.
  - **Buttons:**
    - "I have a Magic Code" — wired ✅.
    - "Log In / Sign Up with Phone Number (Coming Soon)" — `onPressed: () {}` ❌. Tappable, ripples, no effect.
  - **i18n:** none.
  - **a11y:** no `Semantics`. "Magic Code" button reads as just that with no explanation of what a code is.
  - **Animation:** none.
  - **Errors/loading:** the update check that fires here can pop a dialog before any tap.
  - **`withOpacity`:** 3 calls.

#### Splash (inline in `main.dart` lines 41-71)

  - Logo + `CircularProgressIndicator`. Background `0xFF0A0A1A` and indicator `0xFF6C63FF` are off-palette literals. Purple-to-lime transition between splash and welcome is jarring.
  - No timeout — Supabase init hang would freeze the splash forever.

---

### 1.2 Auth — `login_screen.dart` (542 LOC)

  - `HangukScaffold` → `SafeArea` → `SingleChildScrollView` → header + `HangukCard` form.
  - **State:** `_isMagicCodeMode` toggles between functional magic-code portal and a "Coming Soon" stub for phone auth. Eight controllers declared for a UI that today uses one (`_codeCtrl`).
  - **Dead code:**
    - `TabController` declared, no visible `TabBar`. Dead.
    - `_LoadingView` at line 435 — never instantiated. Dead.
    - `_handleStudentLogin`, `_handlePhoneLogin`, `_handleSignUp` reachable from a UI that doesn't expose them.
  - **TextField hygiene:**
    - `_HangukTextField` — no `keyboardType`, no `autofillHints`, no `textInputAction`.
    - Magic code formatter limits to 10 chars; helper says "8-character code" — off by two.
    - No paste-friendly OTP autofill (no `AutofillHints.oneTimeCode`).
    - `letterSpacing: 6` is heavy for an 8-char code.
  - **Errors:** inline red banner (hardcoded English). Not announced to screen readers (no `liveRegion`).
  - **i18n:** zero.
  - **a11y:** prefix icon `Colors.white38` on glass fill — fails contrast. No `Semantics` on the magic-code button.
  - **Loading state:** `_HangukButton` swaps spinner ✅; surrounding UI doesn't disable inputs.
  - **`withOpacity`:** 1 call.

---

### 1.3 Bottom-nav shell — `home_screen.dart` (76 LOC)

  - `BottomNavigationBar` (legacy M2) at line 83 with hardcoded labels `['Home', 'Map', 'Docs', 'Training']`. First label is a misnomer.
  - `AdaptiveBottomNavigation` exists in `lib/design_system/` and is unused here.
  - `_tabs = [...]` holds all 4 tabs in memory simultaneously.
  - **FAB:** `FloatingActionButton` opens AI chat in a 90 %-height `showModalBottomSheet`. Icon is `Icons.smart_toy` (unconventional for AI). No tooltip, no `Semantics`.
  - Bottom sheet has no `showDragHandle: true` — manual handle in the modal body instead.
  - `_checkForUpdates` duplicates `UpdateGate` + WelcomeScreen.
  - **a11y:** none on the bottom-nav.
  - **`withOpacity`:** 0.

---

### 1.4 Applications tab

#### `applications_tab.dart` (131 LOC)

  - `CustomScrollView` with `SliverAppBar(title: 'My Applications')` floating+snap.
  - Sole AppBar action: sign-out icon (line 26-34) — fires `signOut()` directly with no confirmation.
  - Empty state: bare `Text('You have no active applications yet.')`. `EmptyState` widget exists but unused.
  - Loading: `CircularProgressIndicator.adaptive()` ✅.
  - Error: raw `Text('Error loading applications: $err')` — no retry button.
  - Two sections (`Pending`, `Active`) of `ApplicationCard`s.
  - **i18n:** none.
  - **a11y:** sign-out has tooltip ✅. Nothing else.

#### `application_card.dart` (196 LOC)

  - `HangukCard` + `AnimatedSize` (300 ms) expand on tap.
  - Header row: 48 px logo (`Image.network` — no caching) + name + location + "Partner" chip + chevron.
  - Expanded body: status banner OR `ProcessTracker` + Divider + 2 `OutlinedButton.icon`.
  - `errorBuilder` fallback ✅.
  - **a11y:** no `Semantics` that card is expandable. Buttons lack tooltips. Partner chip has no semantics.
  - **`withOpacity`:** 4 calls.

#### `process_tracker.dart` (124 LOC)

  - Vertical timeline of 9 hardcoded English steps.
  - **i18n:** zero. Steps not in any ARB.
  - **a11y:** no `Semantics` that announces "Step 4 of 9: Interview, current". Screen-reader users get nothing.

#### `university_selection_view.dart` (244 LOC)

  - Suggested unis + "AI Compare" button + multi-select (3-cap).
  - Snackbar on cap ✅.
  - Submit footer: instant appearance (no `AnimatedPositioned`).
  - Pluralization ad-hoc: `'Selection${count > 1 ? "s" : ""}'` — English-only.
  - **a11y:** double-semantics — row is `GestureDetector` AND contains `Checkbox`. Screen reader announces both.
  - **`withOpacity`:** 2 calls.

#### `university_room_modal.dart` (448 LOC)

  - `DefaultTabController(length: 4)` modal bottom sheet at 90 % height. Manual drag handle. Tabs: Status, Discussion, News, Calendar.
  - Status tab → `ProcessTracker`.
  - Discussion tab → KakaoTalk-style chat with `ListView.builder(reverse: true)` + fixed bottom input.
  - News tab → permanently empty "No active announcements." (no data source).
  - Calendar tab → `TableCalendar` with lime selected day, red event markers.
  - **i18n:** zero. `DateFormat('hh:mm a')` — 12-hour even in 24-hour-convention locales.
  - **a11y:** "X" close at line 194 has no tooltip. TableCalendar date cells have no `Semantics(label: 'Today, March 5th')`.
  - **Calendar contrast:** today's date marker (lime at 30 %) is hard to spot.
  - **`withOpacity`:** 12 calls.

---

### 1.5 Map tab

#### `map_tab.dart` (319 LOC)

  - SafeArea Column: top bar (title + search + map/list toggle), filter chips, map or list.
  - `AnimatedSwitcher` 350 ms ✅.
  - Real-time search; no debouncing (fine at current scale).
  - Filter chips wrapped in `Semantics(button:true, selected:..., label:...)` ✅ (M21 close).
  - Empty-state badge on map mode with `liveRegion: true` ✅.
  - Empty state on list mode: icon + text + "Clear filters" — reasonable.
  - Error state: best-in-app. Wifi-off icon + headline + subhead + retry.
  - List/map toggle: 40 dp hit target — below 48 dp minimum.
  - **i18n:** hardcoded ("Universities", "Search...", "All", "Partner", "Top", "Clear filters").
  - **`withOpacity`:** 12 calls.

#### `university_card.dart` (129 LOC)

  - 48 px logo (Image.network, no cache) + name + location + tier badge + partner chip + chevron.
  - **a11y:** no `Semantics`. Chevron is decorative-only.
  - **`withOpacity`:** 7 calls.

#### `university_detail_sheet.dart` (319 LOC)

  - `DraggableScrollableSheet` 60 % init, 40-90 % range.
  - Header: 80 px logo + name + location + partner badge.
  - Stats row: tier + IEQAS-verified + next event.
  - Up to 4 full-width buttons stacked: Virtual Tour (if Pannellum), Virtual Tour (if external URL), Virtual Walkaround (if lat/lng), Visit Website. **Hierarchy is flat** — 3 lime buttons in a row.
  - **a11y:** drag handle is decorative.
  - **i18n:** "Partner University", "Virtual Tour", etc. all hardcoded.
  - **`withOpacity`:** 11 calls.

#### `university_roadview_screen.dart` (118 LOC)

  - Kakao Roadview WebView. Sealed-state overlay (M6/K5 close): Loading, NoPano, SdkBlocked, Network, InitError — all localized ✅.
  - **a11y on the canvas:** none. Panorama is opaque to TalkBack/VoiceOver.
  - Back button is `InkWell` — no tooltip, no `Semantics`. Tap target borderline ~48 dp.

#### `virtual_tour_screen.dart` (217 LOC)

  - Pannellum WebView host. Loads `assets/virtual_tour/pannellum.html` + JS bridge.
  - Bool state (`_ready`, `_failed`) — inconsistent with Roadview's sealed-class pattern.
  - **a11y:** Pannellum's hotspots are inaccessible to screen readers (known limitation). Wrapper inherits.

---

### 1.6 Documents tab

#### `documents_tab.dart` (183 LOC)

  - `SliverAppBar('My Documents')` + lime info banner + required-documents list.
  - Error: **`Text('Error: \$err')` — backslash escapes the dollar, user sees raw `$err`**.
  - **i18n:** zero.
  - **a11y:** info banner has no semantics.

#### `document_slot.dart` (145 LOC)

  - Row: numbered circle / check + name + buttons.
  - **Mixed palettes:** `Theme.of(context).colorScheme.primaryContainer` + `Colors.green` + `AppColors.vibrantLime`. `primaryContainer` falls back to default dark scheme (not lime).
  - **a11y:** preview/delete IconButtons have no tooltip. "Upload" button is 36 dp tall — below 48 dp Material minimum.
  - **i18n:** "Pending Review", "Approved", "Upload" hardcoded.

---

### 1.7 Training tab

#### `training_tab.dart` (345 LOC)

  - Bare `Scaffold(transparent)` + title "Training Center" + 3 cards.
  - Cards use bespoke `GestureDetector` + manual decoration with heavy `BoxShadow` glow — **not `HangukCard`** — and not `InkWell`s. Visual style inconsistent with rest of app.
  - Interview card opens 270 LOC of `AlertDialog` with three pickers.
  - **i18n:** the ARB has `studyPlanCardTitle`, etc., but the screen still hardcodes.

#### `study_plan_screen.dart` (982 LOC)

  - `HangukScaffold` + AppBar with PopupMenu (track switch) + close-X.
  - 4-step wizard: Guide, Example, Draft, Feedback. `_buildStepper` connected circles.
  - Step transitions: `setState`-driven, no animated slide.
  - **i18n:** `training_strings.dart` has partial Korean/Uzbek/English for step 1 and a few labels; not the wizard nav, intro, or empty states.
  - **a11y:** stepper is purely visual — no `Semantics(label: "Step 3 of 4")`.

#### `advanced_drafting_workspace.dart` (351 LOC)

  - ChatGPT-style drafting surface. `AiHighlightingTextController` paints grammar inline + AI ghost text at cursor.
  - 1 s AI debounce + 2 s save debounce + 6 s AI rate-cap ✅ (A10 close).
  - **Ghost text accept gesture is Tab-key-only via `KeyboardListener`.** Mobile keyboards have no Tab. **Users cannot accept suggestions on phone** — they can only retype them.
  - Save indicator via `LiveMetricsBar` ✅.
  - "AI cooling down…" copy after each AI call — sounds like an error.

#### `interview_screen.dart` (118 LOC)

  - `HangukScaffold` + AppBar. AppBar action: "End Session" red text button — fails contrast on glass.

#### `interview_setup_view.dart` (230 LOC)

  - Interview type dropdown, language toggle, persona dropdown, focus topic field, Timed Mode `Switch`, Start Practice button.
  - **Switch row doesn't absorb the tap** — only the switch itself is tappable.

#### `interview_active_view.dart` (512 LOC)

  - `WidgetsBindingObserver` lifecycle ✅ (U18 close).
  - Vapi system prompt assembled inline (30 LOC in widget — high coupling).
  - **Live indicators are text strings** — "Your turn to speak", "Interviewer is speaking..." — **no waveform, no level meter, no pulsing avatar.**
  - End button in AppBar; bottom big "Hang up" button not present (covered by `_completeAutoEnd`).
  - **i18n:** some labels via `training_strings.dart`, partial.

#### `interview_analytics_view.dart` (376 LOC), `interview_history_view.dart` (155 LOC)

  - Post-session scorecards + audio replay. 6+ metric bars stack vertically — long scroll on small phones.
  - `DateFormat.yMMMd(locale).add_jm()` ✅ (H3 close).

#### `study_plan_history_view.dart` (226 LOC), `study_plan_analysis_view.dart` (109 LOC), `live_metrics_bar.dart` (124 LOC)

  - Each re-implements own type/spacing — no shared primitives.

---

### 1.8 Account screen — `account_screen.dart` (453 LOC)

  - **Unreachable.** Grep returns 4 hits — all inside `account_screen.dart` itself. Router, HomeScreen, WelcomeScreen, LoginScreen, every tab — none reference `AccountScreen`.
  - Inside the screen: top bar (`Navigator.maybePop()` — assumes a stack to pop, won't be the case via deep link), "Signed in as" card, Session→Sign out, Your data→Download, Danger zone→Delete (type-DELETE confirm + non-dismissible progress + error/success paths), Privacy + Terms footer.
  - **i18n:** `// TODO: localize` on tooltip 'Back'. Rest hardcoded.
  - **a11y:** red Delete button has no `Semantics(hint: 'Irreversible')`. `_DeleteConfirmDialog` hint is normal-weight white38 — visually weak.
  - **`withValues(alpha:)`** used throughout ✅.

---

### 1.9 Updater — `update_dialog.dart` (274 LOC) + `update_gate.dart` (80 LOC)

  - Sealed `UpdateState` + switch-expression render. Five sub-views: Available, Downloading, Installing, Failed, Idle/Checking.
  - Available: PopScope (canPop based on `forced`). Version, size MB, release notes, force-reinstall warning pill.
  - Downloading: `LinearProgressIndicator` + MB/MB text. `canPop: false` ✅.
  - Installing: spinner + "Verifying and installing…".
  - Failed: human-readable copy switched on `UpdateErrorCode`. Try Again CTA.
  - **i18n:** zero. All copy hardcoded.
  - From store-readiness POV: in-app APK installer is non-compliant for Play; `in_app_update` package is in pubspec but not wired in this file.

---

### 1.10 uni_db screens (flag-gated)

#### `institution_detail_screen.dart` (780 LOC)

  - Vanilla M3 (`Card`, `Chip`, `Theme.textTheme.titleMedium`). **The only file in the codebase that consumes the M3 `textTheme`** — inconsistent dialect with rest of app.
  - Sections: HeaderCard, TrackToggle, OpenGuidelineButton, Deadlines, Tuition, Requirements, Scholarships, Document checklist.
  - **i18n:** zero.
  - **a11y:** M3 defaults give baseline. Section headers via `titleMedium` only — no `Semantics(header:true)`.

#### `notification_settings_screen.dart` (158 LOC)

  - `SwitchListTile` (M3 default) for 4 push toggles per tracked uni.
  - **Shows raw `institution_id` UUID instead of name** (line 83).
  - "Push payload language: en" displays bare code without a friendly name.
  - **i18n:** zero.

#### `application_tracker_screen.dart`, `institution_compare_screen.dart`, `admin_review_screen.dart`

  - Exist for the new uni_db model. Not reachable from bottom-nav or training; only via deep links.

#### `widgets/coming_soon_card.dart`, `widgets/home_recent_changes_banner.dart`, `widgets/university_specific_cta.dart`, `widgets/verified_deadline_card.dart`, `widgets/verified_deadlines_overlay.dart`

  - Slot into home/training when uni_db data is present. Each uses `Card` + M3 textTheme — different design dialect.

---

### 1.11 Push / in-app notifications

  - `push_token_bootstrap.dart` wired in `main.dart:85` but no-op until a `PushTokenSource` is configured.
  - **No in-app notifications UI** — no inbox, no badge on bottom-nav, no banner. `home_recent_changes_banner.dart` approximates an inbox strip on Applications, flag-gated to uni_db.
  - `notification_settings_screen` wires 4 push channels but has no test/preview action.

---

### 1.12 Cross-screen concerns

  - **Typography:** no shared scale. 51 separate `TextStyle(fontSize:)` literals across 15 files. Tweaking the type scale = 51 edits.
  - **Spacing:** routinely on 4/8/12/16/24/32 (good) but no constants; inter-screen padding varies (16 px Applications, 32 px Welcome, 24 px Login).
  - **Color:** `AppColors` defines 12 colors but is bypassed in dozens of widgets (`Color(0xFF132A4D)` in 8 widgets, `0xFF0F213D` in 5, `0xFF0F1626` in 4, `0xFF071221` in 2, `0xFF6C63FF` in splash). Off-palette literals proliferate.
  - **Dark mode:** dark-only by design.
  - **RTL:** every `Padding.fromLTRB` is direction-fixed. Switching to an RTL locale would require rework. Non-blocking today.
  - **Keyboard avoidance:** most screens use `SafeArea` + `SingleChildScrollView`. Bottom sheets correctly wrap inputs in `SafeArea`.
  - **Safe area:** top edge respected; bottom-nav embeds bottom padding (legacy `BottomNavigationBar` default).
  - **Gesture conflicts:** WebView uses `EagerGestureRecognizer` ✅; modal sheets use `DraggableScrollableSheet` + handles ✅; no nested-scroll conflicts noted.
  - **Performance:**
    - 4 × `Image.network` without caching.
    - All 4 home-tabs held in memory simultaneously (`IndexedStack` would be the M3 pattern).
    - Glassmorphism stack (gradient + glass card + glass chip) is GPU-expensive on lower-end Android (Samsung A-series, Xiaomi Redmi — the Uzbek market).
    - `withOpacity` precision-lossy in wide-gamut color spaces.


---

## Section 2 — modern mobile UI/UX best practices (research)

This section captures the principles the audit measured against, with sources. Findings in Section 1 reference these where relevant; the backlog in Section 3 names the specific principle violated.

### 2.1 Material Design 3 (Material You)

The app declares `useMaterial3: true` but adopts the M3 visual language only partially. M3 introduced **dynamic colour** (seed-based tonal palettes), a redesigned **NavigationBar**, a revised **type scale**, and motion-easing tokens. Material's own guidance is to start from `ColorScheme.fromSeed(seedColor: ...)` so that all M3 surfaces (`surfaceContainerHighest`, `secondaryContainer`, `tertiaryContainer`, etc.) get tonal-mapped. Hanguk's manual `ColorScheme.dark(primary:..., secondary:..., surface:...)` skips this; M3 tonal surfaces fall back to framework defaults rather than the Hanguk palette.

For bottom navigation, the Flutter team says explicitly: "NavigationBar is the preferred component for new applications configured for Material 3." The M3 component renders a 64-dp-tall bar with pill-shaped active-state indicators using the M3 tonal secondary container. The legacy `BottomNavigationBar` is supported but is not M3-aligned. ([Flutter NavigationBar API](https://api.flutter.dev/flutter/material/NavigationBar-class.html), [M3 NavigationBar guidance](https://www.educative.io/answers/how-to-create-a-material-3-bottom-navigation-bar-in-flutter))

Touch target: the M3 / Android guideline is **48 × 48 dp**. The 24-dp icon you commonly see is the visual centre, with 12 dp padding bringing total tappable area to 48 dp. Google's research validates 48 dp as the threshold where tap accuracy stays above 95 % in the general population, with 56 dp the point where it climbs to 98-99 %. ([M3 accessibility — touch targets](https://m3.material.io/foundations/designing/structure), [Android Accessibility — touch target size](https://support.google.com/accessibility/android/answer/7101858?hl=en))

Hanguk's `_ToggleButton` in `map_tab.dart:333` is 40 dp. The `Switch` in `interview_setup_view.dart:225` is fine on its own, but the surrounding `Row` does not absorb the tap — M3's `SwitchListTile` is the convention for tappable rows.

The M3 type scale (`displayLarge` → `bodySmall`) follows a strict ratio. Bypassing it by hand-rolling `TextStyle(fontSize:...)` literals (51 across 15 files) means the app cannot honor `MediaQuery.textScaler` consistently — some labels scale, others don't. ([M3 type scale](https://m3.material.io/styles/typography/type-scale-tokens))

### 2.2 Apple Human Interface Guidelines (iOS 17+)

Apple's iOS minimum tap target is **44 × 44 points**. Smaller targets produce a documented 25 %+ tap-error rate among users with motor impairments. iOS apps must also support **Dynamic Type** — system text-size preferences that scale all text up to AX5. Apps that ship hardcoded `fontSize` values do not scale; the Apple Review Guidelines treat egregious violations as discretionary rejection grounds. ([Apple HIG — Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons), [Apple HIG — Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility))

Hanguk targets iOS (the store audit closed an iOS submission path), but:

  - No `MediaQuery.textScalerOf(context)` invocations (`grep textScaler lib/` → 0)
  - No `Platform.isIOS` Cupertino styling on screens beyond the unused adaptive widgets
  - The hand-rolled splash uses Material `CircularProgressIndicator` on iOS — iOS expects `CupertinoActivityIndicator`

The `AdaptiveBottomNavigation` (Cupertino on iOS, Material on Android) is the right pattern but its non-adoption means iOS users get a Material widget — a small but noticeable platform-foreign look.

### 2.3 Accessibility — WCAG 2.2 AA + dynamic type + screen readers

WCAG 2.2 AA tightened several criteria in 2023. Relevant additions:

  - **2.5.8 Target Size (Minimum) — AA**: every target ≥ **24 × 24 CSS px** unless inline text or surrounded by sufficient spacing. Native conventions (48 dp / 44 pt) still rule on mobile.
  - **2.4.11 Focus Not Obscured (Minimum) — AA**: focused element must not be entirely obscured by other content.
  - **1.4.11 Non-text Contrast — AA**: UI components must have ≥ **3:1** contrast against adjacent colours.
  - **1.4.3 Contrast (Minimum) — AA**: text ≥ **4.5:1** (3:1 for large text ≥ 24 px regular or ≥ 19 px bold).

([WCAG 2.2 — W3C Recommendation](https://www.w3.org/TR/WCAG22/), [WCAG 2.2 new success criteria — TestParty](https://testparty.ai/blog/wcag-22-new-success-criteria), [WebAIM — Contrast and Color Accessibility](https://webaim.org/articles/contrast/))

Hanguk's `Colors.white38` body text is approximately **4.0:1** — fails AA for normal text. The `vibrantLime.withOpacity(0.1)` background + `vibrantLime` text combo on chips and info banners is **~2.5:1** — fails 1.4.11. The `Color(0x1AFFFFFF)` borderGlass at 0.5 px is **~1.3:1** non-text contrast — fails 1.4.11.

For Flutter specifically: `MediaQuery.textScalerOf(context)` (replacement for deprecated `textScaleFactor`) must be honored in custom widgets. Flutter 3.27+ introduced 80 % faster Semantics-tree compilation, so adding `Semantics(...)` widgets is cheap. The `accessibility_tools` package surfaces missing labels and undersized targets at dev time. ([Flutter — Accessibility docs](https://docs.flutter.dev/ui/accessibility), [Flutter — restrict text scale factor](https://www.launchclub.io/blog/flutter-restrict-text-scale-factor), [Flutter — Android 14 nonlinear font scaling migration](https://docs.flutter.dev/release/breaking-changes/android-14-nonlinear-text-scaling-migration))

### 2.4 Korean UX conventions

KakaoTalk owns ~90 % of Korean messaging and sets expectations for chat UIs in Korea. Its conventions:

  - **Bottom tab bar** with 4-5 destinations.
  - **Vertical info-dense feeds** — each row: 40 px avatar + name + small grey status.
  - **Avatar-first chat rows** — circular avatar left, name above message preview, timestamp right.
  - **Speech bubbles** — own messages right-aligned with yellow background; other-party left-aligned white; avatars next to bubble.
  - **Typing indicators** — animated ellipsis.
  - **Distinctive Hangul typeface** — KakaoTalk designed its own typeface that echoes Hangul's geometric structure. Apps targeting Korean speakers typically bundle **Pretendard** or **Noto Sans KR** explicitly because the system Hangul font differs across Android (Noto Sans CJK KR) and iOS (Apple SD Gothic Neo) in weight and tracking.

([KakaoTalk redesign UX study — Medium Bootcamp](https://medium.com/design-bootcamp/kakaotalk-redesign-user-experience-user-exit-9a5dd575e20d), [Korean app UI review — Messenger part 1](https://medium.com/app-ui-review/korean-app-ui-review-messenger-part-1-b30b7db9d0a), [KakaoTalk — Wikipedia](https://en.wikipedia.org/wiki/KakaoTalk))

Hanguk's university-room discussion tab follows the Kakao pattern reasonably — avatar on left, name + timestamp above bubble, flattened top-left corner. But: no typing indicator (no real-time `is_typing`), Korean-speaker rendering uses Roboto for Latin and system fallback for Hangul (mixed-script rendering looks jarring), messages are left-aligned regardless of sender (loses the "this is me" signal in group rooms).

For info-dense feeds (Applications, Map list, Documents) Hanguk follows the Korean vertical-stack pattern competently — logo + name + location + chips + chevron in a 12-px-padded row, ~76 dp row heights, in line with KakaoTalk's friends list.

### 2.5 Mobile gesture patterns

Standard gestures users expect:

  - **Swipe-to-dismiss** on bottom sheets and modals.
  - **Pull-to-refresh** on list-of-data screens.
  - **Long-press** for context menus.
  - **Swipe-on-row** for row-level actions (Mail-style archive/delete).

Hanguk implements:

  - Bottom-sheet drag handles + swipe-to-dismiss on detail sheet, room modal, chat sheet — ✅
  - **No pull-to-refresh anywhere.**
  - **No long-press** beyond the bare TextField default.
  - **No swipe-to-archive** on documents or applications.

### 2.6 Empty / error / loading states

Nielsen Norman Group's research (2017-2024) and Mobbin's glossary converge on:

  - **Spinners** for short blocking actions (auth, save, submit). Best ≤ 10 s.
  - **Skeleton screens** for data fetches with predictable layout (feeds, lists, dashboards). Perceived faster than spinners; reduce reported wait time.
  - **Progress bars** for downloads or operations with known total.

Hanguk uses spinners almost everywhere. No skeleton screens. For Map and Applications surfaces especially, a skeleton row would look better than a centred spinner.

For empty states, Mobbin and Toptal recommend "icon + headline + supporting copy + CTA". Hanguk has the `EmptyState` widget that implements this exactly but uses it in only a handful of places. Most empty surfaces are bare text — Applications, Study Plan history, university-room News tab, etc.

([Skeleton Screens 101 — NN/G](https://www.nngroup.com/articles/skeleton-screens/), [Skeleton Screens vs Progress Bars vs Spinners — NN/G video](https://www.nngroup.com/videos/skeleton-screens-vs-progress-bars-vs-spinners/), [Empty State UI Design — Mobbin](https://mobbin.com/glossary/empty-state), [Empty States — Toptal](https://www.toptal.com/designers/ux/empty-state-ux-design))

### 2.7 Onboarding for magic-code-login apps

Best practice from Twilio's iOS/Android OTP guides:

  - **Single input field** is simpler than per-digit fields.
  - **`textInputAction: TextInputAction.done`** with auto-submit after the last character.
  - **`autofillHints: [AutofillHints.oneTimeCode]`** on iOS surfaces a quick-fill chip when an SMS arrives.
  - **SMS Retriever API** on Android reads OTP automatically with the app hash; `sms_autofill` Flutter package wraps it.
  - **SMS format**: `Your code is 123456. @yourdomain.com #123456` — the `@domain #code` suffix is the WebOTP-recognised format.

([Twilio — OTP forms on iOS](https://www.twilio.com/en-us/blog/developers/best-practices/best-practices-for-otp-input-forms-in-ios), [Twilio — OTP forms on Android](https://www.twilio.com/en-us/blog/developers/best-practices/best-practices-for-otp-input-forms-in-android), [Auth0 — Mobile OS autofill for OTP codes](https://community.auth0.com/t/enable-mobile-os-autofill-for-otp-codes-in-auth0-universal-login/187671))

Hanguk's magic-code input is single TextField (good), but no `autofillHints`, no `textInputAction`, no `onSubmitted` auto-submit. The code is shared out-of-band by a counsellor (not via SMS), so the WebOTP autofill bridge isn't applicable — but the iOS `autofillHints` would still surface the right keyboard.

For first-run UX: WelcomeScreen is a brand banner + 2 buttons. Modern onboarding (Duolingo, Headspace, Notion) uses 3-5 swipeable cards before the auth gate. For a counsellor-distributed-code app that might be overkill — but a single line of "Apply to Korean universities with AI guidance" under the brand would orient new users.

### 2.8 Form design (multi-step, validation, mobile keyboards, autofill)

Best practices for mobile forms:

  - **`keyboardType:`** on every TextField (`.emailAddress`, `.phone`, `.number`, `.url`).
  - **`autofillHints:`** for password manager + OS autofill.
  - **`textInputAction:`** to set the keyboard's return-key label (Next, Done, Send) and chain focus.
  - **Inline validation** rather than blocking modals.
  - **Progress indicators** on multi-step forms — steppers, breadcrumbs.
  - **Persistent data** across steps — losing input on back-navigation is the biggest user-rage moment.

Hanguk's `study_plan_screen` is a 4-step wizard with a visual stepper (good) but doesn't persist `_draftController` text across step changes. The interview setup dialog (`StatefulBuilder`-local state) loses everything on dismiss-and-reopen.

Across all TextFields: 0 `autofillHints`, 0 manual `keyboardType` settings, 1 `textInputAction`.

### 2.9 Performance / perceived performance

Flutter's frame budget is 16 ms (60 fps; 8 ms on ProMotion 120 Hz). Flutter docs emphasize:

  - `ListView.builder` for large lists ✅.
  - `const` constructors to reduce rebuilds.
  - `RepaintBoundary` around expensive sub-trees (gradients, blurs).
  - `cached_network_image` for any `Image.network` source — Image.network does not cache to disk by default.
  - Avoid `setState` storms inside animation tick listeners — use `AnimatedBuilder`.

Hanguk's specific risks:

  - All 4 home-tabs in memory simultaneously (`home_screen.dart:22`).
  - 4 × `Image.network` re-fetch on rebuild.
  - Glassmorphism stack (gradient + glass card + glass chip) is GPU-expensive on Samsung A-series / Xiaomi Redmi (the Uzbek market).
  - `withOpacity` is precision-lossy in wide-gamut colour spaces (HDR displays), `withValues(alpha:)` is also slightly faster in profile builds. ([Flutter — wide-gamut color migration](https://docs.flutter.dev/release/breaking-changes/wide-gamut-framework))

### 2.10 Unique surfaces

#### 2.10.1 Kakao Roadview / Pannellum 360 walkaround

Pannellum is a lightweight WebGL 360 panorama viewer with hotspot support. Documented accessibility limitations:

  - **Hotspot keyboard navigation is unsupported** (GitHub issue #628, open since 2018).
  - The canvas is opaque to screen readers — Pannellum renders to `<canvas>` with no ARIA layer.

Recommended pattern for an embed:

  - Provide a non-canvas escape hatch (scene list / floor-plan overlay) for assistive tech.
  - Throttle inertia to respect `prefers-reduced-motion`.
  - Provide a back-button-shaped exit before any gestures obscure the OS gesture bar on iOS.

([Pannellum documentation](https://pannellum.org/documentation/overview/), [Pannellum issue #628 — keyboard nav](https://github.com/mpetroff/pannellum/issues/628))

Hanguk wraps Pannellum in `virtual_tour_screen.dart` with a JS bridge for state. Dart-side overlay is good for the failure case but the hotspot UX inside Pannellum is whatever the out-of-the-box behavior is — no escape hatch to a scene list, no reduced-motion handling, no skip-link. Kakao Roadview, similarly, is a WebView with limited gesture surface area inside Flutter. The map audit closed the state-overlay UX; remaining ask is screen-reader friendliness (announce "Loading street view at Yonsei University..." via `Semantics(liveRegion: true)`).

#### 2.10.2 AI voice interview practice (Vapi)

Voice-AI UX best practices per Vapi's docs, the Voice UI Design Guide, and the LiveKit comparison:

  - **Persistent visual indicator** of listening/thinking/speaking — usually three states (waveform / pulse / outline).
  - **Live transcript** so the user can verify the agent heard them correctly.
  - **End-call button** always visible (covered by prior training audit F3).
  - **Latency feedback** — if the agent is thinking >2 s, show "Thinking..." to mask round-trip.
  - **Permission state surfacing** — if mic is muted by OS, show a path to settings.
  - **Reduced-motion alternative** — static dot instead of pulsing waveform.

([Vapi — Build Advanced Voice AI Agents](https://vapi.ai/), [Voice UI Design Guide 2026](https://fuselabcreative.com/voice-user-interface-design-guide-2026/), [LiveKit vs Vapi — Modal blog](https://modal.com/blog/livekit-vs-vapi-article))

Hanguk's `interview_active_view.dart` has lifecycle + open-settings deep link ✅. The live indicator is a text string ("Your turn to speak", "Interviewer is speaking...") rather than a visual. A pulsing 80-dp circle with a 1-2 px border at the audio RMS amplitude would give clear feedback. Vapi exposes amplitude on its event stream.

#### 2.10.3 ChatGPT-style drafting workspace

The OpenAI / Cursor / Zed school of inline AI ghost text relies on three affordances:

  - **Ghost text inline at the cursor**, visually distinct (italic + 50% opacity).
  - **`Tab` to accept**, **`Esc` to dismiss**, arrows to move past.
  - **On mobile, a "Suggest" chip just above the keyboard** OR a swipe-right gesture — there is no Tab key on a phone.

([AI Chat Sentence Autocomplete — Cursor Community Forum](https://forum.cursor.com/t/ai-chat-sentence-autocomplete-like-zeds-ghost-text/49944))

Hanguk's `advanced_drafting_workspace.dart` does ghost text inline + Tab-to-accept (via `KeyboardListener`), but on a phone there is no Tab key and no on-screen accept button. The mobile interaction is **broken** — the AI generates suggestions the user can see but cannot accept without retyping them.

The fix is an above-keyboard suggestion strip (the same pattern as Gboard / SwiftKey predictions): a thin row above the system keyboard showing the next 3-5 ghost-text words as tappable chips. Flutter's `KeyboardActions` package or a hand-rolled `MediaQuery.viewInsets.bottom`-anchored row works.


---

## Section 3 — prioritized backlog

Same letter-prefix-by-category convention as prior audits. Categories: **A** accessibility, **C** consistency/design system, **F** functional bug (UI), **I** i18n, **K** keyboard/input/forms, **N** navigation, **P** performance, **S** state/empty/loading, **T** typography/color, **U** UX polish.

Effort: "1 h" = single focused implementation + verify. "1 dev-day" = 6-8 productive hours.

### P0 — must address before next user-facing release

| # | finding | file:line | what good looks like | effort |
|---|---|---|---|---|
| N1 | **`AccountScreen` is unreachable.** Defined at `account_screen.dart` but no `/account` route, no widget references the class. Account deletion (required by Apple 5.1.1(v) + Play User Data 2024) is unusable. | `app_router.dart`, `account_screen.dart` | Add `/account` GoRoute. Add a profile icon (`Icons.person_outline`) on `applications_tab.dart:26` that navigates to it. Move the bare sign-out icon's destination to `/account`. | 1 h |
| N2 | **Sign-out icon on Applications fires `signOut()` with no confirmation.** Misplaced tap drops the user to /welcome. | `applications_tab.dart:26-34` | Either remove this icon and route through `/account`, or wrap in a confirmation `AlertDialog`. | 30 m |
| I1 | **i18n adoption is ~5%.** Every screen ships hardcoded English. Korean/Uzbek users see English everywhere outside walkaround state + a few training labels. | every screen | Migrate every user-facing string to `AppLocalizations`. Start with bottom-nav labels, AppBar titles, primary CTAs, empty-state copy. Top-up ko/uz/ru/vi ARBs with real translations. | 3 dev-days (engineering) + content (translation) |
| A1 | **Near-zero `Semantics` coverage.** 3 calls across the whole app. Bottom nav, FAB, every IconButton without tooltip, every interactive card has no screen-reader label. WCAG 2.2 fails. | cross-cutting | Add `Semantics(label:..., button:true, ...)` to every tap target without a textual child. Add `tooltip:` to every `IconButton`. Wrap the bottom-nav in M3 `NavigationBar` (announces selected state by default). Add `Semantics(header:true)` on section titles. | 2 dev-days |
| A2 | **Dynamic Type is not respected anywhere.** `MediaQuery.textScalerOf(context)` never read; every `TextStyle(fontSize:N)` is fixed. iOS Larger Text setting has no effect; Android 14 nonlinear font scaling has no effect. | cross-cutting | Define a real `textTheme` in `AppTheme.materialTheme` (or build `AppText` static helpers). Migrate the 51 hand-rolled styles. Test at 200 % text scale. | 2 dev-days |
| F1 | **"Coming Soon" buttons on Welcome and Login are tappable dead-ends.** `welcome_screen.dart:175` "Phone Number (Coming Soon)" outline button has `onPressed: () {}`. Default Login tab is a "Coming Soon" stub. | `welcome_screen.dart:175-200`, `login_screen.dart:356-409` | Remove the Coming Soon buttons OR set `onPressed: null` (greyed-out). On Login, default to magic-code mode and remove the stub tab until phone auth is real. | 1 h |
| F2 | **Three concurrent `checkForUpdates` on cold start.** Splash → Welcome's `initState` → HomeScreen's `initState` → `UpdateGate` builder all kick off the check. Dialog can pop while the user is still in /welcome. | `welcome_screen.dart:19-22`, `home_screen.dart:30-35`, `main.dart:95` | `UpdateGate` is the single source of truth. Delete the `_checkForUpdates` paths in Welcome + Home. | 30 m |
| S1 | **Documents tab "error" prints `\$err` literally.** `Text('Error: \$err')` at line 175 — backslash escapes the dollar so users see `$err`. | `documents_tab.dart:175` | Change to `Text('Error: $err')` (no backslash) or, better, `Text('Could not load documents.')` with a retry button. | 5 m |

**P0 total: 8.**

### P1 — important quality gaps

| # | finding | file:line | what good looks like | effort |
|---|---|---|---|---|
| C1 | **Bottom nav uses legacy `BottomNavigationBar` (M2).** Unused `AdaptiveBottomNavigation` widget in design system is already correct. | `home_screen.dart:83` | Replace with `AdaptiveBottomNavigation` + `kIsWeb` guard on `Platform.isIOS`. Rename first label "Home" → "Applications" (the tab is Applications). | 1 h |
| C2 | **`withOpacity` in 141 sites across 27 files; deprecated.** Half-migrated. | cross-cutting | Sweep with a hand find-replace to `withValues(alpha:)`. | 2 h |
| C3 | **Off-palette colour literals (8+) repeated across widgets.** `Color(0xFF132A4D)`, `0xFF0F213D`, `0xFF0F1626`, `0xFF071221`, `0xFF6C63FF` each appear in multiple files but none are in `AppColors`. | `home_screen.dart:61`, `welcome_screen.dart`, `university_room_modal.dart:141`, `chat_tab.dart:114`, `university_detail_sheet.dart:31`, `main.dart:50,65` | Promote to `AppColors.surfaceNavy400`, etc. | 2 h |
| C4 | **Splash + welcome use a purple spinner; rest of the app uses lime.** | `main.dart:65` | Change to `AppColors.vibrantLime`. | 1 m |
| C5 | **`HangukCard` and training-tab cards visually differ** despite identical role. | `training_tab.dart:101-178` vs `hanguk_card.dart` | Add optional `glow` / `outerShadow` config to `HangukCard`; consolidate. | 2 h |
| C6 | **`borderGlass` colour ~10% white at 0.5 px — essentially invisible.** | `app_colors.dart:26`, `hanguk_card.dart:31` | Bump to `Color(0x33FFFFFF)` at 0.5 px, or 1 px at 10%; or drop the border and use elevation. | 30 m |
| C7 | **Uni_db screens use vanilla M3 (`Card`, `Theme.textTheme`); rest of app uses bespoke glass.** Two dialects in one app. | `institution_detail_screen.dart` and siblings | Adopt the glass dialect on uni_db (apply `HangukScaffold` + `HangukCard`). | 1 dev-day |
| T1 | **No shared text style.** 51 hardcoded literals. | cross-cutting | Define a real `textTheme` in `AppTheme.materialTheme` and migrate. | 1 dev-day |
| T2 | **No Korean / multi-script font bundled.** Hangul + Latin renders in two fonts mid-string. | `app_theme.dart`, `pubspec.yaml`, `assets/` | Bundle Pretendard or Noto Sans KR via `assets/fonts/`; declare in pubspec; set `fontFamily:` on `ThemeData`. | 4 h |
| T3 | **Multiple WCAG 2.2 AA contrast failures.** `Colors.white38` body ≈ 4.0:1 (fails 4.5:1). Lime-on-lime-tint chips ≈ 2.5:1 (fails 3:1 non-text). Glass border ≈ 1.3:1 (fails 3:1 non-text). | cross-cutting | Bump body secondary to `Colors.white70` minimum; use `pureBlack`-on-lime for chips; strengthen borders. Validate with WebAIM tool. | 1 dev-day |
| K1 | **No `autofillHints`, `keyboardType`, or `textInputAction` on any TextField except `chat_tab`.** | login screen (5 fields), university_room_modal:266, interview_setup_view:189, all others | Add per-field `autofillHints` (`oneTimeCode`, `telephoneNumber`, `password`, `name`), `keyboardType`, and `textInputAction: next/done` chaining via `FocusNode`s. | 1 dev-day |
| K2 | **Magic-code helper says "8-character" but formatter allows 10.** | `login_screen.dart:313, 326` | Pick one canonical length. | 5 m |
| K3 | **No `onSubmitted` on magic-code field.** | `login_screen.dart:319-334` | Wire `onSubmitted: (_) => _handleStudentLogin()` and `textInputAction: TextInputAction.done`. | 5 m |
| K4 | **`_showInterviewSetupDialog` loses state on dismiss-and-reopen.** | `training_tab.dart:180-462` | Lift the three pieces of state into `interviewProvider` so the dialog rehydrates. | 2 h |
| K5 | **`AdvancedDraftingWorkspace` ghost-text accept is Tab-only — no mobile path.** Users cannot accept suggestions on phone. | `advanced_drafting_workspace.dart:31-44`, `ai_highlighting_text_controller.dart` | Add an above-keyboard suggestion strip pinned via `MediaQuery.viewInsets.bottom`. Tappable ghost-text chips. | 1 dev-day |
| S2 | **Empty states are bare text in 6+ places.** `EmptyState` widget exists but unused. | `applications_tab.dart:48`, `study_plan_screen.dart:154`, `chat_tab.dart` (no empty), `university_room_modal.dart:319` (News), `interview_history_view.dart`, `documents_tab.dart` (no empty path) | Use `EmptyState(icon, headline, subhead, ctaLabel, onCta)` with real CTAs ("Add your first university", "Start a draft"). | 4 h |
| S3 | **Loading uses spinners; skeleton screens would feel faster.** | Map list, Applications, Documents, Study Plan history | Build 2 skeleton widgets (`SkeletonRow`, `SkeletonCard`) — animated shimmer over the glass-card outline. Use in `.when(loading:)` arms. | 1 dev-day |
| S4 | **Error states show raw exception strings.** | `applications_tab.dart:84`, `documents_tab.dart:175`, `interview_setup_view.dart:298-300`, `university_room_modal.dart:244` | Build a shared `ErrorState` widget (modelled on `map_tab._buildErrorState`). Human copy + retry. | 2 h |
| P1a | **`Image.network` without caching** — every network logo refetches on rebuild. | `application_card.dart:58`, `university_card.dart:67`, `university_detail_sheet.dart:315`, `university_selection_view.dart:152` | Add `cached_network_image` to pubspec; replace 4 sites with `CachedNetworkImage`. | 2 h |
| P1b | **All 4 home-tabs in memory simultaneously.** | `home_screen.dart:21-27` | Wrap body in `IndexedStack` (state preserved AND lazy-builds via `LazyIndexedStack` extension). | 4 h |
| U1 | **No pull-to-refresh anywhere.** | `applications_tab.dart`, `map_tab.dart`, `documents_tab.dart`, `study_plan_screen.dart` | Wrap each list in `RefreshIndicator(onRefresh: () async { ref.invalidate(...) }, child: ...)`. | 1 h × 4 |
| U2 | **`showModalBottomSheet` sheets don't pass `showDragHandle: true`.** Manual handles drawn instead. | `home_screen.dart:54`, applications via UniversityRoomModal, `map_tab._showDetail`, `university_selection_view.dart:48` | Pass `showDragHandle: true` (M3 default) and remove manual handle Containers. | 1 h |
| U3 | **AI-chat FAB icon is `Icons.smart_toy` — unconventional for AI.** | `home_screen.dart:81` | Swap to `Icons.auto_awesome` (sparkle). Add `tooltip: 'Ask Hanguk AI'`. | 5 m |
| U4 | **No voice-AI visual indicator in Interview Active.** Text states only. | `interview_active_view.dart:200-400` | 80-dp circular avatar with `TweenAnimationBuilder` pulse driven by Vapi amplitude event stream. 3 states: idle outlined / listening lime-pulse / speaking royal-blue-pulse. | 1 dev-day |
| U5 | **No typing indicator in university-room chat.** | `university_room_modal.dart:240-310`, `data/university_chat_repository.dart` | Subscribe to Supabase Realtime channel for typing presence; render 3-dot indicator. | 1 dev-day |
| U6 | **Welcome's "Magic Code" button has no explanation.** First-run users have no idea what a code is. | `welcome_screen.dart:158-170` | Add one-line subtitle: "Counsellors give you an 8-character code." | 30 m |
| U7 | **Login dead code: `TabController`, `_LoadingView`, phone-login flow.** ~250 LOC unused. | `login_screen.dart:25, 435, 86-191` | Delete the unreachable widgets and controllers. Keep magic code only. | 1 h |
| U8 | **`Switch` for Timed Mode doesn't absorb the row tap.** | `interview_setup_view.dart:205-232` | Convert to `SwitchListTile` with secondary icon, title, subtitle. | 15 m |
| U9 | **Calendar uses 12-hour `hh:mm a` formatting.** Korea/Uzbekistan use 24-hour. | `university_room_modal.dart:430` | `DateFormat.Hm(locale).format(...)`. | 15 m |
| U10 | **Process tracker doesn't tell the user what's next.** | `process_tracker.dart` | Add "Next step" card above timeline highlighting the next non-active step + CTA if applicable. | 1 dev-day |
| U11 | **Hit targets below platform minimum on multiple controls.** Map list/map toggle (40 dp), Document slot "Upload" button (36 dp), Welcome's logo header tap area. | `map_tab.dart:333`, `document_slot.dart:136`, `welcome_screen.dart:60-87` | Bump each to 48 × 48 dp minimum via `SizedBox`, `IconButton`'s default 48 dp, or `Material InkWell minimumSize`. | 2 h |

**P1 total: 28.**

### P2 — polish, future-facing, nice-to-have

| # | finding | file:line | what good looks like | effort |
|---|---|---|---|---|
| C8 | Splash background `Color(0xFF0A0A1A)` ≠ `AppColors.backgroundNavy`. | `main.dart:50` | Use the constant. | 1 m |
| C9 | `adaptive_button.dart`, `adaptive_text_field.dart`, `adaptive_scaffold.dart` defined but unused. | `lib/design_system/adaptive/*.dart` | Adopt or delete. | 1 h |
| C10 | `app_theme.dart` builds the colour scheme manually instead of `ColorScheme.fromSeed`. M3 tonal surfaces fall back to defaults. | `app_theme.dart:7-21` | Use `fromSeed(seedColor: vibrantLime, brightness: dark)` and override the small fields. | 1 h |
| C11 | `Color(0xFF071221)` background on chat-tab modal matches no other surface. | `home_screen.dart:61`, `university_selection_view.dart:55` | Promote to `AppColors.surfaceModal`. | 15 m |
| C12 | `AppTheme.cupertinoTheme` defined but never wired. | `app_theme.dart:100-107`, `main.dart` | Wire via Builder pattern or delete. | 15 m |
| T4 | `fontFamily: 'monospace'` on magic-code renders inconsistently (Courier on iOS, Roboto Mono on Android). | `login_screen.dart:328-333` | Bundle JetBrains Mono or use a non-mono font with letterSpacing only. | 30 m |
| T5 | Logo is JPEG; that's why `welcome_screen` wraps it in a white square. | `assets/images/logo.jpg`, `welcome_screen.dart:64-87, 96-123` | Replace with PNG (transparent) or SVG via `flutter_svg`. Remove the white wrappers. | 1 h |
| T6 | `vibrantLime.withOpacity(0.1)` chip + `vibrantLime` text fails non-text contrast. | many sites | Darken the lime text OR lighten the chip background OR invert (lime bg + black text). | 4 h |
| A3 | `DraggableScrollableSheet` modals don't expose semantics for the boundary. | `university_detail_sheet.dart`, `university_room_modal.dart`, chat sheet | Wrap sheet body in `Semantics(scopesRoute: true, namesRoute: true, label: '...')`. | 1 h |
| A4 | Bottom-nav has no Semantics on active tab. | `home_screen.dart:83` | Covered by C1 (M3 NavigationBar has built-in semantics). | covered by C1 |
| A5 | No `prefers-reduced-motion` handling. | cross-cutting | Read `MediaQuery.disableAnimations(context)` and conditionally `Duration.zero`. | 1 h |
| A6 | PopupMenuButton on `study_plan_screen.dart:75` reads as just "Button". | `study_plan_screen.dart:75` | Pass `tooltip: 'Session settings'`. | 5 m |
| A7 | Pannellum hotspots inaccessible to screen readers. Roadview likewise. | `virtual_tour_screen.dart`, `university_roadview_screen.dart` | Add an exit / list-scenes overlay reachable from top-right `Icons.list` — accessible parallel navigation. | 1 dev-day |
| I2 | `DateFormat` strings hardcoded English locale. | `university_room_modal.dart:430`, `university_detail_sheet.dart:367` | Pass `Localizations.localeOf(context)` to DateFormat. | 30 m |
| I3 | Pluralization ad-hoc in English. | `university_selection_view.dart:234` | Use ARB plural syntax. | 1 h |
| I4 | `// TODO: localize` on `account_screen.dart:172` tooltip 'Back'. | `account_screen.dart:172` | Replace with `l.commonBack`. | covered by I1 |
| K6 | No focus-traversal order on login. Bluetooth-keyboard Tab skips around. | `login_screen.dart` | `FocusTraversalGroup` + `OrderedTraversalPolicy`. | 1 h |
| K7 | Modal forms (interview setup, study-plan create) don't auto-focus first field. | `training_tab.dart:_showInterviewSetupDialog`, `study_plan_screen._showCreateSessionDialog` | `FocusNode + WidgetsBinding.instance.addPostFrameCallback((_) => node.requestFocus())`. | 30 m |
| N3 | `_RouteMissingShell` "Back to home" always `context.go('/')`. | `app_router.dart:142` | `Navigator.maybePop` first, fall back to `/`. | 15 m |
| N4 | `LoginRoute` reads `state.extra as Map<String, dynamic>?` — won't survive a cold deep link. | `app_router.dart:248` | Use `?magic_code=true` query param. | 30 m |
| S5 | `study_plan_screen` empty state is bare text. | `study_plan_screen.dart:154` | Use `EmptyState` with icon + "Start your first draft" CTA. | 30 m |
| S6 | Chat tab opens with no message history and no welcome message. | `chat_tab.dart` | Seed with an assistant "What would you like help with?" bubble when `messages.isEmpty`. | 30 m |
| S7 | University-room "News" tab permanently empty (no data source). | `university_room_modal.dart:314-324` | Delete the tab until news exists, OR hook it up to an announcements feed with `EmptyState`. | 2 h to remove; 4 h to wire |
| P2a | `HangukScaffold` gradient repaints on every rebuild. | `hanguk_scaffold.dart:23-31` | Wrap in `RepaintBoundary`. | 5 m |
| P2b | Application card's `AnimatedSize` rebuilds the entire card tree on expand. | `application_card.dart:115-176` | Use `AnimatedCrossFade` or move expanded content into a separate `StatefulWidget`. | 1 h |
| P2c | `notification_settings_screen.dart` shows institution UUID instead of name. | `notification_settings_screen.dart:83` | Join `institutions` to resolve `name_uz`/`name_ko`/`name_en` based on locale. | 1 h |
| U12 | Welcome's `Spacer(flex: 2)` can clip the magic-code button on iPhone SE 1st gen (320×568). | `welcome_screen.dart:205` | Reduce to `Spacer(flex: 1)` or wrap hero in `SingleChildScrollView`. | 30 m |
| U13 | "AI cooling down…" copy is alarming. | `advanced_drafting_workspace.dart:164` | "AI rate-limited — pause typing for {N} s". | 5 m |
| U14 | No countdown overlay during Timed Mode. The 5-minute cap fires silently. | `interview_active_view.dart:124-134` | Top-right countdown chip ("4:32 remaining") + 30-second warning haptic. | 4 h |
| U15 | Update dialog doesn't explain what an APK is to non-technical users. | `update_dialog.dart:265` | One-line explainer "Hanguk updates run outside Google Play." Or wait for Play in-app-update wiring. | 30 m once Play path lands |
| U16 | The bottom-nav FAB partially obscures floating actions on each tab. Training pads 100 px; Map and Documents don't. | `training_tab.dart:80`, `map_tab.dart`, `documents_tab.dart` | Add bottom: 100 px padding on every tab body, OR move FAB to a fixed slot above the bottom-nav. | 30 m |
| U17 | No in-app notifications inbox. | n/a | Build a `/inbox` screen with a `notifications` table. Post-push-wiring. | 2 dev-days |
| U18 | No haptic feedback on critical actions (start interview, end interview, delete account, submit applications). | cross-cutting | `HapticFeedback.heavyImpact()` on destructive confirms; `HapticFeedback.lightImpact()` on tab changes. | 1 h |

**P2 total: 33.**

---

## What this audit did not cover

  - **Pixel-level device review.** This audit is code-level; visual review on iPhone SE, iPhone Pro Max, Pixel 8, Samsung Z Flip, iPad, foldable, web at 1024 wide, etc., is a separate device-test pass.
  - **Real measured contrast ratios.** Estimates above are computed from the AppColors palette + glass overlays in my head. A tool like Accessibility Insights or Stark in Figma would surface every failing combination precisely.
  - **Performance profiling.** Frame budgets, jank %, GC pressure — observations are inferred from code shape. A Flutter DevTools timeline pass would surface specific bottlenecks.
  - **Animation curves & motion design.** Material 3 has motion tokens (`easeEmphasized`, etc.); Hanguk uses `Curves.easeOut`/`easeIn`/`easeInOut` ad-hoc.
  - **Light theme design.** The app is dark-only by intent. Adding a light theme is a design decision, not a backlog item.
  - **Copy / tone-of-voice review.** Translation quality of the English source strings is out of scope.
  - **Native iOS / Android UX:** pull-to-search on iOS, Material You dynamic colour on Android 12+, system back button behavior on Android — not measured.
  - **Web-specific surfaces.** `webview_flutter_web` is in pubspec but the web build hasn't been validated for keyboard accessibility on the map, mouse-wheel zoom on Pannellum, etc.
  - **`chat/widgets/`, `applications_view_model.dart`, `home_tab_provider.dart`** — read for context but not surfaced as findings (model/state rather than UI).
