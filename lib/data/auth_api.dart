// data/auth_api.dart: register/login/me по контракту; токен уходит в TokenStore.
// Пароль уходит только на сервер и нигде не сохраняется.
import 'api_client.dart';
import 'result.dart';
import 'token_store.dart';
import 'user.dart';

class AuthApi {
  AuthApi(this._api, this._tokens);

  final ApiClient _api;
  final TokenStore _tokens;

  Future<Result<User>> register(String email, String password, String name) =>
      _enter('/auth/register',
          {'email': email, 'password': password, 'name': name});

  Future<Result<User>> login(String email, String password) =>
      _enter('/auth/login', {'email': email, 'password': password});

  /// Кто я: нужен при запуске, когда токен пережил перезапуск, а пользователя
  /// приложение ещё не знает.
  Future<Result<User>> me() => _api.send(
        'GET',
        '/me',
        ok: {200},
        parse: (json) => User.fromJson(json as Map<String, dynamic>),
      );

  /// Выход: стереть токен. Сервер токены не хранит, отзывать нечего.
  Future<void> logout() => _tokens.clear();

  Future<Result<User>> _enter(String path, Map<String, Object?> body) async {
    final result = await _api.send<(String, User)>(
      'POST',
      path,
      ok: {200, 201},
      body: body,
      authorized: false, // здесь 401 значит неверный пароль, а не мёртвый пропуск
      parse: (json) {
        final data = json as Map<String, dynamic>;
        return (
          data['token'] as String,
          User.fromJson(data['user'] as Map<String, dynamic>),
        );
      },
    );
    switch (result) {
      case Ok(:final value):
        await _tokens.save(value.$1); // login -> setString
        return Ok(value.$2);
      case Err(:final msg):
        return Err(msg);
    }
  }
}
