# Offline Planner — KMP rewrite scaffold (`kmp-rewrite`)

Shared Kotlin logic + native UIs. Offline-first, email/ZIP backup compatible
with Flutter `backup.json v3` (`backup.json + media/`).

## Modules
- `shared/` — domain models (`domain/Models.kt`), backup compat (`backup/BackupCompat.kt`),
  planner stats + music `nextIndex` queue logic, SQLDelight schema next.
- `androidApp/` — Compose host (`MainActivity.kt`). Next: drawer nav, Media3
  background playback, Health Connect steps, CameraX docs + calendar filter,
  exact alarms + boot reschedule.
- `iosApp/` — SwiftUI/Compose host next: AVPlayer background, HealthKit steps,
  VisionKit docs, UserNotifications.

## Native mapping (from Flutter)
| Flutter | KMP |
|---|---|
| Hive + SharedPreferences | SQLDelight + Multiplatform Settings |
| audioplayers queue | Media3 ExoPlayer + MediaSessionService / AVPlayer bg |
| pedometer plugin | Health Connect StepsRecord / HealthKit stepCount |
| flutter_local_notifications | AlarmManager exact + NotifCompat / UNUserNotifications |
| image_picker/file_picker | CameraX / AVFoundation + document picker, app docs `scanned_docs/` + `media/` |
| archive + share_plus ZIP | okio zip + ACTION_SEND / UIActivityViewController |
| Flame space shooter | Compose Canvas game loop (port next) |

## Build (requires Android Studio + Xcode)
- Android: open `kmp/` in Android Studio, run `androidApp`.
  Release APK: `androidApp/build/outputs/apk/release/app-release.apk`.
- Desktop quick check (no Android SDK): `./gradlew :shared:build` with JDK 17.

## Health sensor fix (vs Flutter pedometer)
Request `ACTIVITY_RECOGNITION` / `NSMotionUsageDescription` → then
Health Connect `readSteps` aggregate + `HealthKit HKQuantityType.stepCount`
background delivery, permission onboarding + retry + midnight rollover.
Emulator without step-counter hardware still reports 0 — test on device while walking.
