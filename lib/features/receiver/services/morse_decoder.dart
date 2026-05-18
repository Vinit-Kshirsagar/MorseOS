import '../../../core/constants/morse_constants.dart';

// ── Sealed output type ────────────────────────────────────────────────────────

sealed class DecoderOutput {
  const DecoderOutput();
}

/// A dot or dash was appended. [fragment] is the full current fragment.
final class SymbolAppended extends DecoderOutput {
  final String fragment;
  const SymbolAppended(this.fragment);
}

/// A letter gap was detected. [letter] is the decoded character ('?' if unknown).
final class LetterCommitted extends DecoderOutput {
  final String letter;
  const LetterCommitted(this.letter);
}

/// A word gap was detected with no preceding in-progress letter.
final class WordCommitted extends DecoderOutput {
  const WordCommitted();
}

/// A word gap was detected AND an in-progress letter was simultaneously
/// committed. The BLoC adds the letter to currentWord then flushes the word.
/// This avoids any race condition between the callback and BLoC state.
final class WordCommittedWithLetter extends DecoderOutput {
  final String letter;
  const WordCommittedWithLetter(this.letter);
}

/// No new output this transition (e.g. inter-symbol gap — letter is still
/// being received).
final class DecoderIdle extends DecoderOutput {
  const DecoderIdle();
}

// ── Decoder state machine ─────────────────────────────────────────────────────

/// Converts raw ON/OFF signal durations into Morse symbols, letters, and
/// word boundaries.
///
/// Call [processTransition] each time the signal changes state.
/// [CameraService] measures the duration of each state and calls this.
///
/// Adaptive calibration: after the first dot is detected, the dot/dash
/// boundary is recalibrated to 2× that pulse duration. This makes the
/// decoder self-tuning across all sender speeds (0.25x–3.0x).
class MorseDecoder {
  String _fragment    = '';
  int    _adaptiveDot = MorseDecoderThresholds.dotDashBoundary;
  bool   _calibrated  = false;

  String get currentFragment => _fragment;

  /// Process a completed signal state transition.
  ///
  /// [wasOn]      — the state that just ended (true = was bright / ON).
  /// [durationMs] — how many milliseconds that state lasted.
  DecoderOutput processTransition({
    required bool wasOn,
    required int  durationMs,
  }) {
    return wasOn
        ? _processOnPulse(durationMs)
        : _processOffGap(durationMs);
  }

  DecoderOutput _processOnPulse(int durationMs) {
    final isDot = durationMs < _adaptiveDot * 2;

    if (!_calibrated && isDot && durationMs >= 20) {
      _adaptiveDot = durationMs;
      _calibrated  = true;
    }

    _fragment += isDot ? '.' : '-';
    return SymbolAppended(_fragment);
  }

  DecoderOutput _processOffGap(int durationMs) {
    // Thresholds scale with the adaptive dot duration.
    // symbolGapMax: anything less than 2× dot is within the same letter.
    // letterGapMax: midpoint between letter gap (3× dot) and word gap (7× dot).
    final symbolGapMax = (_adaptiveDot * 2.0).round();
    final letterGapMax = (_adaptiveDot * 5.0).round();

    if (durationMs <= symbolGapMax) {
      return const DecoderIdle();
    }

    if (durationMs <= letterGapMax) {
      return _commitLetter();
    }

    // Word gap. If a letter is in progress, commit it AND the word.
    if (_fragment.isNotEmpty) {
      final letter = kMorseToChar[_fragment] ?? '?';
      _fragment    = '';
      return WordCommittedWithLetter(letter);
    }
    return const WordCommitted();
  }

  DecoderOutput _commitLetter() {
    if (_fragment.isEmpty) return const DecoderIdle();
    final letter = kMorseToChar[_fragment] ?? '?';
    _fragment    = '';
    return LetterCommitted(letter);
  }

  /// Commits any in-progress letter. Call when scanning stops so the
  /// last letter is not lost.
  DecoderOutput flush() {
    if (_fragment.isEmpty) return const DecoderIdle();
    return _commitLetter();
  }

  /// Resets all state. Call when user taps Clear or restarts scanning.
  void reset() {
    _fragment    = '';
    _adaptiveDot = MorseDecoderThresholds.dotDashBoundary;
    _calibrated  = false;
  }
}
