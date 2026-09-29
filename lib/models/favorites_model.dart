// models/favorites_model.dart — разделяемое состояние: избранные вещи.
// Читают три экрана (значок в ленте, карточка вещи, профиль), поэтому
// состояние живёт в модели, а не в setState. Чистый Dart, без widget-ов.
import 'package:flutter/foundation.dart';

class FavoritesModel extends ChangeNotifier {
  final Set<String> _ids = {};

  Set<String> get ids => Set.unmodifiable(_ids);
  int get count => _ids.length;

  bool isFavorite(String itemId) => _ids.contains(itemId);

  void toggle(String itemId) {
    if (!_ids.remove(itemId)) _ids.add(itemId);
    notifyListeners(); // весь уходит ко ВСЕМ подписчикам
  }
}
