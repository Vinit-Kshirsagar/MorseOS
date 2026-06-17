# MorseOS

A bidirectional Morse code communication app for Android. Send text via flashlight and audio. Receive and decode Morse signals. Built with Flutter.

## Quick Start

Download the APK from releases, install on your Android device (8.0+), and grant camera and microphone permissions. Start typing to transmit, or listen to decode incoming Morse.

## Features

**Transmission**
- Text to Morse encoding in real-time
- Synchronized flashlight and audio output
- Speed control (0.25x–3.0x multiplier)
- Live character preview during transmission

**Reception**
- Decode audio Morse input to readable text
- Real-time signal visualization

**Design**
- Dark theme (#151515 background, #E8C547 yellow accent)
- Minimal, focused UI with no unnecessary clutter
- Professional typography (Inter and JetBrains Mono)

## Requirements

Android 8.0 (API 26) or higher • 100 MB RAM • ~50 MB storage

## What's Under the Hood

Built with Flutter and BLoC architecture for clean separation of logic and UI. Audio playback uses programmatically generated WAV files for reliability across devices. Morse timing is precisely calibrated: 120ms dots, 400ms dashes.

Key dependencies: `flutter_bloc`, `equatable`, `torch_light`, `just_audio`, `path_provider`, `google_fonts`

## Project Structure

```
lib/
├── bloc/              # BLoC state management
├── models/            # Data structures
├── services/          # Morse encoding, audio, flashlight
├── ui/                # Flutter widgets
└── main.dart
```

## Building Locally

```bash
flutter pub get
flutter build apk
```

Output APK will be at `build/app/outputs/flutter-app-release.apk`

## How It Works

**Transmission:** Text is encoded to Morse signals, then transmitted simultaneously via the device LED (using `torch_light`) and audio playback (WAV sine waves). Speed is adjustable.

**Reception:** Audio input is captured, analyzed for timing patterns, and decoded back to text. The BLoC pattern handles state changes, validation, and error handling.

**Timing:** International Morse standard with customizable speed multiplier.

## Known Limitations

None. This is a stable, production-ready release.


## Contributing

Pull requests welcome. Follow the conventional commits format for commit messages.

---

Questions? Open an issue on GitHub.
