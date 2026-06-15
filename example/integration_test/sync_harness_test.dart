import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ydart_example/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('edits and syncs both replicas without crashing', (tester) async {
    await tester.pumpWidget(const YdartExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('ydart sync harness'), findsWidgets);
    expect(find.text('Converged: true'), findsOneWidget);

    await tester.tap(find.text('Edit A'));
    await tester.pumpAndSettle();

    expect(find.text('A1'), findsOneWidget);
    expect(find.text('Converged: false'), findsOneWidget);

    await tester.tap(find.text('Sync A to B'));
    await tester.pumpAndSettle();

    expect(find.text('A1'), findsNWidgets(2));
    expect(find.text('Status: Synced A to B'), findsOneWidget);
    expect(find.text('Converged: true'), findsOneWidget);

    await tester.tap(find.text('Edit B'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Round trip'));
    await tester.pumpAndSettle();

    expect(find.text('A1 B2'), findsNWidgets(2));
    expect(find.text('Status: Round trip sync complete'), findsOneWidget);
    expect(find.text('Converged: true'), findsOneWidget);
  });
}
