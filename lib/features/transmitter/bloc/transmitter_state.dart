import 'package:equatable/equatable.dart';
import '../models/transmission_mode.dart';
import '../models/transmitter_state_model.dart';
import '../models/morse_symbol.dart';
import '../models/active_letter_position.dart';

class TransmitterState extends Equatable {
  final TransmitterStateModel      model;
  final TransmissionMode            mode;
  final List<MorseWord>             morseWords;
  // Parallel list to the signal list — maps signal index to letter position.
  // Stored here so the BLoC can look up position during progress callbacks.
  final List<ActiveLetterPosition?> positionMap;

  const TransmitterState({
    required this.model,
    required this.mode,
    required this.morseWords,
    this.positionMap = const [],
  });

  factory TransmitterState.initial() => const TransmitterState(
    model:      TransmitterStateModel(),
    mode:       TransmissionMode.torch,
    morseWords: [],
    positionMap: [],
  );

  TransmitterState copyWith({
    TransmitterStateModel?      model,
    TransmissionMode?            mode,
    List<MorseWord>?             morseWords,
    List<ActiveLetterPosition?>? positionMap,
  }) {
    return TransmitterState(
      model:       model       ?? this.model,
      mode:        mode        ?? this.mode,
      morseWords:  morseWords  ?? this.morseWords,
      positionMap: positionMap ?? this.positionMap,
    );
  }

  @override
  List<Object?> get props => [model, mode, morseWords, positionMap];
}
