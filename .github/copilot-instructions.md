# Project Guidelines

## Architecture

- Flutter desktop app targeting Windows, Linux, and macOS only (no mobile/web).
- State management: Riverpod (`AsyncNotifier`, `StreamProvider`). No other state solution.
- Feature-first layout: `lib/features/<name>/<name>_screen.dart` + `<name>_provider.dart`.
- Theme lives in `lib/theme/app_colors.dart` (color constants) and `lib/theme/app_theme.dart` (ThemeData factory). Dark glassmorphism — indigo/purple accents on deep dark backgrounds.
- Wallpaper sources are abstracted behind `WallpaperSource` in `lib/sources/wallpaper_source.dart`. Implementations: `AiwpmeSource`, `UnsplashSource`, `WallhavenSource`, `LocalFolderSource`.
- Platform-specific operations (set wallpaper, register URL scheme) use Flutter platform channels. Dart interfaces in `lib/platform/`. Native code in `windows/runner/`, `linux/runner/`, `macos/Runner/`.

## Build and Test

- Install deps: `flutter pub get`
- Run tests: `flutter test`
- Run single test: `flutter test test/path/to/file_test.dart`
- Run app: `flutter run -d windows` (or `-d linux`, `-d macos`)
- Build release: `flutter build windows --release` (requires Visual Studio + C++ workload)
- Lint: `flutter analyze`

## Conventions

- Use `abstract final class` for static-only classes (like `AppColors`, `AppTheme`).
- Use `withValues(alpha: x)` not `withOpacity()` — deprecated in Flutter 3.27+.
- TDD strictly: write failing test → verify fail → implement → verify pass → commit.
- Tests use `flutter_test` + `mocktail`. No other mocking library.
- Screen switching uses `IndexedStack` — never `static const` widget lists.
- Only use `ConsumerStatefulWidget` when the widget actually reads a Riverpod provider.
- All input from users, protocols, or external APIs must be validated before file/network ops.

## Agent Gotchas

- `rg` (ripgrep) may not be on PATH — use `grep` or PowerShell `Select-String`.
- `flutter build windows` silently fails without Visual Studio "Desktop development with C++" workload.
- Linux builds need: `libgtk-3-dev libayatana-appindicator3-dev libglib2.0-dev libx11-dev clang cmake ninja-build pkg-config`.
- Run `flutter config --enable-<platform>-desktop` before building on a fresh machine or CI runner.
- Platform channel code: `windows/runner/` (C++), `linux/runner/` (C++), `macos/Runner/` (Swift).

## Docs Map

| Doc | Contents |
|---|---|
| `docs/superpowers/specs/2026-04-15-modernization-design.md` | Full design spec (sources, platform channels, UI, architecture) |
| `docs/superpowers/plans/2026-04-15-v2-foundation.md` | Plan 1 — Foundation (completed) |
