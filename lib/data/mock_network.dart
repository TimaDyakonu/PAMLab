// data/mock_network.dart — «канал связи» mock-а: задержка и аварийный
// переключатель. Один объект на оба mock-репозитория, поэтому одна авария
// валит обращения ко всем хранилищам — как настоящая сеть. Умирает на L5.
class MockNetwork {
  MockNetwork({this.latency = const Duration(milliseconds: 800)});

  /// Сеть не отвечает мгновенно: без задержки состояния «грузится» не
  /// существует, и его нельзя ни увидеть, ни продемонстрировать.
  final Duration latency;

  /// Авария включена → любой вызов любого репозитория проваливается.
  bool simulateError = false;

  static const errMessage = 'Сервер не отвечает — повторите попытку';

  Future<void> delay() => Future.delayed(latency);
}
