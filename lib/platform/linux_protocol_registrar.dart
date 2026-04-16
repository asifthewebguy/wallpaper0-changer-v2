import 'dart:io';
import 'package:flutter/services.dart';
import 'protocol_registrar.dart';

typedef ProcessRunner = Future<ProcessResult> Function(
    String executable, List<String> arguments);
typedef FileWriter = Future<void> Function(String path, String content);

class LinuxProtocolRegistrar implements ProtocolRegistrar {
  LinuxProtocolRegistrar({
    ProcessRunner? processRunner,
    FileWriter? fileWriter,
    Map<String, String>? environment,
    String? resolvedExecutable,
  })  : _run = processRunner ?? Process.run,
        _writeFile = fileWriter ?? _defaultFileWriter,
        _environment = environment ?? Platform.environment,
        _resolvedExecutable =
            resolvedExecutable ?? Platform.resolvedExecutable;

  static Future<void> _defaultFileWriter(String path, String content) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  final ProcessRunner _run;
  final FileWriter _writeFile;
  final Map<String, String> _environment;
  final String _resolvedExecutable;

  @override
  Future<void> register() async {
    final home = _environment['HOME'];
    if (home == null || home.isEmpty) {
      throw PlatformException(
        code: 'NO_HOME',
        message: 'HOME environment variable is not set',
      );
    }
    final desktopDir = '$home/.local/share/applications';
    final desktopPath = '$desktopDir/wallpaper0-changer.desktop';

    final content = '[Desktop Entry]\n'
        'Name=Wallpaper Changer\n'
        'Exec=$_resolvedExecutable %u\n'
        'Type=Application\n'
        'MimeType=x-scheme-handler/wallpaper0-changer;\n';

    await _writeFile(desktopPath, content);

    final mimeResult = await _run('xdg-mime', [
      'default',
      'wallpaper0-changer.desktop',
      'x-scheme-handler/wallpaper0-changer',
    ]);

    if (mimeResult.exitCode != 0) {
      throw PlatformException(
        code: 'REG_FAILED',
        message: mimeResult.stderr.toString(),
      );
    }

    // update-desktop-database is optional — ignore failures
    try {
      await _run('update-desktop-database', [desktopDir]);
    } catch (_) {}
  }
}
