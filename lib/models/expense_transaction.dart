import 'package:flutter/material.dart';

enum ExpenseCategory {
  food('Ăn uống', 'Food', Icons.restaurant, Color(0xFFFF6B6B)),
  study('Học tập', 'Study', Icons.school, Color(0xFF4D96FF)),
  travel('Đi lại', 'Travel', Icons.directions_bus, Color(0xFFFFD93D)),
  gear('Thiết bị', 'Gear', Icons.devices, Color(0xFF6BCB77)),
  entertainment('Giải trí', 'Entertainment', Icons.sports_esports, Color(0xFF9D4EDD)),
  other('Khác', 'Other', Icons.category, Color(0xFF8D99AE));

  final String vietnameseName;
  final String englishName;
  final IconData icon;
  final Color color;

  const ExpenseCategory(this.vietnameseName, this.englishName, this.icon, this.color);

  static ExpenseCategory fromString(String name) {
    for (var cat in ExpenseCategory.values) {
      if (cat.name.toLowerCase() == name.toLowerCase() ||
          cat.englishName.toLowerCase() == name.toLowerCase() ||
          cat.vietnameseName.toLowerCase() == name.toLowerCase()) {
        return cat;
      }
    }
    return ExpenseCategory.other;
  }
}

class ExpenseTransaction {
  final int? id;
  final String merchant;
  final double amount;
  final DateTime date;
  final ExpenseCategory category;
  final String? receiptImagePath;
  final String? rawOcrText;

  ExpenseTransaction({
    this.id,
    required this.merchant,
    required this.amount,
    required this.date,
    required this.category,
    this.receiptImagePath,
    this.rawOcrText,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchant': merchant,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category.name,
      'receiptImagePath': receiptImagePath,
      'rawOcrText': rawOcrText,
    };
  }

  factory ExpenseTransaction.fromMap(Map<String, dynamic> map) {
    return ExpenseTransaction(
      id: map['id'] as int?,
      merchant: map['merchant'] as String? ?? 'Không xác định',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] != null
          ? DateTime.tryParse(map['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      category: ExpenseCategory.fromString(map['category'] as String? ?? 'other'),
      receiptImagePath: map['receiptImagePath'] as String?,
      rawOcrText: map['rawOcrText'] as String?,
    );
  }

  ExpenseTransaction copyWith({
    int? id,
    String? merchant,
    double? amount,
    DateTime? date,
    ExpenseCategory? category,
    String? receiptImagePath,
    String? rawOcrText,
  }) {
    return ExpenseTransaction(
      id: id ?? this.id,
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      rawOcrText: rawOcrText ?? this.rawOcrText,
    );
  }
}
