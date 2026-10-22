// data/file_api.dart: загрузка файла на POST /files (multipart, поле file).
import 'package:http/http.dart' as http;
import 'api_client.dart';
import 'result.dart';

class FileApi {
  FileApi(this._api, this._baseUrl);

  final ApiClient _api;
  final String _baseUrl;

  /// Возвращает ОТНОСИТЕЛЬНЫЙ путь, например «/files/7»: он сохраняется в
  /// сущности темы, а показ это Image.network(baseUrl + путь).
  Future<Result<String>> upload(String path) {
    return _api.execute(
      () async {
        final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/files'));
        request.files.add(await http.MultipartFile.fromPath('file', path));
        return request;
      },
      ok: {201},
      timeout: const Duration(seconds: 20), // timeout НА send: файл мог зависнуть
      parse: (json) => (json as Map<String, dynamic>)['url'] as String,
    );
  }
}
