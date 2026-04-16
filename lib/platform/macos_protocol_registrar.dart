import 'protocol_registrar.dart';

class MacosProtocolRegistrar implements ProtocolRegistrar {
  @override
  Future<void> register() async {
    // No-op: macOS activates CFBundleURLSchemes from Info.plist at first launch.
  }
}
