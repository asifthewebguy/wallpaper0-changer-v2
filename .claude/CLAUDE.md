# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Install dependencies
flutter pub get

# Run all tests
flutter test

# Run a single test file
flutter test test/path/to/file_test.dart

# Run the app locally
flutter run -d windows
flutter run -d linux
flutter run -d macos

# Build for release
flutter build windows --release   # requires Visual Studio + "Desktop development with C++" workload
flutter build linux --release     # requires GTK deps (see CI workflow)
flutter build macos --release

# Lint / analyze
flutter analyze
```

## Architecture

**Flutter desktop app** targeting Windows, Linux, and macOS. No mobile or web targets.

- **State management:** Riverpod (`AsyncNotifier`, `StreamProvider`, `StateNotifier`)
- **Navigation:** `NavigationBar` in `AppBar.bottom` slot — top nav with 5 pages
- **Theme:** Dark glassmorphism — `lib/theme/app_colors.dart` + `lib/theme/app_theme.dart`

### Feature-first folder layout

Each feature lives in `lib/features/<name>/` with two files:
- `<name>_screen.dart` — the UI widget (reads from provider)
- `<name>_provider.dart` — the Riverpod `AsyncNotifier` or `Notifier`

### Key abstractions

| Interface | Location | Responsibility |
|---|---|---|
| `WallpaperSource` | `lib/sources/wallpaper_source.dart` | Browse/random/download from a source (aiwp.me, Unsplash, Wallhaven, LocalFolder) |
| `WallpaperSetter` | `lib/platform/wallpaper_setter.dart` | Set desktop wallpaper — platform-specific impl |
| `ProtocolRegistrar` | `lib/platform/protocol_registrar.dart` | Register `wallpaper0-changer:` URL scheme — platform-specific |

### Platform channels (native code)

OS-specific implementations live in the platform runner directories:
- `windows/runner/` — C++ plugins (SystemParametersInfo, Registry)
- `linux/runner/` — C++ plugins (gsettings/KDE/feh + xdg-mime)
- `macos/Runner/` — Swift plugins (NSWorkspace, CFBundleURLSchemes)

### Set-wallpaper flow

```
User action / protocol / scheduler
  → Feature provider (Riverpod AsyncNotifier)
  → WallpaperService.setWallpaper(image)
      → ValidationService.validate(image)
      → CacheManager.getOrDownload(image, source)
      → WallpaperSetter.set(localFilePath)    ← platform channel
      → CacheManager.recordHistory(image)
      → LocalNotifier.show(message)
```

## Conventions

- Use `abstract final class` for static-only utility classes (e.g., `AppColors`, `AppTheme`)
- Use `withValues(alpha: x)` — **not** `withOpacity()` (deprecated in Flutter 3.27+)
- TDD: write the failing test first, verify it fails, then implement
- `flutter_test` + `mocktail` for all tests
- Use `IndexedStack` for screen switching — **not** `static const` widget lists
- Only use `ConsumerStatefulWidget` when the widget actually reads a Riverpod provider
- Settings stored at: `%APPDATA%\wallpaper_changer\settings.json` (Windows), `~/.config/wallpaper_changer/settings.json` (Linux/macOS) via `path_provider`

## Agent gotchas

- `rg` (ripgrep) may not be on PATH — use `grep` or PowerShell `Select-String`
- `flutter build windows` requires Visual Studio 2022 with the **"Desktop development with C++"** workload — without it the build fails immediately
- Linux builds require system packages: `clang cmake ninja-build pkg-config libgtk-3-dev libayatana-appindicator3-dev libglib2.0-dev libx11-dev liblzma-dev libstdc++-12-dev`
- `flutter config --enable-windows-desktop` / `--enable-linux-desktop` / `--enable-macos-desktop` must be run once per machine/CI runner before `flutter build`
- Platform channel native code lives in the runner directories — Dart-side interface is in `lib/platform/`

## Design docs

| Doc | Contents |
|---|---|
| `docs/superpowers/specs/2026-04-15-modernization-design.md` | Full v2.0 design spec (Flutter, Riverpod, sources, platform channels, UI) |
| `docs/superpowers/plans/2026-04-15-v2-foundation.md` | Plan 1 — Foundation (completed: scaffold, theme, nav, CI) |
