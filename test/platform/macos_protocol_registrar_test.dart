import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper_changer/platform/macos_protocol_registrar.dart';
import 'package:wallpaper_changer/platform/protocol_registrar.dart';

void main() {
  test('register completes without error', () async {
    final registrar = MacosProtocolRegistrar();
    await expectLater(registrar.register(), completes);
  });

  test('MacosProtocolRegistrar implements ProtocolRegistrar', () {
    expect(MacosProtocolRegistrar(), isA<ProtocolRegistrar>());
  });
}
