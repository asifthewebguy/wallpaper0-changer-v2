import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper_changer/models/app_settings.dart';
import 'package:wallpaper_changer/services/config_service.dart';

void main() {
  late Directory tmpDir;
  late ConfigService service;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('config_test_');
    service = ConfigService(getAppDir: () async => tmpDir);
  });

  tearDown(() async {
    await tmpDir.delete(recursive: true);
  });

  test('load returns defaults when no file exists', () async {
    final settings = await service.load();
    expect(settings.schedulerIntervalMinutes, 30);
    expect(settings.activeSourceIds, ['aiwpme']);
  });

  test('save then load round-trips settings', () async {
    const s = AppSettings(
      schedulerIntervalMinutes: 15,
      activeSourceIds: ['unsplash'],
      unsplashApiKey: 'test-key',
    );
    await service.save(s);
    final restored = await service.load();
    expect(restored.schedulerIntervalMinutes, 15);
    expect(restored.activeSourceIds, ['unsplash']);
    expect(restored.unsplashApiKey, 'test-key');
  });

  test('save is atomic — writes .tmp then renames', () async {
    const s = AppSettings(schedulerIntervalMinutes: 60);
    await service.save(s);
    // After save, no .tmp file should remain
    final settingsDir = Directory('${tmpDir.path}/wallpaper_changer');
    final tmp = File('${settingsDir.path}/settings.json.tmp');
    expect(await tmp.exists(), isFalse);
  });
}
