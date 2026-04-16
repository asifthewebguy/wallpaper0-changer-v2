import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper_changer/platform/protocol_registrar.dart';

void main() {
  test('StubProtocolRegistrar.register() completes without error', () async {
    final registrar = StubProtocolRegistrar();
    await expectLater(registrar.register(), completes);
  });
}
