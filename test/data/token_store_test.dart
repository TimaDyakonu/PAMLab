import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:second_hand_market/data/token_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('пока не входили, read() возвращает null', () async {
    expect(await TokenStore().read(), isNull);
  });

  test('save -> read возвращает тот же токен, даже из нового экземпляра', () async {
    await TokenStore().save('abc.def.ghi');
    expect(await TokenStore().read(), 'abc.def.ghi');
  });

  test('clear выбрасывает токен', () async {
    final store = TokenStore();
    await store.save('abc');
    await store.clear();
    expect(await store.read(), isNull);
  });
}
