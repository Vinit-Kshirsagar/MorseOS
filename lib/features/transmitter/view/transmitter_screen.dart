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
