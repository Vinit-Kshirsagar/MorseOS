#!/usr/bin/env bash
# =============================================================================
# MorseOS — Beep Fix Patch
# Run this from INSIDE your morseos/ project folder
# Usage: bash ../fix_beep.sh   (or full path to this file)
# =============================================================================
set -e

echo "============================================"
echo "  MorseOS — applying beep fix"
echo "============================================"

# ── 1. ADD path_provider to pubspec ──────────────────────────────────────────
# just_audio stays — we only change HOW we feed it audio (file not stream)
# path_provider lets us write the WAV to a real temp file

cat > pubspec.yaml << 'PUBSPEC'
name: morseos
description: MorseOS — Morse Signal Transmitter
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.5
  equatable: ^2.0.5
  torch_light: ^1.0.0
  just_audio: ^0.9.38
  path_provider: ^2.1.3
  google_fonts: ^6.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
PUBSPEC

# ── 2. REPLACE audio_service.dart ────────────────────────────────────────────
# Strategy: generate WAV in memory → write to temp file → play via FileAudioSource
# FileAudioSource does NOT use the HTTP proxy, so no cleartext flag needed.
# A single AudioPlayer instance is reused; we call setFilePath + play each time.

cat > lib/features/transmitter/services/audio_service.dart << 'DART'
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  static const int    _sampleRate = 44100;
  static const double _frequency  = 700.0;  // standard Morse tone (Hz)
  static const double _amplitude  = 28000.0;
  static const int    _fadeMs     = 8;       // anti-click fade in/out

  String? _tmpPath;

  /// Play a beep of [durationMs] milliseconds.
  /// Writes a fresh WAV file each call so duration is exact.
  Future<void> beep(int durationMs) async {
    try {
      final bytes = _buildWav(durationMs);
      final path  = await _writeTmp(bytes);

      // Stop any currently playing audio first
      await _player.stop();
      await _player.setFilePath(path);
      await _player.play();
    } catch (e) {
      // Silently swallow — transmission continues even if audio fails
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _player.dispose();
      // Clean up temp file
      if (_tmpPath != null) {
        final f = File(_tmpPath!);
        if (await f.exists()) await f.delete();
      }
    } catch (_) {}
  }

  // ── WAV builder ────────────────────────────────────────────────────────────

  Uint8List _buildWav(int durationMs) {
    final numSamples = (_sampleRate * durationMs / 1000).round();
    final dataSize   = numSamples * 2; // 16-bit mono = 2 bytes per sample
    final buffer     = ByteData(44 + dataSize);

    // RIFF/WAVE header
    _str(buffer,  0, 'RIFF');
    buffer.setUint32( 4, 36 + dataSize, Endian.little);
    _str(buffer,  8, 'WAVE');
    _str(buffer, 12, 'fmt ');
    buffer.setUint32(16, 16,            Endian.little); // chunk size
    buffer.setUint16(20,  1,            Endian.little); // PCM format
    buffer.setUint16(22,  1,            Endian.little); // mono
    buffer.setUint32(24, _sampleRate,   Endian.little);
    buffer.setUint32(28, _sampleRate * 2, Endian.little); // byte rate
    buffer.setUint16(32,  2,            Endian.little); // block align
    buffer.setUint16(34, 16,            Endian.little); // bits per sample
    _str(buffer, 36, 'data');
    buffer.setUint32(40, dataSize,      Endian.little);

    // PCM samples — 700 Hz sine with linear fade in/out to avoid clicks
    final fadeSamples = (_sampleRate * _fadeMs / 1000).round();
    final twoPi       = 2.0 * math.pi;

    for (int i = 0; i < numSamples; i++) {
      double env = 1.0;
      if (i < fadeSamples) {
        env = i / fadeSamples;
      } else if (i > numSamples - fadeSamples) {
        env = (numSamples - i) / fadeSamples;
      }
      final sample = (_amplitude * env *
              math.sin(twoPi * _frequency * i / _sampleRate))
          .round()
          .clamp(-32768, 32767);
      buffer.setInt16(44 + i * 2, sample, Endian.little);
    }

    return buffer.buffer.asUint8List();
  }

  void _str(ByteData bd, int offset, String s) {
    for (int i = 0; i < s.length; i++) {
      bd.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  Future<String> _writeTmp(Uint8List bytes) async {
    final dir  = await getTemporaryDirectory();
    final path = '${dir.path}/morse_beep.wav';
    _tmpPath   = path;
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }
}
DART

# ── 3. GET DEPENDENCIES ───────────────────────────────────────────────────────
flutter pub get

echo ""
echo "============================================"
echo "  Beep fix applied."
echo "  Run: flutter run"
echo "============================================"
