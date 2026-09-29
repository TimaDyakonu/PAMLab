import 'package:flutter_test/flutter_test.dart';

import 'support/test_app.dart';

void main() {
  testWidgets('приложение запускается на экране входа', (tester) async {
    await tester.pumpWidget(buildTestApp());
    expect(find.text('Second Hand Market'), findsWidgets);
  });
}
