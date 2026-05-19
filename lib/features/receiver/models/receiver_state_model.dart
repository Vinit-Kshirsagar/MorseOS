enum ReceiverStatus {
  /// Camera is not open. Default on screen load.
  idle,

  /// Camera is open and actively analysing frames.
  scanning,

  /// Camera was scanning and has been stopped by the user.
  /// Decoded content is preserved for copy/review.
  stopped,
}

/// Immutable data class for all receiver runtime state.
/// Mirrors the TransmitterStateModel pattern exactly.
class ReceiverStateModel {
  final ReceiverStatus status;

  /// Dots/dashes accumulating for the current letter. e.g. ".-"
  final String currentMorseFragment;

  /// Letters assembled for the current word (word gap not yet detected).
  final String currentWord;

  /// Fully committed words (word gap confirmed after each).
  final List<String> committedWords;

  /// Normalised 0.0–1.0 brightness from the most recent frame.
  final double signalLevel;

  /// Whether the camera currently sees the signal as ON (bright).
  final bool signalIsOn;

  /// Human-readable status shown in the status strip.
  final String statusMessage;

  const ReceiverStateModel({
    this.status               = ReceiverStatus.idle,
    this.currentMorseFragment = '',
    this.currentWord          = '',
    this.committedWords       = const [],
    this.signalLevel          = 0.0,
    this.signalIsOn           = false,
    this.statusMessage        = 'READY',
  });

  /// Full decoded text: committed words + in-progress word.
  String get fullDecodedText {
    final parts = <String>[
      ...committedWords,
      if (currentWord.isNotEmpty) currentWord,
    ];
    return parts.join(' ');
  }

  bool get hasContent =>
      committedWords.isNotEmpty || currentWord.isNotEmpty;

  ReceiverStateModel copyWith({
    ReceiverStatus? status,
    String?         currentMorseFragment,
    String?         currentWord,
    List<String>?   committedWords,
    double?         signalLevel,
    bool?           signalIsOn,
    String?         statusMessage,
  }) {
    return ReceiverStateModel(
      status:               status               ?? this.status,
      currentMorseFragment: currentMorseFragment ?? this.currentMorseFragment,
      currentWord:          currentWord          ?? this.currentWord,
      committedWords:       committedWords        ?? this.committedWords,
      signalLevel:          signalLevel          ?? this.signalLevel,
      signalIsOn:           signalIsOn           ?? this.signalIsOn,
      statusMessage:        statusMessage        ?? this.statusMessage,
    );
  }
}
