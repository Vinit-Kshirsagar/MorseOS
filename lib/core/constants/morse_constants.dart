class MorseTimings {
  MorseTimings._();

  // Base timings at 1.0x speed (ms)
  static const int dot       = 120;
  static const int dash      = 400;
  static const int symbolGap = 120;
  static const int letterGap = 360;
  static const int wordGap   = 840;

  // Slider range
  static const double minSpeed =  0.25;
  static const double maxSpeed =  3.0;
  static const double defSpeed =  1.0;

  // Apply multiplier — higher speed = shorter durations
  static int scaled(int base, double speed) =>
      (base / speed).round().clamp(20, 9999);
}

const Map<String, String> kMorseMap = {
  'A': '.-',   'B': '-...', 'C': '-.-.',
  'D': '-..',  'E': '.',    'F': '..-.',
  'G': '--.',  'H': '....', 'I': '..',
  'J': '.---', 'K': '-.-',  'L': '.-..',
  'M': '--',   'N': '-.',   'O': '---',
  'P': '.--.',  'Q': '--.-', 'R': '.-.',
  'S': '...',  'T': '-',    'U': '..-',
  'V': '...-', 'W': '.--',  'X': '-..-',
  'Y': '-.--', 'Z': '--..',
  '0': '-----', '1': '.----', '2': '..---',
  '3': '...--', '4': '....-', '5': '.....',
  '6': '-....', '7': '--...', '8': '---..',
  '9': '----.',
};
