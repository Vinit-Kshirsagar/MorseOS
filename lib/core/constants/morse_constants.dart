class MorseTimings {
  MorseTimings._();

  // Base timings at 1.0x speed (ms)
  static const int dot       = 120;
  static const int dash      = 400;
  static const int symbolGap = 120;
  static const int letterGap = 360;
  static const int wordGap   = 840;

  // Slider range
  static const double minSpeed = 0.25;
  static const double maxSpeed = 3.0;
  static const double defSpeed = 1.0;

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

/// Reverse lookup: Morse code string → character.
/// e.g. kMorseToChar['.-'] == 'A'
///
/// Defined explicitly (not via map-literal-from-kMorseMap) because const
/// map comprehensions are not supported in Dart. Values mirror kMorseMap exactly.
const Map<String, String> kMorseToChar = {
  '.-':    'A', '-...':  'B', '-.-.':  'C',
  '-..':   'D', '.':     'E', '..-.':  'F',
  '--.':   'G', '....':  'H', '..':    'I',
  '.---':  'J', '-.-':   'K', '.-..':  'L',
  '--':    'M', '-.':    'N', '---':   'O',
  '.--.':  'P', '--.-':  'Q', '.-.':   'R',
  '...':   'S', '-':     'T', '..-':   'U',
  '...-':  'V', '.--':   'W', '-..-':  'X',
  '-.--':  'Y', '--..':  'Z',
  '-----': '0', '.----': '1', '..---': '2',
  '...--': '3', '....-': '4', '.....': '5',
  '-....': '6', '--...': '7', '---..': '8',
  '----.': '9',
};

/// Timing thresholds for the receiver decoder state machine.
///
/// The decoder is adaptive — these are the initial values at 1x speed.
/// [dotDashBoundary] is recalibrated after the first confirmed dot, making
/// the decoder self-tuning across all sender speeds (0.25x–3.0x).
class MorseDecoderThresholds {
  MorseDecoderThresholds._();

  /// Initial dot/dash boundary (ms). Midpoint of 1x dot(120ms) and dash(400ms).
  static const int dotDashBoundary = 260;
}
