// Represents a single letter and its morse code within a word
class MorseSymbol {
  final String character;
  final String code;       // e.g. ".-"
  final bool isValid;

  const MorseSymbol({
    required this.character,
    required this.code,
    required this.isValid,
  });
}

// Represents a word broken into MorseSymbols
class MorseWord {
  final List<MorseSymbol> symbols;

  const MorseWord(this.symbols);
}
