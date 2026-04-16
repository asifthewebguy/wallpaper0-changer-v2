import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_notifier/local_notifier.dart';
import 'app.dart';
import 'platform/linux_protocol_registrar.dart';
import 'platform/windows_protocol_registrar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await localNotifier.setup(appName: 'Wallpaper Changer');

  if (Platform.isWindows || Platform.isLinux) {
    final registrar = Platform.isWindows
        ? WindowsProtocolRegistrar()
        : LinuxProtocolRegistrar();
    try {
      await registrar.register();
    } catch (e) {
      debugPrint('Protocol registration failed: $e');
    }
  }

  runApp(const ProviderScope(child: WallpaperChangerApp()));
}
