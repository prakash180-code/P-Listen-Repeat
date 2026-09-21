# P-Listen & Repeat

US English shadowing and speaking practice app built with Flutter.

A hands-on tool for improving English pronunciation and speaking rhythm. Each lesson presents
short native-like phrases with a guided practice flow: listen, repeat, shadow, and get a
pronunciation score.

## Features

- **4 guided lessons, 30 phrases** with bundled native US English audio (TTS) — no internet needed
- **Listen** — play the reference audio with manual controls
- **Repeat** — record yourself saying the phrase, then play it back
- **Shadow** — record your voice simultaneously while listening to the reference
- **Validate** — duration-based pronunciation scoring (0–100) comparing your repeat recording
  against the reference, with helpful feedback
- **Progress tracking** — lessons are marked complete as you practice

## Practice Flow

1. **Listen** — hear the reference phrase
2. **Repeat** — record and play back your own attempt
3. **Shadow** — record while the reference plays, then review your shadow track
4. **Validate** — score your repeat recording against the reference

## Getting Started

### Prerequisites

- Flutter SDK 3.13+ (stable channel)
- Android Studio / Android toolchain for Android builds

### Run

```sh
flutter pub get
flutter run
```

### Build an APK

```sh
flutter build apk --debug
flutter build apk --release
```

## Tech Stack

- [Flutter](https://flutter.dev) — UI framework
- [just_audio](https://pub.dev/packages/just_audio) — audio playback (ExoPlayer on Android)
- [record](https://pub.dev/packages/record) — microphone recording
- [permission_handler](https://pub.dev/packages/permission_handler) — runtime permissions
- [provider](https://pub.dev/packages/provider) — state management
- [shared_preferences](https://pub.dev/packages/shared_preferences) — progress persistence
- [path_provider](https://pub.dev/packages/path_provider) — temporary audio file paths

## Audio Notes

- Lesson audio lives in `assets/audio/` and is generated offline via `edge-tts`
  (`en-US-GuyNeural`) — 30 MP3 files listed explicitly in `pubspec.yaml`.
- Assets are copied to temporary files before playback to avoid `just_audio`
  asset/stream format issues on Android.

## License

Private / personal project.