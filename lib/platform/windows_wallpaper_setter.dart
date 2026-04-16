import 'package:flutter/services.dart';
import 'wallpaper_setter.dart';

class WindowsWallpaperSetter implements WallpaperSetter {
  static const _channel = MethodChannel('wallpaper_changer/wallpaper');

  @override
  Future<void> set(String localFilePath) async {
    final String? error =
        await _channel.invokeMethod<String>('setWallpaper', localFilePath);
    if (error != null) {
      throw PlatformException(code: 'SET_FAILED', message: error);
    }
  }
}
