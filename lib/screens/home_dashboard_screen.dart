import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense_transaction.dart';
import '../services/database_helper.dart';
import '../widgets/donut_pie_chart.dart';
import '../widgets/weekly_bar_chart.dart';
import '../widgets/transaction_tile.dart';
import 'camera_capture_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  List<ExpenseTransaction> _transactions = [];
  double _totalSpending = 0.0;
  Map<ExpenseCategory, double> _categoryDistribution = {};
  List<double> _weeklySpending = List.filled(7, 0.0);
  bool _isLoading = true;
  int _activeChartIndex = 0; // 0: Donut Chart, 1: Bar Chart
  ExpenseCategory? _filterCategory;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final db = DatabaseHelper.instance;
    final txs = await db.getAllTransactions();
    final total = await db.getTotalSpending();
    final catDist = await db.getCategoryDistribution();
    final weekly = await db.getWeeklySpending();

    if (mounted) {
      setState(() {
        _transactions = txs;
        _totalSpending = total;
        _categoryDistribution = catDist;
        _weeklySpending = weekly;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTx(int id) async {
    await DatabaseHelper.instance.deleteTransaction(id);
    _loadDashboardData();
  }

  void _showTransactionDetails(ExpenseTransaction tx) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: tx.category.color.withValues(alpha: 0.15),
                    child: Icon(tx.category.icon, color: tx.category.color, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.merchant,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          tx.category.vietnameseName,
                          style: TextStyle(color: tx.category.color, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '-${currencyFormatter.format(tx.amount)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Thời gian: ${dateFormatter.format(tx.date)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              if (tx.receiptImagePath != null) ...[
                const SizedBox(height: 16),
                const Text('Ảnh chụp hóa đơn:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(tx.receiptImagePath!),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    final filteredList = _filterCategory == null
        ? _transactions
        : _transactions.where((t) => t.category == _filterCategory).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Quản lý chi tiêu OCR'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                children: [
                  // 1. Thẻ Tổng quan số dư chi tiêu
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tổng chi tiêu tháng này',
                              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'On-Device AI',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          currencyFormatter.format(_totalSpending),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.receipt_long, color: Colors.white70, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '${_transactions.length} hóa đơn đã ghi nhận',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Chuyển đổi tab Biểu đồ CustomPainter
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _activeChartIndex = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _activeChartIndex == 0 ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _activeChartIndex == 0
                                    ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  'Tỷ lệ danh mục (Donut)',
                                  style: TextStyle(
                                    fontWeight: _activeChartIndex == 0 ? FontWeight.bold : FontWeight.w500,
                                    color: _activeChartIndex == 0 ? const Color(0xFF0F172A) : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _activeChartIndex = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _activeChartIndex == 1 ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _activeChartIndex == 1
                                    ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  'Theo tuần (Bar Chart)',
                                  style: TextStyle(
                                    fontWeight: _activeChartIndex == 1 ? FontWeight.bold : FontWeight.w500,
                                    color: _activeChartIndex == 1 ? const Color(0xFF0F172A) : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Biểu đồ Canvas tương ứng
                  if (_activeChartIndex == 0)
                    DonutPieChart(
                      data: _categoryDistribution,
                      totalAmount: _totalSpending,
                    )
                  else
                    WeeklyBarChart(
                      weeklyAmounts: _weeklySpending,
                    ),

                  const SizedBox(height: 24),

                  // 4. Bộ lọc danh mục
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('Tất cả'),
                          selected: _filterCategory == null,
                          onSelected: (_) => setState(() => _filterCategory = null),
                        ),
                        const SizedBox(width: 8),
                        ...ExpenseCategory.values.map((cat) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              avatar: Icon(cat.icon, size: 14, color: cat.color),
                              label: Text(cat.vietnameseName),
                              selected: _filterCategory == cat,
                              onSelected: (val) {
                                setState(() {
                                  _filterCategory = val ? cat : null;
                                });
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 5. Tiêu đề danh sách giao dịch gần đây
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Lịch sử chi tiêu gần đây',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        '${filteredList.length} giao dịch',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 6. Danh sách giao dịch
                  if (filteredList.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text(
                            'Chưa có giao dịch nào trong danh mục này',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  else
                    ...filteredList.map((tx) {
                      return TransactionTile(
                        transaction: tx,
                        onDelete: () => _deleteTx(tx.id!),
                        onTap: () => _showTransactionDetails(tx),
                      );
                    }),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.camera_alt),
        label: const Text(
          'Quét hóa đơn OCR',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () async {
          final res = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CameraCaptureScreen(),
            ),
          );
          if (res == true) {
            _loadDashboardData();
          }
        },
      ),
    );
  }
}
