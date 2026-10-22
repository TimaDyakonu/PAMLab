// data/token_store.dart: пропуск поверх shared_preferences.
// Остальной код не знает, где спит токен. Пароль не пишется локально никогда:
// токен можно заменить, он истекает, а пароль - ключ от всего дома.
import 'package:shared_preferences/shared_preferences.dart';

class TokenStore {
  static const _key = 'auth_token';

  /// null: пользователь не входил.
  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(_key);

  Future<void> save(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token); // login -> setString
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key); // logout И 401: мёртвый пропуск выбрасывают
  }
}
