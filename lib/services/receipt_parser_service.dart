import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/expense_transaction.dart';

class ParsedReceiptResult {
  final double amount;
  final DateTime date;
  final String merchant;
  final ExpenseCategory suggestedCategory;
  final String rawText;

  ParsedReceiptResult({
    required this.amount,
    required this.date,
    required this.merchant,
    required this.suggestedCategory,
    required this.rawText,
  });
}

class ReceiptParserService {
  static final ReceiptParserService _instance = ReceiptParserService._internal();
  factory ReceiptParserService() => _instance;
  ReceiptParserService._internal();

  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  /// Trích xuất văn bản từ ảnh và phân tích heuristics
  Future<ParsedReceiptResult> parseReceipt(String imagePath) async {
    final file = File(imagePath);
    if (!file.existsSync()) {
      throw Exception('Không tìm thấy tệp ảnh hóa đơn: $imagePath');
    }

    final inputImage = InputImage.fromFilePath(imagePath);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    final String fullText = recognizedText.text;

    // 1. Heuristic trích xuất Tổng tiền
    final double extractedAmount = _extractTotalAmount(recognizedText);

    // 2. Heuristic trích xuất Ngày giao dịch
    final DateTime extractedDate = _extractDate(fullText);

    // 3. Heuristic trích xuất Tên cửa hàng
    final String extractedMerchant = _extractMerchant(recognizedText);

    // 4. Heuristic gợi ý danh mục chi tiêu
    final ExpenseCategory category = _inferCategory(extractedMerchant, fullText);

    return ParsedReceiptResult(
      amount: extractedAmount,
      date: extractedDate,
      merchant: extractedMerchant,
      suggestedCategory: category,
      rawText: fullText,
    );
  }

  /// 1. Bóc tách số tiền (Heuristic 2-pass: ưu tiên dòng chứa từ khóa tổng tiền)
  double _extractTotalAmount(RecognizedText recognized) {
    final totalKeywords = [
      'tổng cộng',
      'tong cong',
      'tổng tiền',
      'tong tien',
      'thành tiền',
      'thanh tien',
      'thanh toán',
      'thanh toan',
      'total',
      'amount',
      'tiền mặt',
      'tien mat',
      'grand total'
    ];

    // Pass 1: Tìm dòng văn bản chứa từ khóa tổng tiền và số tiền đi liền sau
    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        final lineLower = line.text.toLowerCase();
        for (final keyword in totalKeywords) {
          if (lineLower.contains(keyword)) {
            final numbers = _extractNumbersFromString(line.text);
            if (numbers.isNotEmpty) {
              final candidate = numbers.reduce((a, b) => a > b ? a : b);
              if (candidate >= 1000) return candidate;
            }
          }
        }
      }
    }

    // Pass 2: Fallback tìm tất cả các số có định dạng tiền tệ hợp lệ trong toàn bộ văn bản
    final allNumbers = _extractNumbersFromString(recognized.text);
    if (allNumbers.isNotEmpty) {
      // Lấy số lớn nhất có giá trị tiền tệ hợp lệ (> 1,000 VND và < 1,000,000,000 VND)
      final validAmounts = allNumbers.where((n) => n >= 1000 && n <= 1000000000).toList();
      if (validAmounts.isNotEmpty) {
        return validAmounts.reduce((a, b) => a > b ? a : b);
      }
    }

    return 0.0;
  }

  List<double> _extractNumbersFromString(String text) {
    final List<double> results = [];
    // Hỗ trợ định dạng: 150.000, 150,000, 150000 hoặc kèm đ, VND
    final regex = RegExp(
      r'(?:^|[^\d])(\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{1,2})?|\d{4,9})(?:\s*(?:vnd|đ|dong))?',
      caseSensitive: false,
    );

    final matches = regex.allMatches(text);
    for (final match in matches) {
      final rawStr = match.group(1);
      if (rawStr != null) {
        // Loại bỏ dấu phân cách hàng nghìn . hoặc ,
        String cleanStr = rawStr.replaceAll(RegExp(r'[,.]'), '');
        final val = double.tryParse(cleanStr);
        if (val != null) {
          results.add(val);
        }
      }
    }
    return results;
  }

  /// 2. Bóc tách Ngày tháng (DD/MM/YYYY, DD-MM-YYYY, YYYY-MM-DD...)
  DateTime _extractDate(String text) {
    // DD/MM/YYYY hoặc DD-MM-YYYY
    final dmyRegex = RegExp(r'(\b\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})\b');
    final matchDMY = dmyRegex.firstMatch(text);
    if (matchDMY != null) {
      try {
        final day = int.parse(matchDMY.group(1)!);
        final month = int.parse(matchDMY.group(2)!);
        final year = int.parse(matchDMY.group(3)!);
        if (day >= 1 && day <= 31 && month >= 1 && month <= 12 && year >= 2000 && year <= 2035) {
          return DateTime(year, month, day);
        }
      } catch (_) {}
    }

    // YYYY/MM/DD hoặc YYYY-MM-DD
    final ymdRegex = RegExp(r'(\b\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})\b');
    final matchYMD = ymdRegex.firstMatch(text);
    if (matchYMD != null) {
      try {
        final year = int.parse(matchYMD.group(1)!);
        final month = int.parse(matchYMD.group(2)!);
        final day = int.parse(matchYMD.group(3)!);
        if (day >= 1 && day <= 31 && month >= 1 && month <= 12 && year >= 2000 && year <= 2035) {
          return DateTime(year, month, day);
        }
      } catch (_) {}
    }

    return DateTime.now();
  }

  /// 3. Bóc tách Tên cửa hàng (Merchant Name)
  String _extractMerchant(RecognizedText recognized) {
    if (recognized.blocks.isEmpty) return 'Hóa đơn mua sắm';

    // Cửa hàng thường nằm ở 1-3 khối đầu tiên của hóa đơn
    for (final block in recognized.blocks.take(4)) {
      for (final line in block.lines) {
        final trimmed = line.text.trim();
        // Bỏ qua dòng chỉ có số điện thoại, ngày giờ hoặc quá ngắn
        if (trimmed.length >= 3 &&
            !RegExp(r'^\d+$').hasMatch(trimmed) &&
            !trimmed.toLowerCase().contains('hóa đơn') &&
            !trimmed.toLowerCase().contains('phiếu thu') &&
            !trimmed.toLowerCase().contains('receipt') &&
            !trimmed.toLowerCase().contains('bill')) {
          return trimmed;
        }
      }
    }

    return 'Cửa hàng không xác định';
  }

  /// 4. Suy luận danh mục chi tiêu tự động
  ExpenseCategory _inferCategory(String merchant, String fullText) {
    final textCombined = '$merchant $fullText'.toLowerCase();

    // Ăn uống (Food)
    if (textCombined.contains('kfc') ||
        textCombined.contains('highlands') ||
        textCombined.contains('starbucks') ||
        textCombined.contains('circle k') ||
        textCombined.contains('co.op') ||
        textCombined.contains('winmart') ||
        textCombined.contains('bách hóa') ||
        textCombined.contains('quán ăn') ||
        textCombined.contains('cà phê') ||
        textCombined.contains('coffee') ||
        textCombined.contains('trà sữa') ||
        textCombined.contains('phở') ||
        textCombined.contains('cơm')) {
      return ExpenseCategory.food;
    }

    // Học tập (Study)
    if (textCombined.contains('fahasa') ||
        textCombined.contains('nhà sách') ||
        textCombined.contains('phương nam') ||
        textCombined.contains('tiệm photo') ||
        textCombined.contains('in ấn') ||
        textCombined.contains('giáo trình') ||
        textCombined.contains('bút') ||
        textCombined.contains('văn phòng phẩm')) {
      return ExpenseCategory.study;
    }

    // Đi lại (Travel)
    if (textCombined.contains('grab') ||
        textCombined.contains('be') ||
        textCombined.contains('xanh sm') ||
        textCombined.contains('petrolimex') ||
        textCombined.contains('cây xăng') ||
        textCombined.contains('xăng dầu') ||
        textCombined.contains('vé xe') ||
        textCombined.contains('gửi xe')) {
      return ExpenseCategory.travel;
    }

    // Thiết bị (Gear)
    if (textCombined.contains('phong vũ') ||
        textCombined.contains('gearvn') ||
        textCombined.contains('fpt') ||
        textCombined.contains('thế giới di động') ||
        textCombined.contains('điện máy') ||
        textCombined.contains('cellphones') ||
        textCombined.contains('chuột') ||
        textCombined.contains('bàn phím') ||
        textCombined.contains('laptop')) {
      return ExpenseCategory.gear;
    }

    // Giải trí (Entertainment)
    if (textCombined.contains('cgv') ||
        textCombined.contains('lotte') ||
        textCombined.contains('galaxy') ||
        textCombined.contains('rạp chiếu') ||
        textCombined.contains('bida') ||
        textCombined.contains('karaoke') ||
        textCombined.contains('game') ||
        textCombined.contains('netflix')) {
      return ExpenseCategory.entertainment;
    }

    return ExpenseCategory.food;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
