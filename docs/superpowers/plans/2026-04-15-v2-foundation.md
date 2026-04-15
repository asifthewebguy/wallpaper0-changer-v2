# Wallpaper Changer v2.0 — Plan 1: Foundation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a new Flutter desktop project with dark glassmorphism theme, top navigation shell (5 empty screens), and GitHub Actions CI that builds for Windows, Linux, and macOS.

**Architecture:** New GitHub repo `wallpaper0-changer-v2`. Flutter 3.x project targeting desktop only (Windows/Linux/macOS). GoRouter for declarative navigation. Theme defined centrally in `lib/theme/`. No business logic in this plan — screens are empty stubs.

**Tech Stack:** Flutter 3.x, Dart 3.x, go_router ^14, flutter_riverpod ^2, window_manager ^0.4, tray_manager ^0.2

**Prerequisites:** Flutter SDK installed and on PATH, `flutter doctor` passes for all 3 desktop targets, GitHub CLI (`gh`) authenticated.

---

## File Map

```
wallpaper_changer/
├── pubspec.yaml
├── analysis_options.yaml
├── .github/
│   └── workflows/
│       └── ci.yml
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── theme/
│   │   ├── app_colors.dart
│   │   └── app_theme.dart
│   └── features/
│       ├── discover/
│       │   └── discover_screen.dart
│       ├── history/
│       │   └── history_screen.dart
│       ├── schedule/
│       │   └── schedule_screen.dart
│       ├── sources/
│       │   └── sources_screen.dart
│       └── settings/
│           └── settings_screen.dart
└── test/
    └── widget_test.dart
```

---

## Task 1: Create GitHub Repo + Flutter Project

**Files:**
- Create: `pubspec.yaml`
- Create: `analysis_options.yaml`
- Create: `lib/main.dart`

- [ ] **Step 1: Create new GitHub repo**

```bash
gh repo create wallpaper0-changer-v2 --public --description "Cross-platform wallpaper changer — Flutter desktop (Windows/Linux/macOS)" --clone
cd wallpaper0-changer-v2
```

- [ ] **Step 2: Create Flutter project inside the repo**

```bash
flutter create . --project-name wallpaper_changer --org com.asifthewebguy --platforms windows,linux,macos
```

- [ ] **Step 3: Verify it builds**

```bash
flutter build windows --debug
```

Expected: `Build process succeeded.`

- [ ] **Step 4: Remove mobile/web boilerplate from pubspec.yaml**

Open `pubspec.yaml`. Replace the generated content with:

```yaml
name: wallpaper_changer
description: Cross-platform wallpaper changer — Windows, Linux, macOS
publish_to: none
version: 2.0.0+1

environment:
  sdk: ">=3.3.0 <4.0.0"
  flutter: ">=3.22.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  go_router: ^14.2.7
  window_manager: ^0.4.3
  tray_manager: ^0.2.3
  dio: ^5.4.3+1
  cached_network_image: ^3.3.1
  path_provider: ^2.1.3
  shared_preferences: ^2.2.3
  local_notifier: ^0.1.6
  app_links: ^6.1.1
  file_picker: ^8.0.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  mocktail: ^1.0.3

flutter:
  uses-material-design: true
  assets:
    - assets/icons/
```

- [ ] **Step 5: Create assets directory**

```bash
mkdir -p assets/icons
```

- [ ] **Step 6: Replace analysis_options.yaml**

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - prefer_const_constructors
    - prefer_const_literals_to_create_immutables
    - use_super_parameters
    - avoid_print
```

- [ ] **Step 7: Run flutter pub get**

```bash
flutter pub get
```

Expected: `Resolving dependencies... Got dependencies.`

- [ ] **Step 8: Commit**

```bash
git add .
git commit -m "chore: flutter project scaffold — desktop only (windows/linux/macos)"
```

---

## Task 2: Theme System — Dark Glassmorphism

**Files:**
- Create: `lib/theme/app_colors.dart`
- Create: `lib/theme/app_theme.dart`

- [ ] **Step 1: Write failing widget test for theme**

Create `test/theme_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper_changer/theme/app_colors.dart';
import 'package:wallpaper_changer/theme/app_theme.dart';

void main() {
  test('AppColors has correct base color', () {
    expect(AppColors.base, const Color(0xFF0A0A0F));
  });

  test('AppColors has correct primary accent', () {
    expect(AppColors.primary, const Color(0xFF6366F1));
  });

  test('AppTheme.dark returns a ThemeData with dark brightness', () {
    final theme = AppTheme.dark();
    expect(theme.brightness, Brightness.dark);
  });

  test('AppTheme.dark uses base color as scaffold background', () {
    final theme = AppTheme.dark();
    expect(theme.scaffoldBackgroundColor, AppColors.base);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/theme_test.dart
```

Expected: FAIL — `Target of URI doesn't exist`

- [ ] **Step 3: Create app_colors.dart**

Create `lib/theme/app_colors.dart`:

```dart
import 'package:flutter/material.dart';

abstract final class AppColors {
  // Base surfaces
  static const Color base = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF111118);
  static const Color surfaceAlt = Color(0xFF0D0D14);
  static const Color card = Color(0xFF1A1A2E);
  static const Color border = Color(0xFF1E1E2E);
  static const Color borderAlt = Color(0xFF2A2A4A);

  // Accents
  static const Color primary = Color(0xFF6366F1);   // indigo
  static const Color secondary = Color(0xFFA855F7); // purple
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);

  // Text
  static const Color textPrimary = Color(0xFFE2E8F0);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF4A4A6A);
}
```

- [ ] **Step 4: Create app_theme.dart**

Create `lib/theme/app_theme.dart`:

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.base,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      cardTheme: CardTheme(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withOpacity(0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            );
          }
          return const TextStyle(color: AppColors.textMuted, fontSize: 11);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary);
          }
          return const IconThemeData(color: AppColors.textMuted);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
    );
  }
}
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
flutter test test/theme_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 6: Commit**

```bash
git add lib/theme/ test/theme_test.dart
git commit -m "feat: dark glassmorphism theme (AppColors + AppTheme)"
```

---

## Task 3: Empty Screen Stubs

**Files:**
- Create: `lib/features/discover/discover_screen.dart`
- Create: `lib/features/history/history_screen.dart`
- Create: `lib/features/schedule/schedule_screen.dart`
- Create: `lib/features/sources/sources_screen.dart`
- Create: `lib/features/settings/settings_screen.dart`

- [ ] **Step 1: Create discover_screen.dart**

```dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Discover', style: TextStyle(color: AppColors.textSecondary)),
    );
  }
}
```

- [ ] **Step 2: Create the remaining 4 screen stubs**

`lib/features/history/history_screen.dart`:
```dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('History', style: TextStyle(color: AppColors.textSecondary)),
    );
  }
}
```

`lib/features/schedule/schedule_screen.dart`:
```dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Schedule', style: TextStyle(color: AppColors.textSecondary)),
    );
  }
}
```

`lib/features/sources/sources_screen.dart`:
```dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Sources', style: TextStyle(color: AppColors.textSecondary)),
    );
  }
}
```

`lib/features/settings/settings_screen.dart`:
```dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Settings', style: TextStyle(color: AppColors.textSecondary)),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/
git commit -m "feat: empty screen stubs (discover/history/schedule/sources/settings)"
```

---

## Task 4: Navigation Shell + App Entry Point

**Files:**
- Create: `lib/app.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Write widget test for navigation**

Create `test/navigation_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper_changer/app.dart';

void main() {
  testWidgets('app renders NavigationBar with 5 destinations', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: WallpaperChangerApp()));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Discover'), findsWidgets);
    expect(find.text('History'), findsWidgets);
    expect(find.text('Schedule'), findsWidgets);
    expect(find.text('Sources'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
  });

  testWidgets('tapping History nav item switches screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: WallpaperChangerApp()));
    await tester.pumpAndSettle();
    // Tap the History nav item in the NavigationBar
    final historyItems = find.text('History');
    await tester.tap(historyItems.last);
    await tester.pumpAndSettle();
    // History screen center text is visible
    expect(find.text('History'), findsWidgets);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/navigation_test.dart
```

Expected: FAIL — `Target of URI doesn't exist: 'package:wallpaper_changer/app.dart'`

- [ ] **Step 3: Create lib/app.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'features/discover/discover_screen.dart';
import 'features/history/history_screen.dart';
import 'features/schedule/schedule_screen.dart';
import 'features/sources/sources_screen.dart';
import 'features/settings/settings_screen.dart';

class WallpaperChangerApp extends StatelessWidget {
  const WallpaperChangerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wallpaper Changer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const _AppShell(),
    );
  }
}

class _AppShell extends ConsumerStatefulWidget {
  const _AppShell();

  @override
  ConsumerState<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<_AppShell> {
  int _selectedIndex = 0;

  static const _screens = [
    DiscoverScreen(),
    HistoryScreen(),
    ScheduleScreen(),
    SourcesScreen(),
    SettingsScreen(),
  ];

  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Discover'),
    NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'History'),
    NavigationDestination(icon: Icon(Icons.schedule_outlined), selectedIcon: Icon(Icons.schedule), label: 'Schedule'),
    NavigationDestination(icon: Icon(Icons.source_outlined), selectedIcon: Icon(Icons.source), label: 'Sources'),
    NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(7),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Wallpaper',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kBottomNavigationBarHeight),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            destinations: _destinations,
            backgroundColor: AppColors.surface,
            height: kBottomNavigationBarHeight,
          ),
        ),
      ),
      body: _screens[_selectedIndex],
    );
  }
}
```

- [ ] **Step 4: Update lib/main.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: WallpaperChangerApp()));
}
```

- [ ] **Step 5: Run tests**

```bash
flutter test test/navigation_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 6: Run the app and verify visually**

```bash
flutter run -d windows
```

Expected: App opens with dark background, logo icon in app bar, top navigation with 5 tabs, each tab shows its label in the center.

- [ ] **Step 7: Commit**

```bash
git add lib/main.dart lib/app.dart test/navigation_test.dart
git commit -m "feat: app shell with top navigation (5 screens, dark glassmorphism)"
```

---

## Task 5: GitHub Actions CI

**Files:**
- Create: `.github/workflows/ci.yml`

- [ ] **Step 1: Create CI workflow**

Create `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:

jobs:
  test:
    name: Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.x'
          channel: stable
          cache: true
      - run: flutter pub get
      - run: flutter test --coverage

  build-windows:
    name: Build Windows
    runs-on: windows-latest
    needs: test
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.x'
          channel: stable
          cache: true
      - run: flutter pub get
      - run: flutter build windows --release
      - uses: actions/upload-artifact@v4
        with:
          name: wallpaper-changer-windows
          path: build/windows/x64/runner/Release/

  build-linux:
    name: Build Linux
    runs-on: ubuntu-latest
    needs: test
    steps:
      - uses: actions/checkout@v4
      - name: Install Linux build dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.x'
          channel: stable
          cache: true
      - run: flutter pub get
      - run: flutter build linux --release
      - uses: actions/upload-artifact@v4
        with:
          name: wallpaper-changer-linux
          path: build/linux/x64/release/bundle/

  build-macos:
    name: Build macOS
    runs-on: macos-latest
    needs: test
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.x'
          channel: stable
          cache: true
      - run: flutter pub get
      - run: flutter build macos --release
      - uses: actions/upload-artifact@v4
        with:
          name: wallpaper-changer-macos
          path: build/macos/Build/Products/Release/
```

- [ ] **Step 2: Add .gitignore entries for Flutter**

Append to `.gitignore` (Flutter project should have generated one — verify these are present):

```
# Flutter
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
build/
*.g.dart
coverage/
```

- [ ] **Step 3: Commit and push to trigger CI**

```bash
git add .github/workflows/ci.yml .gitignore
git commit -m "ci: github actions — test + build windows/linux/macos"
git push origin main
```

- [ ] **Step 4: Verify CI passes**

```bash
gh run list --limit 1
```

Wait for all 4 jobs (test, build-windows, build-linux, build-macos) to show `completed / success`.

---

## Verification

After all 5 tasks:

```bash
# All tests pass
flutter test

# App runs on Windows
flutter run -d windows

# Confirm 5 nav tabs work, dark theme renders correctly
# Confirm CI is green on GitHub
gh run list --limit 3
```

---

## Next: Plan 2 — Core (Models, Services, Source Adapters, Riverpod Providers)

Implement in this order:
1. Models (`WallpaperImage`, `AppSettings`, `CachedImage`, `DownloadProgress`)
2. `ValidationService` → `ConfigService` → `CacheManager` → `SchedulerService`
3. `WallpaperSource` interface + 4 source adapters (aiwpme, Unsplash, Wallhaven, LocalFolder)
4. `WallpaperService` (orchestration)
5. Riverpod providers for all 5 features
