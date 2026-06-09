# 3ash — Architecture Overview

Feature-first layout with a shared **core** layer for cross-cutting concerns (theme, routing, errors, services).

## Directory Tree

```
lib/
├── main.dart                          # Bootstrap: Firebase, Hive, providers
├── app.dart                           # MaterialApp.router + StreamProvider auth
│
├── core/
│   ├── ai/
│   │   └── progression_engine.dart    # Smart 1RM / overload suggestions
│   ├── config/
│   │   └── firebase_initializer.dart
│   ├── constants/
│   │   ├── app_constants.dart
│   │   └── route_paths.dart
│   ├── errors/
│   │   ├── app_exception.dart
│   │   └── error_handler.dart         # Global snackbars / dialogs
│   ├── navigation/
│   │   ├── app_router.dart            # go_router + auth redirect
│   │   └── main_shell.dart            # Bottom nav + drawer
│   ├── services/
│   │   ├── connectivity_service.dart
│   │   ├── hive_service.dart
│   │   └── sync_queue_service.dart    # Offline-first Firestore queue
│   └── theme/
│       └── app_theme.dart
│
├── data/
│   └── models/
│       ├── app_user.dart              # User + roles
│       ├── user_role.dart
│       ├── active_workout_session.dart
│       ├── workout_exercise.dart
│       └── workout_set.dart
│
├── features/
│   ├── auth/
│   │   ├── providers/auth_provider.dart
│   │   └── presentation/login_screen.dart
│   ├── dashboard/presentation/
│   ├── workout/
│   │   ├── providers/active_workout_provider.dart
│   │   └── presentation/active_workout_screen.dart
│   ├── history/presentation/
│   ├── analytics/presentation/        # fl_chart
│   ├── admin/presentation/            # Admin role only
│   └── settings/presentation/
│
└── shared/                            # (extend) reusable widgets
```

## Planned Extensions (next iterations)

| Area | Location |
|------|----------|
| Voice logging (`speech_to_text`) | `features/workout/services/voice_log_parser.dart` |
| Biometric lock (`local_auth`) | `core/security/biometric_gate.dart` |
| FCM + local rest timers | `core/services/notification_service.dart` |
| Camera progress photos | `features/profile/services/photo_service.dart` |
| Firestore repositories | `data/repositories/` |

## Firebase Setup

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Then uncomment `options: DefaultFirebaseOptions.currentPlatform` in `firebase_initializer.dart`.

## Roles

Firestore document `users/{uid}` field `role`: `regular` | `admin`.
