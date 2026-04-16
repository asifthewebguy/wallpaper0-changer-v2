import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper_changer/widgets/glass_form_field.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child));

void main() {
  group('GlassFormField', () {
    testWidgets('renders initial value', (tester) async {
      await tester.pumpWidget(_wrap(GlassFormField(
        label: 'Unsplash Key',
        initialValue: 'abc123',
        onBlur: (_) {},
      )));
      expect(find.text('abc123'), findsOneWidget);
      expect(find.text('Unsplash Key'), findsOneWidget);
    });

    testWidgets('onBlur fires with current text when focus lost',
        (tester) async {
      String? committed;
      await tester.pumpWidget(_wrap(GlassFormField(
        label: 'Key',
        initialValue: 'old',
        onBlur: (text) => committed = text,
      )));
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'new');
      // Move focus away
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      expect(committed, 'new');
    });

    testWidgets('onBlur does not fire when text is unchanged',
        (tester) async {
      var calls = 0;
      await tester.pumpWidget(_wrap(GlassFormField(
        label: 'Key',
        initialValue: 'same',
        onBlur: (_) => calls++,
      )));
      await tester.tap(find.byType(TextField));
      await tester.pump();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      expect(calls, 0);
    });

    testWidgets('obscureText hides the input', (tester) async {
      await tester.pumpWidget(_wrap(GlassFormField(
        label: 'Secret',
        initialValue: 'hidden',
        onBlur: (_) {},
        obscureText: true,
      )));
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.obscureText, isTrue);
    });

    testWidgets('updates displayed text when initialValue changes externally',
        (tester) async {
      Widget build(String value) => _wrap(GlassFormField(
            label: 'Key',
            initialValue: value,
            onBlur: (_) {},
          ));
      await tester.pumpWidget(build('first'));
      expect(find.text('first'), findsOneWidget);
      await tester.pumpWidget(build('second'));
      expect(find.text('second'), findsOneWidget);
    });
  });
}
