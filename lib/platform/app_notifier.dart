abstract interface class AppNotifier {
  Future<void> show(String title, {String? body});
}

class StubAppNotifier implements AppNotifier {
  @override
  Future<void> show(String title, {String? body}) async {
    // No-op stub — real implementation in Plan 3 (platform channels).
  }
}
