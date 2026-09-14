
# 🔥 Loopify

> A gamified habit tracker that turns daily routines into a streak you don't want to break.

Loopify is a Flutter app for iOS and Android that wraps habit tracking in a glass-morphic UI, fire-themed streaks, milestone modals, challenges, recovery tokens, and a home-screen widget that yells motivational quips at you based on how the day's going.

---

## ✨ Highlights

- 🔥 **Streak engine** — current streak, best streak, cold-streak warnings, and one-tap recovery tokens to save a broken run
- ➕ **Unlimited custom habits** — simple / duration / numeric types, 16 icons, 10 colors, your own microcopy
- 🏆 **Achievements & milestones** with celebratory modals and a personal note journal
- ⚔️ **Challenges** — set a personal goal with a deadline, get banners + reminders, see the deadline modal fire
- 🗓 **History calendar** with heatmap colors and per-day editing
- 📊 **Analytics screen** for weekly/monthly progress and habit-by-habit breakdowns
- 💾 **Backup & Restore** — full JSON export/import with a pre-restore safety snapshot
- 📂 **Long-term Projects** — track multi-day initiatives separately from habits
- 🌙 **Midnight countdown** so you don't sleep on the last hour
- 📱 **Home-screen widgets** — Android (Kotlin/RemoteViews) and iOS (WidgetKit + SwiftUI)
- 💎 **Glassmorphic UI** — custom design tokens, blurred surfaces, gradient accents, animated tab bar
- 🔌 **Offline-first** — Hive (local NoSQL), zero servers, your data lives on your device

---

## 📸 At a glance

| Today | History | Analytics | Widget |
|-------|---------|-----------|--------|
| 🏠 Habit cards + fire bar | 🗓 Calendar heatmap + recent activity | 📈 Streak & habit trends | 🔥 Live streak + quip |

> 💡 Drop your own screenshots into `assets/screenshots/` and link them here.

---

## 🛠 Tech Stack

| Layer | What |
|-------|------|
| 📱 Framework | Flutter (Dart) |
| 🧠 State | `flutter_riverpod` — providers + notifiers |
| 💾 Storage | `hive` — local NoSQL, all data on-device |
| 🤖 Android widget | Kotlin `AppWidgetProvider` + RemoteViews layout |
| 🍎 iOS widget | SwiftUI + WidgetKit extension (iOS 15+) |
| 🔗 Widget bridge | `home_widget` plugin (Android), custom MethodChannel + Keychain (iOS) |
| 🔔 Notifications | `flutter_local_notifications` |
| 📤 Backup | `share_plus`, `file_picker`, `path_provider` |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.10+ recommended)
- For iOS: macOS + Xcode 15+ + CocoaPods
- For Android: Android Studio + SDK 33+

### Install

```bash
git clone https://github.com/codecravings/loopify.git
cd loopify
flutter pub get
```

### Run

```bash
# Android
flutter run -d <android-device>

# iOS
cd ios && pod install && cd ..
flutter run -d <ios-device>
```

> ⚠️ If the iOS build fails on `--no-tree-shake-icons` errors, pass `--no-tree-shake-icons` to the build/run command.

---

## 🍎 iOS Widget Setup

The iOS WidgetKit extension lives at `ios/LoopifyWidget/`. It's already wired into `Runner.xcodeproj` via [`ios/add_widget_target.rb`](ios/add_widget_target.rb) (idempotent Ruby script using `xcodeproj`).

If you need to re-add it on a fresh clone:

```bash
cd ios && ruby add_widget_target.rb && pod install
```

Full walkthrough in [`ios/LoopifyWidget/SETUP.md`](ios/LoopifyWidget/SETUP.md).

### ⚠️ Sideloading caveat

iOS sideloaders (iLoader, AltStore, Sideloadly, etc.) often strip `com.apple.security.application-groups` and sometimes `keychain-access-groups` on free-cert re-signs. Loopify tries both:

1. App-group `UserDefaults(suiteName: "group.com.loopify.loopify")` — preferred
2. `keychain-access-groups` with `$(AppIdentifierPrefix)com.loopify.loopify` — fallback

If both get stripped, the widget renders but shows `● No data — open app once` instead of live streak data. Fix is sideloader-side (enable custom entitlements) or use a tool that preserves them (AltStore / TrollStore).

---

## 📁 Project Structure

```
lib/
├── main.dart                  # Entry — Hive init, providers, midnight observer
├── constants/
│   └── habits.dart            # Habit catalog, icons, colors, quip pools
├── models/                    # Hive type adapters (generated .g.dart files)
│   ├── habit_log.dart  day_log.dart  streak_state.dart
│   ├── project.dart  custom_habit.dart  challenge.dart
│   ├── achievement.dart  achievement_note.dart
│   └── user_prefs.dart  user_stats.dart
├── providers/                 # Riverpod state notifiers
├── services/
│   ├── hive_service.dart      # All Hive box reads/writes
│   ├── streak_service.dart    # Streak math, cold-streak detection
│   ├── recovery_service.dart  # Streak recovery eligibility & tokens
│   ├── challenge_service.dart # Challenge lifecycle + deadline modals
│   ├── achievement_service.dart
│   ├── notification_service.dart
│   ├── midnight_service.dart  # Midnight rollover observer
│   ├── backup_service.dart    # JSON export / import
│   ├── analytics_service.dart
│   └── widget_service.dart    # Bridge to native widget code
├── screens/                   # main, home, history, analytics, projects, settings, backup, manage_habits…
└── widgets/                   # GlassCard, ModernHabitCard, ProgressRing, Firebar, MorphChip, …

ios/
├── LoopifyWidget/             # iOS WidgetKit extension (SwiftUI glassmorphism)
├── Shared/
│   └── WidgetKeychainStore.swift  # Keychain-backed cross-process store
└── add_widget_target.rb       # Script to wire widget target into Xcode project

android/
└── app/src/main/kotlin/com/loopify/loopify/LoopifyWidget.kt
```

---

## 🎮 Widget Logic

Both widgets render the same data via three "vibe states":

| Habits today | Image | Quip pool |
|--------------|-------|-----------|
| 0 – 2  | `widget_1` | 🌱 **START** — "Wake up LEGEND! 💥" |
| 3 – 5  | `widget_2` | 🔥 **KEEP GOING** — "ON FIRE! Keep going!" |
| 6 +    | `widget_3` | 🏆 **UNSTOPPABLE** — "LEGEND STATUS!" |

Widgets refresh whenever you log/edit a habit (Flutter calls the native bridge → native reloads its timeline / pokes `AppWidgetManager`).

---

## 🎯 Habit Catalog

| # | Name | What | Color |
|---|------|------|-------|
| 1 | 🧘 Sit & Shine | Meditation | Purple |
| 2 | ✨ Glow Potion | Skincare / serum | Pink |
| 3 | 🧊 Ice Warrior | Cold shower | Blue |
| 4 | 💪 Jaw Gym | Face / jaw exercises | Orange |
| 5 | 🍃 Chew Quest | Chewing exercises | Cyan |
| 6 | 🥩 Protein Power-Up | Protein intake | Green |
| 7 | 📚 Study Grind | Study time | Indigo |
| 8 | ♟ Mind Gambit | Chess | Brown |
| 9 | 🚴 Pedal Power | Cycling | Light Green |
| 10 | 🛠 Build Streak | Coding projects | Deep Orange |
| 11 | 🧪 Mad Scientist Mode | Experiments | Deep Purple |

Hide any you don't want from **Settings → Manage Habits**. Add your own custom ones with the **+** button on the home screen.

---

## 🎨 Design Philosophy

- 🎮 **Gamify everything** — streaks, milestones, recovery tokens, achievements, challenges
- ✂️ **Brevity** — punchy microcopy, Hinglish flavor, no walls of text
- ⚡️ **Instant feedback** — confetti on milestones, animated firebar, live widget updates
- 🌑 **Dark by default** — `#05060F` deep, `#0B0D24` mid, `#FF7A2F` orange accent, backdrop-blurred glass surfaces

---

## 🗺 Roadmap

- [ ] 📸 Public screenshot pack + landing page
- [ ] 📈 Per-habit time-series charts
- [ ] 🔁 Optional cloud sync (opt-in, encrypted)
- [ ] 🌍 Multi-language quip pools
- [ ] 🧪 Widget variants (small / medium / large with different layouts)
- [ ] 🎁 Streak shields (auto-recovery on first miss of the month)
- [ ] 📦 Per-project analytics on the project detail screen

---

## 🤝 Contributing

PRs welcome. Loopify is local-first and dependency-light by design — keep that in mind before adding heavy SDKs.

If you're adding a habit type, update both `lib/constants/habits.dart` **and** the widget's `widget_X` image mapping so the home-screen widget keeps making sense.

---


---

> Built with 🔥 by [Om Gholwe](https://github.com/codecravings) · habits are just streaks waiting to happen.


> But APK Built with 🥵🔥 by [Jaat-Jetha256](https://github.com/Jaat-Jetha256) 🍕 Creating an apk for a code is also a habit of learning Something (especially by a Commerce Student 😅)
