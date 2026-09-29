// data/result.dart — вердикт: значение или сообщение для экрана.
// Ожидаемый отказ (нет сети, вещи не существует) — это значение, а не
// исключение, путешествующее через UI.
sealed class Result<T> {
  const Result();
}

class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

class Err<T> extends Result<T> {
  const Err(this.msg);
  final String msg;
}
