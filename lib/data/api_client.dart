// data/api_client.dart: один HTTP-запрос и ТРИ СЛОЯ ОТКАЗА (лекция C8).
// Репозитории и AuthApi описывают только маршруты и разбор ответа, а как
// упасть правильно, решает это одно место.
//
//   1. упавшая дорога БРОСАЕТ: ловится по конкретным типам (поэтому у каждого
//      запроса обязателен timeout);
//   2. дурная весть сервера НЕ бросает: читается через if из statusCode и
//      переводится из конверта через apiMessage;
//   3. тело-сюрприз (другой сервер на порту, HTML от прокси) падает при
//      разборе: FormatException от jsonDecode, TypeError от cast-ов.
// Все ветки стекаются в один Err(msg): UI, знающий только Result, ничего не
// замечает. 401 обрабатывается отдельно: токен стирается, а корень решает,
// куда идти (репозиторий роутер не импортирует).
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_message.dart';
import 'result.dart';
import 'token_store.dart';

class ApiClient {
  ApiClient(
    this.baseUrl,
    this.tokens, {
    this.onUnauthorized,
    this.timeout = const Duration(seconds: 8),
    http.Client? client,
  }) : _http = client ?? http.Client();

  final String baseUrl;
  final TokenStore tokens;
  final void Function()? onUnauthorized; // решает корень: назад на login
  final Duration timeout;
  final http.Client _http;

  /// Обычный JSON-запрос. [ok] - статусы, которые считаются успехом;
  /// [parse] получает разобранный JSON (null, если тело пустое, как у 204).
  Future<Result<T>> send<T>(
    String method,
    String path, {
    required Set<int> ok,
    required T Function(dynamic json) parse,
    Map<String, String>? query,
    Object? body,
    bool authorized = true,
  }) {
    return execute(
      () async {
        final request = http.Request(method, _uri(path, query));
        request.headers['Content-Type'] = 'application/json';
        if (body != null) request.body = jsonEncode(body);
        return request;
      },
      ok: ok,
      parse: parse,
      authorized: authorized,
    );
  }

  /// Запрос любой формы (например multipart); три слоя отказа те же.
  Future<Result<T>> execute<T>(
    Future<http.BaseRequest> Function() build, {
    required Set<int> ok,
    required T Function(dynamic json) parse,
    bool authorized = true,
    Duration? timeout,
  }) async {
    try {
      final request = await build();
      final token = authorized ? await tokens.read() : null;
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      final res = await _roundTrip(request).timeout(timeout ?? this.timeout);

      if (res.statusCode == 401 && authorized) return Err(await _sessionDied());
      if (!ok.contains(res.statusCode)) return Err(apiMessage(res)); // слой 2
      return Ok(parse(res.body.isEmpty ? null : jsonDecode(res.body)));
    } on SocketException {
      return Err('Нет сети - повторите попытку'); // слой 1
    } on http.ClientException {
      return Err('Нет сети - повторите попытку');
    } on TimeoutException {
      return Err('Сервер не отвечает');
    } on FormatException {
      return Err('Ответ не тот, что обещан'); // слой 3
    } on TypeError {
      return Err('Ответ не тот, что обещан');
    }
  }

  // Отправка и чтение тела вместе: timeout должен накрывать оба шага.
  Future<http.Response> _roundTrip(http.BaseRequest request) async =>
      http.Response.fromStream(await _http.send(request));

  Uri _uri(String path, Map<String, String>? query) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  // 401 = пропуск умер: токен выбрасывается, корень навигирует.
  Future<String> _sessionDied() async {
    await tokens.clear();
    onUnauthorized?.call();
    return 'Сессия истекла - войдите снова';
  }
}
