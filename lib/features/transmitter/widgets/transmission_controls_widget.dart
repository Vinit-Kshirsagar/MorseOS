import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../bloc/transmitter_bloc.dart';
import '../bloc/transmitter_event.dart';
import '../bloc/transmitter_state.dart';
import '../models/transmitter_state_model.dart';

class TransmissionControlsWidget extends StatelessWidget {
  const TransmissionControlsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransmitterBloc, TransmitterState>(
      builder: (context, state) {
        final status   = state.model.status;
        final hasText  = state.model.inputText.trim().isNotEmpty;

        final isIdle         = status == TransmissionStatus.idle ||
                               status == TransmissionStatus.done;
        final isTransmitting = status == TransmissionStatus.transmitting;
        final isPaused       = status == TransmissionStatus.paused;
        final isActive       = isTransmitting || isPaused;

        return Column(
          children: [
            // Status strip
            _StatusStrip(state: state),
            const SizedBox(height: 10),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: _PrimaryButton(
                    isIdle:         isIdle,
                    isTransmitting: isTransmitting,
                    isPaused:       isPaused,
                    hasText:        hasText,
                    onTap: () {
                      final bloc = context.read<TransmitterBloc>();
                      if (isIdle)         bloc.add(const TransmitStarted());
                      else if (isTransmitting) bloc.add(const TransmitPaused());
                      else if (isPaused)  bloc.add(const TransmitResumed());
                    },
                  ),
                ),
                const SizedBox(width: 8),
                _CancelButton(
                  active: isActive,
                  onTap:  isActive
                      ? () => context
                          .read<TransmitterBloc>()
                          .add(const TransmitCancelled())
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

class _StatusStrip extends StatelessWidget {
  final TransmitterState state;
  const _StatusStrip({required this.state});

  String get _statusText {
    switch (state.model.status) {
      case TransmissionStatus.idle:         return 'READY';
      case TransmissionStatus.transmitting: return 'TX · TRANSMITTING';
      case TransmissionStatus.paused:       return 'PAUSED';
      case TransmissionStatus.done:         return 'DONE';
    }
  }

  bool get _isLive =>
      state.model.status == TransmissionStatus.transmitting;

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
            _statusText,
            style: GoogleFonts.jetBrainsMono(
              fontSize:   10,
              color:      _isLive ? AppColors.textSecondary : AppColors.textMuted,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value:           state.model.progress,
                minHeight:       2,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.live) {
      return Container(
        width:        7,
        height:       7,
        decoration:   const BoxDecoration(
          color:       AppColors.textMuted,
          shape:       BoxShape.circle,
        ),
      );
    }
    return FadeTransition(
      opacity: _anim,
      child:   Container(
        width:  7,
        height: 7,
        decoration: const BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final bool isIdle;
  final bool isTransmitting;
  final bool isPaused;
  final bool hasText;
  final VoidCallback? onTap;

  const _PrimaryButton({
    required this.isIdle,
    required this.isTransmitting,
    required this.isPaused,
    required this.hasText,
    this.onTap,
  });

  String get _label {
    if (isTransmitting) return 'Pause';
    if (isPaused)       return 'Resume';
    return 'Transmit';
  }

  IconData get _icon {
    if (isTransmitting) return Icons.pause_rounded;
    if (isPaused)       return Icons.play_arrow_rounded;
    return Icons.play_arrow_rounded;
  }

  Color get _bg {
    if (isPaused) return const Color(0xFF2A2719);
    return AppColors.accent;
  }

  Color get _fg {
    if (isPaused) return AppColors.accent;
    return const Color(0xFF111111);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = !isIdle || hasText;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color:        enabled ? _bg : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: isPaused
              ? Border.all(color: AppColors.accentBorder)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_icon, size: 16, color: enabled ? _fg : AppColors.textMuted),
            const SizedBox(width: 6),
            Text(
              _label,
              style: GoogleFonts.inter(
                fontSize:   13,
                fontWeight: FontWeight.w600,
                color:      enabled ? _fg : AppColors.textMuted,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  final bool         active;
  final VoidCallback? onTap;
  const _CancelButton({required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width:  50,
        height: 50,
        decoration: BoxDecoration(
          color:        active
              ? AppColors.errorRedDim
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? AppColors.errorRedBorder
                : AppColors.border,
          ),
        ),
        child: Icon(
          Icons.close_rounded,
          size:  18,
          color: active ? AppColors.errorRed : AppColors.textMuted,
        ),
      ),
    );
  }
}
