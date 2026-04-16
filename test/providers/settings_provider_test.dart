import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper_changer/features/settings/settings_provider.dart';
import 'package:wallpaper_changer/models/app_settings.dart';
import 'package:wallpaper_changer/providers.dart';
import 'package:wallpaper_changer/services/config_service.dart';

void main() {
  late Directory tmpDir;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('settings_prov_test_');
  });
  tearDown(() async => tmpDir.delete(recursive: true));

  test('build loads settings from ConfigService', () async {
    final config = ConfigService(getAppDir: () async => tmpDir);
    await config.save(const AppSettings(schedulerIntervalMinutes: 45));

    final container = ProviderContainer(overrides: [
      configServiceProvider.overrideWithValue(config),
    ]);
    addTearDown(container.dispose);

    final settings = await container.read(settingsProvider.future);
    expect(settings.schedulerIntervalMinutes, 45);
  });

  test('update saves and reflects new settings', () async {
    final config = ConfigService(getAppDir: () async => tmpDir);
    final container = ProviderContainer(overrides: [
      configServiceProvider.overrideWithValue(config),
    ]);
    addTearDown(container.dispose);

    await container.read(settingsProvider.future);
    await container.read(settingsProvider.notifier).save(
          const AppSettings(schedulerIntervalMinutes: 60),
        );
    final updated = await container.read(settingsProvider.future);
    expect(updated.schedulerIntervalMinutes, 60);
  });
}
