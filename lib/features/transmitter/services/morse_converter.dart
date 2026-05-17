import '../../../core/constants/morse_constants.dart';
import '../models/morse_symbol.dart';
import '../models/active_letter_position.dart';

class MorseConverter {
  MorseConverter._();

  static bool isValid(String text) =>
      RegExp(r'^[A-Z0-9 ]*$').hasMatch(text.toUpperCase());

  static List<MorseWord> toWords(String text) {
    final upper  = text.toUpperCase();
    final chunks = upper.split(' ');
    final result = <MorseWord>[];
    for (final chunk in chunks) {
      if (chunk.isEmpty) continue;
      final symbols = chunk.characters.map((ch) {
        final code    = kMorseMap[ch];
        final isValid = code != null;
        return MorseSymbol(
          character: ch,
          code:      code ?? '?',
          isValid:   isValid,
        );
      }).toList();
      result.add(MorseWord(symbols));
    }
    return result;
  }

  /// Returns both the signal list and a position map.
  /// positionMap[i] = the ActiveLetterPosition that signal i belongs to.
  /// Gap signals between letters/words carry the position of the PRECEDING letter.
  static ({
    List<(bool on, int ms)> signals,
    List<ActiveLetterPosition?> positionMap,
  }) toSignals(String text, double speed) {
    final upper   = text.toUpperCase();
    final signals = <(bool, int)>[];
    final positionMap = <ActiveLetterPosition?>[];
    final words   = upper.split(' ');

    final dot       = MorseTimings.scaled(MorseTimings.dot,       speed);
    final dash      = MorseTimings.scaled(MorseTimings.dash,      speed);
    final symbolGap = MorseTimings.scaled(MorseTimings.symbolGap, speed);
    final letterGap = MorseTimings.scaled(MorseTimings.letterGap, speed);
    final wordGap   = MorseTimings.scaled(MorseTimings.wordGap,   speed);

    int wordIndex = 0;

    for (int wi = 0; wi < words.length; wi++) {
      final word = words[wi];
      if (word.isEmpty) continue;

      int letterIndex = 0;

      for (int li = 0; li < word.length; li++) {
        final ch   = word[li];
        final code = kMorseMap[ch];
        if (code == null) continue;

        final pos = ActiveLetterPosition(
          wordIndex:   wordIndex,
          letterIndex: letterIndex,
        );

        for (int si = 0; si < code.length; si++) {
          final sym = code[si];
          final dur = sym == '.' ? dot : dash;
          signals.add((true, dur));
          positionMap.add(pos);                     // ON signal → this letter

          if (si < code.length - 1) {
            signals.add((false, symbolGap));
            positionMap.add(pos);                   // symbol gap → still this letter
          }
        }

        if (li < word.length - 1) {
          signals.add((false, letterGap));
          positionMap.add(pos);                     // letter gap → preceding letter
        }

        letterIndex++;
      }

      if (wi < words.length - 1) {
        signals.add((false, wordGap));
        positionMap.add(null);                      // word gap → no letter highlighted
      }

      wordIndex++;
    }

    return (signals: signals, positionMap: positionMap);
  }
}

extension on String {
  Iterable<String> get characters sync* {
    for (final rune in runes) yield String.fromCharCode(rune);
  }
}
