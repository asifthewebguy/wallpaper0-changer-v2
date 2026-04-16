# Plan 6 — Schedule + Sources + Settings UI Design

## Goal

Replace the three remaining stub screens (Schedule, Sources, Settings) with real glassmorphic UI that exposes every `AppSettings` field and scheduler control. Completes the v2 UI surface; after this plan, the app has no placeholder screens.

---

## Architecture

Three screens, three pre-existing notifiers — no new providers required:

| Screen | Notifier | Key methods |
|---|---|---|
| Schedule | `ScheduleNotifier` | `enable(int)`, `disable()` |
| Sources | `SourcesNotifier` | `setActiveIds(List<String>)` |
| Settings | `SettingsNotifier` | `save(AppSettings)` |

**One new shared widget:** `GlassFormField` — a reusable glassmorphic text input that commits its value on blur. Used by Settings (all text fields) and Schedule ("Custom interval" input).

**One new shared provider:** `currentPageIndexProvider = StateProvider<int>`. The app root's `IndexedStack` reads it; the Sources "Configure →" button writes index 4 (Settings) to trigger cross-screen navigation.

**One new shared provider:** `settingsScrollTargetProvider = StateProvider<String?>`. Sources writes `'unsplash' | 'wallhaven' | 'local'`; Settings consumes it on build to `Scrollable.ensureVisible` the matching field and then clears the value.

**One new package:** `file_picker: ^8.0.0+1` for the Browse button.

---

## File Structure

### New files

| File | Purpose |
|---|---|
| `lib/widgets/glass_form_field.dart` | Reusable glassmorphic text input with on-blur callback |
| `test/widgets/glass_form_field_test.dart` | Initial value, onBlur fires, no-fire on unchanged text |
| `test/features/schedule/schedule_screen_test.dart` | Toggle, interval picker, countdown, Set Now |
| `test/features/sources/sources_screen_test.dart` | Rows render, toggle persists, disabled state on missing key |
| `test/features/settings/settings_screen_test.dart` | Field render, on-blur save, Browse, Linux conditional |

### Modified files

| File | Change |
|---|---|
| `lib/features/schedule/schedule_screen.dart` | Replace stub with full UI |
| `lib/features/sources/sources_screen.dart` | Replace stub with full UI |
| `lib/features/settings/settings_screen.dart` | Replace stub with full UI |
| `lib/providers.dart` | Add `currentPageIndexProvider`, `settingsScrollTargetProvider` |
| `lib/main.dart` (or navigation host) | Wire `IndexedStack` index to `currentPageIndexProvider` |
| `pubspec.yaml` | Add `file_picker: ^8.0.0+1` |

---

## Schedule Screen

```
Scaffold body:
  SingleChildScrollView → Padding(24) → Column:
    ├── Glass card: "Automatic wallpaper rotation"
    │     ├── Row: Switch(isEnabled)  "Rotate every X minutes"
    │     ├── Interval picker:
    │     │     DropdownButton<int?>([5, 10, 15, 30, 60, 120, null="Custom..."])
    │     │     if custom: GlassFormField(number, min=1), commits on blur
    │     └── Countdown display (visible only when enabled):
    │           Consumer(scheduleCountdownProvider) → "Next change in MM:SS"
    └── Glass card: "Manual"
          ElevatedButton "Set Random Wallpaper Now"
          spinner when in-flight; inline error on failure
```

**Interaction semantics:**
- **Toggle off→on:** `scheduleProvider.notifier.enable(interval)`. `ScheduleNotifier.enable` already starts the `SchedulerService` and persists `schedulerIntervalMinutes` to settings.
- **Toggle on→off:** `scheduleProvider.notifier.disable()`.
- **Interval change while enabled:** the screen disables + re-enables with the new value (calls `disable()` then `enable(newInterval)`). `SchedulerService.reset` is available but `ScheduleNotifier` doesn't expose it; going through `disable`/`enable` keeps the notifier state coherent. `enable` persists `schedulerIntervalMinutes` to settings internally.
- **Interval change while disabled:** the dropdown/custom-field value is held in local state only. Persistence happens on the next toggle-on (via `enable`).
- **Set Now button:** reads `appSettings.activeSourceIds.firstOrNull ?? 'aiwpme'`, calls `source.getRandom()` → `wallpaperServiceProvider.setWallpaper(image, source)`. Independent of the timer; does not reset countdown.
- **Error handling:** `scheduleProvider.AsyncValue.error` → inline error text; Set Now failures → inline error below button, button re-enabled.

---

## Sources Screen

```
Scaffold body:
  ListView → Padding(12):
    ├── Text "Active Sources" (textSecondary, small header)
    └── 4 Glass card rows (one per source from allSourcesProvider):
          Row:
            ├── Leading icon (Icons.cloud | Icons.image_outlined | Icons.folder)
            ├── Title: source.displayName
            ├── Subtitle (conditional):
            │     • requiresApiKey && key unset → "API key required"
            │     • id=='local' && localFolderPath empty → "Folder not set"
            │     • else: null
            ├── Trailing:
            │     • Switch (enabled only when prerequisites satisfied)
            │     • TextButton "Configure →" (visible only when unsatisfied)
            │         → sets currentPageIndexProvider=4
            │         → sets settingsScrollTargetProvider=<source id or 'local'>
```

**Data flow:**
- `ref.watch(allSourcesProvider)` for the 4 sources.
- `ref.watch(appSettingsProvider)` for `activeSourceIds`, `unsplashApiKey`, `wallhavenApiKey`, `localFolderPath`.
- Toggle on: `sourcesProvider.notifier.setActiveIds([...current, id])`.
- Toggle off: `sourcesProvider.notifier.setActiveIds(current.where((x) => x != id).toList())`.

**Prerequisites matrix:**

| Source | Requires | Toggle disabled when |
|---|---|---|
| `aiwpme` | — | never |
| `unsplash` | API key | `unsplashApiKey == null \|\| isEmpty` |
| `wallhaven` | API key | `wallhavenApiKey == null \|\| isEmpty` |
| `local` | folder path | `localFolderPath == null \|\| isEmpty` |

Toggling a source does **not** affect `selectedSourceProvider` (Discover dropdown) — they are independent concepts.

---

## Settings Screen

```
Scaffold body:
  ListView → Padding(16):
    ├── Section: "API Keys"
    │     ├── GlassFormField "Unsplash API Key"
    │     │     key: Key('unsplash_key_field')   ← scroll target
    │     │     obscureText: true
    │     │     initial: settings.unsplashApiKey ?? ''
    │     │     onBlur(text) → save(settings.copyWith(
    │     │         unsplashApiKey: text.isEmpty ? null : text))
    │     └── GlassFormField "Wallhaven API Key"
    │           key: Key('wallhaven_key_field')
    │           (same pattern)
    │
    ├── Section: "Local Folder"
    │     Row:
    │       ├── Expanded GlassFormField "Folder path"
    │       │     key: Key('local_folder_field')
    │       │     onBlur(text) → save (empty string → null)
    │       └── OutlinedButton "Browse..."
    │             onPressed: await FilePicker.platform.getDirectoryPath()
    │             if non-null → controller.text = path; save immediately
    │
    ├── Section: "Cache"
    │     GlassFormField "Cache size limit (MB)"
    │       number input, initial = settings.cacheSizeLimitMb.toString()
    │       onBlur(text) → parsed = int.tryParse(text)
    │         if parsed == null or parsed < 50 → revert to previous value
    │         else → save(settings.copyWith(cacheSizeLimitMb: parsed))
    │
    └── Section: "Linux" (only if Platform.isLinux)
          GlassFormField "Custom wallpaper command (optional)"
            onBlur(text) → save (empty → null)
            helper text: "e.g., feh --bg-scale" (hint)
```

**On-blur save mechanics:**

`GlassFormField` is a `StatefulWidget` that:
1. Owns a `TextEditingController` initialized from a `String? initialValue` prop.
2. Owns a `FocusNode`; calls `widget.onBlur(controller.text)` inside a focus listener when `!focusNode.hasFocus`.
3. Skips the callback if `controller.text == initialValue` (no-op on unchanged text).

**Scroll-to-field from Sources:**

After `settingsScrollTargetProvider.state = 'unsplash'`, the Settings screen:
1. `ref.watch(settingsScrollTargetProvider)` in `build()`.
2. On non-null, schedules a `WidgetsBinding.instance.addPostFrameCallback`.
3. In the post-frame callback: resolves the `GlobalKey` for that field, calls `Scrollable.ensureVisible(key.currentContext!)`, then `ref.read(settingsScrollTargetProvider.notifier).state = null` to clear it.

Three `GlobalKey`s: `_unsplashKey`, `_wallhavenKey`, `_localFolderKey`.

---

## Navigation Wiring

The app currently uses `IndexedStack` indexed by a local state. Lift to a Riverpod provider:

```dart
// lib/providers.dart
final currentPageIndexProvider = StateProvider<int>((ref) => 0);
final settingsScrollTargetProvider = StateProvider<String?>((ref) => null);
```

The top-level app shell watches `currentPageIndexProvider` for the `IndexedStack` child index and the `NavigationBar.selectedIndex`. `NavigationBar.onDestinationSelected` writes to the provider.

Sources "Configure →" writes both providers in one action:

```dart
ref.read(currentPageIndexProvider.notifier).state = 4; // Settings tab
ref.read(settingsScrollTargetProvider.notifier).state = 'unsplash';
```

---

## Error Handling

| Scenario | Behavior |
|---|---|
| `settingsProvider.save` throws | Snackbar: "Could not save settings" |
| `scheduleProvider.enable` throws | AsyncValue.error → inline error text; toggle snaps back |
| "Set Now" source fetch fails | Inline error text under button; button re-enabled |
| `file_picker` returns null (user cancels) | No-op, no save |
| Cache size input invalid (not int or < 50) | Revert to previous value silently |
| Config file corrupt | Existing `ConfigService.load` already falls back to `const AppSettings()` |
| `AppSettings.copyWith` with empty string for nullable field | Explicitly saved as `null` (uses existing sentinel) |

---

## Testing Strategy

Follows Plan 5 conventions: `FakeNotifier` subclasses (same pattern as `FakeDiscoverNotifier` / `FakeHistoryNotifier`), `mocktail` for external services.

**`GlassFormField` tests:**
- Initial text equals `initialValue`
- `onBlur` callback fires with current text when focus is lost
- `onBlur` does not fire when text is unchanged since last commit

**Schedule screen tests:**
- Renders toggle, interval dropdown, countdown widget
- Toggle on → `enable(interval)` called once
- Toggle off → `disable()` called once
- Custom interval: selecting "Custom..." reveals GlassFormField; typing a number + blur → `enable(n)` (if already enabled)
- "Set Now" button → `wallpaperService.setWallpaper` called with a random image
- Error state renders error text

**Sources screen tests:**
- Renders 4 rows
- Toggling a satisfied source calls `setActiveIds` with expected list
- Source with missing API key shows "Configure →", toggle is disabled
- Clicking "Configure →" sets both providers (assert via overrides)

**Settings screen tests:**
- Renders all 4 sections (API keys, local folder, cache, Linux conditional)
- Blur on API key field saves via `settingsProvider.save`
- Browse button exists (calls into `file_picker` mocked via channel)
- Linux section hidden on non-Linux (test with a `Platform.isLinux` seam — see below)
- Scroll-target provider triggers `ensureVisible` (smoke test)

**Platform seam:** The Linux conditional is wrapped in `Platform.isLinux` directly in the screen. The Linux-section-hidden test is an intentional gap on non-Linux CI (documented in the test file as a skip comment). Rationale: the logic is a one-line `if`, and introducing a platform-injection seam for a single call site is over-engineering.

---

## Out of Scope

- Cron-style scheduling (interval only)
- Per-source filters (categories, tags, resolution minimums)
- Theme switching, language, startup-on-boot
- Cache inspector / "Clear cache now" button
- API key validation (format, live test)
- `LocalFolderSource` content listing preview
- `ScheduleNotifier.updateInterval(int)` convenience method (can be added later; screen uses disable/enable for now)
