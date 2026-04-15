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

  // Sentinel used by copyWith to distinguish "not provided" from explicit null.
  static const _absent = Object();

  AppSettings copyWith({
    int? schedulerIntervalMinutes,
    List<String>? activeSourceIds,
    Object? unsplashApiKey = _absent,
    Object? wallhavenApiKey = _absent,
    Object? linuxWallpaperCommand = _absent,
    int? cacheSizeLimitMb,
    Object? localFolderPath = _absent,
  }) =>
      AppSettings(
        schedulerIntervalMinutes:
            schedulerIntervalMinutes ?? this.schedulerIntervalMinutes,
        activeSourceIds: activeSourceIds ?? this.activeSourceIds,
        unsplashApiKey: unsplashApiKey == _absent
            ? this.unsplashApiKey
            : unsplashApiKey as String?,
        wallhavenApiKey: wallhavenApiKey == _absent
            ? this.wallhavenApiKey
            : wallhavenApiKey as String?,
        linuxWallpaperCommand: linuxWallpaperCommand == _absent
            ? this.linuxWallpaperCommand
            : linuxWallpaperCommand as String?,
        cacheSizeLimitMb: cacheSizeLimitMb ?? this.cacheSizeLimitMb,
        localFolderPath: localFolderPath == _absent
            ? this.localFolderPath
            : localFolderPath as String?,
      );
}
