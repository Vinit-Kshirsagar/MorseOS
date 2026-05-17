import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/transmission_mode.dart';
import 'torch_service.dart';
import 'audio_service.dart';

typedef SignalProgressCallback = void Function(int completed);

class TransmissionEngine {
  final TorchService _torch;
  final AudioService _audio;

  TransmissionEngine(this._torch, this._audio);

  bool _cancelled = false;
  bool _paused    = false;
  Completer<void>? _pauseCompleter;

  void pause()  {
    _paused = true;
    _pauseCompleter = Completer<void>();
  }

  void resume() {
    _paused = false;
    _pauseCompleter?.complete();
    _pauseCompleter = null;
  }

  void cancel() {
    _cancelled = true;
    resume(); // unblock any awaiting pause
  }

  Future<void> transmit({
    required List<(bool on, int ms)> signals,
    required TransmissionMode mode,
    required SignalProgressCallback onProgress,
  }) async {
    _cancelled = false;
    _paused    = false;

    for (int i = 0; i < signals.length; i++) {
      if (_cancelled) break;

      // Wait if paused
      while (_paused) {
        await _pauseCompleter!.future;
        if (_cancelled) break;
      }
      if (_cancelled) break;

      final (on, ms) = signals[i];

      if (on) {
        await _activate(mode, ms);
      } else {
        await _deactivate(mode);
        await _sleep(ms);
      }

      onProgress(i + 1);
    }

    // Always ensure hardware is OFF after done or cancelled
    await _deactivate(mode);
  }

  Future<void> _activate(TransmissionMode mode, int ms) async {
    switch (mode) {
      case TransmissionMode.torch:
        await _torch.on();
        await _sleep(ms);
        await _torch.off();
      case TransmissionMode.beep:
        await _audio.beep(ms);
        await Future.delayed(Duration(milliseconds: ms));
      case TransmissionMode.both:
        await Future.wait([
          Future(() async {
            await _torch.on();
            await _sleep(ms);
            await _torch.off();
          }),
          _audio.beep(ms).then((_) =>
              Future.delayed(Duration(milliseconds: ms))),
        ]);
    }
  }

  Future<void> _deactivate(TransmissionMode mode) async {
    if (mode == TransmissionMode.torch || mode == TransmissionMode.both) {
      await _torch.off();
    }
    if (mode == TransmissionMode.beep || mode == TransmissionMode.both) {
      await _audio.stop();
    }
  }

  Future<void> _sleep(int ms) =>
      Future.delayed(Duration(milliseconds: ms));
}
