// Reservations: the second entity of the theme. A reservation links a buyer
// with an item and changes the status of the item together with itself, in one
// transaction (this is what the client could not do atomically in L4).

import 'dart:math';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';

import 'auth.dart';
import 'db.dart';
import 'errors.dart';
import 'items.dart';

/// The JSON shape of a reservation; the reserved item is embedded.
Map<String, Object?> _toJson(Row row) => {
      'id': row['id'],
      'itemId': row['item_id'],
      'status': row['status'],
      'createdAt': row['created_at'],
      'item': itemToJson(findItem(row['item_id'] as int)!),
    };

/// Finds a reservation by id, but only among the current user's reservations.
Row? _find(int userId, String? idParam) {
  final id = int.tryParse(idParam ?? '');
  if (id == null) return null;
  final rows = db.select(
    'SELECT * FROM reservations WHERE id = ? AND buyer_id = ?',
    [id, userId],
  );
  return rows.isEmpty ? null : rows.first;
}

/// GET /reservations?page=1&limit=20 -> {items, page, limit, total}
Future<Response> listReservations(Request request) async {
  final query = request.url.queryParameters;
  final page = max(int.tryParse(query['page'] ?? '') ?? 1, 1);
  final limit = (int.tryParse(query['limit'] ?? '') ?? 20).clamp(1, 100);
  final me = currentUserId(request);

  final total = db
      .select('SELECT COUNT(*) AS n FROM reservations WHERE buyer_id = ?', [me])
      .first['n'] as int;
  final rows = db.select(
    'SELECT * FROM reservations WHERE buyer_id = ? '
    'ORDER BY id DESC LIMIT ? OFFSET ?',
    [me, limit, (page - 1) * limit],
  );

  return jsonResponse({
    'items': rows.map(_toJson).toList(),
    'page': page,
    'limit': limit,
    'total': total,
  });
}

/// POST /reservations  {itemId} -> 201 reservation | 404 | 409 ITEM_UNAVAILABLE
Future<Response> createReservation(Request request) async {
  final body = await readJsonBody(request);
  if (body == null) return validationError('Body must be a JSON object');
  final raw = body['itemId'];
  final itemId = raw is int ? raw : int.tryParse('$raw');
  if (itemId == null) return validationError('itemId is required');

  final item = findItem(itemId);
  if (item == null) return notFound('Item not found');
  final me = currentUserId(request);
  if (item['user_id'] == me) {
    return validationError('You cannot reserve your own item');
  }
  if (item['status'] != 'available') {
    return apiError(409, 'ITEM_UNAVAILABLE', 'The item is not available');
  }

  final id = inTransaction(() {
    db.execute(
      'INSERT INTO reservations (item_id, buyer_id, status, created_at) '
      "VALUES (?, ?, 'pending', ?)",
      [itemId, me, nowIso()],
    );
    final created = db.lastInsertRowId;
    db.execute("UPDATE items SET status = 'reserved' WHERE id = ?", [itemId]);
    return created;
  });
  return jsonResponse(_toJson(_find(me, '$id')!), status: 201);
}

/// PUT /reservations/{id}  {status: "cancelled"} -> 200 reservation | 404
/// Only the buyer can cancel, and only while the reservation is still active.
Future<Response> updateReservation(Request request) async {
  final me = currentUserId(request);
  final row = _find(me, request.params['id']);
  if (row == null) return notFound('Reservation not found');

  final body = await readJsonBody(request);
  if (body == null) return validationError('Body must be a JSON object');
  if (body['status'] != 'cancelled') {
    return validationError("status can only be changed to 'cancelled'");
  }
  if (row['status'] != 'pending' && row['status'] != 'confirmed') {
    return validationError('The reservation is already closed');
  }

  inTransaction(() {
    db.execute(
      "UPDATE reservations SET status = 'cancelled' WHERE id = ?",
      [row['id']],
    );
    db.execute(
      "UPDATE items SET status = 'available' "
      "WHERE id = ? AND status = 'reserved'",
      [row['item_id']],
    );
  });
  return jsonResponse(_toJson(_find(me, '${row['id']}')!));
}
