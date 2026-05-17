import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../bloc/transmitter_bloc.dart';
import '../bloc/transmitter_event.dart';
import '../bloc/transmitter_state.dart';
import '../models/transmitter_state_model.dart';
import 'section_label.dart';

class MessageInputWidget extends StatefulWidget {
  const MessageInputWidget({super.key});

  @override
  State<MessageInputWidget> createState() => _MessageInputWidgetState();
}

class _MessageInputWidgetState extends State<MessageInputWidget> {
  final _controller = TextEditingController();
  final _focus      = FocusNode();
  bool _lastWarnShown = false;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TransmitterBloc, TransmitterState>(
      listenWhen: (prev, curr) =>
          prev.model.hasInvalidChar != curr.model.hasInvalidChar,
      listener: (context, state) {
        if (state.model.hasInvalidChar && !_lastWarnShown) {
          _lastWarnShown = true;
        } else if (!state.model.hasInvalidChar) {
          _lastWarnShown = false;
        }
      },
      builder: (context, state) {
        final isTransmitting =
            state.model.status == TransmissionStatus.transmitting ||
            state.model.status == TransmissionStatus.paused;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('Message Input'),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: state.model.hasInvalidChar
                      ? AppColors.accentBorder
                      : AppColors.border,
                  width: state.model.hasInvalidChar ? 1.5 : 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: TextField(
                controller:  _controller,
                focusNode:   _focus,
                enabled:     !isTransmitting,
                maxLength:   100,
                maxLines:    2,
                minLines:    1,
                style: GoogleFonts.inter(
                  fontSize:   19,
                  fontWeight: FontWeight.w500,
                  color:      AppColors.textPrimary,
                  letterSpacing: -0.4,
                ),
                decoration: const InputDecoration(
                  border:          InputBorder.none,
                  enabledBorder:   InputBorder.none,
                  focusedBorder:   InputBorder.none,
                  filled:          false,
                  counterText:     '',
                  isDense:         true,
                  contentPadding:  EdgeInsets.zero,
                ),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  // Allow all chars through — warn on invalid, don't block
                  _UpperCaseFormatter(),
                ],
                onChanged: (val) =>
                    context.read<TransmitterBloc>().add(TextChanged(val)),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (state.model.hasInvalidChar) ...[
                  _WarnPill(),
                  const SizedBox(width: 8),
                ],
                const Spacer(),
                Text(
                  '${state.model.inputText.length} / 100',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color:    AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _WarnPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:        AppColors.accentDim,
        borderRadius: BorderRadius.circular(6),
        border:       Border.all(color: AppColors.accentBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 11, color: AppColors.accent),
          const SizedBox(width: 4),
          Text(
            'Only A–Z, 0–9 and spaces allowed',
            style: GoogleFonts.inter(
              fontSize: 10,
              color:    AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue val) {
    return val.copyWith(text: val.text.toUpperCase());
  }
}
