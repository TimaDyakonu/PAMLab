import 'package:flutter_test/flutter_test.dart';

import 'package:second_hand_market/models/session_model.dart';

import '../support/fake_data.dart';

void main() {
  test('пока не входили: пользователя нет', () {
    final session = SessionModel();

    expect(session.isSignedIn, isFalse);
    expect(session.userId, isNull);
  });

  test('signIn и signOut меняют состояние и извещают подписчиков', () {
    final session = SessionModel();
    var notified = 0;
    session.addListener(() => notified++);

    session.signIn(fakeCurrentUser);
    expect(session.isSignedIn, isTrue);
    expect(session.user.name, 'Admin');
    expect(session.userId, 'u1');

    session.signOut();
    expect(session.isSignedIn, isFalse);
    expect(notified, 2);
  });

  test('после выхода уходящий экран ещё может дорисоваться прежним пользователем',
      () {
    final session = SessionModel()..signIn(fakeCurrentUser);

    session.signOut();

    expect(session.isSignedIn, isFalse);
    expect(session.userId, isNull); // модели данных при этом пересоздаются
    expect(session.user.name, 'Admin');
  });
}
