import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/morse_constants.dart';
import '../../../core/theme/app_colors.dart';
import 'section_label.dart';

class TimingChipsWidget extends StatelessWidget {
  const TimingChipsWidget({super.key});

  static const _chips = [
    ('·',   MorseTimings.dot),
    ('−',   MorseTimings.dash),
    ('sym', MorseTimings.symbolGap),
    ('ltr', MorseTimings.letterGap),
    ('wrd', MorseTimings.wordGap),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Timing'),
        Row(
          children: _chips.map((chip) {
            final (sym, ms) = chip;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 5),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color:        AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border:       Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Text(
                      sym,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize:   13,
                        fontWeight: FontWeight.w600,
                        color:      AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${ms}ms',
                      style: GoogleFonts.inter(
                        fontSize: 8.5,
                        color:    AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
