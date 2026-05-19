import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/receiver_bloc.dart';
import '../bloc/receiver_state.dart';

class DecodedTextWidget extends StatelessWidget {
  const DecodedTextWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReceiverBloc, ReceiverState>(
      buildWhen: (prev, curr) =>
          prev.model.committedWords != curr.model.committedWords ||
          prev.model.currentWord    != curr.model.currentWord,
      builder: (context, state) {
        final fullText   = state.model.fullDecodedText;
        final hasContent = state.model.hasContent;

        return Container(
          width:   double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color:        AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border:       Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'DECODED MESSAGE',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9, color: AppColors.textMuted,
                      letterSpacing: 0.8),
                  ),
                  const Spacer(),
                  if (hasContent)
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: fullText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Copied to clipboard',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color:    const Color(0xFF111111),
                              ),
                            ),
                            backgroundColor: AppColors.accent,
                            duration:    const Duration(seconds: 2),
                            behavior:    SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:        AppColors.accentDim,
                          borderRadius: BorderRadius.circular(5),
                          border:       Border.all(color: AppColors.accentBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.copy_rounded,
                                size: 10, color: AppColors.accent),
                            const SizedBox(width: 4),
                            Text(
                              'COPY',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9, fontWeight: FontWeight.w500,
                                color: AppColors.accent, letterSpacing: 0.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(
                    minHeight: 48, maxHeight: 120),
                child: SingleChildScrollView(
                  child: Text(
                    hasContent ? fullText : 'Awaiting signal...',
                    style: GoogleFonts.inter(
                      fontSize:   16,
                      fontWeight: FontWeight.w500,
                      color: hasContent
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              if (hasContent) ...[
                const SizedBox(height: 8),
                Text(
                  '${state.model.committedWords.length} word'
                  '${state.model.committedWords.length == 1 ? '' : 's'} decoded',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
