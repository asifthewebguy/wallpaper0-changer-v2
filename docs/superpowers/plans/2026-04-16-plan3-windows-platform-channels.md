# Plan 3: Windows Platform Channels — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the three stub platform implementations with real Windows implementations: `SystemParametersInfoW` for wallpaper setting, Registry writes for protocol registration, and `local_notifier` for notifications.

**Architecture:** Two C++ method channels (`wallpaper_changer/wallpaper`, `wallpaper_changer/protocol`) are handled by a single `WallpaperPlugin` class registered in the Windows runner. A third interface (`AppNotifier`) is implemented in pure Dart using the already-present `local_notifier` package. `providers.dart` swaps stubs for real impls via `Platform.isWindows` conditionals.

**Tech Stack:** Flutter 3.27 / Dart 3.x, Riverpod 2.x, `local_notifier ^0.1.6` (already in pubspec), Win32 API (`SystemParametersInfoW`, `RegCreateKeyExW`), `flutter::MethodChannel`, `mocktail` for tests.

---

## File Map

| Action | File | Responsibility |
|---|---|---|
| Create | `lib/platform/protocol_registrar.dart` | `ProtocolRegistrar` interface + `StubProtocolRegistrar` |
| Create | `lib/platform/local_notifier_app_notifier.dart` | `AppNotifier` impl using `local_notifier` package |
| Create | `lib/platform/windows_wallpaper_setter.dart` | `WallpaperSetter` impl — Dart-side channel wrapper |
| Create | `lib/platform/windows_protocol_registrar.dart` | `ProtocolRegistrar` impl — Dart-side channel wrapper |
| Create | `windows/runner/wallpaper_plugin.h` | C++ plugin class declaration |
| Create | `windows/runner/wallpaper_plugin.cpp` | C++ plugin implementation |
| Modify | `windows/runner/CMakeLists.txt` | Add `wallpaper_plugin.cpp` to SOURCES |
| Modify | `windows/runner/flutter_window.cpp` | Register plugin in `OnCreate()` |
| Modify | `lib/providers.dart` | Add `protocolRegistrarProvider`; swap stubs for platform-conditional impls |
| Modify | `lib/main.dart` | Add `local_notifier` setup + protocol registration on startup |
| Create | `test/platform/protocol_registrar_test.dart` | Stub no-op test |
| Create | `test/platform/local_notifier_app_notifier_test.dart` | Mock-based unit tests |

---

### Task 1: ProtocolRegistrar interface + stub

**Files:**
- Create: `lib/platform/protocol_registrar.dart`
- Create: `test/platform/protocol_registrar_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/platform/protocol_registrar_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper_changer/platform/protocol_registrar.dart';

void main() {
  test('StubProtocolRegistrar.register() completes without error', () async {
    final registrar = StubProtocolRegistrar();
    await expectLater(registrar.register(), completes);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```
flutter test test/platform/protocol_registrar_test.dart
```

Expected: FAIL — `Target of URI doesn't exist: 'package:wallpaper_changer/platform/protocol_registrar.dart'`

- [ ] **Step 3: Create the interface + stub**

Create `lib/platform/protocol_registrar.dart`:

```dart
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
```

- [ ] **Step 4: Run test to verify it passes**

```
flutter test test/platform/protocol_registrar_test.dart
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/platform/protocol_registrar.dart test/platform/protocol_registrar_test.dart
git commit -m "feat: ProtocolRegistrar interface + stub"
```

---

### Task 2: LocalNotifierAppNotifier

**Files:**
- Create: `lib/platform/local_notifier_app_notifier.dart`
- Create: `test/platform/local_notifier_app_notifier_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/platform/local_notifier_app_notifier_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallpaper_changer/platform/local_notifier_app_notifier.dart';

class MockLocalNotifier extends Mock implements LocalNotifier {}

void main() {
  late MockLocalNotifier mockNotifier;
  late LocalNotifierAppNotifier appNotifier;

  setUp(() {
    mockNotifier = MockLocalNotifier();
    appNotifier = LocalNotifierAppNotifier(notifier: mockNotifier);
    when(() => mockNotifier.notify(any())).thenAnswer((_) async {});
  });

  test('show calls notify with correct title and body', () async {
    await appNotifier.show('Wallpaper updated', body: 'photo.jpg');

    final captured =
        verify(() => mockNotifier.notify(captureAny())).captured;
    expect(captured, hasLength(1));
    final n = captured.first as LocalNotification;
    expect(n.title, 'Wallpaper updated');
    expect(n.body, 'photo.jpg');
  });

  test('show calls notify with null body when body omitted', () async {
    await appNotifier.show('Wallpaper updated');

    final captured =
        verify(() => mockNotifier.notify(captureAny())).captured;
    final n = captured.first as LocalNotification;
    expect(n.title, 'Wallpaper updated');
    expect(n.body, isNull);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```
flutter test test/platform/local_notifier_app_notifier_test.dart
```

Expected: FAIL — `Target of URI doesn't exist: 'package:wallpaper_changer/platform/local_notifier_app_notifier.dart'`

- [ ] **Step 3: Create the implementation**

Create `lib/platform/local_notifier_app_notifier.dart`:

```dart
import 'package:local_notifier/local_notifier.dart';
import 'app_notifier.dart';

class LocalNotifierAppNotifier implements AppNotifier {
  LocalNotifierAppNotifier({LocalNotifier? notifier})
      : _notifier = notifier ?? localNotifier;

  final LocalNotifier _notifier;

  @override
  Future<void> show(String title, {String? body}) async {
    await _notifier.notify(
      LocalNotification(title: title, body: body),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```
flutter test test/platform/local_notifier_app_notifier_test.dart
```

Expected: PASS (2 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/platform/local_notifier_app_notifier.dart test/platform/local_notifier_app_notifier_test.dart
git commit -m "feat: LocalNotifierAppNotifier — AppNotifier impl via local_notifier"
```

---

### Task 3: Windows Dart channel wrappers

**Files:**
- Create: `lib/platform/windows_wallpaper_setter.dart`
- Create: `lib/platform/windows_protocol_registrar.dart`

No unit tests — these are thin wrappers around method channels. Correctness is verified by manual integration testing after the C++ plugin is wired up.

- [ ] **Step 1: Create WindowsWallpaperSetter**

Create `lib/platform/windows_wallpaper_setter.dart`:

```dart
import 'package:flutter/services.dart';
import 'wallpaper_setter.dart';

class WindowsWallpaperSetter implements WallpaperSetter {
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

- [ ] **Step 2: Create WindowsProtocolRegistrar**

Create `lib/platform/windows_protocol_registrar.dart`:

```dart
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
```

- [ ] **Step 3: Verify no analysis errors**

```
flutter analyze lib/platform/windows_wallpaper_setter.dart lib/platform/windows_protocol_registrar.dart
```

Expected: No issues found.

- [ ] **Step 4: Commit**

```bash
git add lib/platform/windows_wallpaper_setter.dart lib/platform/windows_protocol_registrar.dart
git commit -m "feat: WindowsWallpaperSetter + WindowsProtocolRegistrar Dart channel wrappers"
```

---

### Task 4: C++ wallpaper plugin

**Files:**
- Create: `windows/runner/wallpaper_plugin.h`
- Create: `windows/runner/wallpaper_plugin.cpp`
- Modify: `windows/runner/CMakeLists.txt` (line 9-17, `add_executable` sources list)
- Modify: `windows/runner/flutter_window.cpp` (add include + registration call)

No unit tests — C++ plugin code. Correctness verified by manual integration test.

- [ ] **Step 1: Create wallpaper_plugin.h**

Create `windows/runner/wallpaper_plugin.h`:

```cpp
#ifndef RUNNER_WALLPAPER_PLUGIN_H_
#define RUNNER_WALLPAPER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <memory>

class WallpaperPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(
      flutter::PluginRegistrarWindows* registrar);

  explicit WallpaperPlugin();
  ~WallpaperPlugin() override;

 private:
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      wallpaper_channel_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      protocol_channel_;

  void HandleWallpaperChannel(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void HandleProtocolChannel(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

#endif  // RUNNER_WALLPAPER_PLUGIN_H_
```

- [ ] **Step 2: Create wallpaper_plugin.cpp**

Create `windows/runner/wallpaper_plugin.cpp`:

```cpp
#include "wallpaper_plugin.h"

#include <windows.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <memory>
#include <string>

// static
void WallpaperPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto plugin = std::make_unique<WallpaperPlugin>();

  plugin->wallpaper_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "wallpaper_changer/wallpaper",
          &flutter::StandardMethodCodec::GetInstance());

  plugin->protocol_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "wallpaper_changer/protocol",
          &flutter::StandardMethodCodec::GetInstance());

  WallpaperPlugin* plugin_ptr = plugin.get();

  plugin->wallpaper_channel_->SetMethodCallHandler(
      [plugin_ptr](const auto& call, auto result) {
        plugin_ptr->HandleWallpaperChannel(call, std::move(result));
      });

  plugin->protocol_channel_->SetMethodCallHandler(
      [plugin_ptr](const auto& call, auto result) {
        plugin_ptr->HandleProtocolChannel(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

WallpaperPlugin::WallpaperPlugin() {}
WallpaperPlugin::~WallpaperPlugin() {}

void WallpaperPlugin::HandleWallpaperChannel(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (call.method_name() == "setWallpaper") {
    const auto* path_value = std::get_if<std::string>(call.arguments());
    if (!path_value) {
      result->Error("INVALID_ARGS", "Expected a String path");
      return;
    }

    // Convert UTF-8 path to wide string for Win32 API
    int wlen = MultiByteToWideChar(CP_UTF8, 0, path_value->c_str(), -1,
                                   nullptr, 0);
    std::wstring wpath(wlen, 0);
    MultiByteToWideChar(CP_UTF8, 0, path_value->c_str(), -1,
                        wpath.data(), wlen);

    BOOL ok = SystemParametersInfoW(
        SPI_SETDESKWALLPAPER, 0,
        static_cast<PVOID>(wpath.data()),
        SPIF_UPDATEINIFILE | SPIF_SENDCHANGE);

    if (!ok) {
      DWORD err = GetLastError();
      result->Success(flutter::EncodableValue(
          std::string("SystemParametersInfoW failed: ") +
          std::to_string(err)));
    } else {
      result->Success(flutter::EncodableValue());  // null = success
    }
  } else {
    result->NotImplemented();
  }
}

void WallpaperPlugin::HandleProtocolChannel(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (call.method_name() == "register") {
    // Get the path to this executable
    wchar_t exe_path[MAX_PATH];
    if (GetModuleFileNameW(nullptr, exe_path, MAX_PATH) == 0) {
      result->Success(flutter::EncodableValue(
          std::string("GetModuleFileNameW failed: ") +
          std::to_string(GetLastError())));
      return;
    }

    // Command string: "<exe_path>" "%1"
    std::wstring cmd =
        std::wstring(L"\"") + exe_path + L"\" \"%1\"";

    const wchar_t* kBase =
        L"Software\\Classes\\wallpaper0-changer";

    // --- Write base key ---
    HKEY hKey;
    LSTATUS s = RegCreateKeyExW(
        HKEY_CURRENT_USER, kBase, 0, nullptr,
        REG_OPTION_NON_VOLATILE, KEY_SET_VALUE, nullptr, &hKey, nullptr);
    if (s != ERROR_SUCCESS) {
      result->Success(flutter::EncodableValue(
          std::string("RegCreateKeyExW failed: ") + std::to_string(s)));
      return;
    }

    const wchar_t* kDesc = L"URL:wallpaper0-changer Protocol";
    RegSetValueExW(hKey, L"", 0, REG_SZ,
                   reinterpret_cast<const BYTE*>(kDesc),
                   (static_cast<DWORD>(wcslen(kDesc)) + 1) * sizeof(wchar_t));
    RegSetValueExW(hKey, L"URL Protocol", 0, REG_SZ,
                   reinterpret_cast<const BYTE*>(L""), sizeof(wchar_t));
    RegCloseKey(hKey);

    // --- Write shell\open\command key ---
    std::wstring cmd_key_path =
        std::wstring(kBase) + L"\\shell\\open\\command";
    s = RegCreateKeyExW(
        HKEY_CURRENT_USER, cmd_key_path.c_str(), 0, nullptr,
        REG_OPTION_NON_VOLATILE, KEY_SET_VALUE, nullptr, &hKey, nullptr);
    if (s != ERROR_SUCCESS) {
      result->Success(flutter::EncodableValue(
          std::string("RegCreateKeyExW (command) failed: ") +
          std::to_string(s)));
      return;
    }

    RegSetValueExW(
        hKey, L"", 0, REG_SZ,
        reinterpret_cast<const BYTE*>(cmd.c_str()),
        (static_cast<DWORD>(cmd.size()) + 1) * sizeof(wchar_t));
    RegCloseKey(hKey);

    result->Success(flutter::EncodableValue());  // null = success
  } else {
    result->NotImplemented();
  }
}
```

- [ ] **Step 3: Add wallpaper_plugin.cpp to CMakeLists.txt**

In `windows/runner/CMakeLists.txt`, the `add_executable` block currently reads:

```cmake
add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)
```

Add `"wallpaper_plugin.cpp"` after `"win32_window.cpp"`:

```cmake
add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "wallpaper_plugin.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)
```

- [ ] **Step 4: Register the plugin in flutter_window.cpp**

In `windows/runner/flutter_window.cpp`, add the include at the top (after existing includes):

```cpp
#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"
#include <flutter/plugin_registrar_windows.h>
#include "wallpaper_plugin.h"
```

Then in `FlutterWindow::OnCreate()`, add the registration call immediately after `RegisterPlugins(...)`:

```cpp
bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  WallpaperPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarWindows::GetOrCreateRegistrar(
          flutter_controller_->engine()->GetRegistrarForPlugin(
              "WallpaperPlugin")));
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  flutter_controller_->ForceRedraw();

  return true;
}
```

- [ ] **Step 5: Commit**

```bash
git add windows/runner/wallpaper_plugin.h windows/runner/wallpaper_plugin.cpp windows/runner/CMakeLists.txt windows/runner/flutter_window.cpp
git commit -m "feat: WallpaperPlugin C++ — setWallpaper + register protocol channels"
```

---

### Task 5: Wire providers + main.dart

**Files:**
- Modify: `lib/providers.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Update providers.dart**

Replace the current stub providers with platform-conditional providers and add `protocolRegistrarProvider`. The full updated file:

```dart
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/app_settings.dart';
import 'platform/app_notifier.dart';
import 'platform/local_notifier_app_notifier.dart';
import 'platform/protocol_registrar.dart';
import 'platform/wallpaper_setter.dart';
import 'platform/windows_protocol_registrar.dart';
import 'platform/windows_wallpaper_setter.dart';
import 'services/cache_manager.dart';
import 'services/config_service.dart';
import 'services/scheduler_service.dart';
import 'services/wallpaper_service.dart';
import 'sources/aiwpme_source.dart';
import 'sources/local_folder_source.dart';
import 'sources/unsplash_source.dart';
import 'sources/wallhaven_source.dart';
import 'sources/wallpaper_source.dart';

// ── Infrastructure ────────────────────────────────────────────────────────────

final dioProvider = Provider<Dio>((ref) => Dio());

final configServiceProvider = Provider<ConfigService>((ref) => ConfigService());

final cacheManagerProvider = Provider<CacheManager>((ref) {
  return CacheManager();
});

final schedulerServiceProvider =
    Provider<SchedulerService>((ref) => SchedulerService());

final wallpaperSetterProvider = Provider<WallpaperSetter>((ref) =>
    Platform.isWindows ? WindowsWallpaperSetter() : StubWallpaperSetter());

final appNotifierProvider = Provider<AppNotifier>((ref) => Platform.isWindows
    ? LocalNotifierAppNotifier()
    : StubAppNotifier());

final protocolRegistrarProvider = Provider<ProtocolRegistrar>((ref) =>
    Platform.isWindows
        ? WindowsProtocolRegistrar()
        : StubProtocolRegistrar());

// ── Settings ─────────────────────────────────────────────────────────────────

final appSettingsProvider = FutureProvider<AppSettings>((ref) {
  return ref.watch(configServiceProvider).load();
});

// ── Sources ───────────────────────────────────────────────────────────────────

final aiwpmeSourceProvider = Provider<WallpaperSource>(
  (ref) => AiwpmeSource(dio: ref.watch(dioProvider)),
);

final unsplashSourceProvider = Provider<WallpaperSource>((ref) {
  final settings = ref.watch(appSettingsProvider).valueOrNull;
  return UnsplashSource(
    apiKey: settings?.unsplashApiKey,
    dio: ref.watch(dioProvider),
  );
});

final wallhavenSourceProvider = Provider<WallpaperSource>((ref) {
  final settings = ref.watch(appSettingsProvider).valueOrNull;
  return WallhavenSource(
    apiKey: settings?.wallhavenApiKey,
    dio: ref.watch(dioProvider),
  );
});

final localFolderSourceProvider = Provider<WallpaperSource>((ref) {
  final settings = ref.watch(appSettingsProvider).valueOrNull;
  return LocalFolderSource(folderPath: settings?.localFolderPath);
});

/// All sources indexed by their [WallpaperSource.id].
final allSourcesProvider = Provider<Map<String, WallpaperSource>>((ref) => {
      'aiwpme': ref.watch(aiwpmeSourceProvider),
      'unsplash': ref.watch(unsplashSourceProvider),
      'wallhaven': ref.watch(wallhavenSourceProvider),
      'local': ref.watch(localFolderSourceProvider),
    });

// ── WallpaperService ──────────────────────────────────────────────────────────

final wallpaperServiceProvider = Provider<WallpaperService>((ref) {
  final settings = ref.watch(appSettingsProvider).valueOrNull;
  return WallpaperService(
    cacheManager: ref.watch(cacheManagerProvider),
    wallpaperSetter: ref.watch(wallpaperSetterProvider),
    notifier: ref.watch(appNotifierProvider),
    cacheSizeLimitMb: settings?.cacheSizeLimitMb ?? 500,
  );
});
```

- [ ] **Step 2: Run existing tests to catch regressions**

```
flutter test
```

Expected: All tests pass. (The providers change is additive — no existing tests break.)

- [ ] **Step 3: Update main.dart**

Replace the current `main.dart` content with:

```dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_notifier/local_notifier.dart';
import 'app.dart';
import 'platform/windows_protocol_registrar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await localNotifier.setup(appName: 'Wallpaper Changer');

  if (Platform.isWindows) {
    try {
      await WindowsProtocolRegistrar().register();
    } catch (e) {
      debugPrint('Protocol registration failed: $e');
    }
  }

  runApp(const ProviderScope(child: WallpaperChangerApp()));
}
```

- [ ] **Step 4: Run flutter analyze**

```
flutter analyze
```

Expected: No issues found.

- [ ] **Step 5: Commit**

```bash
git add lib/providers.dart lib/main.dart
git commit -m "feat: wire Windows platform impls in providers + init local_notifier on startup"
```

---

## Manual Integration Test (Windows)

After all tasks are complete, verify on Windows:

1. `flutter run -d windows` — app launches without crash
2. Navigate to Discover, set a wallpaper → desktop background changes
3. Open `regedit`, navigate to `HKCU\Software\Classes\wallpaper0-changer` → keys present:
   - `(Default)` = `URL:wallpaper0-changer Protocol`
   - `URL Protocol` = `""`
   - `shell\open\command\(Default)` = `"<path to runner.exe>" "%1"`
4. When wallpaper is set → Windows notification toast appears with title "Wallpaper updated"
