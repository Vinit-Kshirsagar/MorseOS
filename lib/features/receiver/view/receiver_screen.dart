import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/receiver_bloc.dart';
import '../widgets/camera_viewfinder_widget.dart';
import '../widgets/detected_morse_widget.dart';
import '../widgets/decoded_text_widget.dart';
import '../widgets/receiver_controls_widget.dart';

class ReceiverScreen extends StatelessWidget {
  const ReceiverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReceiverBloc(),
      child:  const _ReceiverView(),
    );
  }
}

class _ReceiverView extends StatelessWidget {
  const _ReceiverView();

  @override
  Widget build(BuildContext context) {
    // No AnnotatedRegion here — AppShell owns system UI overlay style.
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _ReceiverHeader()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _divider(),
                    const SizedBox(height: 14),
                    const CameraViewfinderWidget(),
                    const SizedBox(height: 16),
                    _divider(),
                    const SizedBox(height: 14),
                    const DetectedMorseWidget(),
                    const SizedBox(height: 16),
                    _divider(),
                    const SizedBox(height: 14),
                    const DecodedTextWidget(),
                    const SizedBox(height: 16),
                    _divider(),
                    const SizedBox(height: 14),
                    const ReceiverControlsWidget(),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => const Divider(
      height: 1, thickness: 1, color: AppColors.borderSubtle);
}

class _ReceiverHeader extends StatelessWidget {
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
                  text:  'Morse',
                  style: GoogleFonts.inter(
                    fontSize:      24,
                    fontWeight:    FontWeight.w600,
                    color:         AppColors.textPrimary,
                    letterSpacing: -1,
                  ),
                ),
                TextSpan(
                  text:  'OS',
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
              'Signal reception system',
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
