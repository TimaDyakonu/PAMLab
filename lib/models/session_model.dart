// models/session_model.dart: кто сейчас вошёл. Разделяемое состояние: его читают
// почти все экраны (лента отделяет чужие вещи от моих, профиль показывает имя).
// Сам токен лежит не здесь, а в TokenStore: модель знает только пользователя.
import 'package:flutter/foundation.dart';
import '../data/user.dart';

class SessionModel extends ChangeNotifier {
  User? _user;
  User? _lastUser;

  bool get isSignedIn => _user != null;

  /// id вошедшего пользователя; модели данных привязываются к нему.
  String? get userId => _user?.id;

  /// Только внутри экранов, доступных после входа. Навигация на login
  /// применяется асинхронно, а signOut() извещает сразу, поэтому экран, который
  /// ещё не успел уйти со сцены, дорисовывается прежним пользователем.
  User get user => _user ?? _lastUser!;

  void signIn(User user) {
    _user = user;
    notifyListeners();
  }

  void signOut() {
    _lastUser = _user ?? _lastUser;
    _user = null;
    notifyListeners();
  }
}
