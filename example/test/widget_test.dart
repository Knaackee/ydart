import 'package:flutter_test/flutter_test.dart';
import 'package:ydart_example/main.dart';

void main() {
  testWidgets('renders sync harness controls', (tester) async {
    await tester.pumpWidget(const YdartExampleApp());

    expect(find.text('ydart sync harness'), findsWidgets);
    expect(find.text('Edit A'), findsOneWidget);
    expect(find.text('Edit B'), findsOneWidget);
    expect(find.text('Sync A to B'), findsOneWidget);
    expect(find.text('Sync B to A'), findsOneWidget);
  }, skip: true);
}
