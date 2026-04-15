import '../models/wallpaper_image.dart';
import '../platform/app_notifier.dart';
import '../platform/wallpaper_setter.dart';
import '../sources/wallpaper_source.dart';
import 'cache_manager.dart';
import 'validation_service.dart';

class WallpaperService {
  final CacheManager _cacheManager;
  final WallpaperSetter _wallpaperSetter;
  final AppNotifier _notifier;
  final int cacheSizeLimitMb;

  WallpaperService({
    required CacheManager cacheManager,
    required WallpaperSetter wallpaperSetter,
    required AppNotifier notifier,
    this.cacheSizeLimitMb = 500,
  })  : _cacheManager = cacheManager,
        _wallpaperSetter = wallpaperSetter,
        _notifier = notifier;

  Future<void> setWallpaper(
    WallpaperImage image,
    WallpaperSource source,
  ) async {
    ValidationService.validateImage(image);
    final localPath = await _cacheManager.getOrDownload(
      image,
      source,
      cacheSizeLimitMb: cacheSizeLimitMb,
    );
    await _wallpaperSetter.set(localPath);
    await _cacheManager.recordHistory(image);
    await _notifier.show('Wallpaper updated');
  }
}
