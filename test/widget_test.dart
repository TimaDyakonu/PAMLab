import 'package:flutter_test/flutter_test.dart';

import 'package:second_hand_market/main.dart';

void main() {
  testWidgets('приложение запускается', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Second Hand Market'), findsWidgets);
  });
}
