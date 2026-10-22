// data/api_message.dart: русское сообщение для человека из ответа сервера.
// Контракт обещает на ЛЮБОЙ ошибке один и тот же конверт:
//   {"error": {"code": "...", "message": "..."}}
// Код стабилен и принадлежит программе, английский message на экран не попадает.
import 'dart:convert';
import 'package:http/http.dart' as http;

String apiMessage(http.Response res) {
  try {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final error = body['error'] as Map<String, dynamic>;
    final code = error['code'] as String;
    return switch (code) {
      'VALIDATION_ERROR' => 'Отправленные данные недействительны',
      'UNAUTHORIZED' => 'Неверный email или пароль',
      'EMAIL_TAKEN' => 'Аккаунт с этим email уже существует',
      'NOT_FOUND' => 'Запись не существует',
      'ITEM_UNAVAILABLE' => 'Вещь уже недоступна',
      _ => 'Ошибка сервера ($code)',
    };
  } on FormatException {
    return 'Ошибка сервера (${res.statusCode})';
  } on TypeError {
    return 'Ошибка сервера (${res.statusCode})';
  }
}
