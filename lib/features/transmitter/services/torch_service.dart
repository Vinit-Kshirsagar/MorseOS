import 'package:torch_light/torch_light.dart';

class TorchService {
  Future<bool> isAvailable() async {
    try {
      return await TorchLight.isTorchAvailable();
    } catch (_) {
      return false;
    }
  }

  Future<void> on() async {
    try {
      await TorchLight.enableTorch();
    } catch (_) {}
  }

  Future<void> off() async {
    try {
      await TorchLight.disableTorch();
    } catch (_) {}
  }
}
