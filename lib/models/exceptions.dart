class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);
  @override
  String toString() => 'ValidationException: $message';
}

class DownloadException implements Exception {
  final String message;
  const DownloadException(this.message);
  @override
  String toString() => 'DownloadException: $message';
}

class WallpaperSetException implements Exception {
  final String message;
  const WallpaperSetException(this.message);
  @override
  String toString() => 'WallpaperSetException: $message';
}

class MissingApiKeyException implements Exception {
  final String sourceName;
  const MissingApiKeyException(this.sourceName);
  @override
  String toString() => 'MissingApiKeyException: $sourceName requires an API key';
}
