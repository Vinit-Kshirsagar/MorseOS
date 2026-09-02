import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/receiver_bloc.dart';
import '../bloc/receiver_state.dart';

class DetectedMorseWidget extends StatelessWidget {
  const DetectedMorseWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReceiverBloc, ReceiverState>(
      buildWhen: (prev, curr) =>
          prev.model.currentMorseFragment != curr.model.currentMorseFragment ||
          prev.model.currentWord          != curr.model.currentWord,
      builder: (context, state) {
        final fragment = state.model.currentMorseFragment;
        final word     = state.model.currentWord;

        return Container(
          width:   double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color:        AppColors.surfaceDeep,
            borderRadius: BorderRadius.circular(10),
            border:       Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LIVE SIGNAL',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9, color: AppColors.textMuted,
                  letterSpacing: 0.8),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 120),
                      child: Align(
                        key:       ValueKey(fragment),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          fragment.isEmpty ? '—' : fragment,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize:   22,
                            fontWeight: FontWeight.w500,
                            color: fragment.isEmpty
                                ? AppColors.textMuted
                                : AppColors.accent,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'FRAGMENT',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9, color: AppColors.textMuted,
                      letterSpacing: 0.4),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, thickness: 1,
                  color: AppColors.borderSubtle),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      word.isEmpty ? '—' : word,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize:   15,
                        fontWeight: FontWeight.w500,
                        color: word.isEmpty
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  Text(
                    'CURRENT WORD',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9, color: AppColors.textMuted,
                      letterSpacing: 0.4),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
