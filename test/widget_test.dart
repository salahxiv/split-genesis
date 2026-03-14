import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:split_genesis/app.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SplitGenesisApp()),
    );
    // App renders without crashing — shows loading indicator or home screen
    await tester.pump();
    expect(find.byType(ProviderScope), findsOneWidget);
  });
}
