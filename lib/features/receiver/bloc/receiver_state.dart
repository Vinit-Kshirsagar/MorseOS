import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import '../models/receiver_state_model.dart';

class ReceiverState extends Equatable {
  final ReceiverStateModel model;

  /// Nullable CameraController forwarded to the UI through state.
  /// The preview widget never imports CameraService directly.
  /// Null when status is idle or stopped.
  final CameraController? cameraController;

  const ReceiverState({
    required this.model,
    this.cameraController,
  });

  factory ReceiverState.initial() => const ReceiverState(
    model:            ReceiverStateModel(),
    cameraController: null,
  );

  ReceiverState copyWith({
    ReceiverStateModel? model,
    CameraController?   cameraController,
    bool                clearCamera = false,
  }) {
    return ReceiverState(
      model:            model            ?? this.model,
      cameraController: clearCamera
          ? null
          : (cameraController ?? this.cameraController),
    );
  }

  @override
  List<Object?> get props => [model, cameraController];
}
