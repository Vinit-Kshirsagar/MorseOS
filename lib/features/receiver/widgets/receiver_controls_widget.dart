import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/receiver_bloc.dart';
import '../bloc/receiver_event.dart';
import '../bloc/receiver_state.dart';
import '../models/receiver_state_model.dart';

class ReceiverControlsWidget extends StatelessWidget {
  const ReceiverControlsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReceiverBloc, ReceiverState>(
      builder: (context, state) {
        final isScanning = state.model.status == ReceiverStatus.scanning;
        final hasContent = state.model.hasContent;
        final canClear   = hasContent ||
            state.model.status == ReceiverStatus.stopped;

        return Column(
          children: [
            _ReceiverStatusStrip(state: state),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _PrimaryButton(
                    isScanning: isScanning,
                    onTap: () {
                      final bloc = context.read<ReceiverBloc>();
                      isScanning
                          ? bloc.add(const ScanStopped())
                          : bloc.add(const ScanStarted());
                    },
                  ),
                ),
                const SizedBox(width: 8),
                _ClearButton(
                  active: canClear,
                  onTap:  canClear
                      ? () => context
                          .read<ReceiverBloc>()
                          .add(const DecodingReset())
                      : null,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ReceiverStatusStrip extends StatelessWidget {
  final ReceiverState state;
  const _ReceiverStatusStrip({required this.state});

  bool get _isLive => state.model.status == ReceiverStatus.scanning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color:        AppColors.surfaceDeep,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          _LiveDot(live: _isLive),
          const SizedBox(width: 8),
          Text(
            state.model.statusMessage,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              color:    _isLive
                  ? AppColors.textSecondary
                  : AppColors.textMuted,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value:           state.model.signalLevel,
                minHeight:       2,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(
                  state.model.signalIsOn
                      ? AppColors.accent
                      : AppColors.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Identical implementation to TransmissionControlsWidget._LiveDot —
// kept local to this widget file to avoid coupling across features.
class _LiveDot extends StatefulWidget {
  final bool live;
  const _LiveDot({required this.live});

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (!widget.live) {
      return Container(
        width: 7, height: 7,
        decoration: const BoxDecoration(
          color: AppColors.textMuted, shape: BoxShape.circle),
      );
    }
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 7, height: 7,
        decoration: const BoxDecoration(
          color: AppColors.accent, shape: BoxShape.circle),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final bool         isScanning;
  final VoidCallback onTap;

  const _PrimaryButton({required this.isScanning, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isScanning
              ? const Color(0xFF1C2010)
              : AppColors.accent,
          borderRadius: BorderRadius.circular(12),
          border: isScanning
              ? Border.all(color: AppColors.accentBorder)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isScanning
                  ? Icons.stop_rounded
                  : Icons.radio_button_checked_rounded,
              size:  16,
              color: isScanning
                  ? AppColors.accent
                  : const Color(0xFF111111),
            ),
            const SizedBox(width: 6),
            Text(
              isScanning ? 'Stop' : 'Start Scanning',
              style: GoogleFonts.inter(
                fontSize:      13,
                fontWeight:    FontWeight.w600,
                color:         isScanning
                    ? AppColors.accent
                    : const Color(0xFF111111),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClearButton extends StatelessWidget {
  final bool          active;
  final VoidCallback? onTap;
  const _ClearButton({required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 50, height: 50,
        decoration: BoxDecoration(
          color:        active ? AppColors.errorRedDim   : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(
            color: active ? AppColors.errorRedBorder : AppColors.border),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          size:  18,
          color: active ? AppColors.errorRed : AppColors.textMuted,
        ),
      ),
    );
  }
}
