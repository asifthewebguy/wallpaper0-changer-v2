abstract interface class ProtocolRegistrar {
  /// Registers the custom URL scheme (e.g. wallpaper0-changer://) with the OS.
  /// Platform-channel implementation added in Plan 3.
  Future<void> register();
}

class StubProtocolRegistrar implements ProtocolRegistrar {
  @override
  Future<void> register() async {
    // No-op stub — real implementation in Plan 3 (platform channels).
  }
}
