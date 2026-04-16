import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper_changer/platform/macos_wallpaper_setter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('wallpaper_changer/wallpaper');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('set calls setWallpaper with path and succeeds on null result', () async {
    MethodCall? capturedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      capturedCall = call;
      return null; // null = success
    });

    final setter = MacosWallpaperSetter();
    await setter.set('/Users/user/photo.jpg');

    expect(capturedCall?.method, 'setWallpaper');
    expect(capturedCall?.arguments, '/Users/user/photo.jpg');
  });

  test('set throws PlatformException when channel returns error string', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            channel, (call) async => 'NSWorkspace setDesktopImageURL failed');

    final setter = MacosWallpaperSetter();
    await expectLater(
      setter.set('/bad/path.jpg'),
      throwsA(isA<PlatformException>()
          .having((e) => e.code, 'code', 'SET_FAILED')
          .having((e) => e.message, 'message',
              'NSWorkspace setDesktopImageURL failed')),
    );
  });

  test('set propagates PlatformException from channel', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(
          code: 'INVALID_ARGUMENT', message: 'Expected a String path');
    });

    final setter = MacosWallpaperSetter();
    await expectLater(
      setter.set('/some/path.jpg'),
      throwsA(isA<PlatformException>()
          .having((e) => e.code, 'code', 'INVALID_ARGUMENT')),
    );
  });

  test('set propagates NO_SCREEN PlatformException from channel', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(
          code: 'NO_SCREEN', message: 'No main screen available');
    });

    final setter = MacosWallpaperSetter();
    await expectLater(
      setter.set('/some/path.jpg'),
      throwsA(isA<PlatformException>()
          .having((e) => e.code, 'code', 'NO_SCREEN')),
    );
  });
}
