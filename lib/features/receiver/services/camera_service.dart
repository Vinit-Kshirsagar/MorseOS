import 'package:camera/camera.dart';

typedef FrameCallback = void Function({
  required bool   isOn,
  required double brightness,
});

typedef TransitionCallback = void Function({
  required bool wasOn,
  required int  durationMs,
});

/// Hardware wrapper for the camera package.
/// Follows the TorchService pattern: pure wrapper, all exceptions silently
/// caught, callback-based interface. The BLoC is the only caller.
///
/// Brightness detection uses the YUV420 Y-plane (luminance only — no colour
/// processing needed). An adaptive hysteresis baseline prevents flickering.
class CameraService {
  CameraController? _controller;

  // ── Frame analysis configuration ──────────────────────────────────────────

  /// Process every Nth frame. Camera runs ~30fps; N=3 → ~10 samples/sec.
  /// Sufficient for Morse at 0.25× (dot=480ms ≈ 4–5 samples per dot).
  static const int _frameSkip = 3;
  int _frameCount = 0;

  /// Adaptive ambient baseline (0–255). Tracks background light slowly.
  double _baseline = 128.0;

  /// Hysteresis band. Signal must exceed baseline+band to flip ON,
  /// and drop below baseline−band to flip OFF. Prevents rapid toggling.
  static const double _hysteresisBand = 22.0;

  /// EMA alpha for baseline update (lower = slower adaptation).
  /// Only updated during OFF frames so the ON signal cannot drag up the baseline.
  static const double _emaAlpha = 0.04;

  /// Central crop for brightness sampling — focuses on the held phone's flash.
  static const int _cropSize = 80;

  // ── Transition tracking ────────────────────────────────────────────────────

  bool? _lastIsOn;
  int   _stateStartMs = 0;

  // ── Public API ─────────────────────────────────────────────────────────────

  CameraController? get controller => _controller;

  bool get isScanning =>
      _controller != null && _controller!.value.isStreamingImages;

  /// Opens the rear camera and begins the image stream.
  /// Returns true on success, false on any failure.
  Future<bool> startScanning({
    required FrameCallback      onFrame,
    required TransitionCallback onTransition,
  }) async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return false;

      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        back,
        ResolutionPreset.low,
        enableAudio:      false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();

      _frameCount   = 0;
      _baseline     = 128.0;
      _lastIsOn     = null;
      _stateStartMs = DateTime.now().millisecondsSinceEpoch;

      await _controller!.startImageStream((CameraImage image) {
        _processFrame(image, onFrame: onFrame, onTransition: onTransition);
      });

      return true;
    } catch (_) {
      await _cleanup();
      return false;
    }
  }

  /// Stops the image stream and releases the camera. Safe to call multiple times.
  Future<void> stopScanning() async {
    try {
      if (_controller != null &&
          _controller!.value.isInitialized &&
          _controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }
    } catch (_) {}
    await _cleanup();
  }

  Future<void> dispose() async => stopScanning();

  // ── Frame processing ───────────────────────────────────────────────────────

  void _processFrame(
    CameraImage image, {
    required FrameCallback      onFrame,
    required TransitionCallback onTransition,
  }) {
    _frameCount++;
    if (_frameCount % _frameSkip != 0) return;

    try {
      final brightness = _extractBrightness(image);

      // Update baseline only during OFF frames (adaptive to ambient light).
      if (_lastIsOn == null || !_lastIsOn!) {
        _baseline = _baseline * (1 - _emaAlpha) + brightness * _emaAlpha;
      }

      // Hysteresis: separate thresholds for ON and OFF transitions.
      final bool isOn;
      if (_lastIsOn == null || !_lastIsOn!) {
        isOn = brightness > _baseline + _hysteresisBand;
      } else {
        isOn = brightness > _baseline - _hysteresisBand;
      }

      final normalised = (brightness / 255.0).clamp(0.0, 1.0);
      onFrame(isOn: isOn, brightness: normalised);

      // Detect state transitions and measure duration.
      final now = DateTime.now().millisecondsSinceEpoch;
      if (_lastIsOn != null && isOn != _lastIsOn) {
        final duration = now - _stateStartMs;
        if (duration > 0) {
          onTransition(wasOn: _lastIsOn!, durationMs: duration);
        }
        _stateStartMs = now;
      } else if (_lastIsOn == null) {
        _stateStartMs = now;
      }

      _lastIsOn = isOn;
    } catch (_) {
      // Never propagate frame errors to the BLoC.
    }
  }

  /// Average luminance of the central [_cropSize]×[_cropSize] Y-plane region.
  double _extractBrightness(CameraImage image) {
    final yPlane = image.planes[0];
    final bytes  = yPlane.bytes;
    final width  = image.width;
    final height = image.height;

    final startX = ((width  - _cropSize) ~/ 2).clamp(0, width  - 1);
    final startY = ((height - _cropSize) ~/ 2).clamp(0, height - 1);
    final endX   = (startX + _cropSize).clamp(0, width);
    final endY   = (startY + _cropSize).clamp(0, height);

    int sum   = 0;
    int count = 0;

    for (int y = startY; y < endY; y++) {
      for (int x = startX; x < endX; x++) {
        final idx = y * yPlane.bytesPerRow + x;
        if (idx < bytes.length) {
          sum  += bytes[idx] & 0xFF;
          count++;
        }
      }
    }

    return count > 0 ? sum / count : 0.0;
  }

  Future<void> _cleanup() async {
    try {
      await _controller?.dispose();
    } catch (_) {}
    _controller = null;
  }
}
