import '../models/exceptions.dart';
import '../models/wallpaper_image.dart';

abstract final class ValidationService {
  static void validateImage(WallpaperImage image) {
    if (image.id.isEmpty) {
      throw const ValidationException('Image ID cannot be empty');
    }
    if (image.thumbnailUrl.isEmpty) {
      throw const ValidationException('thumbnailUrl cannot be empty');
    }
    if (image.downloadUrl.isEmpty) {
      throw const ValidationException('downloadUrl cannot be empty');
    }
    // Local-source images use file paths, not URLs — skip scheme check.
    if (image.sourceId != 'local') {
      _requireHttps(image.thumbnailUrl, 'thumbnailUrl');
      _requireHttps(image.downloadUrl, 'downloadUrl');
    } else {
      validateLocalPath(image.downloadUrl);
    }
  }

  static void validateLocalPath(String path) {
    if (path.isEmpty) {
      throw const ValidationException('Local path cannot be empty');
    }
    if (path.contains('..')) {
      throw const ValidationException(
          'Local path must not contain path traversal (..)');
    }
    final isAbsoluteUnix = path.startsWith('/');
    final isAbsoluteWindows = RegExp(r'^[A-Za-z]:\\').hasMatch(path);
    if (!isAbsoluteUnix && !isAbsoluteWindows) {
      throw const ValidationException('Local path must be absolute');
    }
  }

  static void _requireHttps(String url, String fieldName) {
    if (!url.startsWith('https://')) {
      throw ValidationException('$fieldName must use https:// scheme');
    }
  }
}
