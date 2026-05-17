import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../bloc/transmitter_bloc.dart';
import '../bloc/transmitter_event.dart';
import '../bloc/transmitter_state.dart';
import '../models/transmission_mode.dart';
import '../models/transmitter_state_model.dart';
import 'section_label.dart';

class ModeToggleWidget extends StatelessWidget {
  const ModeToggleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransmitterBloc, TransmitterState>(
      builder: (context, state) {
        final isTransmitting =
            state.model.status == TransmissionStatus.transmitting ||
            state.model.status == TransmissionStatus.paused;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('Transmission Mode'),
            Container(
              padding:    const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color:        AppColors.surfaceDeep,
                borderRadius: BorderRadius.circular(12),
                border:       Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: TransmissionMode.values.map((mode) {
                  final selected = state.mode == mode;
                  return Expanded(
                    child: GestureDetector(
                      onTap: isTransmitting
                          ? null
                          : () => context
                              .read<TransmitterBloc>()
                              .add(ModeChanged(mode)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.accent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Column(
                          children: [
                            Text(
                              mode.tag,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize:   9,
                                fontWeight: FontWeight.w600,
                                color:      selected
                                    ? const Color(0xFF111111)
                                    : AppColors.textMuted,
                                letterSpacing: 0.05,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              mode.label,
                              style: GoogleFonts.inter(
                                fontSize:   11,
                                fontWeight: FontWeight.w500,
                                color:      selected
                                    ? const Color(0xFF111111)
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
