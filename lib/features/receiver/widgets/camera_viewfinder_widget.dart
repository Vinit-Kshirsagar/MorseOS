import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/receiver_bloc.dart';
import '../bloc/receiver_state.dart';
import '../models/receiver_state_model.dart';

class CameraViewfinderWidget extends StatelessWidget {
  const CameraViewfinderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReceiverBloc, ReceiverState>(
      buildWhen: (prev, curr) =>
          prev.cameraController != curr.cameraController ||
          prev.model.signalIsOn != curr.model.signalIsOn ||
          prev.model.signalLevel != curr.model.signalLevel ||
          prev.model.status != curr.model.status,
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color:        AppColors.surfaceDeep,
            borderRadius: BorderRadius.circular(12),
            border:       Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.hardEdge,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (state.cameraController != null &&
                    state.cameraController!.value.isInitialized)
                  CameraPreview(state.cameraController!)
                else
                  _Placeholder(status: state.model.status),

                if (state.model.status == ReceiverStatus.scanning)
                  _ReticleOverlay(signalIsOn: state.model.signalIsOn),

                Positioned(
                  left: 0, right: 0, bottom: 0,
                  child: _SignalBar(level: state.model.signalLevel),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  final ReceiverStatus status;
  const _Placeholder({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = status == ReceiverStatus.scanning
        ? 'INITIALISING...'
        : 'CAMERA INACTIVE';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam_off_rounded, size: 32,
              color: AppColors.textMuted),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ReticleOverlay extends StatelessWidget {
  final bool signalIsOn;
  const _ReticleOverlay({required this.signalIsOn});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 64, height: 64,
        decoration: BoxDecoration(
          border: Border.all(
            color: signalIsOn
                ? AppColors.accent.withOpacity(0.9)
                : AppColors.accent.withOpacity(0.25),
            width: signalIsOn ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(6),
          color: signalIsOn
              ? AppColors.accent.withOpacity(0.08)
              : Colors.transparent,
        ),
      ),
    );
  }
}

class _SignalBar extends StatelessWidget {
  final double level;
  const _SignalBar({required this.level});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 3,
      child: Stack(
        children: [
          Container(color: AppColors.surfaceDeep.withOpacity(0.6)),
          FractionallySizedBox(
            alignment:   Alignment.centerLeft,
            widthFactor: level.clamp(0.0, 1.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 60),
              color: Color.lerp(AppColors.textMuted, AppColors.accent, level),
            ),
          ),
        ],
      ),
    );
  }
}
