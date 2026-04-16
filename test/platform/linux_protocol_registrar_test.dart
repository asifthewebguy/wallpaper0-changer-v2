import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper_changer/platform/linux_protocol_registrar.dart';

void main() {
  group('LinuxProtocolRegistrar', () {
    test('writes .desktop file with correct content', () async {
      String? writtenPath;
      String? writtenContent;

      final registrar = LinuxProtocolRegistrar(
        processRunner: (exe, args) async => ProcessResult(0, 0, '', ''),
        fileWriter: (path, content) async {
          writtenPath = path;
          writtenContent = content;
        },
        environment: {'HOME': '/home/testuser'},
        resolvedExecutable: '/usr/bin/wallpaper_changer',
      );

      await registrar.register();

      expect(writtenPath,
          '/home/testuser/.local/share/applications/wallpaper0-changer.desktop');
      expect(writtenContent, contains('Exec=/usr/bin/wallpaper_changer %u'));
      expect(writtenContent,
          contains('MimeType=x-scheme-handler/wallpaper0-changer;'));
      expect(writtenContent, contains('[Desktop Entry]'));
    });

    test('calls xdg-mime default with correct args', () async {
      final calls = <List<String>>[];

      final registrar = LinuxProtocolRegistrar(
        processRunner: (exe, args) async {
          calls.add([exe, ...args]);
          return ProcessResult(0, 0, '', '');
        },
        fileWriter: (path, content) async {},
        environment: {'HOME': '/home/testuser'},
        resolvedExecutable: '/usr/bin/wallpaper_changer',
      );

      await registrar.register();

      final mimeCall = calls.firstWhere((c) => c.first == 'xdg-mime');
      expect(mimeCall, [
        'xdg-mime',
        'default',
        'wallpaper0-changer.desktop',
        'x-scheme-handler/wallpaper0-changer',
      ]);
    });

    test('xdg-mime non-zero exit throws PlatformException with REG_FAILED',
        () async {
      final registrar = LinuxProtocolRegistrar(
        processRunner: (exe, args) async {
          if (exe == 'xdg-mime') {
            return ProcessResult(0, 1, '', 'xdg-mime: not found');
          }
          return ProcessResult(0, 0, '', '');
        },
        fileWriter: (path, content) async {},
        environment: {'HOME': '/home/testuser'},
        resolvedExecutable: '/usr/bin/wallpaper_changer',
      );

      await expectLater(
        registrar.register(),
        throwsA(isA<PlatformException>()
            .having((e) => e.code, 'code', 'REG_FAILED')
            .having((e) => e.message, 'message', 'xdg-mime: not found')),
      );
    });

    test('update-desktop-database failure is non-fatal', () async {
      final registrar = LinuxProtocolRegistrar(
        processRunner: (exe, args) async {
          if (exe == 'update-desktop-database') {
            return ProcessResult(0, 127, '', 'command not found');
          }
          return ProcessResult(0, 0, '', '');
        },
        fileWriter: (path, content) async {},
        environment: {'HOME': '/home/testuser'},
        resolvedExecutable: '/usr/bin/wallpaper_changer',
      );

      // Should complete without throwing
      await expectLater(registrar.register(), completes);
    });

    test('missing HOME throws PlatformException with NO_HOME code', () async {
      final registrar = LinuxProtocolRegistrar(
        processRunner: (exe, args) async => ProcessResult(0, 0, '', ''),
        fileWriter: (path, content) async {},
        environment: {},
        resolvedExecutable: '/usr/bin/wallpaper_changer',
      );

      await expectLater(
        registrar.register(),
        throwsA(isA<PlatformException>()
            .having((e) => e.code, 'code', 'NO_HOME')),
      );
    });
  });
}
