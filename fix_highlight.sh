#!/usr/bin/env bash
# =============================================================================
# MorseOS — Preview Highlight Patch
# Run from INSIDE your morseos/ folder: bash ../fix_highlight.sh
# =============================================================================
set -e

echo "============================================"
echo "  MorseOS — adding live preview highlight"
echo "============================================"

# ── 1. NEW MODEL — ActiveLetterPosition ──────────────────────────────────────
# Tracks which word and letter is currently being transmitted.
# null = nothing active (idle/paused/done)

cat > lib/features/transmitter/models/active_letter_position.dart << 'DART'
import 'package:equatable/equatable.dart';

class ActiveLetterPosition extends Equatable {
  final int wordIndex;
  final int letterIndex;

  const ActiveLetterPosition({
    required this.wordIndex,
    required this.letterIndex,
  });

  @override
  List<Object?> get props => [wordIndex, letterIndex];
}
DART

# ── 2. MORSE CONVERTER — also return a signal-index → position map ────────────
# toSignals() now returns a record: the signal list AND a map from
# signal index to ActiveLetterPosition. The engine uses the map to tell
# the BLoC which letter each signal belongs to.

cat > lib/features/transmitter/services/morse_converter.dart << 'DART'
import '../../../core/constants/morse_constants.dart';
import '../models/morse_symbol.dart';
import '../models/active_letter_position.dart';

class MorseConverter {
  MorseConverter._();

  static bool isValid(String text) =>
      RegExp(r'^[A-Z0-9 ]*$').hasMatch(text.toUpperCase());

  static List<MorseWord> toWords(String text) {
    final upper  = text.toUpperCase();
    final chunks = upper.split(' ');
    final result = <MorseWord>[];
    for (final chunk in chunks) {
      if (chunk.isEmpty) continue;
      final symbols = chunk.characters.map((ch) {
        final code    = kMorseMap[ch];
        final isValid = code != null;
        return MorseSymbol(
          character: ch,
          code:      code ?? '?',
          isValid:   isValid,
        );
      }).toList();
      result.add(MorseWord(symbols));
    }
    return result;
  }

  /// Returns both the signal list and a position map.
  /// positionMap[i] = the ActiveLetterPosition that signal i belongs to.
  /// Gap signals between letters/words carry the position of the PRECEDING letter.
  static ({
    List<(bool on, int ms)> signals,
    List<ActiveLetterPosition?> positionMap,
  }) toSignals(String text, double speed) {
    final upper   = text.toUpperCase();
    final signals = <(bool, int)>[];
    final positionMap = <ActiveLetterPosition?>[];
    final words   = upper.split(' ');

    final dot       = MorseTimings.scaled(MorseTimings.dot,       speed);
    final dash      = MorseTimings.scaled(MorseTimings.dash,      speed);
    final symbolGap = MorseTimings.scaled(MorseTimings.symbolGap, speed);
    final letterGap = MorseTimings.scaled(MorseTimings.letterGap, speed);
    final wordGap   = MorseTimings.scaled(MorseTimings.wordGap,   speed);

    int wordIndex = 0;

    for (int wi = 0; wi < words.length; wi++) {
      final word = words[wi];
      if (word.isEmpty) continue;

      int letterIndex = 0;

      for (int li = 0; li < word.length; li++) {
        final ch   = word[li];
        final code = kMorseMap[ch];
        if (code == null) continue;

        final pos = ActiveLetterPosition(
          wordIndex:   wordIndex,
          letterIndex: letterIndex,
        );

        for (int si = 0; si < code.length; si++) {
          final sym = code[si];
          final dur = sym == '.' ? dot : dash;
          signals.add((true, dur));
          positionMap.add(pos);                     // ON signal → this letter

          if (si < code.length - 1) {
            signals.add((false, symbolGap));
            positionMap.add(pos);                   // symbol gap → still this letter
          }
        }

        if (li < word.length - 1) {
          signals.add((false, letterGap));
          positionMap.add(pos);                     // letter gap → preceding letter
        }

        letterIndex++;
      }

      if (wi < words.length - 1) {
        signals.add((false, wordGap));
        positionMap.add(null);                      // word gap → no letter highlighted
      }

      wordIndex++;
    }

    return (signals: signals, positionMap: positionMap);
  }
}

extension on String {
  Iterable<String> get characters sync* {
    for (final rune in runes) yield String.fromCharCode(rune);
  }
}
DART

# ── 3. STATE — add activePosition field ──────────────────────────────────────

cat > lib/features/transmitter/models/transmitter_state_model.dart << 'DART'
import '../../../core/constants/morse_constants.dart';
import 'active_letter_position.dart';

enum TransmissionStatus { idle, transmitting, paused, done }

class TransmitterStateModel {
  final String               inputText;
  final bool                 hasInvalidChar;
  final TransmissionStatus   status;
  final int                  totalSignals;
  final int                  completedSignals;
  final double               speed;
  final ActiveLetterPosition? activePosition; // null when idle/done

  const TransmitterStateModel({
    this.inputText         = '',
    this.hasInvalidChar    = false,
    this.status            = TransmissionStatus.idle,
    this.totalSignals      = 0,
    this.completedSignals  = 0,
    this.speed             = MorseTimings.defSpeed,
    this.activePosition,
  });

  double get progress =>
      totalSignals == 0 ? 0.0 : completedSignals / totalSignals;

  int get estimatedMs {
    final letters = inputText.replaceAll(' ', '').length;
    final words   = inputText.trim().isEmpty
        ? 0
        : inputText.trim().split(RegExp(r'\s+')).length;
    final base = (letters * 800) + ((words - 1).clamp(0, 999) * 840);
    return (base / speed).round();
  }

  TransmitterStateModel copyWith({
    String?               inputText,
    bool?                 hasInvalidChar,
    TransmissionStatus?   status,
    int?                  totalSignals,
    int?                  completedSignals,
    double?               speed,
    ActiveLetterPosition? activePosition,
    bool                  clearActivePosition = false,
  }) {
    return TransmitterStateModel(
      inputText:        inputText        ?? this.inputText,
      hasInvalidChar:   hasInvalidChar   ?? this.hasInvalidChar,
      status:           status           ?? this.status,
      totalSignals:     totalSignals     ?? this.totalSignals,
      completedSignals: completedSignals ?? this.completedSignals,
      speed:            speed            ?? this.speed,
      activePosition:   clearActivePosition
          ? null
          : (activePosition ?? this.activePosition),
    );
  }
}
DART

# ── 4. TRANSMISSION STATE — propagate positionMap ────────────────────────────

cat > lib/features/transmitter/bloc/transmitter_state.dart << 'DART'
import 'package:equatable/equatable.dart';
import '../models/transmission_mode.dart';
import '../models/transmitter_state_model.dart';
import '../models/morse_symbol.dart';
import '../models/active_letter_position.dart';

class TransmitterState extends Equatable {
  final TransmitterStateModel      model;
  final TransmissionMode            mode;
  final List<MorseWord>             morseWords;
  // Parallel list to the signal list — maps signal index to letter position.
  // Stored here so the BLoC can look up position during progress callbacks.
  final List<ActiveLetterPosition?> positionMap;

  const TransmitterState({
    required this.model,
    required this.mode,
    required this.morseWords,
    this.positionMap = const [],
  });

  factory TransmitterState.initial() => const TransmitterState(
    model:      TransmitterStateModel(),
    mode:       TransmissionMode.torch,
    morseWords: [],
    positionMap: [],
  );

  TransmitterState copyWith({
    TransmitterStateModel?      model,
    TransmissionMode?            mode,
    List<MorseWord>?             morseWords,
    List<ActiveLetterPosition?>? positionMap,
  }) {
    return TransmitterState(
      model:       model       ?? this.model,
      mode:        mode        ?? this.mode,
      morseWords:  morseWords  ?? this.morseWords,
      positionMap: positionMap ?? this.positionMap,
    );
  }

  @override
  List<Object?> get props => [model, mode, morseWords, positionMap];
}
DART

# ── 5. EVENT — add InternalPositionChanged ───────────────────────────────────

cat > lib/features/transmitter/bloc/transmitter_event.dart << 'DART'
import 'package:equatable/equatable.dart';
import '../models/transmission_mode.dart';
import '../models/active_letter_position.dart';

abstract class TransmitterEvent extends Equatable {
  const TransmitterEvent();
  @override
  List<Object?> get props => [];
}

class TextChanged extends TransmitterEvent {
  final String text;
  const TextChanged(this.text);
  @override List<Object?> get props => [text];
}

class ModeChanged extends TransmitterEvent {
  final TransmissionMode mode;
  const ModeChanged(this.mode);
  @override List<Object?> get props => [mode];
}

class SpeedChanged extends TransmitterEvent {
  final double speed;
  const SpeedChanged(this.speed);
  @override List<Object?> get props => [speed];
}

class TransmitStarted   extends TransmitterEvent { const TransmitStarted(); }
class TransmitPaused    extends TransmitterEvent { const TransmitPaused(); }
class TransmitResumed   extends TransmitterEvent { const TransmitResumed(); }
class TransmitCancelled extends TransmitterEvent { const TransmitCancelled(); }

class InternalProgressTicked extends TransmitterEvent {
  final int                  completed;
  final ActiveLetterPosition? position; // which letter is active right now
  const InternalProgressTicked(this.completed, this.position);
  @override List<Object?> get props => [completed, position];
}

class InternalTransmitDone extends TransmitterEvent {
  const InternalTransmitDone();
}
DART

# ── 6. BLOC — store positionMap, look up position on each progress tick ───────

cat > lib/features/transmitter/bloc/transmitter_bloc.dart << 'DART'
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/transmission_mode.dart';
import '../models/transmitter_state_model.dart';
import '../services/morse_converter.dart';
import '../services/transmission_engine.dart';
import '../services/torch_service.dart';
import '../services/audio_service.dart';
import 'transmitter_event.dart';
import 'transmitter_state.dart';

class TransmitterBloc extends Bloc<TransmitterEvent, TransmitterState> {
  final TorchService _torch = TorchService();
  final AudioService _audio = AudioService();
  late final TransmissionEngine _engine;

  TransmitterBloc() : super(TransmitterState.initial()) {
    _engine = TransmissionEngine(_torch, _audio);

    on<TextChanged>            (_onTextChanged);
    on<ModeChanged>            (_onModeChanged);
    on<SpeedChanged>           (_onSpeedChanged);
    on<TransmitStarted>        (_onTransmitStarted);
    on<TransmitPaused>         (_onTransmitPaused);
    on<TransmitResumed>        (_onTransmitResumed);
    on<TransmitCancelled>      (_onTransmitCancelled);
    on<InternalProgressTicked> (_onProgressTicked);
    on<InternalTransmitDone>   (_onTransmitDone);
  }

  void _onTextChanged(TextChanged event, Emitter<TransmitterState> emit) {
    final upper      = event.text.toUpperCase();
    final hasInvalid = !RegExp(r'^[A-Z0-9 ]*$').hasMatch(upper);
    final words      = MorseConverter.toWords(upper);
    emit(state.copyWith(
      model: state.model.copyWith(
        inputText:      upper,
        hasInvalidChar: hasInvalid,
        status:         TransmissionStatus.idle,
        clearActivePosition: true,
      ),
      morseWords: words,
    ));
  }

  void _onModeChanged(ModeChanged event, Emitter<TransmitterState> emit) =>
      emit(state.copyWith(mode: event.mode));

  void _onSpeedChanged(SpeedChanged event, Emitter<TransmitterState> emit) =>
      emit(state.copyWith(
        model: state.model.copyWith(speed: event.speed),
      ));

  Future<void> _onTransmitStarted(
      TransmitStarted event, Emitter<TransmitterState> emit) async {
    final text = state.model.inputText.trim();
    if (text.isEmpty) return;

    // toSignals now returns both the list and the position map
    final result = MorseConverter.toSignals(text, state.model.speed);
    if (result.signals.isEmpty) return;

    emit(state.copyWith(
      model: state.model.copyWith(
        status:           TransmissionStatus.transmitting,
        totalSignals:     result.signals.length,
        completedSignals: 0,
        clearActivePosition: true,
      ),
      positionMap: result.positionMap,
    ));

    _engine.transmit(
      signals: result.signals,
      mode:    state.mode,
      onProgress: (completed) {
        // Look up which letter this signal belongs to
        final map = state.positionMap;
        final pos = (completed - 1 < map.length) ? map[completed - 1] : null;
        add(InternalProgressTicked(completed, pos));
      },
    ).then((_) => add(const InternalTransmitDone()));
  }

  void _onTransmitPaused(
      TransmitPaused event, Emitter<TransmitterState> emit) {
    _engine.pause();
    emit(state.copyWith(
      model: state.model.copyWith(status: TransmissionStatus.paused),
    ));
  }

  void _onTransmitResumed(
      TransmitResumed event, Emitter<TransmitterState> emit) {
    _engine.resume();
    emit(state.copyWith(
      model: state.model.copyWith(status: TransmissionStatus.transmitting),
    ));
  }

  void _onTransmitCancelled(
      TransmitCancelled event, Emitter<TransmitterState> emit) {
    _engine.cancel();
    emit(state.copyWith(
      model: state.model.copyWith(
        status:           TransmissionStatus.idle,
        completedSignals: 0,
        totalSignals:     0,
        clearActivePosition: true,
      ),
      positionMap: const [],
    ));
  }

  void _onProgressTicked(
      InternalProgressTicked event, Emitter<TransmitterState> emit) {
    emit(state.copyWith(
      model: state.model.copyWith(
        completedSignals: event.completed,
        activePosition:   event.position,
      ),
    ));
  }

  void _onTransmitDone(
      InternalTransmitDone event, Emitter<TransmitterState> emit) {
    emit(state.copyWith(
      model: state.model.copyWith(
        status:           TransmissionStatus.done,
        completedSignals: state.model.totalSignals,
        clearActivePosition: true,
      ),
      positionMap: const [],
    ));
  }

  @override
  Future<void> close() async {
    _engine.cancel();
    await _audio.dispose();
    return super.close();
  }
}
DART

# ── 7. MORSE PREVIEW WIDGET — highlight active letter ────────────────────────

cat > lib/features/transmitter/widgets/morse_preview_widget.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../bloc/transmitter_bloc.dart';
import '../bloc/transmitter_state.dart';
import '../models/morse_symbol.dart';
import '../models/active_letter_position.dart';
import '../models/transmitter_state_model.dart';
import 'section_label.dart';

class MorsePreviewWidget extends StatelessWidget {
  const MorsePreviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransmitterBloc, TransmitterState>(
      builder: (context, state) {
        final isActive = state.model.status == TransmissionStatus.transmitting
                      || state.model.status == TransmissionStatus.paused;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('Morse Output'),
            Container(
              width:   double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
              decoration: BoxDecoration(
                color:        AppColors.surfaceDeep,
                borderRadius: BorderRadius.circular(12),
                border:       Border.all(color: AppColors.borderSubtle),
              ),
              child: state.morseWords.isEmpty
                  ? Text(
                      '—',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 14,
                        color:    AppColors.textMuted,
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _buildRows(state, isActive),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildRows(TransmitterState state, bool isActive) {
    final widgets  = <Widget>[];
    final activePos = isActive ? state.model.activePosition : null;

    for (int wi = 0; wi < state.morseWords.length; wi++) {
      widgets.add(_WordBlock(
        word:        state.morseWords[wi],
        wordIndex:   wi,
        activePos:   activePos,
        isActive:    isActive,
      ));
      if (wi < state.morseWords.length - 1) {
        widgets.add(_WordGap(isDim: isActive && activePos != null));
      }
    }
    return widgets;
  }
}

class _WordBlock extends StatelessWidget {
  final MorseWord             word;
  final int                   wordIndex;
  final ActiveLetterPosition? activePos;
  final bool                  isActive;

  const _WordBlock({
    required this.word,
    required this.wordIndex,
    required this.activePos,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(word.symbols.length, (li) {
        final isThisActive = isActive &&
            activePos != null &&
            activePos!.wordIndex   == wordIndex &&
            activePos!.letterIndex == li;

        // A letter is "done" if it's in a previous word, or same word but
        // earlier letter index than the current active position.
        final isDone = isActive && activePos != null && (
            activePos!.wordIndex > wordIndex ||
            (activePos!.wordIndex == wordIndex && activePos!.letterIndex > li)
        );

        return _LetterCol(
          symbol:       word.symbols[li],
          isHighlighted: isThisActive,
          isDone:        isDone,
          isActive:      isActive,
        );
      }),
    );
  }
}

class _LetterCol extends StatelessWidget {
  final MorseSymbol symbol;
  final bool        isHighlighted; // currently transmitting
  final bool        isDone;        // already transmitted
  final bool        isActive;      // transmission in progress

  const _LetterCol({
    required this.symbol,
    required this.isHighlighted,
    required this.isDone,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    // Colors for each state
    final Color charColor;
    final Color codeColor;
    final Color bgColor;

    if (isHighlighted) {
      charColor = AppColors.background;
      codeColor = AppColors.background;
      bgColor   = AppColors.accent;
    } else if (isDone) {
      charColor = AppColors.textMuted.withOpacity(0.5);
      codeColor = AppColors.textMuted.withOpacity(0.4);
      bgColor   = Colors.transparent;
    } else if (isActive) {
      // upcoming — slightly dimmed
      charColor = AppColors.textMuted.withOpacity(0.7);
      codeColor = AppColors.accent.withOpacity(0.35);
      bgColor   = Colors.transparent;
    } else {
      // idle state — normal colors
      charColor = symbol.isValid ? AppColors.textMuted : AppColors.accent.withOpacity(0.35);
      codeColor = symbol.isValid ? AppColors.accent    : AppColors.textMuted;
      bgColor   = Colors.transparent;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      margin:  const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        color:        bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 120),
            style: GoogleFonts.inter(
              fontSize:   9,
              fontWeight: FontWeight.w500,
              color:      charColor,
            ),
            child: Text(symbol.character),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 120),
            style: GoogleFonts.jetBrainsMono(
              fontSize:   12,
              fontWeight: FontWeight.w500,
              color:      codeColor,
              letterSpacing: 0.04,
            ),
            child: Text(symbol.code),
          ),
        ],
      ),
    );
  }
}

class _WordGap extends StatelessWidget {
  final bool isDim;
  const _WordGap({required this.isDim});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Text(
            'spc',
            style: GoogleFonts.inter(
              fontSize: 8,
              color:    isDim
                  ? AppColors.textMuted.withOpacity(0.3)
                  : AppColors.textMuted.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 3),
          Container(
            width:  1,
            height: 16,
            color:  isDim
                ? AppColors.border.withOpacity(0.4)
                : AppColors.border,
          ),
        ],
      ),
    );
  }
}
DART

echo ""
echo "============================================"
echo "  Preview highlight patch applied."
echo "  Run: flutter run"
echo "============================================"
