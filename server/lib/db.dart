// SQLite setup. The database file is created automatically on first start.
//
// To add your own entity: add a CREATE TABLE below, then copy the pattern
// of lib/notes.dart for its routes.

import 'package:sqlite3/sqlite3.dart';

/// The single database connection, opened once at startup by [initDb].
late final Database db;

/// Opens (and creates, on first run) the database and its schema.
void initDb(String path) {
  db = sqlite3.open(path);
  db.execute('''
    CREATE TABLE IF NOT EXISTS users (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      email         TEXT    NOT NULL UNIQUE,
      password_hash TEXT    NOT NULL,
      name          TEXT    NOT NULL,
      created_at    TEXT    NOT NULL
    );

    CREATE TABLE IF NOT EXISTS notes (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id    INTEGER NOT NULL REFERENCES users (id),
      title      TEXT    NOT NULL,
      content    TEXT    NOT NULL DEFAULT '',
      created_at TEXT    NOT NULL
    );

    CREATE TABLE IF NOT EXISTS items (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id     INTEGER NOT NULL REFERENCES users (id),
      title       TEXT    NOT NULL,
      description TEXT    NOT NULL DEFAULT '',
      price       REAL    NOT NULL,
      size        TEXT    NOT NULL,
      condition   TEXT    NOT NULL,
      category_id TEXT    NOT NULL,
      status      TEXT    NOT NULL DEFAULT 'available',
      image_url   TEXT    NOT NULL DEFAULT '',
      created_at  TEXT    NOT NULL
    );

    CREATE TABLE IF NOT EXISTS reservations (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      item_id    INTEGER NOT NULL REFERENCES items (id),
      buyer_id   INTEGER NOT NULL REFERENCES users (id),
      status     TEXT    NOT NULL DEFAULT 'pending',
      created_at TEXT    NOT NULL
    );

    CREATE TABLE IF NOT EXISTS files (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id    INTEGER NOT NULL REFERENCES users (id),
      name       TEXT    NOT NULL,
      mime_type  TEXT    NOT NULL,
      size       INTEGER NOT NULL,
      path       TEXT    NOT NULL,
      created_at TEXT    NOT NULL
    );
  ''');
}

/// Runs [action] in one transaction: all its writes happen, or none do.
T inTransaction<T>(T Function() action) {
  db.execute('BEGIN');
  try {
    final result = action();
    db.execute('COMMIT');
    return result;
  } catch (_) {
    db.execute('ROLLBACK');
    rethrow;
  }
}

/// Current UTC time in ISO-8601, the format used for all timestamps.
String nowIso() => DateTime.now().toUtc().toIso8601String();
