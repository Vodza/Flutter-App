import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/expense_transaction.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(docsDir.path, 'ocr_expense_tracker.db');

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            merchant TEXT NOT NULL,
            amount REAL NOT NULL,
            date TEXT NOT NULL,
            category TEXT NOT NULL,
            receiptImagePath TEXT,
            rawOcrText TEXT
          )
        ''');

        // Tạo một số dữ liệu mẫu ban đầu để giao diện biểu đồ hiển thị đẹp ngay lập tức
        final now = DateTime.now();
        await db.insert('transactions', {
          'merchant': 'Highlands Coffee',
          'amount': 59000.0,
          'date': now.subtract(const Duration(days: 0)).toIso8601String(),
          'category': 'food',
          'receiptImagePath': null,
          'rawOcrText': 'HIGHLANDS COFFEE\nFreeze Tra Xanh 59.000d\nTong tien: 59.000 VND',
        });
        await db.insert('transactions', {
          'merchant': 'Nhà Sách Fahasa',
          'amount': 145000.0,
          'date': now.subtract(const Duration(days: 1)).toIso8601String(),
          'category': 'study',
          'receiptImagePath': null,
          'rawOcrText': 'FAHASA DA NANG\nGiao trinh Flutter\nTong cong: 145,000 VND',
        });
        await db.insert('transactions', {
          'merchant': 'Cây Xăng Petrolimex',
          'amount': 80000.0,
          'date': now.subtract(const Duration(days: 2)).toIso8601String(),
          'category': 'travel',
          'receiptImagePath': null,
          'rawOcrText': 'PETROLIMEX\nXang RON 95-III\nThanh toan: 80.000 d',
        });
        await db.insert('transactions', {
          'merchant': 'Circle K',
          'amount': 32000.0,
          'date': now.subtract(const Duration(days: 3)).toIso8601String(),
          'category': 'food',
          'receiptImagePath': null,
          'rawOcrText': 'CIRCLE K VIETNAM\nBanh mi + Nuoc suoi\nTong: 32.000 VND',
        });
        await db.insert('transactions', {
          'merchant': 'CGV Cinema',
          'amount': 120000.0,
          'date': now.subtract(const Duration(days: 4)).toIso8601String(),
          'category': 'entertainment',
          'receiptImagePath': null,
          'rawOcrText': 'CGV CINEMAS\nVe xem phim 2D\nThanh tien: 120.000 VND',
        });
      },
    );
  }

  // --- CRUD Giao dịch ---
  Future<int> insertTransaction(ExpenseTransaction tx) async {
    final db = await database;
    return await db.insert('transactions', tx.toMap());
  }

  Future<List<ExpenseTransaction>> getAllTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'date DESC, id DESC',
    );
    return maps.map((m) => ExpenseTransaction.fromMap(m)).toList();
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // --- Thống kê & Phân tích cho Biểu đồ CustomPainter ---

  /// Tính tổng chi tiêu
  Future<double> getTotalSpending() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(amount) as total FROM transactions');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Phân bổ chi tiêu theo từng danh mục (Dùng cho Donut/Pie Chart)
  Future<Map<ExpenseCategory, double>> getCategoryDistribution() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT category, SUM(amount) as cat_total 
      FROM transactions 
      GROUP BY category
    ''');

    final Map<ExpenseCategory, double> distribution = {};
    for (var row in result) {
      final cat = ExpenseCategory.fromString(row['category'] as String);
      final sum = (row['cat_total'] as num?)?.toDouble() ?? 0.0;
      distribution[cat] = sum;
    }
    return distribution;
  }

  /// Thống kê chi tiêu 7 ngày gần nhất (Dùng cho Weekly Bar Chart)
  Future<List<double>> getWeeklySpending() async {
    final db = await database;
    final now = DateTime.now();
    final List<double> weekly = List.filled(7, 0.0);

    // Tính chi tiêu cho 7 ngày qua (từ 6 ngày trước đến hôm nay)
    for (int i = 0; i < 7; i++) {
      final targetDate = now.subtract(Duration(days: 6 - i));
      final dateStr = "${targetDate.year.toString().padLeft(4, '0')}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";

      final res = await db.rawQuery('''
        SELECT SUM(amount) as day_total 
        FROM transactions 
        WHERE date LIKE ?
      ''', ['$dateStr%']);

      weekly[i] = (res.first['day_total'] as num?)?.toDouble() ?? 0.0;
    }
    return weekly;
  }

  /// Lưu ảnh hóa đơn lâu dài vào Application Documents Directory
  Future<String> saveReceiptImagePermanently(String sourcePath) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory(join(docsDir.path, 'receipts'));
      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }

      final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final targetPath = join(receiptsDir.path, fileName);
      final savedFile = await File(sourcePath).copy(targetPath);
      return savedFile.path;
    } catch (e) {
      return sourcePath;
    }
  }
}
