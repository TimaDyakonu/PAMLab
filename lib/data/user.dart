// data/user.dart — сущность «пользователь».
class User {
  final String id;
  final String name;
  final String email;
  final String avatarUrl; // пусто — вместо фото аватар с инициалами

  const User(this.id, this.name, this.email, [this.avatarUrl = '']);

  /// Граница JSON: id приходит от сервера числом, внутри приложения он строка.
  factory User.fromJson(Map<String, dynamic> json) => User(
        '${json['id']}',
        json['name'] as String,
        json['email'] as String,
      );
}
