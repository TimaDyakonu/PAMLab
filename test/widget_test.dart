import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:second_hand_market/main.dart';
import 'package:second_hand_market/models/favorites_model.dart';

void main() {
  testWidgets('приложение запускается', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => FavoritesModel())],
        child: const MyApp(),
      ),
    );
    expect(find.text('Second Hand Market'), findsWidgets);
  });
}
