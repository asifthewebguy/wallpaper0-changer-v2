# Wallpaper Changer v2.0 — Plan 2: Core Layer Design

**Date:** 2026-04-15
**Status:** Approved
**Parent spec:** `docs/superpowers/specs/2026-04-15-modernization-design.md`

---

## Overview

Plan 2 implements the full core layer of the app: models, services, source adapters, orchestration service, and Riverpod providers. No platform channels yet — `WallpaperSetter` is a stub. No screen UI changes — providers are wired but screens remain stubs until Plan 4.

**Implementation order (Option A — bottom-up layers):**
1. Models
2. Services
3. Source adapters
4. WallpaperService
5. Riverpod providers

---

## Layer 1 — Models (`lib/models/`)

Three immutable data classes with `fromJson`/`toJson`. No business logic.

### `WallpaperImage`

Unified model across all sources.

| Field | Type | Notes |
|---|---|---|
| `id` | `String` | Source-scoped unique ID |
| `sourceId` | `String` | Matches `WallpaperSource.id` |
| `thumbnailUrl` | `String` | For grid display |
| `downloadUrl` | `String` | Full-resolution URL |
| `width` | `int` | Pixels |
| `height` | `int` | Pixels |
| `format` | `String` | `jpg`, `png`, `webp` |

### `AppSettings`

| Field | Type | Default |
|---|---|---|
| `schedulerIntervalMinutes` | `int` | `30` |
| `activeSourceIds` | `List<String>` | `['aiwpme']` |
| `unsplashApiKey` | `String?` | `null` |
| `wallhavenApiKey` | `String?` | `null` |
| `linuxWallpaperCommand` | `String?` | `null` (auto-detect) |
| `cacheSizeLimitMb` | `int` | `500` |
| `localFolderPath` | `String?` | `null` (source disabled when null) |

### `CachedImage`

| Field | Type | Notes |
|---|---|---|
| `wallpaperImageId` | `String` | FK to `WallpaperImage.id` |
| `localPath` | `String` | Absolute path on disk |
| `downloadedAt` | `DateTime` | For LRU eviction |
| `fileSizeBytes` | `int` | For cache size accounting |

---

## Layer 2 — Services (`lib/services/`)

### `ValidationService`

Pure static methods — no deps, no state.

- `validateImage(WallpaperImage)` — asserts non-empty `id`, `thumbnailUrl`, `downloadUrl`; URLs must use `https://` scheme
- `validateLocalPath(String)` — no `..` path traversal, path must be absolute
- Throws `ValidationException` with a descriptive message on failure

### `ConfigService`

- Reads/writes `AppSettings` to JSON via `path_provider` (`getApplicationSupportDirectory`)
- File path: `<appSupport>/wallpaper_changer/settings.json`
- `Future<AppSettings> load()` — returns defaults if file missing
- `Future<void> save(AppSettings)` — atomic write (write to `.tmp`, rename)
- No debouncing at this layer — callers decide when to save

### `CacheManager`

- Cache metadata stored in `<appSupport>/wallpaper_changer/cache.json` — list of `CachedImage`
- Files stored in `<appSupport>/wallpaper_changer/cache/`
- `Future<String> getOrDownload(WallpaperImage, WallpaperSource, {void Function(int, int)? onProgress})` — returns local path
  - Cache hit: returns existing `localPath`
  - Cache miss: streams download from source, saves to disk, updates metadata
- `Future<void> recordHistory(WallpaperImage)` — appends to history list (max 500 entries, trims oldest)
- `Future<List<WallpaperImage>> getHistory()` — returns history newest-first
- `Future<void> evictToLimit(int limitBytes)` — removes oldest entries until under limit
- `Future<void> clearCache()` — deletes all cached files and metadata

### `SchedulerService`

- `void start({required Duration interval, required VoidCallback onTick})` — starts `Timer.periodic`
- `void stop()` — cancels timer
- `void reset(Duration newInterval)` — stop + start with new interval
- `bool get isRunning`
- `DateTime? get nextFireAt` — computed from last start time + interval

---

## Layer 3 — Source Adapters (`lib/sources/`)

### `WallpaperSource` (abstract interface)

```dart
abstract interface class WallpaperSource {
  String get id;
  String get displayName;
  bool get requiresApiKey;

  Future<List<WallpaperImage>> browse({String? query, int page = 1});
  Future<WallpaperImage> getRandom();
  Future<Stream<List<int>>> download(WallpaperImage image, {void Function(int sent, int total)? onProgress});
}
```

### `AiwpmeSource`

- Base URL: `https://aiwp.me`
- `browse()` → `GET /api/images-data.json` (fetched once, cached in memory for the session). Filters client-side by `query` against `id`. Returns page slice of 40.
- `getRandom()` → `GET /api/random/index.html` → `{"id": "..."}` → constructs `WallpaperImage`
- `download()` → streams from the Google Drive URL in the image data
- No auth required

### `UnsplashSource`

- Base URL: `https://api.unsplash.com`
- Auth: `Authorization: Client-ID <unsplashApiKey>` header
- `browse({query, page})` → `GET /search/photos?query=<query>&page=<page>&per_page=40` (falls back to `GET /photos?page=<page>&per_page=40` when query is empty)
- `getRandom()` → `GET /photos/random`
- `download()` → streams from `WallpaperImage.downloadUrl` (Unsplash `full` size URL)
- Throws `MissingApiKeyException` if key not configured

### `WallhavenSource`

- Base URL: `https://wallhaven.cc/api/v1`
- Auth: optional `X-API-Key` header
- `browse({query, page})` → `GET /search?q=<query>&page=<page>&purity=100` (SFW-only always in Plan 2 — purity settings are out of scope)
- `getRandom()` → `GET /search?sorting=random&purity=100&page=1` → first result
- `download()` → streams from `WallpaperImage.downloadUrl`

### `LocalFolderSource`

- No HTTP — reads from a configured folder path in `AppSettings`
- `browse({query, page})` → `Directory.list()` scan for `.jpg/.jpeg/.png/.webp`, filters by filename if `query` set, returns page slice of 40
- `getRandom()` → picks a random file from the scanned list
- `download()` → `File(image.downloadUrl).openRead()` — file is already local, no network needed
- `id` → `'local'`, `requiresApiKey` → `false`

---

## Layer 4 — WallpaperService (`lib/services/wallpaper_service.dart`)

Orchestrates the full set-wallpaper flow. Injected deps: `ValidationService`, `CacheManager`, `WallpaperSetter`, `LocalNotifier`.

```
setWallpaper(WallpaperImage image, WallpaperSource source):
  1. ValidationService.validateImage(image)
  2. localPath = CacheManager.getOrDownload(image, source, onProgress)
  3. WallpaperSetter.set(localPath)          ← stub in Plan 2
  4. CacheManager.recordHistory(image)
  5. LocalNotifier.show("Wallpaper updated")
```

Throws typed exceptions: `ValidationException`, `DownloadException`, `WallpaperSetException`. All bubble up as `AsyncValue.error` in providers.

**`WallpaperSetter` stub** (`lib/platform/wallpaper_setter.dart`):

```dart
abstract interface class WallpaperSetter {
  Future<void> set(String localFilePath);
}

class StubWallpaperSetter implements WallpaperSetter {
  @override
  Future<void> set(String localFilePath) async {
    // Real implementation in Plan 3 (platform channels)
  }
}
```

---

## Layer 5 — Riverpod Providers (`lib/features/*/`)

One `AsyncNotifier` per feature. All depend on `configServiceProvider` and `cacheManagerProvider` (provided at app root via `ProviderScope` overrides).

### `DiscoverNotifier` (`AsyncNotifier<List<WallpaperImage>>`)
- `build()` → calls `browse()` on the first active source
- `browse({String? query, int page = 1})` → loads wallpapers
- `setWallpaper(WallpaperImage)` → delegates to `WallpaperService`
- `random()` → calls `getRandom()` on active source then `setWallpaper`

### `HistoryNotifier` (`AsyncNotifier<List<WallpaperImage>>`)
- `build()` → calls `CacheManager.getHistory()`
- `clear()` → calls `CacheManager.clearCache()`, refreshes state

### `ScheduleNotifier` (`AsyncNotifier<ScheduleState>`)
- `ScheduleState` holds `isEnabled`, `intervalMinutes`, `nextFireAt`
- `enable(int intervalMinutes)` → starts `SchedulerService`, saves to `ConfigService`
- `disable()` → stops `SchedulerService`, saves to `ConfigService`
- Countdown exposed as a `StreamProvider<Duration>` ticking every second

### `SourcesNotifier` (`AsyncNotifier<List<WallpaperSource>>`)
- `build()` → loads active source IDs from `ConfigService`, returns matching sources
- `setActive(List<String> sourceIds)` → updates `AppSettings` via `ConfigService`

### `SettingsNotifier` (`AsyncNotifier<AppSettings>`)
- `build()` → calls `ConfigService.load()`
- `update(AppSettings)` → calls `ConfigService.save()`, refreshes state

---

## Testing Strategy

| Layer | Approach |
|---|---|
| Models | Unit tests: `fromJson` round-trips, field validation |
| Services | Unit tests with `mocktail`: mock `path_provider`, mock `dio`, mock `WallpaperSetter` |
| Source adapters | `mocktail` + `dio` mock adapter: one test per endpoint, one error path per source |
| WallpaperService | Unit tests: mock all 4 deps, verify call order and error propagation |
| Providers | `ProviderContainer` with overridden mocks, test state transitions |

No real HTTP calls. No real file I/O in unit tests (paths mocked via `mocktail`).

---

## Out of Scope (Plan 2)

- Real `WallpaperSetter` implementations (Plan 3 — platform channels)
- `ProtocolRegistrar` (Plan 3)
- Screen UI beyond current stubs (Plan 4)
- System tray integration (Plan 4)
