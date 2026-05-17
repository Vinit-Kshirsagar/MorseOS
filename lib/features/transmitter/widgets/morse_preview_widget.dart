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
