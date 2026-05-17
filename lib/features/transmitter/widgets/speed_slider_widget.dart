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
