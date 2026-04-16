import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/app_settings.dart';
import 'platform/app_notifier.dart';
import 'platform/local_notifier_app_notifier.dart';
import 'platform/protocol_registrar.dart';
import 'platform/wallpaper_setter.dart';
import 'platform/linux_protocol_registrar.dart';
import 'platform/linux_wallpaper_setter.dart';
import 'platform/macos_protocol_registrar.dart';
import 'platform/macos_wallpaper_setter.dart';
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

final selectedSourceProvider = StateProvider<String>((ref) => 'aiwpme');

final configServiceProvider = Provider<ConfigService>((ref) => ConfigService());

final cacheManagerProvider = Provider<CacheManager>((ref) {
  return CacheManager();
});

final schedulerServiceProvider =
    Provider<SchedulerService>((ref) => SchedulerService());

final wallpaperSetterProvider = Provider<WallpaperSetter>((ref) {
  if (Platform.isWindows) return WindowsWallpaperSetter();
  if (Platform.isLinux) return LinuxWallpaperSetter();
  if (Platform.isMacOS) return MacosWallpaperSetter();
  return StubWallpaperSetter();
});

final appNotifierProvider =
    Provider<AppNotifier>((ref) => LocalNotifierAppNotifier());

final protocolRegistrarProvider = Provider<ProtocolRegistrar>((ref) {
  if (Platform.isWindows) return WindowsProtocolRegistrar();
  if (Platform.isLinux) return LinuxProtocolRegistrar();
  if (Platform.isMacOS) return MacosProtocolRegistrar();
  return StubProtocolRegistrar();
});

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
