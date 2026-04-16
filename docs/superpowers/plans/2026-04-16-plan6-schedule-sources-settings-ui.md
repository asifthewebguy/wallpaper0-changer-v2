# Plan 6 — Schedule + Sources + Settings UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the remaining three stub screens (Schedule, Sources, Settings) with fully functional glassmorphic UI that exposes every `AppSettings` field and scheduler control.

**Architecture:** Three screens backed by pre-existing notifiers (`ScheduleNotifier`, `SourcesNotifier`, `SettingsNotifier`). One new shared widget `GlassFormField` (on-blur save pattern). Two new `StateProvider`s for cross-screen navigation (index + scroll target). Existing `_AppShell` converts from `StatefulWidget` to `ConsumerWidget` to observe the index provider.

**Tech Stack:** Flutter Riverpod, `file_picker: ^8.0.3` (already in pubspec), `flutter_test` + `mocktail`

---

## File Map

| File | Action | Purpose |
|---|---|---|
| `lib/providers.dart` | Modify | Add `currentPageIndexProvider` + `settingsScrollTargetProvider` |
| `lib/app.dart` | Modify | Convert `_AppShell` to `ConsumerWidget` observing `currentPageIndexProvider` |
| `lib/widgets/glass_form_field.dart` | Create | Reusable on-blur text input with glassmorphic styling |
| `lib/features/schedule/schedule_screen.dart` | Replace | Full scheduler UI (toggle, interval, countdown, Set Now) |
| `lib/features/sources/sources_screen.dart` | Replace | List of 4 sources with toggles + Configure → link |
| `lib/features/settings/settings_screen.dart` | Replace | API keys, local folder, cache, Linux sections |
| `test/widgets/glass_form_field_test.dart` | Create | Initial, onBlur fires, no-fire unchanged |
| `test/features/schedule/schedule_screen_test.dart` | Create | Toggle, dropdown, countdown, Set Now |
| `test/features/sources/sources_screen_test.dart` | Create | 4 rows, toggle, disabled state, Configure → |
| `test/features/settings/settings_screen_test.dart` | Create | Field render, on-blur save, Browse button |
| `test/navigation_test.dart` | Modify | Update for new provider wiring |

---

## Task 1: Cross-screen navigation providers + AppShell rewire

**Files:**
- Modify: `lib/providers.dart`
- Modify: `lib/app.dart`
- Modify: `test/navigation_test.dart`

- [ ] **Step 1: Add the two providers to providers.dart**

Add these two lines near the top of `lib/providers.dart`, right after the existing `selectedSourceProvider = StateProvider<String>(...)` declaration:

```dart
final currentPageIndexProvider = StateProvider<int>((ref) => 0);
final settingsScrollTargetProvider = StateProvider<String?>((ref) => null);
```

- [ ] **Step 2: Convert `_AppShell` to a ConsumerWidget**

Replace the `_AppShell` and `_AppShellState` classes in `lib/app.dart` with:

```dart
class _AppShell extends ConsumerWidget {
  const _AppShell();

  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Discover'),
    NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'History'),
    NavigationDestination(icon: Icon(Icons.schedule_outlined), selectedIcon: Icon(Icons.schedule), label: 'Schedule'),
    NavigationDestination(icon: Icon(Icons.source_outlined), selectedIcon: Icon(Icons.source), label: 'Sources'),
    NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(currentPageIndexProvider);
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
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Wallpaper Changer',
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
            selectedIndex: selectedIndex,
            onDestinationSelected: (i) =>
                ref.read(currentPageIndexProvider.notifier).state = i,
            destinations: _destinations,
            backgroundColor: AppColors.surface,
            height: kBottomNavigationBarHeight,
          ),
        ),
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: const [
          DiscoverScreen(),
          HistoryScreen(),
          ScheduleScreen(),
          SourcesScreen(),
          SettingsScreen(),
        ],
      ),
    );
  }
}
```

Also add this import at the top of `lib/app.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
```

- [ ] **Step 3: Run the existing navigation test to confirm no regression**

Run: `flutter test test/navigation_test.dart`
Expected: Both existing tests PASS (the test already uses `ProviderScope` — no code changes needed there yet).

- [ ] **Step 4: Add a test that `currentPageIndexProvider` drives navigation**

Append this test inside the `main()` body of `test/navigation_test.dart`:

```dart
  testWidgets('writing to currentPageIndexProvider switches screen',
      (tester) async {
    final container = ProviderContainer(overrides: _overrides());
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const WallpaperChangerApp(),
    ));
    await tester.pumpAndSettle();
    container.read(currentPageIndexProvider.notifier).state = 1;
    await tester.pumpAndSettle();
    expect(find.text('No wallpapers set yet'), findsOneWidget);
  });
```

- [ ] **Step 5: Run the test**

Run: `flutter test test/navigation_test.dart`
Expected: All 3 tests PASS.

- [ ] **Step 6: Run full suite**

Run: `flutter test`
Expected: No regressions (109 tests + 1 new = 110).

- [ ] **Step 7: Commit**

```bash
git add lib/providers.dart lib/app.dart test/navigation_test.dart
git commit -m "feat: currentPageIndexProvider + settingsScrollTargetProvider for cross-screen nav"
```

---

## Task 2: GlassFormField widget

**Files:**
- Create: `lib/widgets/glass_form_field.dart`
- Create: `test/widgets/glass_form_field_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/widgets/glass_form_field_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper_changer/widgets/glass_form_field.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child));

void main() {
  group('GlassFormField', () {
    testWidgets('renders initial value', (tester) async {
      await tester.pumpWidget(_wrap(GlassFormField(
        label: 'Unsplash Key',
        initialValue: 'abc123',
        onBlur: (_) {},
      )));
      expect(find.text('abc123'), findsOneWidget);
      expect(find.text('Unsplash Key'), findsOneWidget);
    });

    testWidgets('onBlur fires with current text when focus lost',
        (tester) async {
      String? committed;
      await tester.pumpWidget(_wrap(GlassFormField(
        label: 'Key',
        initialValue: 'old',
        onBlur: (text) => committed = text,
      )));
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'new');
      // Move focus away
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      expect(committed, 'new');
    });

    testWidgets('onBlur does not fire when text is unchanged',
        (tester) async {
      var calls = 0;
      await tester.pumpWidget(_wrap(GlassFormField(
        label: 'Key',
        initialValue: 'same',
        onBlur: (_) => calls++,
      )));
      await tester.tap(find.byType(TextField));
      await tester.pump();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      expect(calls, 0);
    });

    testWidgets('obscureText hides the input', (tester) async {
      await tester.pumpWidget(_wrap(GlassFormField(
        label: 'Secret',
        initialValue: 'hidden',
        onBlur: (_) {},
        obscureText: true,
      )));
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.obscureText, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/widgets/glass_form_field_test.dart`
Expected: FAIL — `glass_form_field.dart` does not exist.

- [ ] **Step 3: Implement GlassFormField**

Create `lib/widgets/glass_form_field.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassFormField extends StatefulWidget {
  const GlassFormField({
    super.key,
    required this.label,
    required this.onBlur,
    this.initialValue,
    this.obscureText = false,
    this.keyboardType,
    this.helperText,
    this.controller,
  });

  final String label;
  final String? initialValue;
  final void Function(String) onBlur;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? helperText;
  final TextEditingController? controller;

  @override
  State<GlassFormField> createState() => _GlassFormFieldState();
}

class _GlassFormFieldState extends State<GlassFormField> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();
  late String _lastCommitted;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      if (widget.initialValue != null && _controller.text.isEmpty) {
        _controller.text = widget.initialValue!;
      }
    } else {
      _controller = TextEditingController(text: widget.initialValue ?? '');
      _ownsController = true;
    }
    _lastCommitted = _controller.text;
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      final text = _controller.text;
      if (text != _lastCommitted) {
        _lastCommitted = text;
        widget.onBlur(text);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 2),
          child: Text(
            widget.label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
        if (widget.helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 2),
            child: Text(
              widget.helperText!,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/widgets/glass_form_field_test.dart`
Expected: All 4 tests PASS.

- [ ] **Step 5: Run full suite**

Run: `flutter test`
Expected: No regressions.

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/glass_form_field.dart test/widgets/glass_form_field_test.dart
git commit -m "feat: GlassFormField — reusable glassmorphic input with on-blur save"
```

---

## Task 3: ScheduleScreen

**Files:**
- Replace: `lib/features/schedule/schedule_screen.dart`
- Create: `test/features/schedule/schedule_screen_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/features/schedule/schedule_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallpaper_changer/features/schedule/schedule_provider.dart';
import 'package:wallpaper_changer/features/schedule/schedule_screen.dart';
import 'package:wallpaper_changer/features/schedule/schedule_state.dart';
import 'package:wallpaper_changer/models/app_settings.dart';
import 'package:wallpaper_changer/models/wallpaper_image.dart';
import 'package:wallpaper_changer/providers.dart';
import 'package:wallpaper_changer/services/wallpaper_service.dart';
import 'package:wallpaper_changer/sources/wallpaper_source.dart';

class FakeScheduleNotifier extends ScheduleNotifier {
  FakeScheduleNotifier(this._initial);
  final ScheduleState _initial;
  int enableCalls = 0;
  int disableCalls = 0;
  int? lastEnabledInterval;

  @override
  Future<ScheduleState> build() async => _initial;

  @override
  Future<void> enable(int intervalMinutes) async {
    enableCalls++;
    lastEnabledInterval = intervalMinutes;
    state = AsyncValue.data(ScheduleState(
      isEnabled: true,
      intervalMinutes: intervalMinutes,
    ));
  }

  @override
  Future<void> disable() async {
    disableCalls++;
    state = AsyncValue.data(ScheduleState(
      isEnabled: false,
      intervalMinutes: state.valueOrNull?.intervalMinutes ?? 30,
    ));
  }
}

class MockWallpaperService extends Mock implements WallpaperService {}
class MockWallpaperSource extends Mock implements WallpaperSource {}

WallpaperImage _img() => const WallpaperImage(
      id: 'r', sourceId: 'aiwpme',
      thumbnailUrl: 'https://e.com/t.jpg',
      downloadUrl: 'https://e.com/f.jpg',
      width: 1920, height: 1080, format: 'jpg',
    );

void main() {
  late FakeScheduleNotifier notifier;
  late MockWallpaperService wallpaperService;
  late MockWallpaperSource source;

  setUpAll(() {
    registerFallbackValue(_img());
  });

  setUp(() {
    notifier = FakeScheduleNotifier(
      const ScheduleState(isEnabled: false, intervalMinutes: 30),
    );
    wallpaperService = MockWallpaperService();
    source = MockWallpaperSource();
    when(() => source.id).thenReturn('aiwpme');
    when(() => source.displayName).thenReturn('AI Wallpapers');
    when(() => source.getRandom()).thenAnswer((_) async => _img());
    when(() => wallpaperService.setWallpaper(any(), any()))
        .thenAnswer((_) async {});
  });

  Widget wrap() => ProviderScope(
        overrides: [
          scheduleProvider.overrideWith(() => notifier),
          appSettingsProvider.overrideWith((ref) async => const AppSettings()),
          allSourcesProvider.overrideWithValue({'aiwpme': source}),
          wallpaperServiceProvider.overrideWithValue(wallpaperService),
        ],
        child: const MaterialApp(home: Scaffold(body: ScheduleScreen())),
      );

  testWidgets('shows toggle, interval dropdown, and Set Now button',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    expect(find.byType(Switch), findsOneWidget);
    expect(find.byType(DropdownButton<int?>), findsOneWidget);
    expect(find.text('Set Random Wallpaper Now'), findsOneWidget);
  });

  testWidgets('toggling on calls enable with current interval',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(notifier.enableCalls, 1);
    expect(notifier.lastEnabledInterval, 30);
  });

  testWidgets('toggling off calls disable', (tester) async {
    notifier = FakeScheduleNotifier(
      const ScheduleState(isEnabled: true, intervalMinutes: 30),
    );
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(notifier.disableCalls, 1);
  });

  testWidgets('Set Now button triggers wallpaperService.setWallpaper',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set Random Wallpaper Now'));
    await tester.pumpAndSettle();
    verify(() => wallpaperService.setWallpaper(any(), any())).called(1);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/schedule/schedule_screen_test.dart`
Expected: FAIL — screen is a stub with no Switch, DropdownButton, or button.

- [ ] **Step 3: Implement ScheduleScreen**

Replace the full contents of `lib/features/schedule/schedule_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_form_field.dart';
import 'schedule_provider.dart';

const _presetIntervals = [5, 10, 15, 30, 60, 120];

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  bool _customMode = false;
  int _customInterval = 30;
  bool _setNowLoading = false;
  String? _setNowError;

  String _formatCountdown(Duration d) {
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  int _currentInterval(int stateInterval) {
    if (_customMode) return _customInterval;
    return stateInterval;
  }

  Future<void> _onToggle(bool enable, int interval) async {
    final notifier = ref.read(scheduleProvider.notifier);
    if (enable) {
      await notifier.enable(interval);
    } else {
      await notifier.disable();
    }
  }

  Future<void> _onIntervalChanged(int? value, bool isEnabled) async {
    setState(() {
      if (value == null) {
        _customMode = true;
      } else {
        _customMode = false;
        _customInterval = value;
      }
    });
    if (isEnabled) {
      final interval = _currentInterval(value ?? _customInterval);
      final notifier = ref.read(scheduleProvider.notifier);
      await notifier.disable();
      await notifier.enable(interval);
    }
  }

  Future<void> _onSetNow() async {
    setState(() {
      _setNowLoading = true;
      _setNowError = null;
    });
    try {
      final settings = await ref.read(appSettingsProvider.future);
      final sources = ref.read(allSourcesProvider);
      final activeId = settings.activeSourceIds.firstOrNull ?? 'aiwpme';
      final source = sources[activeId] ?? sources['aiwpme']!;
      final image = await source.getRandom();
      await ref.read(wallpaperServiceProvider).setWallpaper(image, source);
      if (mounted) setState(() => _setNowLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _setNowLoading = false;
          _setNowError = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduleState = ref.watch(scheduleProvider);
    final countdownAsync = ref.watch(scheduleCountdownProvider);

    return scheduleState.when(
      data: (state) {
        final displayedInterval = _currentInterval(state.intervalMinutes);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GlassCard(
                title: 'Automatic wallpaper rotation',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Switch(
                          value: state.isEnabled,
                          activeColor: AppColors.primary,
                          onChanged: (v) => _onToggle(v, displayedInterval),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            state.isEnabled
                                ? 'Rotating every $displayedInterval minutes'
                                : 'Disabled',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButton<int?>(
                      value: _customMode
                          ? null
                          : (_presetIntervals.contains(state.intervalMinutes)
                              ? state.intervalMinutes
                              : null),
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(color: AppColors.textPrimary),
                      isExpanded: true,
                      items: [
                        ..._presetIntervals.map(
                          (m) => DropdownMenuItem<int?>(
                            value: m,
                            child: Text('$m minutes'),
                          ),
                        ),
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Custom...'),
                        ),
                      ],
                      onChanged: (v) => _onIntervalChanged(v, state.isEnabled),
                    ),
                    if (_customMode) ...[
                      const SizedBox(height: 12),
                      GlassFormField(
                        label: 'Custom interval (minutes)',
                        initialValue: _customInterval.toString(),
                        keyboardType: TextInputType.number,
                        onBlur: (text) async {
                          final parsed = int.tryParse(text);
                          if (parsed == null || parsed < 1) return;
                          setState(() => _customInterval = parsed);
                          if (state.isEnabled) {
                            final n = ref.read(scheduleProvider.notifier);
                            await n.disable();
                            await n.enable(parsed);
                          }
                        },
                      ),
                    ],
                    if (state.isEnabled) ...[
                      const SizedBox(height: 16),
                      countdownAsync.when(
                        data: (remaining) => Text(
                          'Next change in ${_formatCountdown(remaining)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _GlassCard(
                title: 'Manual',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_setNowLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textPrimary,
                        ),
                        onPressed: _onSetNow,
                        child: const Text('Set Random Wallpaper Now'),
                      ),
                    if (_setNowError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _setNowError!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          e.toString(),
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/schedule/schedule_screen_test.dart`
Expected: All 4 tests PASS.

- [ ] **Step 5: Run full suite**

Run: `flutter test`
Expected: No regressions.

- [ ] **Step 6: Commit**

```bash
git add lib/features/schedule/schedule_screen.dart test/features/schedule/schedule_screen_test.dart
git commit -m "feat: ScheduleScreen — toggle, interval picker, countdown, Set Now"
```

---

## Task 4: SourcesScreen

**Files:**
- Replace: `lib/features/sources/sources_screen.dart`
- Create: `test/features/sources/sources_screen_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/features/sources/sources_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallpaper_changer/features/sources/sources_provider.dart';
import 'package:wallpaper_changer/features/sources/sources_screen.dart';
import 'package:wallpaper_changer/models/app_settings.dart';
import 'package:wallpaper_changer/providers.dart';
import 'package:wallpaper_changer/sources/wallpaper_source.dart';

class FakeSourcesNotifier extends SourcesNotifier {
  FakeSourcesNotifier(this._data);
  final List<WallpaperSource> _data;
  List<String>? lastSetIds;

  @override
  Future<List<WallpaperSource>> build() async => _data;

  @override
  Future<void> setActiveIds(List<String> ids) async {
    lastSetIds = ids;
  }
}

class MockWallpaperSource extends Mock implements WallpaperSource {}

MockWallpaperSource _src(String id, String name, {bool requiresKey = false}) {
  final s = MockWallpaperSource();
  when(() => s.id).thenReturn(id);
  when(() => s.displayName).thenReturn(name);
  when(() => s.requiresApiKey).thenReturn(requiresKey);
  return s;
}

void main() {
  late FakeSourcesNotifier notifier;

  setUp(() {
    notifier = FakeSourcesNotifier([]);
  });

  Widget wrap(AppSettings settings, Map<String, WallpaperSource> sources) {
    return ProviderScope(
      overrides: [
        sourcesProvider.overrideWith(() => notifier),
        appSettingsProvider.overrideWith((ref) async => settings),
        allSourcesProvider.overrideWithValue(sources),
      ],
      child: const MaterialApp(home: Scaffold(body: SourcesScreen())),
    );
  }

  testWidgets('renders one row per source', (tester) async {
    final sources = {
      'aiwpme': _src('aiwpme', 'AI Wallpapers'),
      'unsplash': _src('unsplash', 'Unsplash', requiresKey: true),
      'wallhaven': _src('wallhaven', 'Wallhaven', requiresKey: true),
      'local': _src('local', 'Local Folder'),
    };
    await tester.pumpWidget(wrap(const AppSettings(), sources));
    await tester.pumpAndSettle();
    expect(find.text('AI Wallpapers'), findsOneWidget);
    expect(find.text('Unsplash'), findsOneWidget);
    expect(find.text('Wallhaven'), findsOneWidget);
    expect(find.text('Local Folder'), findsOneWidget);
  });

  testWidgets('source needing API key shows Configure link and disabled toggle',
      (tester) async {
    final sources = {
      'unsplash': _src('unsplash', 'Unsplash', requiresKey: true),
    };
    await tester.pumpWidget(wrap(const AppSettings(), sources));
    await tester.pumpAndSettle();
    expect(find.text('API key required'), findsOneWidget);
    expect(find.text('Configure →'), findsOneWidget);
    final sw = tester.widget<Switch>(find.byType(Switch));
    expect(sw.onChanged, isNull);
  });

  testWidgets('toggling an enabled source calls setActiveIds',
      (tester) async {
    final sources = {
      'aiwpme': _src('aiwpme', 'AI Wallpapers'),
    };
    await tester.pumpWidget(wrap(const AppSettings(), sources));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(notifier.lastSetIds, isNot(contains('aiwpme')));
  });

  testWidgets('source with API key set has enabled toggle', (tester) async {
    final sources = {
      'unsplash': _src('unsplash', 'Unsplash', requiresKey: true),
    };
    await tester.pumpWidget(wrap(
      const AppSettings(unsplashApiKey: 'abc123', activeSourceIds: []),
      sources,
    ));
    await tester.pumpAndSettle();
    final sw = tester.widget<Switch>(find.byType(Switch));
    expect(sw.onChanged, isNotNull);
  });

  testWidgets('Configure → tap writes to nav + scroll providers',
      (tester) async {
    final container = ProviderContainer(overrides: [
      sourcesProvider.overrideWith(() => notifier),
      appSettingsProvider
          .overrideWith((ref) async => const AppSettings()),
      allSourcesProvider.overrideWithValue({
        'unsplash': _src('unsplash', 'Unsplash', requiresKey: true),
      }),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: SourcesScreen())),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Configure →'));
    await tester.pumpAndSettle();
    expect(container.read(currentPageIndexProvider), 4);
    expect(container.read(settingsScrollTargetProvider), 'unsplash');
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/sources/sources_screen_test.dart`
Expected: FAIL — screen is a stub.

- [ ] **Step 3: Implement SourcesScreen**

Replace the full contents of `lib/features/sources/sources_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_settings.dart';
import '../../providers.dart';
import '../../sources/wallpaper_source.dart';
import '../../theme/app_colors.dart';
import 'sources_provider.dart';

class SourcesScreen extends ConsumerWidget {
  const SourcesScreen({super.key});

  IconData _iconFor(String sourceId) {
    switch (sourceId) {
      case 'aiwpme':
        return Icons.auto_awesome_outlined;
      case 'unsplash':
      case 'wallhaven':
        return Icons.cloud_outlined;
      case 'local':
        return Icons.folder_outlined;
      default:
        return Icons.image_outlined;
    }
  }

  String? _disabledReason(WallpaperSource source, AppSettings settings) {
    if (source.id == 'unsplash' &&
        (settings.unsplashApiKey == null ||
            settings.unsplashApiKey!.isEmpty)) {
      return 'API key required';
    }
    if (source.id == 'wallhaven' &&
        (settings.wallhavenApiKey == null ||
            settings.wallhavenApiKey!.isEmpty)) {
      return 'API key required';
    }
    if (source.id == 'local' &&
        (settings.localFolderPath == null ||
            settings.localFolderPath!.isEmpty)) {
      return 'Folder not set';
    }
    return null;
  }

  String _scrollTargetFor(String sourceId) {
    if (sourceId == 'unsplash') return 'unsplash';
    if (sourceId == 'wallhaven') return 'wallhaven';
    return 'local';
  }

  void _navigateToSettings(WidgetRef ref, String target) {
    ref.read(currentPageIndexProvider.notifier).state = 4;
    ref.read(settingsScrollTargetProvider.notifier).state = target;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourcesMap = ref.watch(allSourcesProvider);
    final settingsAsync = ref.watch(appSettingsProvider);

    return settingsAsync.when(
      data: (settings) {
        final sources = sourcesMap.values.toList();
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8, left: 4),
              child: Text(
                'Active Sources',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...sources.map((source) {
              final disabledReason = _disabledReason(source, settings);
              final isActive = settings.activeSourceIds.contains(source.id);
              final canToggle = disabledReason == null;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(_iconFor(source.id),
                          color: AppColors.textSecondary, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              source.displayName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (disabledReason != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  disabledReason,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (!canToggle)
                        TextButton(
                          onPressed: () => _navigateToSettings(
                              ref, _scrollTargetFor(source.id)),
                          child: const Text(
                            'Configure →',
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ),
                      Switch(
                        value: isActive,
                        activeColor: AppColors.primary,
                        onChanged: !canToggle
                            ? null
                            : (v) async {
                                final current =
                                    List<String>.from(settings.activeSourceIds);
                                if (v) {
                                  if (!current.contains(source.id)) {
                                    current.add(source.id);
                                  }
                                } else {
                                  current.remove(source.id);
                                }
                                await ref
                                    .read(sourcesProvider.notifier)
                                    .setActiveIds(current);
                              },
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(e.toString(),
            style: const TextStyle(color: AppColors.error)),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/sources/sources_screen_test.dart`
Expected: All 5 tests PASS.

- [ ] **Step 5: Run full suite**

Run: `flutter test`
Expected: No regressions.

- [ ] **Step 6: Commit**

```bash
git add lib/features/sources/sources_screen.dart test/features/sources/sources_screen_test.dart
git commit -m "feat: SourcesScreen — toggle active sources, Configure → link"
```

---

## Task 5: SettingsScreen — API keys, cache, Linux sections

**Files:**
- Replace: `lib/features/settings/settings_screen.dart` (initial version, will extend in Task 6)
- Create: `test/features/settings/settings_screen_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/features/settings/settings_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper_changer/features/settings/settings_provider.dart';
import 'package:wallpaper_changer/features/settings/settings_screen.dart';
import 'package:wallpaper_changer/models/app_settings.dart';

class FakeSettingsNotifier extends SettingsNotifier {
  FakeSettingsNotifier(this._initial);
  final AppSettings _initial;
  AppSettings? lastSaved;

  @override
  Future<AppSettings> build() async => _initial;

  @override
  Future<void> save(AppSettings settings) async {
    lastSaved = settings;
    state = AsyncValue.data(settings);
  }
}

Widget _wrap(FakeSettingsNotifier notifier) {
  return ProviderScope(
    overrides: [
      settingsProvider.overrideWith(() => notifier),
    ],
    child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
  );
}

void main() {
  testWidgets('renders API key fields and cache size', (tester) async {
    final notifier = FakeSettingsNotifier(const AppSettings());
    await tester.pumpWidget(_wrap(notifier));
    await tester.pumpAndSettle();
    expect(find.text('Unsplash API Key'), findsOneWidget);
    expect(find.text('Wallhaven API Key'), findsOneWidget);
    expect(find.text('Cache size limit (MB)'), findsOneWidget);
  });

  testWidgets('blur on Unsplash key field saves setting', (tester) async {
    final notifier = FakeSettingsNotifier(const AppSettings());
    await tester.pumpWidget(_wrap(notifier));
    await tester.pumpAndSettle();
    final keyField = find.ancestor(
      of: find.text('Unsplash API Key'),
      matching: find.byType(Column),
    ).first;
    final textField = find.descendant(
      of: keyField,
      matching: find.byType(TextField),
    );
    await tester.tap(textField);
    await tester.enterText(textField, 'newkey');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(notifier.lastSaved?.unsplashApiKey, 'newkey');
  });

  testWidgets('invalid cache size reverts (not saved)', (tester) async {
    final notifier =
        FakeSettingsNotifier(const AppSettings(cacheSizeLimitMb: 500));
    await tester.pumpWidget(_wrap(notifier));
    await tester.pumpAndSettle();
    final cacheField = find.ancestor(
      of: find.text('Cache size limit (MB)'),
      matching: find.byType(Column),
    ).first;
    final textField = find.descendant(
      of: cacheField,
      matching: find.byType(TextField),
    );
    await tester.tap(textField);
    await tester.enterText(textField, 'abc');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(notifier.lastSaved, isNull);
  });

  testWidgets('empty API key saves null (not empty string)', (tester) async {
    final notifier =
        FakeSettingsNotifier(const AppSettings(unsplashApiKey: 'oldkey'));
    await tester.pumpWidget(_wrap(notifier));
    await tester.pumpAndSettle();
    final keyField = find.ancestor(
      of: find.text('Unsplash API Key'),
      matching: find.byType(Column),
    ).first;
    final textField = find.descendant(
      of: keyField,
      matching: find.byType(TextField),
    );
    await tester.tap(textField);
    await tester.enterText(textField, '');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(notifier.lastSaved?.unsplashApiKey, isNull);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/settings/settings_screen_test.dart`
Expected: FAIL — screen is a stub.

- [ ] **Step 3: Implement SettingsScreen (initial: API keys + cache + Linux)**

Replace the full contents of `lib/features/settings/settings_screen.dart`:

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_settings.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_form_field.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _cacheController = TextEditingController();

  @override
  void dispose() {
    _cacheController.dispose();
    super.dispose();
  }

  AppSettings _current() =>
      ref.read(settingsProvider).valueOrNull ?? const AppSettings();

  Future<void> _saveWith(AppSettings updated) async {
    await ref.read(settingsProvider.notifier).save(updated);
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      data: (settings) {
        if (_cacheController.text != settings.cacheSizeLimitMb.toString()) {
          _cacheController.text = settings.cacheSizeLimitMb.toString();
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionHeader('API Keys'),
            GlassFormField(
              key: const Key('unsplash_key_field'),
              label: 'Unsplash API Key',
              initialValue: settings.unsplashApiKey ?? '',
              obscureText: true,
              onBlur: (text) => _saveWith(
                _current().copyWith(
                    unsplashApiKey: text.isEmpty ? null : text),
              ),
            ),
            const SizedBox(height: 16),
            GlassFormField(
              key: const Key('wallhaven_key_field'),
              label: 'Wallhaven API Key',
              initialValue: settings.wallhavenApiKey ?? '',
              obscureText: true,
              onBlur: (text) => _saveWith(
                _current().copyWith(
                    wallhavenApiKey: text.isEmpty ? null : text),
              ),
            ),
            const SizedBox(height: 24),
            _SectionHeader('Cache'),
            GlassFormField(
              label: 'Cache size limit (MB)',
              initialValue: settings.cacheSizeLimitMb.toString(),
              keyboardType: TextInputType.number,
              controller: _cacheController,
              onBlur: (text) async {
                final parsed = int.tryParse(text);
                if (parsed == null || parsed < 50) {
                  _cacheController.text =
                      _current().cacheSizeLimitMb.toString();
                  return;
                }
                await _saveWith(
                    _current().copyWith(cacheSizeLimitMb: parsed));
              },
            ),
            if (Platform.isLinux) ...[
              const SizedBox(height: 24),
              _SectionHeader('Linux'),
              GlassFormField(
                label: 'Custom wallpaper command (optional)',
                initialValue: settings.linuxWallpaperCommand ?? '',
                helperText: 'e.g., feh --bg-scale',
                onBlur: (text) => _saveWith(
                  _current().copyWith(
                      linuxWallpaperCommand: text.isEmpty ? null : text),
                ),
              ),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(e.toString(),
            style: const TextStyle(color: AppColors.error)),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 2),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/settings/settings_screen_test.dart`
Expected: All 4 tests PASS.

- [ ] **Step 5: Run full suite**

Run: `flutter test`
Expected: No regressions.

- [ ] **Step 6: Commit**

```bash
git add lib/features/settings/settings_screen.dart test/features/settings/settings_screen_test.dart
git commit -m "feat: SettingsScreen initial — API keys, cache size, Linux command"
```

---

## Task 6: SettingsScreen — Local folder + Browse + scroll-to-field

**Files:**
- Modify: `lib/features/settings/settings_screen.dart`
- Modify: `test/features/settings/settings_screen_test.dart`

- [ ] **Step 1: Add failing tests for local folder and scroll target**

Append these tests to the `main()` body of `test/features/settings/settings_screen_test.dart`:

```dart
  testWidgets('renders local folder field and Browse button',
      (tester) async {
    final notifier = FakeSettingsNotifier(const AppSettings());
    await tester.pumpWidget(_wrap(notifier));
    await tester.pumpAndSettle();
    expect(find.text('Folder path'), findsOneWidget);
    expect(find.text('Browse...'), findsOneWidget);
  });

  testWidgets('blur on local folder field saves path', (tester) async {
    final notifier = FakeSettingsNotifier(const AppSettings());
    await tester.pumpWidget(_wrap(notifier));
    await tester.pumpAndSettle();
    final folderField = find.ancestor(
      of: find.text('Folder path'),
      matching: find.byType(Column),
    ).first;
    final textField = find.descendant(
      of: folderField,
      matching: find.byType(TextField),
    );
    await tester.tap(textField);
    await tester.enterText(textField, '/tmp/walls');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(notifier.lastSaved?.localFolderPath, '/tmp/walls');
  });
```

- [ ] **Step 2: Run tests to verify new tests fail**

Run: `flutter test test/features/settings/settings_screen_test.dart`
Expected: The two new tests FAIL (existing 4 still pass).

- [ ] **Step 3: Add local folder section + scroll-to-target wiring**

Replace the full contents of `lib/features/settings/settings_screen.dart` with this extended version:

```dart
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_settings.dart';
import '../../providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_form_field.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _cacheController = TextEditingController();
  final _localFolderController = TextEditingController();
  final _unsplashKey = GlobalKey();
  final _wallhavenKey = GlobalKey();
  final _localFolderKey = GlobalKey();

  @override
  void dispose() {
    _cacheController.dispose();
    _localFolderController.dispose();
    super.dispose();
  }

  AppSettings _current() =>
      ref.read(settingsProvider).valueOrNull ?? const AppSettings();

  Future<void> _saveWith(AppSettings updated) async {
    await ref.read(settingsProvider.notifier).save(updated);
  }

  Future<void> _pickFolder() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path == null) return;
    _localFolderController.text = path;
    await _saveWith(_current().copyWith(localFolderPath: path));
  }

  void _handleScrollTarget(String? target) {
    if (target == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GlobalKey? key;
      switch (target) {
        case 'unsplash':
          key = _unsplashKey;
          break;
        case 'wallhaven':
          key = _wallhavenKey;
          break;
        case 'local':
          key = _localFolderKey;
          break;
      }
      final ctx = key?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          alignment: 0.1,
        );
      }
      ref.read(settingsScrollTargetProvider.notifier).state = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    ref.listen<String?>(settingsScrollTargetProvider, (_, next) {
      _handleScrollTarget(next);
    });

    return settingsAsync.when(
      data: (settings) {
        if (_cacheController.text != settings.cacheSizeLimitMb.toString()) {
          _cacheController.text = settings.cacheSizeLimitMb.toString();
        }
        if (_localFolderController.text !=
            (settings.localFolderPath ?? '')) {
          _localFolderController.text = settings.localFolderPath ?? '';
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SectionHeader('API Keys'),
            GlassFormField(
              key: _unsplashKey,
              label: 'Unsplash API Key',
              initialValue: settings.unsplashApiKey ?? '',
              obscureText: true,
              onBlur: (text) => _saveWith(
                _current().copyWith(
                    unsplashApiKey: text.isEmpty ? null : text),
              ),
            ),
            const SizedBox(height: 16),
            GlassFormField(
              key: _wallhavenKey,
              label: 'Wallhaven API Key',
              initialValue: settings.wallhavenApiKey ?? '',
              obscureText: true,
              onBlur: (text) => _saveWith(
                _current().copyWith(
                    wallhavenApiKey: text.isEmpty ? null : text),
              ),
            ),
            const SizedBox(height: 24),
            const _SectionHeader('Local Folder'),
            Row(
              key: _localFolderKey,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: GlassFormField(
                    label: 'Folder path',
                    controller: _localFolderController,
                    initialValue: settings.localFolderPath ?? '',
                    onBlur: (text) => _saveWith(
                      _current().copyWith(
                          localFolderPath: text.isEmpty ? null : text),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _pickFolder,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                  ),
                  child: const Text('Browse...'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionHeader('Cache'),
            GlassFormField(
              label: 'Cache size limit (MB)',
              controller: _cacheController,
              initialValue: settings.cacheSizeLimitMb.toString(),
              keyboardType: TextInputType.number,
              onBlur: (text) async {
                final parsed = int.tryParse(text);
                if (parsed == null || parsed < 50) {
                  _cacheController.text =
                      _current().cacheSizeLimitMb.toString();
                  return;
                }
                await _saveWith(
                    _current().copyWith(cacheSizeLimitMb: parsed));
              },
            ),
            if (Platform.isLinux) ...[
              const SizedBox(height: 24),
              const _SectionHeader('Linux'),
              GlassFormField(
                label: 'Custom wallpaper command (optional)',
                initialValue: settings.linuxWallpaperCommand ?? '',
                helperText: 'e.g., feh --bg-scale',
                onBlur: (text) => _saveWith(
                  _current().copyWith(
                      linuxWallpaperCommand: text.isEmpty ? null : text),
                ),
              ),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(e.toString(),
            style: const TextStyle(color: AppColors.error)),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 2),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run Settings tests**

Run: `flutter test test/features/settings/settings_screen_test.dart`
Expected: All 6 tests PASS.

- [ ] **Step 5: Run full suite**

Run: `flutter test`
Expected: No regressions.

- [ ] **Step 6: Run flutter analyze**

Run: `flutter analyze`
Expected: No new issues.

- [ ] **Step 7: Commit**

```bash
git add lib/features/settings/settings_screen.dart test/features/settings/settings_screen_test.dart
git commit -m "feat: SettingsScreen local folder with Browse + scroll-to-field from Sources"
```
