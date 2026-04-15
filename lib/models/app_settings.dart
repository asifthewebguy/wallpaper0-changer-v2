import 'package:flutter/foundation.dart';

@immutable
class AppSettings {
  final int schedulerIntervalMinutes;
  final List<String> activeSourceIds;
  final String? unsplashApiKey;
  final String? wallhavenApiKey;
  final String? linuxWallpaperCommand;
  final int cacheSizeLimitMb;
  final String? localFolderPath;

  const AppSettings({
    this.schedulerIntervalMinutes = 30,
    this.activeSourceIds = const ['aiwpme'],
    this.unsplashApiKey,
    this.wallhavenApiKey,
    this.linuxWallpaperCommand,
    this.cacheSizeLimitMb = 500,
    this.localFolderPath,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        schedulerIntervalMinutes: (json['schedulerIntervalMinutes'] as int?) ?? 30,
        activeSourceIds:
            (json['activeSourceIds'] as List<dynamic>?)?.cast<String>() ?? const ['aiwpme'],
        unsplashApiKey: json['unsplashApiKey'] as String?,
        wallhavenApiKey: json['wallhavenApiKey'] as String?,
        linuxWallpaperCommand: json['linuxWallpaperCommand'] as String?,
        cacheSizeLimitMb: (json['cacheSizeLimitMb'] as int?) ?? 500,
        localFolderPath: json['localFolderPath'] as String?,
      );

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'schedulerIntervalMinutes': schedulerIntervalMinutes,
      'activeSourceIds': activeSourceIds,
      'cacheSizeLimitMb': cacheSizeLimitMb,
    };
    if (unsplashApiKey != null) m['unsplashApiKey'] = unsplashApiKey;
    if (wallhavenApiKey != null) m['wallhavenApiKey'] = wallhavenApiKey;
    if (linuxWallpaperCommand != null) m['linuxWallpaperCommand'] = linuxWallpaperCommand;
    if (localFolderPath != null) m['localFolderPath'] = localFolderPath;
    return m;
  }

  AppSettings copyWith({
    int? schedulerIntervalMinutes,
    List<String>? activeSourceIds,
    String? unsplashApiKey,
    String? wallhavenApiKey,
    String? linuxWallpaperCommand,
    int? cacheSizeLimitMb,
    String? localFolderPath,
  }) =>
      AppSettings(
        schedulerIntervalMinutes: schedulerIntervalMinutes ?? this.schedulerIntervalMinutes,
        activeSourceIds: activeSourceIds ?? this.activeSourceIds,
        unsplashApiKey: unsplashApiKey ?? this.unsplashApiKey,
        wallhavenApiKey: wallhavenApiKey ?? this.wallhavenApiKey,
        linuxWallpaperCommand: linuxWallpaperCommand ?? this.linuxWallpaperCommand,
        cacheSizeLimitMb: cacheSizeLimitMb ?? this.cacheSizeLimitMb,
        localFolderPath: localFolderPath ?? this.localFolderPath,
      );
}
