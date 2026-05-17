import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../bloc/transmitter_bloc.dart';
import '../bloc/transmitter_state.dart';
import '../models/transmitter_state_model.dart';

class MetricsWidget extends StatelessWidget {
  const MetricsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransmitterBloc, TransmitterState>(
      builder: (context, state) {
        final isLive = state.model.status == TransmissionStatus.transmitting ||
            state.model.status == TransmissionStatus.paused;

        final leftLabel = isLive ? 'Progress' : 'Characters';
        final leftValue = isLive
            ? '${(state.model.progress * 100).toStringAsFixed(0)}%'
            : '${state.model.inputText.replaceAll(' ', '').length} chars';
        final leftFill  = isLive ? state.model.progress : 0.0;

        final estMs     = state.model.estimatedMs;
        final rightLabel = isLive ? 'Remaining' : 'Est. duration';
        final rightValue = isLive
            ? '${((1 - state.model.progress) * estMs / 1000).toStringAsFixed(1)}s'
            : '${(estMs / 1000).toStringAsFixed(1)}s';
        final rightFill  = isLive ? (1 - state.model.progress) : 0.0;

        return Row(
          children: [
            Expanded(child: _MetricCard(
              label: leftLabel,
              value: leftValue,
              fill:  leftFill,
            )),
            const SizedBox(width: 8),
            Expanded(child: _MetricCard(
              label: rightLabel,
              value: rightValue,
              fill:  rightFill,
            )),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final double fill;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.fill,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize:      9,
              fontWeight:    FontWeight.w500,
              color:         AppColors.textMuted,
              letterSpacing: 0.08,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize:   17,
              fontWeight: FontWeight.w600,
              color:      AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value:           fill,
              minHeight:       2,
              backgroundColor: AppColors.borderSubtle,
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}
