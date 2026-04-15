abstract interface class WallpaperSetter {
  /// Sets the desktop wallpaper to the file at [localFilePath].
  /// Platform-channel implementation added in Plan 3.
  Future<void> set(String localFilePath);
}

class StubWallpaperSetter implements WallpaperSetter {
  @override
  Future<void> set(String localFilePath) async {
    // No-op stub — real implementation in Plan 3 (platform channels).
  }
}
