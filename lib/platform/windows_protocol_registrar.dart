import 'package:flutter/services.dart';
import 'protocol_registrar.dart';

class WindowsProtocolRegistrar implements ProtocolRegistrar {
  static const _channel = MethodChannel('wallpaper_changer/protocol');

  @override
  Future<void> register() async {
    final String? error =
        await _channel.invokeMethod<String>('register');
    if (error != null) {
      throw PlatformException(code: 'REG_FAILED', message: error);
    }
  }
}
