# Ascend AI

Your AI Life Companion — achieve any goal through AI coaching, analytics, habit tracking, accountability, and personalized planning.

## Run

```bash
flutter pub get
flutter run
```

## Architecture

```
lib/
├── app.dart                 # Root MaterialApp
├── main.dart                # Entry point + Hive init
├── core/
│   ├── constants/           # App & route constants
│   ├── errors/              # Exception types
│   ├── extensions/          # BuildContext & DateTime helpers
│   ├── router/              # GoRouter + bottom nav shell
│   ├── theme/               # Material 3 dark-first theme
│   └── utils/               # Shared utilities
├── models/                  # Data models + enums
├── services/
│   ├── ai/                  # Abstract AI provider + coach logic
│   └── storage/             # Hive local storage + Firebase stub
├── repositories/            # Repository pattern (Hive-backed MVP)
├── providers/               # Riverpod state management
├── shared/widgets/          # Reusable UI components
└── features/                # Feature screens (MVP)
    ├── splash/
    ├── onboarding/          # 5-step identity onboarding
    ├── home/                # Goal card, mission, quick actions
    ├── coach/               # AI coach insights
    ├── chat/                # AI chat with context
    ├── analytics/           # Success probability dashboard
    ├── accountability/      # Evening check-in
    ├── focus/               # Pomodoro deep work
    ├── habits/
    ├── journal/
    ├── vision_board/
    ├── roadmap/
    ├── profile/
    └── settings/
```

## MVP Features

- **5-step onboarding** — identity goal, deadline, skill level, daily hours, motivation
- **AI roadmap generator** — long-term → monthly → weekly → daily → today's mission
- **AI coach** — personalized daily messages based on streak, skips, and performance
- **AI adaptation** — auto-adjusts roadmap after 3 consecutive skips
- **Accountability check-in** — yes/partial/no with skip reason analysis
- **Analytics dashboard** — consistency, success probability, predictions, weekly trends
- **AI chat** — context-aware coach (mock AI for dev, swap to OpenAI/Claude)
- **Deep work mode** — Pomodoro timer with session tracking
- **Habits, journal, vision board, profile, settings**

## Firebase Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
3. Run `flutterfire configure` in the project root (generates `lib/firebase_options.dart` and platform config files)
4. Enable **Email/Password** and **Google** sign-in under Firebase Console → Authentication → Sign-in method
5. `FirebaseService.instance.init()` runs automatically in `main.dart`
6. See `docs/firestore_schema.md` for collection structure

## AI Provider Setup

Swap `MockAiProvider` in `AiService` for production:

```dart
// OpenAI
AiService(provider: OpenAiProvider(apiKey: 'your-key'));

// Claude
AiService(provider: ClaudeAiProvider(apiKey: 'your-key'));
```

## Tech Stack

- Flutter + Riverpod + Go Router + Flutter Hooks
- Material 3 (dark-first) + Google Fonts + flutter_animate
- Hive (local MVP) + Firebase (production sync)
- fl_chart (analytics) + table_calendar (streak calendar)

## Next Features

- [x] Firebase Auth (email/password)
- [ ] Firestore sync
- [ ] Push & local notifications
- [ ] Voice AI
- [ ] Achievement system (XP, badges, levels)
- [ ] GitHub-style streak calendar with real data
- [ ] Weekly AI reports (Sunday)
- [ ] Image upload for vision board
- [ ] Friends & leaderboards
