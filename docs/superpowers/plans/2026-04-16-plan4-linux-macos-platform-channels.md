# Plan 4 — Linux + macOS Platform Channels

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace stub `WallpaperSetter` and `ProtocolRegistrar` implementations with real Linux (Process.run) and macOS (Swift method channel / Info.plist) ones, and wire `LocalNotifierAppNotifier` on all three platforms.

**Architecture:** Linux implementations call system tools (`gsettings`, `plasma-apply-wallpaperimage`, `feh`, `xdg-mime`) via `Process.run` with injectable `ProcessRunner` for testability. macOS wallpaper uses a Swift method channel plugin wrapping `NSWorkspace.shared.setDesktopImageURL`; macOS protocol registration is static via `Info.plist`. `providers.dart` is extended from `isWindows`-only to tri-platform conditionals.

**Tech Stack:** Dart `dart:io` (`Process.run`, `File`, `Platform`), Flutter `MethodChannel`, Swift `NSWorkspace`, `mocktail`, `flutter_test`

---

## File Map

| File | Action | Purpose |
|---|---|---|
| `lib/platform/linux_wallpaper_setter.dart` | Create | `LinuxWallpaperSetter` — gsettings / KDE / feh via Process.run |
| `lib/platform/linux_protocol_registrar.dart` | Create | `LinuxProtocolRegistrar` — .desktop file + xdg-mime |
| `lib/platform/macos_wallpaper_setter.dart` | Create | `MacosWallpaperSetter` — MethodChannel wrapper |
| `lib/platform/macos_protocol_registrar.dart` | Create | `MacosProtocolRegistrar` — no-op (Info.plist handles it) |
| `macos/Runner/WallpaperPlugin.swift` | Create | Swift plugin: NSWorkspace setDesktopImageURL |
| `macos/Runner/MainFlutterWindow.swift` | Modify | Register WallpaperPlugin after RegisterGeneratedPlugins |
| `macos/Runner/Info.plist` | Modify | Add CFBundleURLTypes for wallpaper0-changer scheme |
| `lib/providers.dart` | Modify | Extend to isLinux/isMacOS; AppNotifier always LocalNotifierAppNotifier |
| `lib/main.dart` | Modify | Call register() on Linux too |
| `test/platform/linux_wallpaper_setter_test.dart` | Create | Unit tests with injected ProcessRunner |
| `test/platform/linux_protocol_registrar_test.dart` | Create | Unit tests with injected ProcessRunner + FileWriter |
| `test/platform/macos_wallpaper_setter_test.dart` | Create | Unit tests with mocked MethodChannel |
| `test/platform/macos_protocol_registrar_test.dart` | Create | Single test: register() completes |

---

## Task 1: LinuxWallpaperSetter

**Files:**
- Create: `lib/platform/linux_wallpaper_setter.dart`
- Create: `test/platform/linux_wallpaper_setter_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/platform/linux_wallpaper_setter_test.dart`:

```dart
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper_changer/platform/linux_wallpaper_setter.dart';

void main() {
  group('LinuxWallpaperSetter', () {
    test('GNOME: calls gsettings for picture-uri and picture-uri-dark', () async {
      final calls = <List<String>>[];
      final setter = LinuxWallpaperSetter(
        processRunner: (exe, args) async {
          calls.add([exe, ...args]);
          return ProcessResult(0, 0, '', '');
        },
        environment: {'XDG_CURRENT_DESKTOP': 'GNOME'},
      );

      await setter.set('/home/user/photo.jpg');

      expect(calls, hasLength(2));
      expect(calls[0], [
        'gsettings', 'set',
        'org.gnome.desktop.background', 'picture-uri',
        'file:///home/user/photo.jpg',
      ]);
      expect(calls[1], [
        'gsettings', 'set',
        'org.gnome.desktop.background', 'picture-uri-dark',
        'file:///home/user/photo.jpg',
      ]);
    });

    test('ubuntu:GNOME variant is treated as GNOME', () async {
      final calls = <List<String>>[];
      final setter = LinuxWallpaperSetter(
        processRunner: (exe, args) async {
          calls.add([exe, ...args]);
          return ProcessResult(0, 0, '', '');
        },
        environment: {'XDG_CURRENT_DESKTOP': 'ubuntu:GNOME'},
      );

      await setter.set('/home/user/photo.jpg');

      expect(calls.first.first, 'gsettings');
    });

    test('KDE: calls plasma-apply-wallpaperimage', () async {
      final calls = <List<String>>[];
      final setter = LinuxWallpaperSetter(
        processRunner: (exe, args) async {
          calls.add([exe, ...args]);
          return ProcessResult(0, 0, '', '');
        },
        environment: {'XDG_CURRENT_DESKTOP': 'KDE'},
      );

      await setter.set('/home/user/photo.jpg');

      expect(calls, hasLength(1));
      expect(calls[0], ['plasma-apply-wallpaperimage', '/home/user/photo.jpg']);
    });

    test('unknown DE: falls back to feh --bg-scale', () async {
      final calls = <List<String>>[];
      final setter = LinuxWallpaperSetter(
        processRunner: (exe, args) async {
          calls.add([exe, ...args]);
          return ProcessResult(0, 0, '', '');
        },
        environment: {'XDG_CURRENT_DESKTOP': 'XFCE'},
      );

      await setter.set('/home/user/photo.jpg');

      expect(calls, hasLength(1));
      expect(calls[0], ['feh', '--bg-scale', '/home/user/photo.jpg']);
    });

    test('missing XDG_CURRENT_DESKTOP: falls back to feh', () async {
      final calls = <List<String>>[];
      final setter = LinuxWallpaperSetter(
        processRunner: (exe, args) async {
          calls.add([exe, ...args]);
          return ProcessResult(0, 0, '', '');
        },
        environment: {},
      );

      await setter.set('/home/user/photo.jpg');

      expect(calls.first.first, 'feh');
    });

    test('non-zero exit throws PlatformException with SET_FAILED code', () async {
      final setter = LinuxWallpaperSetter(
        processRunner: (exe, args) async =>
            ProcessResult(0, 1, '', 'gsettings: command not found'),
        environment: {'XDG_CURRENT_DESKTOP': 'GNOME'},
      );

      await expectLater(
        setter.set('/home/user/photo.jpg'),
        throwsA(isA<PlatformException>()
            .having((e) => e.code, 'code', 'SET_FAILED')
            .having((e) => e.message, 'message', 'gsettings: command not found')),
      );
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```
flutter test test/platform/linux_wallpaper_setter_test.dart
```

Expected: FAIL — `linux_wallpaper_setter.dart` doesn't exist yet.

- [ ] **Step 3: Implement LinuxWallpaperSetter**

Create `lib/platform/linux_wallpaper_setter.dart`:

```dart
import 'dart:io';
import 'package:flutter/services.dart';
import 'wallpaper_setter.dart';

typedef ProcessRunner = Future<ProcessResult> Function(
    String executable, List<String> arguments);

class LinuxWallpaperSetter implements WallpaperSetter {
  LinuxWallpaperSetter({
    ProcessRunner? processRunner,
    Map<String, String>? environment,
  })  : _run = processRunner ?? Process.run,
        _environment = environment ?? Platform.environment;

  final ProcessRunner _run;
  final Map<String, String> _environment;

  @override
  Future<void> set(String localFilePath) async {
    final de = (_environment['XDG_CURRENT_DESKTOP'] ?? '').toUpperCase();

    if (de.contains('GNOME') || de.contains('UBUNTU')) {
      await _gnomeSet(localFilePath);
    } else if (de.contains('KDE')) {
      await _kdeSet(localFilePath);
    } else {
      await _fehSet(localFilePath);
    }
  }

  Future<void> _gnomeSet(String path) async {
    final uri = 'file://$path';
    for (final key in ['picture-uri', 'picture-uri-dark']) {
      final result = await _run('gsettings', [
        'set', 'org.gnome.desktop.background', key, uri,
      ]);
      if (result.exitCode != 0) {
        throw PlatformException(
          code: 'SET_FAILED',
          message: result.stderr as String,
        );
      }
    }
  }

  Future<void> _kdeSet(String path) async {
    final result = await _run('plasma-apply-wallpaperimage', [path]);
    if (result.exitCode != 0) {
      throw PlatformException(
        code: 'SET_FAILED',
        message: result.stderr as String,
      );
    }
  }

  Future<void> _fehSet(String path) async {
    final result = await _run('feh', ['--bg-scale', path]);
    if (result.exitCode != 0) {
      throw PlatformException(
        code: 'SET_FAILED',
        message: result.stderr as String,
      );
    }
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```
flutter test test/platform/linux_wallpaper_setter_test.dart
```

Expected: All 6 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/platform/linux_wallpaper_setter.dart test/platform/linux_wallpaper_setter_test.dart
git commit -m "feat: LinuxWallpaperSetter — gsettings/KDE/feh via Process.run"
```

---

## Task 2: LinuxProtocolRegistrar

**Files:**
- Create: `lib/platform/linux_protocol_registrar.dart`
- Create: `test/platform/linux_protocol_registrar_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/platform/linux_protocol_registrar_test.dart`:

```dart
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper_changer/platform/linux_protocol_registrar.dart';

void main() {
  group('LinuxProtocolRegistrar', () {
    test('writes .desktop file with correct content', () async {
      String? writtenPath;
      String? writtenContent;

      final registrar = LinuxProtocolRegistrar(
        processRunner: (exe, args) async => ProcessResult(0, 0, '', ''),
        fileWriter: (path, content) async {
          writtenPath = path;
          writtenContent = content;
        },
        environment: {'HOME': '/home/testuser'},
        resolvedExecutable: '/usr/bin/wallpaper_changer',
      );

      await registrar.register();

      expect(writtenPath,
          '/home/testuser/.local/share/applications/wallpaper0-changer.desktop');
      expect(writtenContent, contains('Exec=/usr/bin/wallpaper_changer %u'));
      expect(writtenContent,
          contains('MimeType=x-scheme-handler/wallpaper0-changer;'));
      expect(writtenContent, contains('[Desktop Entry]'));
    });

    test('calls xdg-mime default with correct args', () async {
      final calls = <List<String>>[];

      final registrar = LinuxProtocolRegistrar(
        processRunner: (exe, args) async {
          calls.add([exe, ...args]);
          return ProcessResult(0, 0, '', '');
        },
        fileWriter: (path, content) async {},
        environment: {'HOME': '/home/testuser'},
        resolvedExecutable: '/usr/bin/wallpaper_changer',
      );

      await registrar.register();

      final mimeCall = calls.firstWhere((c) => c.first == 'xdg-mime');
      expect(mimeCall, [
        'xdg-mime',
        'default',
        'wallpaper0-changer.desktop',
        'x-scheme-handler/wallpaper0-changer',
      ]);
    });

    test('xdg-mime non-zero exit throws PlatformException with REG_FAILED', () async {
      final registrar = LinuxProtocolRegistrar(
        processRunner: (exe, args) async {
          if (exe == 'xdg-mime') {
            return ProcessResult(0, 1, '', 'xdg-mime: not found');
          }
          return ProcessResult(0, 0, '', '');
        },
        fileWriter: (path, content) async {},
        environment: {'HOME': '/home/testuser'},
        resolvedExecutable: '/usr/bin/wallpaper_changer',
      );

      await expectLater(
        registrar.register(),
        throwsA(isA<PlatformException>()
            .having((e) => e.code, 'code', 'REG_FAILED')
            .having((e) => e.message, 'message', 'xdg-mime: not found')),
      );
    });

    test('update-desktop-database failure is non-fatal', () async {
      final registrar = LinuxProtocolRegistrar(
        processRunner: (exe, args) async {
          if (exe == 'update-desktop-database') {
            return ProcessResult(0, 127, '', 'command not found');
          }
          return ProcessResult(0, 0, '', '');
        },
        fileWriter: (path, content) async {},
        environment: {'HOME': '/home/testuser'},
        resolvedExecutable: '/usr/bin/wallpaper_changer',
      );

      // Should complete without throwing
      await expectLater(registrar.register(), completes);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```
flutter test test/platform/linux_protocol_registrar_test.dart
```

Expected: FAIL — `linux_protocol_registrar.dart` doesn't exist yet.

- [ ] **Step 3: Implement LinuxProtocolRegistrar**

Create `lib/platform/linux_protocol_registrar.dart`:

```dart
import 'dart:io';
import 'package:flutter/services.dart';
import 'protocol_registrar.dart';

typedef ProcessRunner = Future<ProcessResult> Function(
    String executable, List<String> arguments);
typedef FileWriter = Future<void> Function(String path, String content);

class LinuxProtocolRegistrar implements ProtocolRegistrar {
  LinuxProtocolRegistrar({
    ProcessRunner? processRunner,
    FileWriter? fileWriter,
    Map<String, String>? environment,
    String? resolvedExecutable,
  })  : _run = processRunner ?? Process.run,
        _writeFile = fileWriter ?? _defaultFileWriter,
        _environment = environment ?? Platform.environment,
        _resolvedExecutable =
            resolvedExecutable ?? Platform.resolvedExecutable;

  static Future<void> _defaultFileWriter(String path, String content) =>
      File(path).writeAsString(content);

  final ProcessRunner _run;
  final FileWriter _writeFile;
  final Map<String, String> _environment;
  final String _resolvedExecutable;

  @override
  Future<void> register() async {
    final home = _environment['HOME'] ?? '';
    final desktopDir = '$home/.local/share/applications';
    final desktopPath = '$desktopDir/wallpaper0-changer.desktop';

    final content = '[Desktop Entry]\n'
        'Name=Wallpaper Changer\n'
        'Exec=$_resolvedExecutable %u\n'
        'Type=Application\n'
        'MimeType=x-scheme-handler/wallpaper0-changer;\n';

    await _writeFile(desktopPath, content);

    final mimeResult = await _run('xdg-mime', [
      'default',
      'wallpaper0-changer.desktop',
      'x-scheme-handler/wallpaper0-changer',
    ]);

    if (mimeResult.exitCode != 0) {
      throw PlatformException(
        code: 'REG_FAILED',
        message: mimeResult.stderr as String,
      );
    }

    // update-desktop-database is optional — ignore failures
    try {
      await _run('update-desktop-database', [desktopDir]);
    } catch (_) {}
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```
flutter test test/platform/linux_protocol_registrar_test.dart
```

Expected: All 4 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/platform/linux_protocol_registrar.dart test/platform/linux_protocol_registrar_test.dart
git commit -m "feat: LinuxProtocolRegistrar — .desktop file + xdg-mime"
```

---

## Task 3: macOS Swift Plugin + MacosWallpaperSetter

**Files:**
- Create: `macos/Runner/WallpaperPlugin.swift`
- Modify: `macos/Runner/MainFlutterWindow.swift`
- Create: `lib/platform/macos_wallpaper_setter.dart`
- Create: `test/platform/macos_wallpaper_setter_test.dart`

- [ ] **Step 1: Write the failing Dart test**

Create `test/platform/macos_wallpaper_setter_test.dart`:

```dart
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
}
```

- [ ] **Step 2: Run test to verify it fails**

```
flutter test test/platform/macos_wallpaper_setter_test.dart
```

Expected: FAIL — `macos_wallpaper_setter.dart` doesn't exist yet.

- [ ] **Step 3: Create MacosWallpaperSetter**

Create `lib/platform/macos_wallpaper_setter.dart`:

```dart
import 'package:flutter/services.dart';
import 'wallpaper_setter.dart';

class MacosWallpaperSetter implements WallpaperSetter {
  static const _channel = MethodChannel('wallpaper_changer/wallpaper');

  @override
  Future<void> set(String localFilePath) async {
    final String? error =
        await _channel.invokeMethod<String>('setWallpaper', localFilePath);
    if (error != null) {
      throw PlatformException(code: 'SET_FAILED', message: error);
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```
flutter test test/platform/macos_wallpaper_setter_test.dart
```

Expected: Both tests PASS.

- [ ] **Step 5: Create WallpaperPlugin.swift**

Create `macos/Runner/WallpaperPlugin.swift`:

```swift
import Cocoa
import FlutterMacOS

class WallpaperPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "wallpaper_changer/wallpaper",
      binaryMessenger: registrar.messenger
    )
    let instance = WallpaperPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "setWallpaper" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard let path = call.arguments as? String else {
      result("Expected a String path")
      return
    }
    guard let screen = NSScreen.main else {
      result("No main screen available")
      return
    }
    let url = URL(fileURLWithPath: path)
    do {
      try NSWorkspace.shared.setDesktopImageURL(url, for: screen, options: [:])
      result(nil) // nil = success
    } catch {
      result(error.localizedDescription)
    }
  }
}
```

- [ ] **Step 6: Wire WallpaperPlugin into MainFlutterWindow.swift**

Current `macos/Runner/MainFlutterWindow.swift`:
```swift
import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
```

Add WallpaperPlugin registration after `RegisterGeneratedPlugins`:
```swift
import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    WallpaperPlugin.register(
      with: flutterViewController.registrar(forPlugin: "WallpaperPlugin")!)

    super.awakeFromNib()
  }
}
```

- [ ] **Step 7: Run all Dart tests to confirm no regressions**

```
flutter test
```

Expected: All tests PASS.

- [ ] **Step 8: Commit**

```bash
git add macos/Runner/WallpaperPlugin.swift macos/Runner/MainFlutterWindow.swift \
  lib/platform/macos_wallpaper_setter.dart test/platform/macos_wallpaper_setter_test.dart
git commit -m "feat: MacosWallpaperSetter + WallpaperPlugin Swift channel"
```

---

## Task 4: MacosProtocolRegistrar + Info.plist

**Files:**
- Create: `lib/platform/macos_protocol_registrar.dart`
- Create: `test/platform/macos_protocol_registrar_test.dart`
- Modify: `macos/Runner/Info.plist`

- [ ] **Step 1: Write the failing test**

Create `test/platform/macos_protocol_registrar_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper_changer/platform/macos_protocol_registrar.dart';

void main() {
  test('register completes without error', () async {
    final registrar = MacosProtocolRegistrar();
    await expectLater(registrar.register(), completes);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```
flutter test test/platform/macos_protocol_registrar_test.dart
```

Expected: FAIL — `macos_protocol_registrar.dart` doesn't exist yet.

- [ ] **Step 3: Implement MacosProtocolRegistrar**

Create `lib/platform/macos_protocol_registrar.dart`:

```dart
import 'protocol_registrar.dart';

class MacosProtocolRegistrar implements ProtocolRegistrar {
  @override
  Future<void> register() async {
    // No-op: macOS activates CFBundleURLSchemes from Info.plist at first launch.
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```
flutter test test/platform/macos_protocol_registrar_test.dart
```

Expected: PASS.

- [ ] **Step 5: Add CFBundleURLTypes to Info.plist**

Open `macos/Runner/Info.plist`. Find the closing `</dict>` tag before `</plist>` and add before it:

```xml
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleURLName</key>
			<string>wallpaper0-changer</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>wallpaper0-changer</string>
			</array>
		</dict>
	</array>
```

- [ ] **Step 6: Run all Dart tests to confirm no regressions**

```
flutter test
```

Expected: All tests PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/platform/macos_protocol_registrar.dart \
  test/platform/macos_protocol_registrar_test.dart \
  macos/Runner/Info.plist
git commit -m "feat: MacosProtocolRegistrar (no-op) + Info.plist CFBundleURLSchemes"
```

---

## Task 5: Wire Providers + main.dart

**Files:**
- Modify: `lib/providers.dart`
- Modify: `lib/main.dart`

Context: `providers.dart` currently uses `Platform.isWindows ? real : stub`. We extend to full tri-platform. `main.dart` currently calls `register()` only on Windows; we add Linux too.

- [ ] **Step 1: Update providers.dart**

Current `lib/providers.dart` (platform section, lines 35–45):
```dart
final wallpaperSetterProvider = Provider<WallpaperSetter>((ref) =>
    Platform.isWindows ? WindowsWallpaperSetter() : StubWallpaperSetter());

final appNotifierProvider = Provider<AppNotifier>((ref) => Platform.isWindows
    ? LocalNotifierAppNotifier()
    : StubAppNotifier());

final protocolRegistrarProvider = Provider<ProtocolRegistrar>((ref) =>
    Platform.isWindows
        ? WindowsProtocolRegistrar()
        : StubProtocolRegistrar());
```

Replace with:
```dart
final wallpaperSetterProvider = Provider<WallpaperSetter>((ref) {
  if (Platform.isWindows) return WindowsWallpaperSetter();
  if (Platform.isLinux) return LinuxWallpaperSetter();
  if (Platform.isMacOS) return MacosWallpaperSetter();
  return StubWallpaperSetter();
});

final appNotifierProvider =
    Provider<AppNotifier>((ref) => LocalNotifierAppNotifier());

final protocolRegistrarProvider = Provider<ProtocolRegistrar>((ref) {
  if (Platform.isWindows) return WindowsProtocolRegistrar();
  if (Platform.isLinux) return LinuxProtocolRegistrar();
  if (Platform.isMacOS) return MacosProtocolRegistrar();
  return StubProtocolRegistrar();
});
```

Add the new imports at the top of `lib/providers.dart` (after existing platform imports):
```dart
import 'platform/linux_wallpaper_setter.dart';
import 'platform/linux_protocol_registrar.dart';
import 'platform/macos_wallpaper_setter.dart';
import 'platform/macos_protocol_registrar.dart';
```

- [ ] **Step 2: Update main.dart**

Current `lib/main.dart` platform registration block:
```dart
if (Platform.isWindows) {
  try {
    await WindowsProtocolRegistrar().register();
  } catch (e) {
    debugPrint('Protocol registration failed: $e');
  }
}
```

Replace with:
```dart
if (Platform.isWindows || Platform.isLinux) {
  final registrar = Platform.isWindows
      ? WindowsProtocolRegistrar()
      : LinuxProtocolRegistrar();
  try {
    await registrar.register();
  } catch (e) {
    debugPrint('Protocol registration failed: $e');
  }
}
```

Add `linux_protocol_registrar.dart` import to `lib/main.dart`:
```dart
import 'platform/linux_protocol_registrar.dart';
```

- [ ] **Step 3: Run all tests**

```
flutter test
```

Expected: All tests PASS, 0 failures.

- [ ] **Step 4: Run flutter analyze**

```
flutter analyze
```

Expected: No new issues.

- [ ] **Step 5: Commit**

```bash
git add lib/providers.dart lib/main.dart
git commit -m "feat: wire Linux + macOS platform impls in providers; register protocol on Linux"
```
