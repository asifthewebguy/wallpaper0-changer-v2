import 'package:flutter/foundation.dart';

@immutable
class WallpaperImage {
  final String id;
  final String sourceId;
  final String thumbnailUrl;
  final String downloadUrl;
  final int width;
  final int height;
  final String format;

  const WallpaperImage({
    required this.id,
    required this.sourceId,
    required this.thumbnailUrl,
    required this.downloadUrl,
    required this.width,
    required this.height,
    required this.format,
  });

  factory WallpaperImage.fromJson(Map<String, dynamic> json) => WallpaperImage(
        id: json['id'] as String,
        sourceId: json['sourceId'] as String,
        thumbnailUrl: json['thumbnailUrl'] as String,
        downloadUrl: json['downloadUrl'] as String,
        width: json['width'] as int,
        height: json['height'] as int,
        format: json['format'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceId': sourceId,
        'thumbnailUrl': thumbnailUrl,
        'downloadUrl': downloadUrl,
        'width': width,
        'height': height,
        'format': format,
      };

  WallpaperImage copyWith({
    String? id,
    String? sourceId,
    String? thumbnailUrl,
    String? downloadUrl,
    int? width,
    int? height,
    String? format,
  }) =>
      WallpaperImage(
        id: id ?? this.id,
        sourceId: sourceId ?? this.sourceId,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        downloadUrl: downloadUrl ?? this.downloadUrl,
        width: width ?? this.width,
        height: height ?? this.height,
        format: format ?? this.format,
      );
}
