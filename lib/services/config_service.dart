import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/app_settings.dart';

class ConfigService {
  final Future<Directory> Function() _getAppDir;

  ConfigService({Future<Directory> Function()? getAppDir})
      : _getAppDir = getAppDir ?? getApplicationSupportDirectory;

  Future<File> _settingsFile() async {
    final base = await _getAppDir();
    final dir = Directory('${base.path}/wallpaper_changer');
    if (!await dir.exists()) await dir.create(recursive: true);
    return File('${dir.path}/settings.json');
  }

  Future<AppSettings> load() async {
    final file = await _settingsFile();
    if (!await file.exists()) return const AppSettings();
    try {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return AppSettings.fromJson(json);
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> save(AppSettings settings) async {
    final file = await _settingsFile();
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(settings.toJson()));
    await tmp.rename(file.path);
  }
}
