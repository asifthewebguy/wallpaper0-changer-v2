# Plan 4 — Linux + macOS Platform Channels Design

## Goal

Replace stub `WallpaperSetter` and `ProtocolRegistrar` implementations with real ones for Linux and macOS. Wire `LocalNotifierAppNotifier` (already cross-platform) on all three platforms.

---

## Architecture

Plan 4 adds platform implementations for Linux and macOS following the same interface contract established in Plan 3 (Windows). `AppNotifier` already works on all platforms via `local_notifier` — no new class needed, just provider wiring.

### Linux — Dart `Process.run` (no C++)

Both Linux implementations use Dart `Process.run` directly. No C++ plugin is needed.

**`LinuxWallpaperSetter`**:
- Reads `Platform.environment['XDG_CURRENT_DESKTOP']` to detect DE
- GNOME (`GNOME`, `ubuntu:GNOME`, etc.): `gsettings set org.gnome.desktop.background picture-uri 'file:///path'` + `picture-uri-dark` (same path, covers light/dark mode)
- KDE (`KDE`): `plasma-apply-wallpaperimage /path`
- Fallback (anything else, or env var missing): `feh --bg-scale /path`
- If `exitCode != 0` or `ProcessException`, throws `PlatformException(code: 'SET_FAILED', message: stderr)`

**`LinuxProtocolRegistrar`**:
- Gets exe path via `Platform.resolvedExecutable`
- Writes `~/.local/share/applications/wallpaper0-changer.desktop` via `File.writeAsString` with `Exec=/path/to/exe %u`
- Calls `xdg-mime default wallpaper0-changer.desktop x-scheme-handler/wallpaper0-changer`
- Calls `update-desktop-database ~/.local/share/applications/` — non-fatal if it fails (tool may not be installed)
- If `xdg-mime` exits non-zero, throws `PlatformException(code: 'REG_FAILED', message: stderr)`

### macOS — Swift method channel + Info.plist

**`WallpaperPlugin.swift`** (new file in `macos/Runner/`):
- Flutter method channel: `wallpaper_changer/wallpaper`, method `setWallpaper`
- Uses `NSWorkspace.shared.setDesktopImageURL(_:options:for:)` on `NSScreen.main`
- Error protocol: return `nil` for success, error string for failure (same as Windows C++ plugin)
- Registered in `MainFlutterWindow.swift` after `RegisterGeneratedPlugins`

**`MacosWallpaperSetter`** (Dart wrapper):
- Same pattern as `WindowsWallpaperSetter`: `MethodChannel('wallpaper_changer/wallpaper').invokeMethod<String>('setWallpaper', path)`
- Non-null return → `PlatformException(code: 'SET_FAILED', message: error)`

**`MacosProtocolRegistrar`** (Dart no-op):
- `register()` is a no-op — macOS activates `CFBundleURLSchemes` at first launch automatically
- `macos/Runner/Info.plist` gets a `CFBundleURLTypes` entry declaring scheme `wallpaper0-changer`

### Provider wiring

`providers.dart` extended from `isWindows` to full tri-platform conditional:

```dart
final wallpaperSetterProvider = Provider<WallpaperSetter>((ref) {
  if (Platform.isWindows) return WindowsWallpaperSetter();
  if (Platform.isLinux)   return LinuxWallpaperSetter();
  if (Platform.isMacOS)   return MacosWallpaperSetter();
  return StubWallpaperSetter();
});

final appNotifierProvider = Provider<AppNotifier>((ref) =>
    LocalNotifierAppNotifier()); // local_notifier is cross-platform

final protocolRegistrarProvider = Provider<ProtocolRegistrar>((ref) {
  if (Platform.isWindows) return WindowsProtocolRegistrar();
  if (Platform.isLinux)   return LinuxProtocolRegistrar();
  if (Platform.isMacOS)   return MacosProtocolRegistrar();
  return StubProtocolRegistrar();
});
```

`main.dart` extended to call `register()` on Linux too (same try/catch guard as Windows).

---

## File Structure

### New files

| File | Purpose |
|---|---|
| `lib/platform/linux_wallpaper_setter.dart` | `LinuxWallpaperSetter` — gsettings/KDE/feh via Process.run |
| `lib/platform/linux_protocol_registrar.dart` | `LinuxProtocolRegistrar` — .desktop + xdg-mime |
| `lib/platform/macos_wallpaper_setter.dart` | `MacosWallpaperSetter` — MethodChannel wrapper |
| `lib/platform/macos_protocol_registrar.dart` | `MacosProtocolRegistrar` — no-op (Info.plist handles it) |
| `macos/Runner/WallpaperPlugin.swift` | Swift plugin: NSWorkspace setDesktopImageURL |
| `test/platform/linux_wallpaper_setter_test.dart` | Unit tests with injected mock ProcessRunner |
| `test/platform/linux_protocol_registrar_test.dart` | Unit tests with injected mock ProcessRunner |
| `test/platform/macos_wallpaper_setter_test.dart` | Unit tests with mocked MethodChannel |
| `test/platform/macos_protocol_registrar_test.dart` | Single test: register() completes without error |

### Modified files

| File | Change |
|---|---|
| `macos/Runner/MainFlutterWindow.swift` | Register `WallpaperPlugin` after `RegisterGeneratedPlugins` |
| `macos/Runner/Info.plist` | Add `CFBundleURLTypes` with scheme `wallpaper0-changer` |
| `lib/providers.dart` | Extend to isLinux / isMacOS conditionals; AppNotifier always LocalNotifierAppNotifier |
| `lib/main.dart` | Call `register()` on Linux (Platform.isLinux guard, same try/catch) |

---

## Error Handling

| Scenario | Behavior |
|---|---|
| Unknown Linux DE | Falls through to `feh` fallback |
| `feh` not installed | `ProcessException` → `PlatformException(SET_FAILED)` |
| `update-desktop-database` missing | Log warning, do not throw |
| `gsettings`/`plasma-apply-wallpaperimage` non-zero exit | `PlatformException(SET_FAILED, stderr)` |
| `xdg-mime` non-zero exit | `PlatformException(REG_FAILED, stderr)` |
| macOS `NSWorkspace` throws | Return error string → Dart throws `PlatformException(SET_FAILED)` |
| Protocol registration failure | `main.dart` catches and `debugPrint`s — non-fatal |

---

## Testing Strategy

**Linux tests** — injectable `ProcessRunner` abstraction:
```dart
typedef ProcessRunner = Future<ProcessResult> Function(
    String executable, List<String> arguments);

class LinuxWallpaperSetter implements WallpaperSetter {
  LinuxWallpaperSetter({ProcessRunner? processRunner})
      : _run = processRunner ?? Process.run;
  final ProcessRunner _run;
  ...
}
```
Test verifies correct command for each DE (GNOME, KDE, fallback) and throws on non-zero exit.

**macOS Dart tests** — mock `MethodChannel` via `TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler`.

**`MacosProtocolRegistrar` test** — single test: `register()` completes without error (mirrors `StubProtocolRegistrar` test pattern).

**`LinuxProtocolRegistrar` tests**:
- Verify `.desktop` file content written correctly
- Verify `xdg-mime default` called with correct args
- Verify `update-desktop-database` failure is non-fatal
