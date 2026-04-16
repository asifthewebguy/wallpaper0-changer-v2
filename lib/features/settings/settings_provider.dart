import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_settings.dart';
import '../../providers.dart';

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() {
    return ref.watch(configServiceProvider).load();
  }

  Future<void> save(AppSettings settings) async {
    await ref.read(configServiceProvider).save(settings);
    state = AsyncValue.data(settings);
  }
}
