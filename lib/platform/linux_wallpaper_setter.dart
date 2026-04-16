import 'dart:io';
import 'package:flutter/services.dart';
import 'wallpaper_setter.dart';

typedef ProcessRunner = Future<ProcessResult> Function(
    String executable, List<String> arguments);

class LinuxWallpaperSetter implements WallpaperSetter {
  LinuxWallpaperSetter({
    ProcessRunner? processRunner,
    Map<String, String>? environment,
  })  : _run = processRunner ?? Process.run,
        _environment = environment ?? Platform.environment;

  final ProcessRunner _run;
  final Map<String, String> _environment;

  @override
  Future<void> set(String localFilePath) async {
    final de = (_environment['XDG_CURRENT_DESKTOP'] ?? '').toUpperCase();

    if (de.contains('GNOME') || de.contains('UBUNTU')) {
      await _gnomeSet(localFilePath);
    } else if (de.contains('KDE')) {
      await _kdeSet(localFilePath);
    } else {
      await _fehSet(localFilePath);
    }
  }

  Future<void> _gnomeSet(String path) async {
    final uri = Uri.file(path).toString();
    for (final key in ['picture-uri', 'picture-uri-dark']) {
      final result = await _run('gsettings', [
        'set', 'org.gnome.desktop.background', key, uri,
      ]);
      if (result.exitCode != 0) {
        throw PlatformException(
          code: 'SET_FAILED',
          message: result.stderr.toString(),
        );
      }
    }
  }

  Future<void> _kdeSet(String path) async {
    final result = await _run('plasma-apply-wallpaperimage', [path]);
    if (result.exitCode != 0) {
      throw PlatformException(
        code: 'SET_FAILED',
        message: result.stderr.toString(),
      );
    }
  }

  Future<void> _fehSet(String path) async {
    final result = await _run('feh', ['--bg-scale', path]);
    if (result.exitCode != 0) {
      throw PlatformException(
        code: 'SET_FAILED',
        message: result.stderr.toString(),
      );
    }
  }
}
