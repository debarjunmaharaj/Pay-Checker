import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/payment_transaction.dart';
import '../models/app_log.dart';

class OfflineQueueService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pay_checker.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id TEXT PRIMARY KEY,
            trx_id TEXT UNIQUE,
            provider TEXT,
            amount REAL,
            sender TEXT,
            raw_sms TEXT,
            status TEXT,
            order_id TEXT,
            customer_name TEXT,
            received_at TEXT,
            processed_at TEXT,
            failure_reason TEXT,
            is_synced INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE logs (
            id TEXT PRIMARY KEY,
            type TEXT,
            title TEXT,
            message TEXT,
            details TEXT,
            timestamp TEXT
          )
        ''');
      },
    );
  }

  Future<void> saveTransaction(PaymentTransaction transaction) async {
    final db = await database;
    await db.insert(
      'transactions',
      transaction.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<PaymentTransaction>> getUnsyncedTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'is_synced = ?',
      whereArgs: [0],
      orderBy: 'received_at ASC',
    );
    return maps.map((e) => PaymentTransaction.fromJson(e)).toList();
  }

  Future<List<PaymentTransaction>> getAllTransactions({int limit = 100}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'received_at DESC',
      limit: limit,
    );
    return maps.map((e) => PaymentTransaction.fromJson(e)).toList();
  }

  Future<void> markAsSynced(String trxId) async {
    final db = await database;
    await db.update(
      'transactions',
      {'is_synced': 1},
      where: 'trx_id = ?',
      whereArgs: [trxId],
    );
  }

  Future<void> saveLog(AppLog log) async {
    final db = await database;
    await db.insert(
      'logs',
      log.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<AppLog>> getLogs({int limit = 100}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'logs',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return maps.map((e) => AppLog.fromJson(e)).toList();
  }

  Future<void> clearLogs() async {
    final db = await database;
    await db.delete('logs');
  }
}
