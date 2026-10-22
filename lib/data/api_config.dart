// data/api_config.dart: адрес сервера для тех, кому нужен полный URL
// (например, для показа загруженных фотографий через Image.network).
class ApiConfig {
  final String baseUrl;

  const ApiConfig(this.baseUrl);

  /// «/files/7» -> «http://10.0.2.2:8765/files/7»
  String url(String path) => '$baseUrl$path';
}
