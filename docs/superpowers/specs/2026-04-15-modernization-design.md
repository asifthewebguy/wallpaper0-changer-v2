# Wallpaper Changer v2.0 — Modernization Design Spec

**Date:** 2026-04-15  
**Status:** Approved  

---

## Overview

Full holistic rethink of Wallpaper Changer: complete rewrite in Flutter + Dart targeting Windows, Linux, and macOS desktop. Dark glassmorphism visual design, Riverpod state management, multi-source wallpaper support, and native platform channels for OS-specific operations.

The existing .NET/C# codebase is retired. All business logic is re-implemented in Dart.

---

## Decisions

| Dimension | Decision |
|---|---|
| UI Framework | Flutter (Dart) — desktop targets: Windows, Linux, macOS |
| State management | Riverpod (`AsyncNotifier`, `StreamProvider`) |
| Visual design | Dark glassmorphism (indigo/purple accent, deep dark background) |
| Navigation | Top navigation bar (Discover, History, Schedule, Sources, Settings) |
| Wallpaper sources | aiwp.me, Unsplash (free API key), Wallhaven (optional key), Local Folder |
| OS integration | Flutter platform channels (C++/Swift native plugins per platform) |
| Linux wallpaper setting | Auto-detect DE + user-configurable command override (`%FILE%` placeholder) |

---

## Project Structure

```
wallpaper_changer/                        (Flutter project root)
├── lib/
│   ├── main.dart                         (entry point, ProviderScope, DI)
│   ├── app.dart                          (app shell, top nav routing)
│   ├── features/
│   │   ├── discover/
│   │   │   ├── discover_screen.dart      (wallpaper grid, search, Set Now)
│   │   │   └── discover_provider.dart    (AsyncNotifier — browse/random)
│   │   ├── history/
│   │   │   ├── history_screen.dart
│   │   │   └── history_provider.dart
│   │   ├── schedule/
│   │   │   ├── schedule_screen.dart
│   │   │   └── schedule_provider.dart
│   │   ├── sources/
│   │   │   ├── sources_screen.dart       (add/configure/reorder sources)
│   │   │   └── sources_provider.dart
│   │   └── settings/
│   │       ├── settings_screen.dart
│   │       └── settings_provider.dart
│   ├── services/
│   │   ├── wallpaper_service.dart        (orchestration — fetch → download → set → cache)
│   │   ├── cache_manager.dart            (LRU cache, JSON metadata, file store)
│   │   ├── config_service.dart           (JSON settings persistence)
│   │   ├── scheduler_service.dart        (timer-based auto-rotation)
│   │   └── validation_service.dart       (input validation, SSRF/path-traversal guards)
│   ├── sources/
│   │   ├── wallpaper_source.dart         (abstract interface)
│   │   ├── aiwpme_source.dart
│   │   ├── unsplash_source.dart
│   │   ├── wallhaven_source.dart
│   │   └── local_folder_source.dart
│   ├── platform/
│   │   ├── wallpaper_setter.dart         (abstract interface)
│   │   └── protocol_registrar.dart       (abstract interface)
│   └── models/
│       ├── wallpaper_image.dart          (unified model across sources)
│       ├── app_settings.dart
│       └── cached_image.dart
├── windows/
│   └── runner/wallpaper_plugin.cpp       (SystemParametersInfo, registry protocol)
├── linux/
│   └── runner/wallpaper_plugin.cc        (gsettings/KDE/feh, xdg-mime)
├── macos/
│   └── Runner/WallpaperPlugin.swift      (NSWorkspace, CFBundleURLSchemes)
└── test/
    ├── services/                          (unit tests for all services)
    ├── providers/                         (Riverpod provider tests)
    └── sources/                           (source adapter tests, HTTP mocked)
```

---

## Key Dart Packages

| Package | Purpose |
|---|---|
| `flutter_riverpod` | State management |
| `dio` | HTTP client (retry interceptors replace Polly) |
| `cached_network_image` | Thumbnail loading + in-memory cache |
| `path_provider` | Cross-platform file paths (`getApplicationSupportDirectory`) |
| `shared_preferences` | Lightweight settings persistence |
| `tray_manager` | System tray icon + context menu (Windows/Linux/macOS) |
| `window_manager` | Minimize to tray, single-instance window control |
| `local_notifier` | Desktop toast notifications |
| `go_router` | Declarative routing for top nav |
| `mocktail` | Mocking in tests |

---

## Source Abstraction

### Abstract interface (`wallpaper_source.dart`)

```dart
abstract interface class WallpaperSource {
  String get id;
  String get displayName;
  bool get requiresApiKey;

  Future<List<WallpaperImage>> browse({String? query, int page = 1});
  Future<WallpaperImage> getRandom();
  Future<Stream<List<int>>> download(WallpaperImage image, {void Function(int, int)? onProgress});
}
```

### WallpaperImage model

```dart
class WallpaperImage {
  final String id;
  final String sourceId;
  final String thumbnailUrl;
  final String downloadUrl;
  final int width;
  final int height;
  final String format;
}
```

### Sources shipping in v2.0

| Source | Auth | Notes |
|---|---|---|
| aiwp.me | None | Re-implement existing API calls in Dart |
| Unsplash | Free API key (user-provided) | 50 req/hour free tier |
| Wallhaven | Optional API key | SFW-only without key |
| Local Folder | None | `Directory.list()` scan, serves files directly |

---

## Set-Wallpaper Flow

```
User taps "Set Now" / protocol activation / scheduler tick
  → DiscoverNotifier.setWallpaper(image)
  → WallpaperService.setWallpaper(image)
      → ValidationService.validate(image)
      → CacheManager.getOrDownload(image, source, onProgress)
      → WallpaperSetter.set(localFilePath)       ← platform channel
      → CacheManager.recordHistory(image)
      → LocalNotifier.show(success message)
```

Errors bubble up through Riverpod `AsyncValue.error` → UI shows non-blocking toast.

---

## Platform Channels (Native Plugins)

### WallpaperSetter

| Platform | Native implementation |
|---|---|
| Windows | `wallpaper_plugin.cpp` → `SystemParametersInfo(SPI_SETDESKWALLPAPER)` |
| Linux | `wallpaper_plugin.cc` → auto-detect: `gsettings` (GNOME) → `plasma-apply-wallpaperimage` (KDE) → `xfconf-query` (XFCE) → `feh --bg-scale` (fallback). Reads user override command from settings. |
| macOS | `WallpaperPlugin.swift` → `NSWorkspace.shared.setDesktopImageURL()` |

### ProtocolRegistrar

| Platform | Mechanism |
|---|---|
| Windows | Registry `HKCU\Software\Classes\wallpaper0-changer` (C++ via plugin) |
| Linux | `~/.local/share/applications/wallpaper-changer.desktop` + `xdg-mime default` |
| macOS | `Info.plist` CFBundleURLSchemes (registered at build time) |

### Single-instance + IPC

`window_manager` package handles bring-to-front. Protocol activations from the OS pass arguments via `app_links` package (handles deep links on all platforms).

---

## UI Design

**Style:** Dark glassmorphism — `#0a0a0f` base, `#6366f1`/`#a855f7` indigo-purple accents, `BoxDecoration` with `borderRadius`, subtle `BoxShadow` glow effects. Flutter's `CustomPaint` for any glass blur effects.

**Navigation:** `NavigationBar` (top) with 5 destinations. Active page: indigo tinted background. Source switcher `DropdownButton` in app bar trailing slot.

**Discover page:**
- `TextField` search + Random `OutlinedButton` + Set Now `FilledButton` (gradient via `ShaderMask`)
- `GridView.builder` with 4 columns; active wallpaper has indigo glow border + badge overlay
- Bottom status bar: cache usage + next rotation countdown (`StreamProvider`)

**Settings persistence:**
- Windows: `%APPDATA%\wallpaper_changer\settings.json`
- Linux/macOS: `~/.config/wallpaper_changer/settings.json`
- Cache metadata JSON format new (no v1 backwards compatibility needed — full rewrite)

---

## Testing Strategy

| Layer | Scope | Tools |
|---|---|---|
| Services | Business logic, cache, validation, scheduler | `flutter_test` + `mocktail` |
| Providers | Riverpod notifier state transitions, error paths | `flutter_riverpod` test utilities |
| Source adapters | HTTP responses, pagination, error handling | `mocktail` + `dio` mock adapter |
| Platform channels | Wallpaper setter smoke tests | Platform-conditional integration tests |
| Widget tests | Discover grid, navigation, settings form | `flutter_test` `WidgetTester` |

---

## Migration & Delivery

- **New GitHub repository** — Flutter project starts in a fresh repo (e.g. `wallpaper-changer` or `wallpaper0-changer-v2`)
- Existing `wallpaper0-changer` repo is **archived** (read-only) on GitHub once v2.0 ships; README updated to point to new repo
- CI: GitHub Actions matrix build — `flutter build windows`, `flutter build linux`, `flutter build macos`

---

## Out of Scope (v2.0)

- Android / iOS / Web targets (Flutter supports them — easy to add later)
- Plugin system for third-party sources
- Multi-monitor per-display wallpaper management
- Auto-updater (Sparkle / WinSparkle integration)
- macOS App Store / Microsoft Store / Linux Flatpak packaging (separate task)
