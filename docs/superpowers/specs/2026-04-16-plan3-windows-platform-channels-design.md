# Plan 3: Windows Platform Channels — Design Spec

## Goal

Replace the three stub platform implementations (`StubWallpaperSetter`, `StubProtocolRegistrar`, `StubAppNotifier`) with real Windows implementations, wiring them into `providers.dart` via `Platform.isWindows` conditionals.

## Scope

Windows only. Linux and macOS real implementations are deferred to Plan 4.

---

## Architecture

Three real implementations are added alongside the existing stubs:

| Interface | Stub (existing) | Windows impl | Mechanism |
|---|---|---|---|
| `WallpaperSetter` | `StubWallpaperSetter` | `WindowsWallpaperSetter` | C++ method channel → `SystemParametersInfoW` |
| `ProtocolRegistrar` | `StubProtocolRegistrar` | `WindowsProtocolRegistrar` | C++ method channel → Registry write |
| `AppNotifier` | `StubAppNotifier` | `LocalNotifierAppNotifier` | `local_notifier` Flutter package |

The C++ implementations share one plugin class registered in the Windows runner. Stubs remain and continue to be used on non-Windows platforms and in unit tests.

---

## Components

### 1. C++ Plugin (`windows/runner/`)

**New files:**
- `windows/runner/wallpaper_plugin.h`
- `windows/runner/wallpaper_plugin.cpp`

The plugin registers two method channels with the Flutter engine:

| Channel | Method | Action |
|---|---|---|
| `wallpaper_changer/wallpaper` | `setWallpaper(String path)` | Calls `SystemParametersInfoW(SPI_SETDESKWALLPAPER, ...)` |
| `wallpaper_changer/protocol` | `register()` | Writes Registry keys under `HKCU\Software\Classes\wallpaper0-changer\` |

**`SetWallpaper`:** Converts the UTF-8 path to wide string, calls `SystemParametersInfoW` with `SPIF_UPDATEINIFILE | SPIF_SENDCHANGE`. Returns a non-null error string on failure; returns null on success.

**`RegisterProtocol`:** Writes the following Registry keys:
- `HKCU\Software\Classes\wallpaper0-changer\(Default)` = `"URL:wallpaper0-changer Protocol"`
- `HKCU\Software\Classes\wallpaper0-changer\URL Protocol` = `""`
- `HKCU\Software\Classes\wallpaper0-changer\shell\open\command\(Default)` = `"<exe_path>" "%1"`

Exe path is obtained via `GetModuleFileNameW`. Returns a non-null error string on failure; returns null on success.

**Registration:** `WallpaperPlugin::RegisterWithRegistrar()` is called from `FlutterWindow::OnCreate()` in `flutter_window.cpp`.

**`CMakeLists.txt`:** `wallpaper_plugin.cpp` added to the runner `SOURCES` list. No extra libraries needed — Win32 APIs are already linked.

---

### 2. Dart-side Wrappers (`lib/platform/`)

**`lib/platform/windows_wallpaper_setter.dart`**
```dart
class WindowsWallpaperSetter implements WallpaperSetter {
  static const _channel = MethodChannel('wallpaper_changer/wallpaper');

  @override
  Future<void> set(String localFilePath) async {
    final error = await _channel.invokeMethod<String>('setWallpaper', localFilePath);
    if (error != null) throw PlatformException(code: 'SET_FAILED', message: error);
  }
}
```

**`lib/platform/windows_protocol_registrar.dart`**
```dart
class WindowsProtocolRegistrar implements ProtocolRegistrar {
  static const _channel = MethodChannel('wallpaper_changer/protocol');

  @override
  Future<void> register() async {
    final error = await _channel.invokeMethod<String>('register');
    if (error != null) throw PlatformException(code: 'REG_FAILED', message: error);
  }
}
```

**`lib/platform/local_notifier_app_notifier.dart`**
```dart
class LocalNotifierAppNotifier implements AppNotifier {
  @override
  Future<void> show(String title, {String? body}) async {
    final n = LocalNotification(title: title, body: body);
    await localNotifier.notify(n);
  }
}
```

---

### 3. Provider Wiring (`lib/providers.dart`)

Replace stub providers with platform-conditional providers:

```dart
final wallpaperSetterProvider = Provider<WallpaperSetter>((ref) =>
    Platform.isWindows ? WindowsWallpaperSetter() : StubWallpaperSetter());

final protocolRegistrarProvider = Provider<ProtocolRegistrar>((ref) =>
    Platform.isWindows ? WindowsProtocolRegistrar() : StubProtocolRegistrar());

final appNotifierProvider = Provider<AppNotifier>((ref) =>
    Platform.isWindows ? LocalNotifierAppNotifier() : StubAppNotifier());
```

---

### 4. `local_notifier` Setup (`lib/main.dart`)

Add before `runApp()`:
```dart
await localNotifier.setup(appName: 'Wallpaper Changer');
```

Add `local_notifier` to `pubspec.yaml` dependencies.

---

## Data Flow

```
WallpaperService.setWallpaper(image)
  → WallpaperSetter.set(localFilePath)          ← WindowsWallpaperSetter
      → MethodChannel('wallpaper_changer/wallpaper').invokeMethod('setWallpaper', path)
          → C++ WallpaperPlugin::SetWallpaper()
              → SystemParametersInfoW(SPI_SETDESKWALLPAPER, ...)

main() startup
  → ProtocolRegistrar.register()                ← WindowsProtocolRegistrar
      → MethodChannel('wallpaper_changer/protocol').invokeMethod('register')
          → C++ WallpaperPlugin::RegisterProtocol()
              → RegSetValueExW(HKCU\Software\Classes\wallpaper0-changer\...)

WallpaperService.setWallpaper(image)
  → AppNotifier.show('Wallpaper updated')       ← LocalNotifierAppNotifier
      → localNotifier.notify(LocalNotification(title: 'Wallpaper updated'))
```

---

## File Structure

**New files:**
- `windows/runner/wallpaper_plugin.h`
- `windows/runner/wallpaper_plugin.cpp`
- `lib/platform/windows_wallpaper_setter.dart`
- `lib/platform/windows_protocol_registrar.dart`
- `lib/platform/local_notifier_app_notifier.dart`

**Modified files:**
- `windows/runner/flutter_window.cpp` — register plugin in `OnCreate()`
- `windows/runner/CMakeLists.txt` — add `wallpaper_plugin.cpp` to `SOURCES`
- `lib/providers.dart` — swap stub providers for platform-conditional providers
- `lib/main.dart` — add `local_notifier` setup
- `pubspec.yaml` — add `local_notifier` dependency

**Unchanged files:**
- `lib/platform/wallpaper_setter.dart` — stub remains
- `lib/platform/protocol_registrar.dart` — stub remains
- `lib/platform/app_notifier.dart` — stub remains

---

## Testing

### Unit Tests (automated)

- `LocalNotifierAppNotifier` — mock `localNotifier` global; verify `notify()` called with correct title/body
- `providers.dart` wiring — `ProviderContainer` overrides; verify correct impl type on Windows vs non-Windows

### Integration Tests (manual, on Windows)

1. `flutter run -d windows` — app launches without crash
2. Set a wallpaper from Discover screen → desktop background changes
3. Check `HKCU\Software\Classes\wallpaper0-changer` in `regedit` → all keys present
4. Open `wallpaper0-changer://test` in browser → app opens (or is foregrounded)
5. Notification appears when wallpaper is set

### What is NOT unit-tested

`WindowsWallpaperSetter` and `WindowsProtocolRegistrar` are thin channel wrappers. Mock-based tests would only verify that `invokeMethod` was called — no value added. Correctness is verified by the manual integration tests above.

---

## Error Handling

- C++ methods return a non-null error string on failure; Dart side converts to `PlatformException`
- `WallpaperService` callers already catch exceptions — no changes needed there
- `register()` is best-effort on startup; failure is logged but does not block app launch
