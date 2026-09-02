#!/usr/bin/env bash
# =============================================================================
# MorseOS — Speed Slider Patch
# Run from INSIDE your morseos/ folder: bash ../fix_speed.sh
# =============================================================================
set -e

echo "============================================"
echo "  MorseOS — adding speed slider"
echo "============================================"

# ── 1. CONSTANTS — base timings only, multiplier applied at runtime ───────────
cat > lib/core/constants/morse_constants.dart << 'DART'
class MorseTimings {
  MorseTimings._();

  // Base timings at 1.0x speed (ms)
  static const int dot       = 120;
  static const int dash      = 400;
  static const int symbolGap = 120;
  static const int letterGap = 360;
  static const int wordGap   = 840;

  // Slider range
  static const double minSpeed =  0.25;
  static const double maxSpeed =  3.0;
  static const double defSpeed =  1.0;

  // Apply multiplier — higher speed = shorter durations
  static int scaled(int base, double speed) =>
      (base / speed).round().clamp(20, 9999);
}

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

# ── 2. MORSE CONVERTER — accept speed param ───────────────────────────────────
cat > lib/features/transmitter/services/morse_converter.dart << 'DART'
import '../../../core/constants/morse_constants.dart';
import '../models/morse_symbol.dart';

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

  /// [speed] — multiplier: 1.0 = normal, 2.0 = 2x faster, 0.5 = half speed
  static List<(bool on, int ms)> toSignals(String text, double speed) {
    final upper   = text.toUpperCase();
    final signals = <(bool, int)>[];
    final words   = upper.split(' ');

    final dot       = MorseTimings.scaled(MorseTimings.dot,       speed);
    final dash      = MorseTimings.scaled(MorseTimings.dash,      speed);
    final symbolGap = MorseTimings.scaled(MorseTimings.symbolGap, speed);
    final letterGap = MorseTimings.scaled(MorseTimings.letterGap, speed);
    final wordGap   = MorseTimings.scaled(MorseTimings.wordGap,   speed);

    for (int wi = 0; wi < words.length; wi++) {
      final word = words[wi];
      if (word.isEmpty) continue;
      for (int li = 0; li < word.length; li++) {
        final ch   = word[li];
        final code = kMorseMap[ch];
        if (code == null) continue;
        for (int si = 0; si < code.length; si++) {
          final sym = code[si];
          final dur = sym == '.' ? dot : dash;
          signals.add((true, dur));
          if (si < code.length - 1) signals.add((false, symbolGap));
        }
        if (li < word.length - 1) signals.add((false, letterGap));
      }
      if (wi < words.length - 1) signals.add((false, wordGap));
    }
    return signals;
  }
}

extension on String {
  Iterable<String> get characters sync* {
    for (final rune in runes) yield String.fromCharCode(rune);
  }
}
DART

# ── 3. STATE MODEL — add speed field ─────────────────────────────────────────
cat > lib/features/transmitter/models/transmitter_state_model.dart << 'DART'
import '../../../core/constants/morse_constants.dart';

enum TransmissionStatus { idle, transmitting, paused, done }

class TransmitterStateModel {
  final String             inputText;
  final bool               hasInvalidChar;
  final TransmissionStatus status;
  final int                totalSignals;
  final int                completedSignals;
  final double             speed; // multiplier

  const TransmitterStateModel({
    this.inputText         = '',
    this.hasInvalidChar    = false,
    this.status            = TransmissionStatus.idle,
    this.totalSignals      = 0,
    this.completedSignals  = 0,
    this.speed             = MorseTimings.defSpeed,
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
    String?             inputText,
    bool?               hasInvalidChar,
    TransmissionStatus? status,
    int?                totalSignals,
    int?                completedSignals,
    double?             speed,
  }) {
    return TransmitterStateModel(
      inputText:        inputText        ?? this.inputText,
      hasInvalidChar:   hasInvalidChar   ?? this.hasInvalidChar,
      status:           status           ?? this.status,
      totalSignals:     totalSignals     ?? this.totalSignals,
      completedSignals: completedSignals ?? this.completedSignals,
      speed:            speed            ?? this.speed,
    );
  }
}
DART

# ── 4. EVENT — add SpeedChanged ───────────────────────────────────────────────
cat > lib/features/transmitter/bloc/transmitter_event.dart << 'DART'
import 'package:equatable/equatable.dart';
import '../models/transmission_mode.dart';

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
  final int completed;
  const InternalProgressTicked(this.completed);
  @override List<Object?> get props => [completed];
}

class InternalTransmitDone extends TransmitterEvent {
  const InternalTransmitDone();
}
DART

# ── 5. BLOC — wire SpeedChanged, pass speed to toSignals ─────────────────────
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

    final signals = MorseConverter.toSignals(text, state.model.speed);
    if (signals.isEmpty) return;

    emit(state.copyWith(
      model: state.model.copyWith(
        status:           TransmissionStatus.transmitting,
        totalSignals:     signals.length,
        completedSignals: 0,
      ),
    ));

    _engine.transmit(
      signals:    signals,
      mode:       state.mode,
      onProgress: (c) => add(InternalProgressTicked(c)),
    ).then((_) => add(const InternalTransmitDone()));
  }

  void _onTransmitPaused(TransmitPaused event, Emitter<TransmitterState> emit) {
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
      ),
    ));
  }

  void _onProgressTicked(
      InternalProgressTicked event, Emitter<TransmitterState> emit) =>
      emit(state.copyWith(
        model: state.model.copyWith(completedSignals: event.completed),
      ));

  void _onTransmitDone(
      InternalTransmitDone event, Emitter<TransmitterState> emit) =>
      emit(state.copyWith(
        model: state.model.copyWith(
          status:           TransmissionStatus.done,
          completedSignals: state.model.totalSignals,
        ),
      ));

  @override
  Future<void> close() async {
    _engine.cancel();
    await _audio.dispose();
    return super.close();
  }
}
DART

# ── 6. SPEED SLIDER WIDGET ────────────────────────────────────────────────────
cat > lib/features/transmitter/widgets/speed_slider_widget.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/morse_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../bloc/transmitter_bloc.dart';
import '../bloc/transmitter_event.dart';
import '../bloc/transmitter_state.dart';
import '../models/transmitter_state_model.dart';
import 'section_label.dart';

class SpeedSliderWidget extends StatelessWidget {
  const SpeedSliderWidget({super.key});

  String _speedLabel(double speed) {
    if (speed < 0.4)  return 'Very slow';
    if (speed < 0.75) return 'Slow';
    if (speed < 1.25) return 'Normal';
    if (speed < 1.75) return 'Fast';
    if (speed < 2.5)  return 'Very fast';
    return 'Max';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransmitterBloc, TransmitterState>(
      builder: (context, state) {
        final speed        = state.model.speed;
        final isActive     = state.model.status == TransmissionStatus.transmitting
                          || state.model.status == TransmissionStatus.paused;
        final dot          = MorseTimings.scaled(MorseTimings.dot,  speed);
        final dash         = MorseTimings.scaled(MorseTimings.dash, speed);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('Speed'),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              decoration: BoxDecoration(
                color:        AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border:       Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  // Top row: label left, speed value right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _speedLabel(speed),
                        style: GoogleFonts.inter(
                          fontSize:   12,
                          fontWeight: FontWeight.w500,
                          color:      AppColors.textSecondary,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${speed.toStringAsFixed(2)}x',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize:   13,
                              fontWeight: FontWeight.w600,
                              color:      AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Slider
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor:   AppColors.accent,
                      inactiveTrackColor: AppColors.border,
                      thumbColor:         AppColors.accent,
                      overlayColor:       AppColors.accentDim,
                      trackHeight:        2.5,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 7,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 16,
                      ),
                    ),
                    child: Slider(
                      value:    speed,
                      min:      MorseTimings.minSpeed,
                      max:      MorseTimings.maxSpeed,
                      // 23 discrete steps gives clean snap points
                      divisions: 22,
                      onChanged: isActive
                          ? null // lock during transmission
                          : (v) => context
                              .read<TransmitterBloc>()
                              .add(SpeedChanged(v)),
                    ),
                  ),
                  // Bottom row: dot/dash preview at current speed
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _Chip(sym: '·', label: '${dot}ms'),
                      _Chip(sym: '−', label: '${dash}ms'),
                      _Chip(
                        sym:   'sym',
                        label: '${MorseTimings.scaled(MorseTimings.symbolGap, speed)}ms',
                      ),
                      _Chip(
                        sym:   'ltr',
                        label: '${MorseTimings.scaled(MorseTimings.letterGap, speed)}ms',
                      ),
                      _Chip(
                        sym:   'wrd',
                        label: '${MorseTimings.scaled(MorseTimings.wordGap, speed)}ms',
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  final String sym;
  final String label;
  const _Chip({required this.sym, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          sym,
          style: GoogleFonts.jetBrainsMono(
            fontSize:   11,
            fontWeight: FontWeight.w600,
            color:      AppColors.accent,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 8.5,
            color:    AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
DART

# ── 7. REMOVE OLD TIMING CHIPS WIDGET and update the screen ──────────────────
# The speed slider now shows live timings, so TimingChipsWidget is redundant.
# We replace it in the screen with SpeedSliderWidget.

cat > lib/features/transmitter/view/transmitter_screen.dart << 'DART'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../bloc/transmitter_bloc.dart';
import '../widgets/message_input_widget.dart';
import '../widgets/morse_preview_widget.dart';
import '../widgets/mode_toggle_widget.dart';
import '../widgets/speed_slider_widget.dart';
import '../widgets/metrics_widget.dart';
import '../widgets/transmission_controls_widget.dart';

class TransmitterScreen extends StatelessWidget {
  const TransmitterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TransmitterBloc(),
      child: const _TransmitterView(),
    );
  }
}

class _TransmitterView extends StatelessWidget {
  const _TransmitterView();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor:                    Colors.transparent,
        statusBarIconBrightness:           Brightness.light,
        systemNavigationBarColor:          AppColors.background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _AppHeader()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _divider(),
                      const SizedBox(height: 14),
                      const MessageInputWidget(),
                      const SizedBox(height: 16),
                      _divider(),
                      const SizedBox(height: 14),
                      const MorsePreviewWidget(),
                      const SizedBox(height: 16),
                      _divider(),
                      const SizedBox(height: 14),
                      const ModeToggleWidget(),
                      const SizedBox(height: 16),
                      _divider(),
                      const SizedBox(height: 14),
                      const SpeedSliderWidget(),   // replaces static timing chips
                      const SizedBox(height: 16),
                      _divider(),
                      const SizedBox(height: 14),
                      const MetricsWidget(),
                      const SizedBox(height: 16),
                      _divider(),
                      const SizedBox(height: 14),
                      const TransmissionControlsWidget(),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() => const Divider(
        height: 1, thickness: 1, color: AppColors.borderSubtle);
}

class _AppHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Morse',
                  style: GoogleFonts.inter(
                    fontSize:      24,
                    fontWeight:    FontWeight.w600,
                    color:         AppColors.textPrimary,
                    letterSpacing: -1,
                  ),
                ),
                TextSpan(
                  text: 'OS',
                  style: GoogleFonts.inter(
                    fontSize:      24,
                    fontWeight:    FontWeight.w600,
                    color:         AppColors.accent,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              'Signal transmission system',
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.textMuted),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color:        AppColors.accentDim,
              borderRadius: BorderRadius.circular(6),
              border:       Border.all(color: AppColors.accentBorder),
            ),
            child: Text(
              'v1.0',
              style: GoogleFonts.jetBrainsMono(
                fontSize:   10,
                fontWeight: FontWeight.w500,
                color:      AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
DART

echo ""
echo "============================================"
echo "  Speed slider patch applied."
echo "  Run: flutter run"
echo "============================================"
