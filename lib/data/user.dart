// data/user.dart — сущность «пользователь».
class User {
  final String id;
  final String name;
  final String email;
  final String avatarUrl; // пусто — вместо фото аватар с инициалами

  const User(this.id, this.name, this.email, [this.avatarUrl = '']);
}
