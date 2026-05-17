import 'package:equatable/equatable.dart';
import '../models/transmission_mode.dart';
import '../models/active_letter_position.dart';

abstract class TransmitterEvent extends Equatable {
  const TransmitterEvent();
  @override
  List<Object?> get props => [];
}

class TextChanged extends TransmitterEvent {
  final String text;
  const TextChanged(this.text);
  @override List<Object?> get props => [text];
}

class ModeChanged extends TransmitterEvent {
  final TransmissionMode mode;
  const ModeChanged(this.mode);
  @override List<Object?> get props => [mode];
}

class SpeedChanged extends TransmitterEvent {
  final double speed;
  const SpeedChanged(this.speed);
  @override List<Object?> get props => [speed];
}

class TransmitStarted   extends TransmitterEvent { const TransmitStarted(); }
class TransmitPaused    extends TransmitterEvent { const TransmitPaused(); }
class TransmitResumed   extends TransmitterEvent { const TransmitResumed(); }
class TransmitCancelled extends TransmitterEvent { const TransmitCancelled(); }

class InternalProgressTicked extends TransmitterEvent {
  final int                  completed;
  final ActiveLetterPosition? position; // which letter is active right now
  const InternalProgressTicked(this.completed, this.position);
  @override List<Object?> get props => [completed, position];
}

class InternalTransmitDone extends TransmitterEvent {
  const InternalTransmitDone();
}
