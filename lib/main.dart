import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_notifier/local_notifier.dart';
import 'app.dart';
import 'platform/windows_protocol_registrar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await localNotifier.setup(appName: 'Wallpaper Changer');

  if (Platform.isWindows) {
    try {
      await WindowsProtocolRegistrar().register();
    } catch (e) {
      debugPrint('Protocol registration failed: $e');
    }
  }

  runApp(const ProviderScope(child: WallpaperChangerApp()));
}
