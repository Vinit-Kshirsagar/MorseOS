import 'package:equatable/equatable.dart';

abstract class ReceiverEvent extends Equatable {
  const ReceiverEvent();

  @override
  List<Object?> get props => [];
}

// ── User-dispatched ──────────────────────────────────────────────────────────

class ScanStarted extends ReceiverEvent {
  const ScanStarted();
}

class ScanStopped extends ReceiverEvent {
  const ScanStopped();
}

class DecodingReset extends ReceiverEvent {
  const DecodingReset();
}

// ── Internal — dispatched from CameraService / MorseDecoder callbacks ────────
// Named with Internal* prefix to mirror TransmitterBloc convention.

class InternalFrameAnalysed extends ReceiverEvent {
  final bool   isOn;
  final double brightness;

  const InternalFrameAnalysed({
    required this.isOn,
    required this.brightness,
  });

  @override
  List<Object?> get props => [isOn, brightness];
}

class InternalSymbolAppended extends ReceiverEvent {
  final String fragment;
  const InternalSymbolAppended(this.fragment);

  @override
  List<Object?> get props => [fragment];
}

class InternalLetterCommitted extends ReceiverEvent {
  final String letter;
  const InternalLetterCommitted(this.letter);

  @override
  List<Object?> get props => [letter];
}

class InternalWordCommitted extends ReceiverEvent {
  const InternalWordCommitted();
}

/// Word gap detected AND an implicit letter was committed simultaneously.
/// Dispatch this instead of InternalLetterCommitted + InternalWordCommitted
/// when the decoder returns WordCommittedWithLetter.
class InternalWordCommittedWithLetter extends ReceiverEvent {
  final String letter;
  const InternalWordCommittedWithLetter(this.letter);

  @override
  List<Object?> get props => [letter];
}

class InternalCameraError extends ReceiverEvent {
  final String message;
  const InternalCameraError(this.message);

  @override
  List<Object?> get props => [message];
}
