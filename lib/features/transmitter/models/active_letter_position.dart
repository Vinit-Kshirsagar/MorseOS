import 'package:equatable/equatable.dart';

class ActiveLetterPosition extends Equatable {
  final int wordIndex;
  final int letterIndex;

  const ActiveLetterPosition({
    required this.wordIndex,
    required this.letterIndex,
  });

  @override
  List<Object?> get props => [wordIndex, letterIndex];
}
