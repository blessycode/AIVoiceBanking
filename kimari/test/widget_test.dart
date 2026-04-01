import 'package:flutter_test/flutter_test.dart';
import 'package:kimari/main.dart';

void main() {
  testWidgets('splash shell renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ZimVoiceBankApp(autoStart: false));

    expect(find.text('Jonten'), findsOneWidget);
    expect(find.text('Your AI Voice Banking Assistant'), findsOneWidget);
    expect(find.text('Continue →'), findsOneWidget);
  });
}
