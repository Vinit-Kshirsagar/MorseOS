#!/usr/bin/env bash
# =============================================================================
# MorseOS — Timing Patch
# Run from INSIDE your morseos/ folder: bash ../fix_timing.sh
# =============================================================================
set -e

cat > lib/core/constants/morse_constants.dart << 'DART'
// Morse timing constants (ms)
// Ratios preserved: dash = 3x dot, sym gap = 1x dot,
// letter gap = 3x dot, word gap = 7x dot
class MorseTimings {
  MorseTimings._();
  static const int dot       = 120;   // was 200
  static const int dash      = 400;   // was 600  (~3.3x dot)
  static const int symbolGap = 120;   // was 200  (1x dot)
  static const int letterGap = 360;   // was 600  (3x dot)
  static const int wordGap   = 840;   // was 1400 (7x dot)
}

// Morse code map — A-Z and 0-9
const Map<String, String> kMorseMap = {
  'A': '.-',   'B': '-...', 'C': '-.-.',
  'D': '-..',  'E': '.',    'F': '..-.',
  'G': '--.',  'H': '....', 'I': '..',
  'J': '.---', 'K': '-.-',  'L': '.-..',
  'M': '--',   'N': '-.',   'O': '---',
  'P': '.--.',  'Q': '--.-', 'R': '.-.',
  'S': '...',  'T': '-',    'U': '..-',
  'V': '...-', 'W': '.--',  'X': '-..-',
  'Y': '-.--', 'Z': '--..',
  '0': '-----', '1': '.----', '2': '..---',
  '3': '...--', '4': '....-', '5': '.....',
  '6': '-....', '7': '--...', '8': '---..',
  '9': '----.',
};
DART

echo "Timing updated. Run: flutter run"
