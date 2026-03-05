import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('nubank.db');
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
      CREATE TABLE cards (
        id TEXT PRIMARY KEY,
        cardNumber TEXT NOT NULL,
        cardHolder TEXT NOT NULL,
        expiryDate TEXT NOT NULL,
        cvv TEXT NOT NULL,
        type TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        accountNumber TEXT NOT NULL,
        holderName TEXT NOT NULL,
        balance REAL NOT NULL,
        type TEXT
      )
    ''');

    await db.insert('accounts', {
      'id': '1',
      'accountNumber': '123456789012',
      'holderName': 'John Doe',
      'balance': 5000.00,
      'type': 'checking',
    });
  }

  Future<int> saveCard(Map<String, dynamic> card) async {
    final db = await database;
    await db.delete('cards');
    return await db.insert('cards', card);
  }

  Future<Map<String, dynamic>?> getSavedCard() async {
    final db = await database;
    final maps = await db.query('cards', limit: 1);
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<int> saveTransaction(Map<String, dynamic> transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction);
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    final db = await database;
    return await db.query('transactions', orderBy: 'date DESC');
  }

  Future<Map<String, dynamic>?> getAccount() async {
    final db = await database;
    final maps = await db.query('accounts', limit: 1);
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<void> updateBalance(String id, double balance) async {
    final db = await database;
    await db.update(
      'accounts',
      {'balance': balance},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}