enum TransmissionMode { torch, beep, both }

extension TransmissionModeLabel on TransmissionMode {
  String get label {
    switch (this) {
      case TransmissionMode.torch: return 'Flashlight';
      case TransmissionMode.beep:  return 'Beep';
      case TransmissionMode.both:  return 'Combined';
    }
  }

  String get tag {
    switch (this) {
      case TransmissionMode.torch: return 'TORCH';
      case TransmissionMode.beep:  return 'AUDIO';
      case TransmissionMode.both:  return 'BOTH';
    }
  }
}
