import 'package:flutter_test/flutter_test.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallpaper_changer/platform/local_notifier_app_notifier.dart';

class MockLocalNotifier extends Mock implements LocalNotifier {}

class _FakeLocalNotification extends Fake implements LocalNotification {}

void main() {
  late MockLocalNotifier mockNotifier;
  late LocalNotifierAppNotifier appNotifier;

  setUpAll(() {
    registerFallbackValue(_FakeLocalNotification());
  });

  setUp(() {
    mockNotifier = MockLocalNotifier();
    appNotifier = LocalNotifierAppNotifier(notifier: mockNotifier);
    when(() => mockNotifier.notify(any())).thenAnswer((_) async {});
  });

  testWidgets('show calls notify with correct title and body', (tester) async {
    await appNotifier.show('Wallpaper updated', body: 'photo.jpg');

    final captured =
        verify(() => mockNotifier.notify(captureAny())).captured;
    expect(captured, hasLength(1));
    final n = captured.first as LocalNotification;
    expect(n.title, 'Wallpaper updated');
    expect(n.body, 'photo.jpg');
  });

  testWidgets('show calls notify with null body when body omitted', (tester) async {
    await appNotifier.show('Wallpaper updated');

    final captured =
        verify(() => mockNotifier.notify(captureAny())).captured;
    final n = captured.first as LocalNotification;
    expect(n.title, 'Wallpaper updated');
    expect(n.body, isNull);
  });
}
