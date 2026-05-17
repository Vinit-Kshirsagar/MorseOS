import '../../../core/constants/morse_constants.dart';
import 'active_letter_position.dart';

enum TransmissionStatus { idle, transmitting, paused, done }

class TransmitterStateModel {
  final String               inputText;
  final bool                 hasInvalidChar;
  final TransmissionStatus   status;
  final int                  totalSignals;
  final int                  completedSignals;
  final double               speed;
  final ActiveLetterPosition? activePosition; // null when idle/done

  const TransmitterStateModel({
    this.inputText         = '',
    this.hasInvalidChar    = false,
    this.status            = TransmissionStatus.idle,
    this.totalSignals      = 0,
    this.completedSignals  = 0,
    this.speed             = MorseTimings.defSpeed,
    this.activePosition,
  });

  double get progress =>
      totalSignals == 0 ? 0.0 : completedSignals / totalSignals;

  int get estimatedMs {
    final letters = inputText.replaceAll(' ', '').length;
    final words   = inputText.trim().isEmpty
        ? 0
        : inputText.trim().split(RegExp(r'\s+')).length;
    final base = (letters * 800) + ((words - 1).clamp(0, 999) * 840);
    return (base / speed).round();
  }

  TransmitterStateModel copyWith({
    String?               inputText,
    bool?                 hasInvalidChar,
    TransmissionStatus?   status,
    int?                  totalSignals,
    int?                  completedSignals,
    double?               speed,
    ActiveLetterPosition? activePosition,
    bool                  clearActivePosition = false,
  }) {
    return TransmitterStateModel(
      inputText:        inputText        ?? this.inputText,
      hasInvalidChar:   hasInvalidChar   ?? this.hasInvalidChar,
      status:           status           ?? this.status,
      totalSignals:     totalSignals     ?? this.totalSignals,
      completedSignals: completedSignals ?? this.completedSignals,
      speed:            speed            ?? this.speed,
      activePosition:   clearActivePosition
          ? null
          : (activePosition ?? this.activePosition),
    );
  }
}
