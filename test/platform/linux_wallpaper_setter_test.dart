import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper_changer/platform/linux_wallpaper_setter.dart';

void main() {
  group('LinuxWallpaperSetter', () {
    test('GNOME: calls gsettings for picture-uri and picture-uri-dark', () async {
      final calls = <List<String>>[];
      final setter = LinuxWallpaperSetter(
        processRunner: (exe, args) async {
          calls.add([exe, ...args]);
          return ProcessResult(0, 0, '', '');
        },
        environment: {'XDG_CURRENT_DESKTOP': 'GNOME'},
      );

      await setter.set('/home/user/photo.jpg');

      expect(calls, hasLength(2));
      expect(calls[0], [
        'gsettings', 'set',
        'org.gnome.desktop.background', 'picture-uri',
        'file:///home/user/photo.jpg',
      ]);
      expect(calls[1], [
        'gsettings', 'set',
        'org.gnome.desktop.background', 'picture-uri-dark',
        'file:///home/user/photo.jpg',
      ]);
    });

    test('ubuntu:GNOME variant is treated as GNOME', () async {
      final calls = <List<String>>[];
      final setter = LinuxWallpaperSetter(
        processRunner: (exe, args) async {
          calls.add([exe, ...args]);
          return ProcessResult(0, 0, '', '');
        },
        environment: {'XDG_CURRENT_DESKTOP': 'ubuntu:GNOME'},
      );

      await setter.set('/home/user/photo.jpg');

      expect(calls.first.first, 'gsettings');
    });

    test('KDE: calls plasma-apply-wallpaperimage', () async {
      final calls = <List<String>>[];
      final setter = LinuxWallpaperSetter(
        processRunner: (exe, args) async {
          calls.add([exe, ...args]);
          return ProcessResult(0, 0, '', '');
        },
        environment: {'XDG_CURRENT_DESKTOP': 'KDE'},
      );

      await setter.set('/home/user/photo.jpg');

      expect(calls, hasLength(1));
      expect(calls[0], ['plasma-apply-wallpaperimage', '/home/user/photo.jpg']);
    });

    test('unknown DE: falls back to feh --bg-scale', () async {
      final calls = <List<String>>[];
      final setter = LinuxWallpaperSetter(
        processRunner: (exe, args) async {
          calls.add([exe, ...args]);
          return ProcessResult(0, 0, '', '');
        },
        environment: {'XDG_CURRENT_DESKTOP': 'XFCE'},
      );

      await setter.set('/home/user/photo.jpg');

      expect(calls, hasLength(1));
      expect(calls[0], ['feh', '--bg-scale', '/home/user/photo.jpg']);
    });

    test('missing XDG_CURRENT_DESKTOP: falls back to feh', () async {
      final calls = <List<String>>[];
      final setter = LinuxWallpaperSetter(
        processRunner: (exe, args) async {
          calls.add([exe, ...args]);
          return ProcessResult(0, 0, '', '');
        },
        environment: {},
      );

      await setter.set('/home/user/photo.jpg');

      expect(calls.first.first, 'feh');
    });

    test('non-zero exit throws PlatformException with SET_FAILED code', () async {
      final setter = LinuxWallpaperSetter(
        processRunner: (exe, args) async =>
            ProcessResult(0, 1, '', 'gsettings: command not found'),
        environment: {'XDG_CURRENT_DESKTOP': 'GNOME'},
      );

      await expectLater(
        setter.set('/home/user/photo.jpg'),
        throwsA(isA<PlatformException>()
            .having((e) => e.code, 'code', 'SET_FAILED')
            .having((e) => e.message, 'message', 'gsettings: command not found')),
      );
    });
  });
}
