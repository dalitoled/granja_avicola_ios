import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabaseService {
  static Database? _database;
  static final LocalDatabaseService instance = LocalDatabaseService._init();

  LocalDatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('granja_avicola.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pending_sync (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        collection TEXT NOT NULL,
        documentId TEXT,
        data TEXT NOT NULL,
        operation TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE cached_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        collection TEXT NOT NULL,
        documentId TEXT NOT NULL,
        userId TEXT NOT NULL,
        data TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        UNIQUE(collection, documentId)
      )
    ''');
  }

  Future<int> insertPendingSync({
    required String collection,
    String? documentId,
    required String data,
    required String operation,
  }) async {
    final db = await database;
    return await db.insert('pending_sync', {
      'collection': collection,
      'documentId': documentId,
      'data': data,
      'operation': operation,
      'createdAt': DateTime.now().toIso8601String(),
      'synced': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await database;
    return await db.query(
      'pending_sync',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'createdAt ASC',
    );
  }

  Future<void> markAsSynced(int id) async {
    final db = await database;
    await db.update(
      'pending_sync',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletePendingSyncItem(int id) async {
    final db = await database;
    await db.delete(
      'pending_sync',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getPendingSyncCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM pending_sync WHERE synced = 0',
    );
    return result.first['count'] as int;
  }

  Future<void> cacheData({
    required String collection,
    required String documentId,
    required String userId,
    required String data,
  }) async {
    final db = await database;
    await db.insert(
      'cached_data',
      {
        'collection': collection,
        'documentId': documentId,
        'userId': userId,
        'data': data,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getCachedData({
    required String collection,
    required String userId,
  }) async {
    final db = await database;
    return await db.query(
      'cached_data',
      where: 'collection = ? AND userId = ?',
      whereArgs: [collection, userId],
      orderBy: 'updatedAt DESC',
    );
  }

  Future<Map<String, dynamic>?> getCachedDocument({
    required String collection,
    required String documentId,
  }) async {
    final db = await database;
    final result = await db.query(
      'cached_data',
      where: 'collection = ? AND documentId = ?',
      whereArgs: [collection, documentId],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> clearCache() async {
    final db = await database;
    await db.delete('cached_data');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
