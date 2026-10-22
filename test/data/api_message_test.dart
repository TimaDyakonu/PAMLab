import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:second_hand_market/data/api_message.dart';

http.Response reply(int status, String body) => http.Response(body, status);

void main() {
  String envelope(String code) =>
      '{"error":{"code":"$code","message":"english text"}}';

  test('известные коды переводятся на русский', () {
    expect(apiMessage(reply(400, envelope('VALIDATION_ERROR'))),
        'Отправленные данные недействительны');
    expect(apiMessage(reply(401, envelope('UNAUTHORIZED'))),
        'Неверный email или пароль');
    expect(apiMessage(reply(409, envelope('EMAIL_TAKEN'))),
        'Аккаунт с этим email уже существует');
    expect(apiMessage(reply(404, envelope('NOT_FOUND'))),
        'Запись не существует');
    expect(apiMessage(reply(409, envelope('ITEM_UNAVAILABLE'))),
        'Вещь уже недоступна');
  });

  test('английский message сервера на экран не попадает', () {
    expect(apiMessage(reply(400, envelope('VALIDATION_ERROR'))),
        isNot(contains('english')));
  });

  test('неизвестный код -> Ошибка сервера (код)', () {
    expect(apiMessage(reply(500, envelope('BOOM'))), 'Ошибка сервера (BOOM)');
  });

  test('тело вне контракта (HTML от прокси) -> Ошибка сервера (статус)', () {
    expect(apiMessage(reply(502, '<html>Bad gateway</html>')),
        'Ошибка сервера (502)');
  });

  test('JSON не того вида -> Ошибка сервера (статус)', () {
    expect(apiMessage(reply(500, '[1,2,3]')), 'Ошибка сервера (500)');
    expect(apiMessage(reply(500, '{"error":"text"}')), 'Ошибка сервера (500)');
  });
}
