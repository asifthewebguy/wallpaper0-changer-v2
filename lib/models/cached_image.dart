import 'package:flutter/foundation.dart';

@immutable
class CachedImage {
  final String wallpaperImageId;
  final String localPath;
  final DateTime downloadedAt;
  final int fileSizeBytes;

  const CachedImage({
    required this.wallpaperImageId,
    required this.localPath,
    required this.downloadedAt,
    required this.fileSizeBytes,
  });

  factory CachedImage.fromJson(Map<String, dynamic> json) => CachedImage(
        wallpaperImageId: json['wallpaperImageId'] as String,
        localPath: json['localPath'] as String,
        downloadedAt: DateTime.parse(json['downloadedAt'] as String),
        fileSizeBytes: json['fileSizeBytes'] as int,
      );

  Map<String, dynamic> toJson() => {
        'wallpaperImageId': wallpaperImageId,
        'localPath': localPath,
        'downloadedAt': downloadedAt.toIso8601String(),
        'fileSizeBytes': fileSizeBytes,
      };
}
