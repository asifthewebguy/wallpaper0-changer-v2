import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallpaper_changer/features/schedule/schedule_provider.dart';
import 'package:wallpaper_changer/features/schedule/schedule_screen.dart';
import 'package:wallpaper_changer/features/schedule/schedule_state.dart';
import 'package:wallpaper_changer/models/app_settings.dart';
import 'package:wallpaper_changer/models/wallpaper_image.dart';
import 'package:wallpaper_changer/providers.dart';
import 'package:wallpaper_changer/services/wallpaper_service.dart';
import 'package:wallpaper_changer/sources/wallpaper_source.dart';

class FakeScheduleNotifier extends ScheduleNotifier {
  FakeScheduleNotifier(this._initial);
  final ScheduleState _initial;
  int enableCalls = 0;
  int disableCalls = 0;
  int? lastEnabledInterval;

  @override
  Future<ScheduleState> build() async => _initial;

  @override
  Future<void> enable(int intervalMinutes) async {
    enableCalls++;
    lastEnabledInterval = intervalMinutes;
    state = AsyncValue.data(ScheduleState(
      isEnabled: true,
      intervalMinutes: intervalMinutes,
    ));
  }

  @override
  Future<void> disable() async {
    disableCalls++;
    state = AsyncValue.data(ScheduleState(
      isEnabled: false,
      intervalMinutes: state.valueOrNull?.intervalMinutes ?? 30,
    ));
  }
}

class MockWallpaperService extends Mock implements WallpaperService {}
class MockWallpaperSource extends Mock implements WallpaperSource {}

WallpaperImage _img() => const WallpaperImage(
      id: 'r', sourceId: 'aiwpme',
      thumbnailUrl: 'https://e.com/t.jpg',
      downloadUrl: 'https://e.com/f.jpg',
      width: 1920, height: 1080, format: 'jpg',
    );

void main() {
  late FakeScheduleNotifier notifier;
  late MockWallpaperService wallpaperService;
  late MockWallpaperSource source;

  setUpAll(() {
    registerFallbackValue(_img());
    registerFallbackValue(MockWallpaperSource());
  });

  setUp(() {
    notifier = FakeScheduleNotifier(
      const ScheduleState(isEnabled: false, intervalMinutes: 30),
    );
    source = MockWallpaperSource();
    when(() => source.id).thenReturn('aiwpme');
    when(() => source.displayName).thenReturn('AI Wallpapers');
    when(() => source.getRandom()).thenAnswer((_) async => _img());
    wallpaperService = MockWallpaperService();
    when(() => wallpaperService.setWallpaper(any(), any()))
        .thenAnswer((_) async {});
  });

  Widget wrap() => ProviderScope(
        overrides: [
          scheduleProvider.overrideWith(() => notifier),
          scheduleCountdownProvider.overrideWith(
            (ref) => Stream.value(Duration.zero),
          ),
          appSettingsProvider.overrideWith((ref) async => const AppSettings()),
          allSourcesProvider.overrideWithValue({'aiwpme': source}),
          wallpaperServiceProvider.overrideWithValue(wallpaperService),
        ],
        child: const MaterialApp(home: Scaffold(body: ScheduleScreen())),
      );

  testWidgets('shows toggle, interval dropdown, and Set Now button',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    expect(find.byType(Switch), findsOneWidget);
    expect(find.byType(DropdownButton<int?>), findsOneWidget);
    expect(find.text('Set Random Wallpaper Now'), findsOneWidget);
  });

  testWidgets('toggling on calls enable with current interval',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(notifier.enableCalls, 1);
    expect(notifier.lastEnabledInterval, 30);
  });

  testWidgets('toggling off calls disable', (tester) async {
    notifier = FakeScheduleNotifier(
      const ScheduleState(isEnabled: true, intervalMinutes: 30),
    );
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(notifier.disableCalls, 1);
  });

  testWidgets('Set Now button triggers wallpaperService.setWallpaper',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set Random Wallpaper Now'));
    await tester.pumpAndSettle();
    verify(() => wallpaperService.setWallpaper(any(), any())).called(1);
  });

  testWidgets('changing preset while enabled re-enables with new interval',
      (tester) async {
    notifier = FakeScheduleNotifier(
      const ScheduleState(isEnabled: true, intervalMinutes: 30),
    );
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    // Open dropdown and select 60
    await tester.tap(find.byType(DropdownButton<int?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('60 minutes').last);
    await tester.pumpAndSettle();
    expect(notifier.lastEnabledInterval, 60);
  });
}
