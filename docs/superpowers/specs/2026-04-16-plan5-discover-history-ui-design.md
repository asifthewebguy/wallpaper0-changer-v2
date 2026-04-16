# Plan 5 — Discover + History UI Design

## Goal

Replace the stub Discover and History screens with real glassmorphic UI: a 2-column wallpaper grid, source dropdown, search, preview dialog with one-tap set, and a history grid with timestamps.

---

## Architecture

### Shared widgets (new, in `lib/widgets/`)

Three new widgets used by both screens:

**`WallpaperCard`** — a single grid cell. Takes `WallpaperImage`, optional `String? caption`, and `VoidCallback onTap`. Renders a 16:9 cached thumbnail (`cached_network_image`) with a rounded glassmorphic border. If `caption` is non-null, renders a small text below the image.

**`WallpaperGrid`** — a `GridView.builder` with `SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 16/9)`. Takes `List<WallpaperImage>`, optional `captionBuilder`, `onTap`, and optional `onLoadMore` callback (triggered when last item is visible via a scroll listener). Handles empty-state and load-more spinner at the bottom.

**`WallpaperPreviewDialog`** — a `showDialog` full-screen dialog. Shows a large image (full width, ~60% screen height), image metadata (source, dimensions if available), and a "Set as Wallpaper" button. Uses `ref.read(discoverProvider.notifier).setWallpaper(image)` internally (reads from ProviderScope — no constructor parameter for the notifier). Shows `CircularProgressIndicator` during the call, closes on success, shows inline error text on failure.

### Model change

`WallpaperImage` gains an optional field:
```dart
final DateTime? setAt;
```
All existing constructors default it to `null`. `CacheManager.getHistory()` returns images with `setAt` populated from `CachedImage.downloadedAt`.

### Provider changes

**`selectedSourceProvider`** — new `StateProvider<String>` in `providers.dart`, defaults to `'aiwpme'`. Discover reads this instead of `settings.activeSourceIds`.

**`DiscoverNotifier`** — updated `build()` watches `selectedSourceProvider`. New method `loadMore()` appends the next page (tracks `_page` int, resets to 1 when source changes). `search()` already exists — no change needed.

**`HistoryNotifier`** — no change needed.

---

## File Structure

### New files

| File | Purpose |
|---|---|
| `lib/widgets/wallpaper_card.dart` | Reusable thumbnail card with optional caption |
| `lib/widgets/wallpaper_grid.dart` | 2-column GridView with load-more + empty state |
| `lib/widgets/wallpaper_preview_dialog.dart` | Full-screen preview + Set as Wallpaper button |
| `test/widgets/wallpaper_card_test.dart` | Card renders, caption shows, onTap fires |
| `test/widgets/wallpaper_grid_test.dart` | Grid renders items, empty state, load-more |
| `test/widgets/wallpaper_preview_dialog_test.dart` | Button calls setWallpaper, shows loading/error |

### Modified files

| File | Change |
|---|---|
| `lib/models/wallpaper_image.dart` | Add optional `DateTime? setAt` field |
| `lib/services/cache_manager.dart` | `getHistory()` populates `setAt` from `CachedImage.downloadedAt` |
| `lib/providers.dart` | Add `selectedSourceProvider = StateProvider<String>` |
| `lib/features/discover/discover_provider.dart` | `build()` watches `selectedSourceProvider`; add `loadMore()` |
| `lib/features/discover/discover_screen.dart` | Replace stub with full UI |
| `lib/features/history/history_screen.dart` | Replace stub with full UI |

---

## Discover Screen

```
Scaffold body:
  Column:
    ├── Padding:
    │     Row:
    │       ├── DropdownButton<String>(sources) → writes selectedSourceProvider
    │       └── Expanded TextField(search, debounce 500ms) → calls notifier.search()
    └── Expanded:
          state.when(
            data: (images) => WallpaperGrid(
              images: images,
              onLoadMore: notifier.loadMore,
              onTap: (img) => showDialog(WallpaperPreviewDialog(img, notifier)),
            ),
            loading: () => Center(CircularProgressIndicator()),
            error: (e, _) => Center(Text(e.toString())),
          )
```

Selecting a new source in the dropdown: writes to `selectedSourceProvider`, which invalidates `discoverNotifier` (via `ref.watch`), triggering a fresh `build()`.

Search debounce: 500ms `Timer` in `initState`; cancels previous timer on each keystroke.

---

## History Screen

```
Scaffold body:
  state.when(
    data: (images) => images.isEmpty
      ? Center(Text('No wallpapers set yet'))
      : WallpaperGrid(
          images: images,
          captionBuilder: (img) => _timeAgo(img.setAt),
          onTap: (img) => showDialog(WallpaperPreviewDialog(img, null)),
        ),
    loading: () => Center(CircularProgressIndicator()),
    error: (e, _) => Center(Text(e.toString())),
  )
```

`_timeAgo(DateTime? dt)`: returns `''` if null, `'today'` if same day, `'N days ago'` otherwise.

`WallpaperPreviewDialog` is a `ConsumerStatefulWidget` — reads `discoverProvider.notifier` directly from `ref`. No constructor parameter for the notifier.

---

## Error Handling

| Scenario | Behavior |
|---|---|
| Source browse fails | Discover shows error text, retry on pull-to-refresh (future) |
| setWallpaper fails | Preview dialog shows inline error string, button re-enabled |
| thumbnail load fails | `cached_network_image` error widget (broken image icon) |
| History empty | Empty state text, no error |
| `setAt` is null | History caption shows empty string |

---

## Testing Strategy

**Widget tests** use `ProviderScope` with overridden providers via `mocktail`:

```dart
ProviderScope(
  overrides: [
    discoverProvider.overrideWith(() => MockDiscoverNotifier()),
  ],
  child: MaterialApp(home: DiscoverScreen()),
)
```

**`WallpaperCard` tests:**
- Renders thumbnail URL via `Image.network` (or `CachedNetworkImage`)
- Shows caption when provided, hides when null
- Fires `onTap` callback on tap

**`WallpaperGrid` tests:**
- Renders correct number of `WallpaperCard` children
- Shows empty-state widget when list is empty
- Shows load-more spinner at bottom when `onLoadMore` provided

**`WallpaperPreviewDialog` tests:**
- "Set as Wallpaper" button calls `setWallpaper` on notifier
- Shows loading indicator while in-flight
- Shows error text on failure
- Closes on success

**`DiscoverScreen` tests:**
- Dropdown renders source names from `allSourcesProvider`
- Selecting source writes to `selectedSourceProvider`
- Search field change triggers `search()` after debounce
- Grid visible when provider returns data

**`HistoryScreen` tests:**
- Grid renders when history non-empty
- Empty state visible when history is `[]`
- Captions use `setAt` from `WallpaperImage`
