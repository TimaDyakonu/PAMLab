// Items: the main entity of the theme (a clothing listing).
//
// Built from the lib/notes.dart template, with two differences that come from
// the domain: items of ALL users are visible (it is a marketplace feed), while
// changing or deleting an item is allowed only to its owner. Someone else's
// item answers 404 on PUT/DELETE, exactly like a missing one.

import 'dart:math';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';

import 'auth.dart';
import 'db.dart';
import 'errors.dart';

const _statuses = ['available', 'reserved', 'sold'];

const _select = 'SELECT i.*, u.name AS owner_name, u.email AS owner_email '
    'FROM items i JOIN users u ON u.id = i.user_id';

/// The JSON shape of an item; the seller travels together with the item.
Map<String, Object?> itemToJson(Row row) => {
      'id': row['id'],
      'title': row['title'],
      'description': row['description'],
      'price': row['price'],
      'size': row['size'],
      'condition': row['condition'],
      'categoryId': row['category_id'],
      'status': row['status'],
      'imageUrl': row['image_url'],
      'createdAt': row['created_at'],
      'owner': {
        'id': row['user_id'],
        'name': row['owner_name'],
        'email': row['owner_email'],
      },
    };

/// Finds an item by id among all items (null when there is none).
Row? findItem(int? id) {
  if (id == null) return null;
  final rows = db.select('$_select WHERE i.id = ?', [id]);
  return rows.isEmpty ? null : rows.first;
}

/// Finds an item by id, but only among the current user's own items.
Row? _findOwn(int userId, String? idParam) {
  final row = findItem(int.tryParse(idParam ?? ''));
  return row != null && row['user_id'] == userId ? row : null;
}

/// GET /items?page=1&limit=20&search=&mine=false -> {items, page, limit, total}
/// mine=true: my own items; otherwise: the feed (everybody else's items).
Future<Response> listItems(Request request) async {
  final query = request.url.queryParameters;
  final page = max(int.tryParse(query['page'] ?? '') ?? 1, 1);
  final limit = (int.tryParse(query['limit'] ?? '') ?? 20).clamp(1, 100);
  final search = query['search'] ?? '';
  final owner = query['mine'] == 'true' ? '=' : '!=';

  final where = 'i.user_id $owner ? '
      'AND (i.title LIKE ? OR i.description LIKE ?)';
  final args = [currentUserId(request), '%$search%', '%$search%'];

  final total = db
      .select('SELECT COUNT(*) AS n FROM items i WHERE $where', args)
      .first['n'] as int;
  final rows = db.select(
    '$_select WHERE $where ORDER BY i.id DESC LIMIT ? OFFSET ?',
    [...args, limit, (page - 1) * limit],
  );

  return jsonResponse({
    'items': rows.map(itemToJson).toList(),
    'page': page,
    'limit': limit,
    'total': total,
  });
}

/// POST /items  {title, description, price, size, condition, categoryId,
/// imageUrl?} -> 201 item
Future<Response> createItem(Request request) async {
  final body = await readJsonBody(request);
  if (body == null) return validationError('Body must be a JSON object');
  final problem = _validate(body);
  if (problem != null) return validationError(problem);

  db.execute(
    'INSERT INTO items (user_id, title, description, price, size, condition, '
    'category_id, status, image_url, created_at) '
    "VALUES (?, ?, ?, ?, ?, ?, ?, 'available', ?, ?)",
    [
      currentUserId(request),
      stringField(body, 'title'),
      _description(body),
      (body['price'] as num).toDouble(),
      stringField(body, 'size'),
      stringField(body, 'condition'),
      stringField(body, 'categoryId'),
      _imageUrl(body),
      nowIso(),
    ],
  );
  return jsonResponse(itemToJson(findItem(db.lastInsertRowId)!), status: 201);
}

/// GET /items/{id} -> 200 item | 404
Future<Response> getItem(Request request) async {
  final row = findItem(int.tryParse(request.params['id'] ?? ''));
  if (row == null) return notFound('Item not found');
  return jsonResponse(itemToJson(row));
}

/// PUT /items/{id}  (same body as POST, status optional) -> 200 item | 404
Future<Response> updateItem(Request request) async {
  final row = _findOwn(currentUserId(request), request.params['id']);
  if (row == null) return notFound('Item not found');

  final body = await readJsonBody(request);
  if (body == null) return validationError('Body must be a JSON object');
  final problem = _validate(body);
  if (problem != null) return validationError(problem);
  final status = body['status'] is String ? body['status'] : row['status'];
  if (!_statuses.contains(status)) {
    return validationError('status must be one of $_statuses');
  }

  db.execute(
    'UPDATE items SET title = ?, description = ?, price = ?, size = ?, '
    'condition = ?, category_id = ?, status = ?, image_url = ? WHERE id = ?',
    [
      stringField(body, 'title'),
      _description(body),
      (body['price'] as num).toDouble(),
      stringField(body, 'size'),
      stringField(body, 'condition'),
      stringField(body, 'categoryId'),
      status,
      _imageUrl(body),
      row['id'],
    ],
  );
  return jsonResponse(itemToJson(findItem(row['id'] as int)!));
}

/// DELETE /items/{id} -> 204 | 404 (also removes the reservations of the item)
Future<Response> deleteItem(Request request) async {
  final row = _findOwn(currentUserId(request), request.params['id']);
  if (row == null) return notFound('Item not found');

  inTransaction(() {
    db.execute('DELETE FROM reservations WHERE item_id = ?', [row['id']]);
    db.execute('DELETE FROM items WHERE id = ?', [row['id']]);
  });
  return Response(204);
}

/// Returns a text describing the first problem in [body], or null when valid.
String? _validate(Map<String, dynamic> body) {
  final title = stringField(body, 'title');
  if (title == null || title.length < 3) {
    return 'title is required (at least 3 characters)';
  }
  final price = body['price'];
  if (price is! num || price <= 0 || price > 100000) {
    return 'price must be a number from 0 (exclusive) to 100000';
  }
  for (final field in ['size', 'condition', 'categoryId']) {
    if (stringField(body, field) == null) return '$field is required';
  }
  return null;
}

String _description(Map<String, dynamic> body) =>
    body['description'] is String ? (body['description'] as String).trim() : '';

/// Only links to our own uploads (/files/{id}) are accepted, or an empty one.
String _imageUrl(Map<String, dynamic> body) {
  final url = body['imageUrl'];
  return url is String && RegExp(r'^/files/\d+$').hasMatch(url) ? url : '';
}
