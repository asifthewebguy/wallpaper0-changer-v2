import 'package:local_notifier/local_notifier.dart';
import 'app_notifier.dart';

class LocalNotifierAppNotifier implements AppNotifier {
  LocalNotifierAppNotifier({LocalNotifier? notifier})
      : _notifier = notifier ?? localNotifier;

  final LocalNotifier _notifier;

  @override
  Future<void> show(String title, {String? body}) async {
    await _notifier.notify(
      LocalNotification(title: title, body: body),
    );
  }
}
