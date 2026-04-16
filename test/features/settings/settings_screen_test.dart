import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper_changer/features/settings/settings_provider.dart';
import 'package:wallpaper_changer/features/settings/settings_screen.dart';
import 'package:wallpaper_changer/models/app_settings.dart';

class FakeSettingsNotifier extends SettingsNotifier {
  FakeSettingsNotifier(this._initial);
  final AppSettings _initial;
  AppSettings? lastSaved;

  @override
  Future<AppSettings> build() async => _initial;

  @override
  Future<void> save(AppSettings settings) async {
    lastSaved = settings;
    state = AsyncValue.data(settings);
  }
}

Widget _wrap(FakeSettingsNotifier notifier) {
  return ProviderScope(
    overrides: [
      settingsProvider.overrideWith(() => notifier),
    ],
    child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
  );
}

void main() {
  testWidgets('renders API key fields and cache size', (tester) async {
    final notifier = FakeSettingsNotifier(const AppSettings());
    await tester.pumpWidget(_wrap(notifier));
    await tester.pumpAndSettle();
    expect(find.text('Unsplash API Key'), findsOneWidget);
    expect(find.text('Wallhaven API Key'), findsOneWidget);
    expect(find.text('Cache size limit (MB)'), findsOneWidget);
  });

  testWidgets('blur on Unsplash key field saves setting', (tester) async {
    final notifier = FakeSettingsNotifier(const AppSettings());
    await tester.pumpWidget(_wrap(notifier));
    await tester.pumpAndSettle();
    final keyField = find.ancestor(
      of: find.text('Unsplash API Key'),
      matching: find.byType(Column),
    ).first;
    final textField = find.descendant(
      of: keyField,
      matching: find.byType(TextField),
    );
    await tester.tap(textField);
    await tester.enterText(textField, 'newkey');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(notifier.lastSaved?.unsplashApiKey, 'newkey');
  });

  testWidgets('invalid cache size reverts (not saved)', (tester) async {
    final notifier =
        FakeSettingsNotifier(const AppSettings(cacheSizeLimitMb: 500));
    await tester.pumpWidget(_wrap(notifier));
    await tester.pumpAndSettle();
    final cacheField = find.ancestor(
      of: find.text('Cache size limit (MB)'),
      matching: find.byType(Column),
    ).first;
    final textField = find.descendant(
      of: cacheField,
      matching: find.byType(TextField),
    );
    await tester.tap(textField);
    await tester.enterText(textField, 'abc');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(notifier.lastSaved, isNull);
  });

  testWidgets('empty API key saves null (not empty string)', (tester) async {
    final notifier =
        FakeSettingsNotifier(const AppSettings(unsplashApiKey: 'oldkey'));
    await tester.pumpWidget(_wrap(notifier));
    await tester.pumpAndSettle();
    final keyField = find.ancestor(
      of: find.text('Unsplash API Key'),
      matching: find.byType(Column),
    ).first;
    final textField = find.descendant(
      of: keyField,
      matching: find.byType(TextField),
    );
    await tester.tap(textField);
    await tester.enterText(textField, '');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(notifier.lastSaved?.unsplashApiKey, isNull);
  });

  testWidgets('renders local folder field and Browse button',
      (tester) async {
    final notifier = FakeSettingsNotifier(const AppSettings());
    await tester.pumpWidget(_wrap(notifier));
    await tester.pumpAndSettle();
    expect(find.text('Folder path'), findsOneWidget);
    expect(find.text('Browse...'), findsOneWidget);
  });

  testWidgets('blur on local folder field saves path', (tester) async {
    final notifier = FakeSettingsNotifier(const AppSettings());
    await tester.pumpWidget(_wrap(notifier));
    await tester.pumpAndSettle();
    final folderField = find.ancestor(
      of: find.text('Folder path'),
      matching: find.byType(Column),
    ).first;
    final textField = find.descendant(
      of: folderField,
      matching: find.byType(TextField),
    );
    await tester.tap(textField);
    await tester.enterText(textField, '/tmp/walls');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(notifier.lastSaved?.localFolderPath, '/tmp/walls');
  });
}
