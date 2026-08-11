import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quickboom_hrm/core/services/mobile_commission_service.dart';

class CommissionScreen extends StatefulWidget {
  const CommissionScreen({super.key});

  @override
  State<CommissionScreen> createState() => _CommissionScreenState();
}

class _CommissionScreenState extends State<CommissionScreen> {
  double totalCommission = 0;
  double totalSales = 0;
  int billCount = 0;
  double commissionRate = 0;

  List<Map<String, dynamic>> dailyBills = [];
  List<Map<String, dynamic>> recentTransactions = [];

  bool loading = true;
  String selectedDate = '';

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now().toString().split(' ')[0];
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    setState(() => loading = true);
    try {
      await Future.wait([
        fetchDashboard(),
        fetchDailyBills(),
        fetchTransactions(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> fetchDashboard() async {
    try {
      final res = await MobileCommissionService.getCommissionDashboard();
      if (res != null && res['success'] == true && res['data'] != null) {
        final data = res['data'];
        final summary = data['summary'] ?? data['month'] ?? {};

        if (mounted) {
          setState(() {
            totalSales = (summary['totalSalesAmount'] ?? summary['sales'] ?? 0).toDouble();
            totalCommission = (summary['approvedCommission'] ?? summary['commissionAmount'] ?? summary['commission'] ?? 0).toDouble();
            commissionRate = (summary['commissionRate'] ?? 0).toDouble();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching dashboard: $e');
    }
  }

  Future<void> fetchDailyBills() async {
    try {
      final res = await MobileCommissionService.getDailyBills(date: selectedDate);
      if (res != null && res['success'] == true && res['data'] != null) {
        final bills = res['data']['bills'] ?? [];
        if (mounted) {
          setState(() {
            dailyBills = List<Map<String, dynamic>>.from(bills);
            billCount = bills.length;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching daily bills: $e');
    }
  }

  Future<void> fetchTransactions() async {
    try {
      final res = await MobileCommissionService.getCommissionTransactions(limit: 30);
      if (res != null && res['success'] == true && res['data'] != null) {
        final transactions = res['data']['transactions'] ?? [];
        if (mounted) {
          setState(() {
            recentTransactions = List<Map<String, dynamic>>.from(transactions).take(10).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commission'),
        backgroundColor: const Color(0xFF1e293b),
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchAllData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // SUMMARY CARDS
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Total Commission Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF16A085), Color(0xFF1E8449)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Commission (This Month)',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '₹${totalCommission.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Total Sales', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                                        Text('₹${totalSales.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Rate', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                                        Text('${commissionRate.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Bills', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                                        Text('$billCount', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // DATE PICKER FOR DAILY BILLS
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Bills for: ${DateFormat('dd MMM yyyy').format(DateTime.parse(selectedDate))}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.tryParse(selectedDate) ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() {
                                  selectedDate = date.toString().split(' ')[0];
                                });
                                fetchDailyBills();
                              }
                            },
                            child: const Icon(Icons.calendar_today, color: Colors.blue),
                          ),
                        ],
                      ),
                    ),

                    // DAILY BILLS LIST
                    if (dailyBills.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No bills for this date'),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: dailyBills.length,
                        itemBuilder: (context, index) {
                          final bill = dailyBills[index];
                          final billAmount = (bill['amount'] ?? 0).toDouble();
                          final billCommission = (bill['commission'] ?? 0).toDouble();
                          final billTimeStr = bill['time']?.toString();
                          DateTime billTime = DateTime.now();
                          if (billTimeStr != null) {
                            billTime = DateTime.tryParse(billTimeStr) ?? DateTime.now();
                          }

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Bill: ${bill['billId'] ?? '-'}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      DateFormat('hh:mm a').format(billTime),
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${billCommission.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '₹${billAmount.toStringAsFixed(0)} sale',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 24),

                    // RECENT TRANSACTIONS
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Recent Bills (Last 30 days)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          if (recentTransactions.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Text('No recent transactions', style: TextStyle(color: Colors.grey)),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: recentTransactions.length,
                              itemBuilder: (context, index) {
                                final tx = recentTransactions[index];
                                final amount = (tx['amount'] ?? tx['saleAmount'] ?? 0).toDouble();
                                final comm = (tx['commission'] ?? tx['commissionAmount'] ?? 0).toDouble();
                                final dateStr = tx['date']?.toString() ?? tx['createdAt']?.toString();
                                DateTime dt = DateTime.now();
                                if (dateStr != null) {
                                  dt = DateTime.tryParse(dateStr) ?? DateTime.now();
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(tx['billId']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.w600)),
                                          Text(DateFormat('dd MMM').format(dt), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text('₹${comm.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                          Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
