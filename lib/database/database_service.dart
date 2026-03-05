import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/payment_card.dart';

class DatabaseService {
  static Database? _db;
  static const String _tableName = 'payment_cards';

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'payment.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            number TEXT,
            expiry TEXT,
            cvv TEXT,
            holder TEXT
          )
        ''');
      },
    );
  }

  Future<void> savePaymentCard(PaymentCard card) async {
    final db = await database;
    await db.delete(_tableName);
    await db.insert(_tableName, card.toMap());
  }

  Future<PaymentCard?> getLastPaymentCard() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(_tableName, orderBy: 'id DESC', limit: 1);
    if (result.isEmpty) return null;
    return PaymentCard.fromMap(result.first);
  }
}