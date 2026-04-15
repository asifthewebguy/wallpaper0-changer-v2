import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper_changer/models/app_settings.dart';

void main() {
  test('AppSettings has sensible defaults', () {
    const s = AppSettings();
    expect(s.schedulerIntervalMinutes, 30);
    expect(s.activeSourceIds, const ['aiwpme']);
    expect(s.cacheSizeLimitMb, 500);
    expect(s.unsplashApiKey, isNull);
  });

  test('fromJson round-trips toJson', () {
    final s = AppSettings(
      schedulerIntervalMinutes: 15,
      activeSourceIds: const ['unsplash', 'wallhaven'],
      unsplashApiKey: 'my-key',
      cacheSizeLimitMb: 200,
    );
    final restored = AppSettings.fromJson(s.toJson());
    expect(restored.schedulerIntervalMinutes, 15);
    expect(restored.activeSourceIds, const ['unsplash', 'wallhaven']);
    expect(restored.unsplashApiKey, 'my-key');
    expect(restored.cacheSizeLimitMb, 200);
  });

  test('fromJson uses defaults for missing keys', () {
    final s = AppSettings.fromJson({});
    expect(s.schedulerIntervalMinutes, 30);
    expect(s.activeSourceIds, const ['aiwpme']);
  });

  test('copyWith replaces specified fields', () {
    const s = AppSettings();
    final updated = s.copyWith(schedulerIntervalMinutes: 60, unsplashApiKey: 'key');
    expect(updated.schedulerIntervalMinutes, 60);
    expect(updated.unsplashApiKey, 'key');
    expect(updated.cacheSizeLimitMb, 500);
  });

  test('copyWith can clear nullable fields to null', () {
    final s = AppSettings(unsplashApiKey: 'key', localFolderPath: '/photos');
    final cleared = s.copyWith(unsplashApiKey: null, localFolderPath: null);
    expect(cleared.unsplashApiKey, isNull);
    expect(cleared.localFolderPath, isNull);
    expect(cleared.schedulerIntervalMinutes, 30); // unrelated fields preserved
  });
}
