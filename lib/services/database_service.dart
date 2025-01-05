import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/income.dart';
import '../models/expense.dart';
import '../models/investment.dart';

class AppDbService {
  static final AppDbService _instance = AppDbService._internal();
  Database? _database;
  // ignore: constant_identifier_names
  static const String DB_NAME = 'wallet_track.db';

  factory AppDbService() => _instance;

  AppDbService._internal();

  Future<void> resetDatabase() async {
    String path = join(await getDatabasesPath(), DB_NAME);
    await deleteDatabase(path);
    _database = null;
  }

  Future<Database> get database async {
    if (_database == null || !_database!.isOpen) {
      _database = await _initDatabase();
    }
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, DB_NAME);

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE expenses(
            id INTEGER PRIMARY KEY,
            name TEXT,
            amount REAL,
            date TEXT,
            isInstallment INTEGER,
            totalInstallments INTEGER,
            paidInstallments INTEGER,
            paidInstallmentsList TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE incomes(
            id INTEGER PRIMARY KEY,
            name TEXT,
            amount REAL,
            date TEXT,
            isRecurring INTEGER,
            recurringPeriod TEXT,
            receivedPaymentsList TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE investments(
            id INTEGER PRIMARY KEY,
            category TEXT,
            name TEXT,
            amount REAL,
            buyPrice REAL,
            currentPrice REAL,
            date TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertExpense(Expense expense) async {
    final db = await database;
    await db.insert('expenses', expense.toMap());
  }

  Future<List<Expense>> getExpenses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('expenses');

    return List.generate(maps.length, (i) {
      return Expense(
        id: maps[i]['id'],
        name: maps[i]['name'],
        amount: maps[i]['amount'],
        date: DateTime.parse(maps[i]['date']),
        isInstallment: maps[i]['isInstallment'] == 1,
        totalInstallments: maps[i]['totalInstallments'],
        paidInstallments: maps[i]['paidInstallments'],
      );
    });
  }

  Future<void> updateExpense(Expense expense) async {
    final db = await database;
    await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<void> deleteExpense(int id) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertIncome(Income income) async {
    final db = await database;
    await db.insert(
      'incomes',
      income.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Income>> getIncomes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('incomes');
    return List.generate(maps.length, (i) {
      return Income.fromMap(maps[i]);
    });
  }

  Future<void> deleteIncome(int id) async {
    final db = await database;
    await db.delete('incomes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateIncome(Income income) async {
    final db = await database;
    await db.update(
      'incomes',
      income.toMap(),
      where: 'id = ?',
      whereArgs: [income.id],
    );
  }

  Future<void> insertInvestment(Investment investment) async {
    final db = await database;
    await db.insert('investments', investment.toMap());
  }

  Future<List<Investment>> getInvestments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('investments');
    return List.generate(maps.length, (i) => Investment.fromMap(maps[i]));
  }

  Future<void> updateInvestment(Investment investment) async {
    final db = await database;
    await db.update(
      'investments',
      investment.toMap(),
      where: 'id = ?',
      whereArgs: [investment.id],
    );
  }

  Future<void> deleteInvestment(int id) async {
    final db = await database;
    await db.delete(
      'investments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
