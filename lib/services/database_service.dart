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

        // Test data
        await db.insert('incomes', {
          'id': 1,
          'name': 'Maaş',
          'amount': 25000.0,
          'date': DateTime(2024, 1, 1).toIso8601String(),
          'isRecurring': 1,
          'recurringPeriod': 'monthly',
          'receivedPaymentsList': '1,1,1',
        });

        await db.insert('incomes', {
          'id': 2,
          'name': 'Kira Geliri',
          'amount': 8000.0,
          'date': DateTime(2024, 1, 5).toIso8601String(),
          'isRecurring': 1,
          'recurringPeriod': 'monthly',
          'receivedPaymentsList': '1,1,1',
        });

        // Örnek giderler
        final now = DateTime.now();

        await db.insert('expenses', {
          'id': 1,
          'name': 'Market Alışverişi',
          'amount': 2500.0,
          'date': DateTime(now.year, now.month, 15).toIso8601String(),
          'isInstallment': 0,
          'totalInstallments': null,
          'paidInstallments': null,
          'paidInstallmentsList': '',
        });

        await db.insert('expenses', {
          'id': 2,
          'name': 'Telefon',
          'amount': 12000.0,
          'date': DateTime(now.year, now.month, 10).toIso8601String(),
          'isInstallment': 1,
          'totalInstallments': 6,
          'paidInstallments': 2,
          'paidInstallmentsList': '1,1,0,0,0,0',
        });

        await db.insert('expenses', {
          'id': 3,
          'name': 'Elektrik Faturası',
          'amount': 750.0,
          'date': DateTime(now.year, now.month, 5).toIso8601String(),
          'isInstallment': 0,
          'totalInstallments': null,
          'paidInstallments': null,
          'paidInstallmentsList': '',
        });

        await db.insert('expenses', {
          'id': 4,
          'name': 'Araba Tamiri',
          'amount': 15000.0,
          'date': DateTime(now.year, now.month, 20).toIso8601String(),
          'isInstallment': 1,
          'totalInstallments': 3,
          'paidInstallments': 1,
          'paidInstallmentsList': '1,0,0',
        });

        await db.insert('expenses', {
          'id': 5,
          'name': 'Kira',
          'amount': 10000.0,
          'date': DateTime(now.year, now.month, 1).toIso8601String(),
          'isInstallment': 0,
          'totalInstallments': null,
          'paidInstallments': null,
          'paidInstallmentsList': '',
        });

        // Döviz örnekleri
        await db.insert('investments', {
          'id': 1,
          'category': 'currency',
          'name': 'USD',
          'amount': 1000.0,
          'buyPrice': 28.5,
          'currentPrice': 29.2,
          'date': DateTime(now.year, now.month - 1, 15).toIso8601String(),
        });

        await db.insert('investments', {
          'id': 2,
          'category': 'currency',
          'name': 'EUR',
          'amount': 500.0,
          'buyPrice': 31.2,
          'currentPrice': 31.8,
          'date': DateTime(now.year, now.month, 1).toIso8601String(),
        });

        // Emtia örnekleri
        await db.insert('investments', {
          'id': 3,
          'category': 'commodity',
          'name': 'Gold',
          'amount': 50.0,
          'buyPrice': 1200.0,
          'currentPrice': 1250.0,
          'date': DateTime(now.year, now.month - 2, 10).toIso8601String(),
        });

        await db.insert('investments', {
          'id': 4,
          'category': 'commodity',
          'name': 'Silver',
          'amount': 100.0,
          'buyPrice': 25.0,
          'currentPrice': 26.5,
          'date': DateTime(now.year, now.month, 5).toIso8601String(),
        });

        // Kripto örnekleri
        await db.insert('investments', {
          'id': 5,
          'category': 'crypto',
          'name': 'BTC',
          'amount': 0.5,
          'buyPrice': 35000.0,
          'currentPrice': 38000.0,
          'date': DateTime(now.year, now.month - 1, 20).toIso8601String(),
        });

        await db.insert('investments', {
          'id': 6,
          'category': 'crypto',
          'name': 'ETH',
          'amount': 2.0,
          'buyPrice': 2200.0,
          'currentPrice': 2300.0,
          'date': DateTime(now.year, now.month, 3).toIso8601String(),
        });
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
