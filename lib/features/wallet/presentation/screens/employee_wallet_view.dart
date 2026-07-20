import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/core/constants/app_url.dart';
import 'package:quickboom_hrm/core/services/api_service.dart';
import 'package:quickboom_hrm/core/services/wallet_service.dart';
import 'package:quickboom_hrm/core/services/sales_service.dart';
import 'package:quickboom_hrm/core/services/mobile_store_service.dart';
import 'package:quickboom_hrm/core/services/permission_service.dart';
import 'package:quickboom_hrm/features/auth/presentation/providers/auth_viewmodel.dart';
import 'package:quickboom_hrm/features/auth/data/models/user_model.dart';
import 'package:quickboom_hrm/features/payroll/presentation/providers/employee_payroll_viewmodel.dart';
import 'package:quickboom_hrm/features/expense/presentation/screens/employee_expenses_view.dart';
import 'package:quickboom_hrm/features/payroll/presentation/screens/employee_payroll_view.dart';

class EmployeeWalletView extends ConsumerStatefulWidget {
  const EmployeeWalletView({super.key});

  @override
  ConsumerState<EmployeeWalletView> createState() => _EmployeeWalletViewState();
}

class _EmployeeWalletViewState extends ConsumerState<EmployeeWalletView>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<dynamic> _commissionData = [];
  bool _isLoadingComm = false;
  String _groupBy = 'day';
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();

  Map<String, dynamic>? _advanceData;
  List<dynamic> _stores = [];

  List<dynamic> _payslips = [];
  bool _isLoadingPayslips = false;
  int? _downloadingPayslipId;

  Map<String, dynamic>? _bankDetails;
  bool _obscureAccountNumber = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(() {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authViewModelProvider).currentUser;
      if (user != null) {
        final isSalesman = PermissionService.canViewCommissionWidget(user);
        if (isSalesman) {
          _fetchCommissionReport();
          _loadStores();
          SalesService.syncOfflineQueue().then((synced) {
            if (synced > 0 && mounted) {
              _fetchCommissionReport();
            }
          });
        } else {
          _fetchPayslips();
        }
      }
    });

    _loadWalletData();

    // Automatically trigger sync of offline queue on load
    SalesService.syncOfflineQueue().then((synced) {
      if (synced > 0 && mounted) {
        _fetchCommissionReport();
      }
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadStores() async {
    try {
      final res = await MobileStoreService.getAllStores();
      if (res != null && res['success'] == true) {
        setState(() {
          _stores = res['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error loading stores: $e');
    }
  }

  Future<void> _loadWalletData() async {
    final results = await Future.wait([
      WalletService.fetchEmployeeWallet(),
      WalletService.fetchBankDetails(),
    ]);
    if (mounted) {
      setState(() {
        _advanceData = results[0];
        _bankDetails = results[1];
      });
    }
  }

  String _getBankValue(String? apiValue, String? userValue) {
    if (apiValue != null && apiValue.trim().isNotEmpty) {
      return apiValue;
    }
    if (userValue != null && userValue.trim().isNotEmpty) {
      return userValue;
    }
    return 'Not Configured';
  }

  String _maskAccountNumber(String val) {
    if (val.isEmpty || val == 'Not Configured' || val == 'N/A') return val;
    if (val.length <= 4) return val;
    final last4 = val.substring(val.length - 4);
    final stars = '*' * (val.length - 4);
    return '$stars$last4';
  }

  Future<void> _fetchCommissionReport() async {
    setState(() => _isLoadingComm = true);
    try {
      final fromStr = DateFormat('yyyy-MM-dd').format(_fromDate);
      final toStr = DateFormat('yyyy-MM-dd').format(_toDate);
      final url =
          '${AppUrl.commissionReport}?from=$fromStr&to=$toStr&groupBy=$_groupBy';

      final res = await ApiService.get(url);
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        setState(() {
          _commissionData = body['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching employee report: $e');
    } finally {
      setState(() => _isLoadingComm = false);
    }
  }

  Future<void> _fetchPayslips() async {
    setState(() => _isLoadingPayslips = true);
    try {
      final res = await ApiService.get(AppUrl.employeePayslips);
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        setState(() {
          _payslips = body['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching payslips in wallet: $e');
    } finally {
      setState(() => _isLoadingPayslips = false);
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }

  Future<void> _downloadPayslip(int id) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _downloadingPayslipId = id);
    try {
      final success = await ref
          .read(employeePayrollViewModelProvider.notifier)
          .downloadPayslip(id);
      if (!success && mounted) {
        final errorMsg = ref
            .read(employeePayrollViewModelProvider)
            .errorMessage;
        messenger.showSnackBar(
          SnackBar(
            content: Text(errorMsg ?? 'Failed to download payslip PDF.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error downloading payslip: $e');
    } finally {
      if (mounted) {
        setState(() => _downloadingPayslipId = null);
      }
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      _fetchCommissionReport();
    }
  }

  void _showRequestAdvanceSheet(BuildContext context) {
    final advanceLimit =
        (_advanceData?['advanceLimit'] as num?)?.toDouble() ?? 25000.0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RequestAdvanceSheet(
        maxLimit: advanceLimit,
        onSubmit: (double amount, int months, String reason) async {
          Navigator.pop(ctx);
          final result = await WalletService.requestSalaryAdvance(
            amount: amount,
            months: months,
            reason: reason,
          );
          if (result != null && mounted) {
            _showSuccessDialog(amount);
            _loadWalletData();
          }
        },
      ),
    );
  }

  void _showSuccessDialog(double amount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                RemixIcons.checkbox_circle_fill,
                color: AppColors.success,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Request Submitted',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Your salary advance request of ₹${NumberFormat('#,##,###').format(amount)} has been sent to HR for approval.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Back to Wallet',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBankDetailsSheet(BuildContext context) {
    final user = ref.read(authViewModelProvider).currentUser;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BankDetailsSheet(
        bankDetails: _bankDetails,
        userName: user?.name ?? 'User',
      ),
    );
  }

  void _showSalesActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sales Transactions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _SalesActionTile(
              icon: RemixIcons.money_dollar_circle_line,
              title: 'Add New Sale',
              subtitle: 'Log a new sale and earn commission',
              color: AppColors.success,
              onTap: () {
                Navigator.pop(ctx);
                _showTransactionFormSheet(context, 'AddSale');
              },
            ),
            _SalesActionTile(
              icon: RemixIcons.edit_line,
              title: 'Update Sale',
              subtitle: 'Modify an existing sale amount/details',
              color: AppColors.primary,
              onTap: () {
                Navigator.pop(ctx);
                _showTransactionFormSheet(context, 'UpdateSale');
              },
            ),
            _SalesActionTile(
              icon: RemixIcons.file_warning_line,
              title: 'Add Credit Note',
              subtitle: 'Process a return/refund adjustment',
              color: AppColors.error,
              onTap: () {
                Navigator.pop(ctx);
                _showTransactionFormSheet(context, 'CreditNote');
              },
            ),
            _SalesActionTile(
              icon: RemixIcons.swap_line,
              title: 'Sales Exchange',
              subtitle: 'Swap a returned item for a new purchase',
              color: AppColors.warning,
              onTap: () {
                Navigator.pop(ctx);
                _showTransactionFormSheet(context, 'Exchange');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionFormSheet(BuildContext context, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SalesTransactionFormSheet(
        type: type,
        stores: _stores,
        onSubmit: (Map<String, dynamic> payload) async {
          Navigator.pop(ctx);

          String endpoint = '';
          if (type == 'AddSale') {
            endpoint = '/api/Sales/AddSales';
          } else if (type == 'UpdateSale') {
            endpoint = '/api/Sales/UpdateSales';
          } else if (type == 'CreditNote') {
            endpoint = '/api/Sales/AddCreditNote';
          } else if (type == 'Exchange') {
            endpoint = '/api/Sales/AddSalesExchange';
          }

          final messenger = ScaffoldMessenger.of(context);
          final result = await SalesService.submitTransaction(
            endpoint: endpoint,
            payload: payload,
          );

          if (mounted) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(result['message']),
                backgroundColor: result['success']
                    ? (result['offline']
                          ? AppColors.warning
                          : AppColors.success)
                    : AppColors.error,
              ),
            );
            _fetchCommissionReport();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authViewModelProvider).currentUser;
    if (user == null) return const Scaffold();

    final isSalesman = PermissionService.canViewCommissionWidget(user);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          'My Wallet',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: isSalesman
            ? TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'Commission'),
                  Tab(text: 'Salary'),
                ],
              )
            : null,
      ),
      body: isSalesman
          ? TabBarView(
              controller: _tabController,
              children: [_buildCommissionTab(), _buildSalaryTab(user)],
            )
          : _buildSalaryTab(user),
      floatingActionButton: isSalesman && _tabController?.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showSalesActionSheet(context),
              backgroundColor: AppColors.primary,
              icon: const Icon(RemixIcons.add_line, color: Colors.white),
              label: const Text(
                'Add Transaction',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildCommissionTab() {
    final netSales = _commissionData.fold<double>(
      0.0,
      (sum, item) => sum + (item['netSales'] as num).toDouble(),
    );
    final commissionEarned = _commissionData.fold<double>(
      0.0,
      (sum, item) => sum + (item['commissionAmount'] as num).toDouble(),
    );

    return RefreshIndicator(
      onRefresh: () async {
        await _fetchCommissionReport();
        await SalesService.syncOfflineQueue();
      },
      child: Column(
        children: [
          // Filter bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectDateRange,
                    icon: const Icon(RemixIcons.calendar_2_line, size: 16),
                    label: Text(
                      '${DateFormat('dd MMM').format(_fromDate)} - ${DateFormat('dd MMM').format(_toDate)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _groupBy,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _groupBy = val);
                      _fetchCommissionReport();
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: 'day',
                      child: Text('Daily', style: TextStyle(fontSize: 13)),
                    ),
                    DropdownMenuItem(
                      value: 'week',
                      child: Text('Weekly', style: TextStyle(fontSize: 13)),
                    ),
                    DropdownMenuItem(
                      value: 'month',
                      child: Text('Monthly', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Summary cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Net Sales',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${NumberFormat('#,##,###').format(netSales)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Commission',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${NumberFormat('#,##,###').format(commissionEarned)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Report list
          Expanded(
            child: _isLoadingComm
                ? const Center(child: CircularProgressIndicator())
                : _commissionData.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.15,
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              RemixIcons.bar_chart_box_line,
                              size: 40,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No commission records found',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      110,
                    ), // Leave space for FAB
                    itemCount: _commissionData.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final item = _commissionData[i];
                      final rate = item['commissionRate'] as num? ?? 0.0;
                      final comm = item['commissionAmount'] as num? ?? 0.0;
                      final net = item['netSales'] as num? ?? 0.0;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['periodStart'] == item['periodEnd']
                                      ? DateFormat('dd MMM yyyy').format(
                                          DateTime.parse(item['periodStart']),
                                        )
                                      : '${DateFormat('dd MMM').format(DateTime.parse(item['periodStart']))} - ${DateFormat('dd MMM yyyy').format(DateTime.parse(item['periodEnd']))}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Net Sales: ₹${NumberFormat('#,##,###').format(net)} (Rate: $rate%)',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '₹${NumberFormat('#,##,###').format(comm)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryTab(UserModel user) {
    final isSalesman = PermissionService.canViewCommissionWidget(user);
    final pendingClaims =
        (_advanceData?['pendingClaims'] as num?)?.toDouble() ?? 0.0;
    final phoneStr = user.phone.toString();
    final phoneLast4 = phoneStr.length >= 4
        ? phoneStr.substring(phoneStr.length - 4)
        : phoneStr;

    return RefreshIndicator(
      onRefresh: () async {
        await _loadWalletData();
        if (!isSalesman) {
          await _fetchPayslips();
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Green Wallet Card
            Container(
              width: double.infinity,
              height: 185,
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    // Translucent circular pattern on the right
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PAY CARD',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.65,
                                      ),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    user.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(
                                RemixIcons.vip_crown_line,
                                color: Color(0xFFFBBF24),
                                size: 28,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'BALANCE',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.65,
                                      ),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _advanceData?['balance'] != null
                                        ? '₹${NumberFormat('#,##,###').format(_advanceData!['balance'])}'
                                        : '₹.00',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'CARD NO',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.65,
                                      ),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'HK$phoneLast4-${user.employeeCode}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
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
            ),
            const SizedBox(height: 20),

            // Financial Overview (Single container with divider)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Advance Limit',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '₹${NumberFormat('#,##,###').format((_advanceData?['advanceLimit'] as num?)?.toDouble() ?? 25000.0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Color(0xFF9333EA), // Purple color
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 40, color: AppColors.divider),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Pending Claims',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '₹${NumberFormat('#,##,###').format(pendingClaims)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Color(0xFFF59E0B), // Orange color
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'QUICK ACTIONS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.0,
              children: [
                _QuickActionButton(
                  icon: RemixIcons.hand_coin_line,
                  label: 'Request\nAdvance',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => _showRequestAdvanceSheet(context),
                ),
                _QuickActionButton(
                  icon: RemixIcons.coupon_line,
                  label: 'Claim\nExpense',
                  color: const Color(0xFFF59E0B),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EmployeeExpensesView()),
                    );
                  },
                ),
                _QuickActionButton(
                  icon: RemixIcons.file_text_line,
                  label: 'Payslips &\nPayroll',
                  color: const Color(0xFF10B981),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EmployeePayrollView()),
                    );
                  },
                ),
                _QuickActionButton(
                  icon: RemixIcons.bank_line,
                  label: 'Bank\nDetails',
                  color: const Color(0xFF3B82F6),
                  onTap: () => _showBankDetailsSheet(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Transactions
            Text(
              'RECENT TRANSACTIONS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      RemixIcons.history_line,
                      size: 40,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No transactions yet',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Payslips Section for non-salesman
            if (!isSalesman) ...[
              Text(
                'MY PAYSLIPS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),
              if (_isLoadingPayslips)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_payslips.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Center(
                    child: Text(
                      'No payslips generated yet',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _payslips.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final slip = _payslips[idx];
                    final slipId = slip['id'] as int? ?? 0;
                    final month = slip['month'] as int? ?? 1;
                    final year = slip['year'] as int? ?? 2026;
                    final netSalary =
                        (slip['netSalary'] as num?)?.toDouble() ?? 0.0;
                    final isDownloading = _downloadingPayslipId == slipId;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_getMonthName(month)} $year',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Net Salary: ₹${NumberFormat('#,##,###').format(netSalary)}',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          isDownloading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(
                                    RemixIcons.download_2_line,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  onPressed: () => _downloadPayslip(slipId),
                                ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 20),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'BANK & ACCOUNT DETAILS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showEditBankDetailsSheet(context),
                  icon: const Icon(RemixIcons.edit_2_line, size: 14),
                  label: const Text(
                    'Edit',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _DetailRow(
              label: 'Bank Name',
              value: _getBankValue(
                _bankDetails?['bankName']?.toString(),
                user.bankName,
              ),
            ),
            _DetailRow(
              label: 'Account Number',
              value: _obscureAccountNumber
                  ? _maskAccountNumber(
                      _getBankValue(
                        _bankDetails?['accountNumber']?.toString(),
                        user.accountNumber,
                      ),
                    )
                  : _getBankValue(
                      _bankDetails?['accountNumber']?.toString(),
                      user.accountNumber,
                    ),
              trailing: GestureDetector(
                onTap: () => setState(() => _obscureAccountNumber = !_obscureAccountNumber),
                child: Icon(
                  _obscureAccountNumber ? RemixIcons.eye_off_line : RemixIcons.eye_line,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            _DetailRow(
              label: 'IFSC Code',
              value: _getBankValue(
                _bankDetails?['ifscCode']?.toString(),
                user.ifscCode,
              ),
            ),
            _DetailRow(
              label: 'Account Type',
              value: _getBankValue(
                _bankDetails?['accountType']?.toString(),
                user.accountType,
              ),
            ),
            _DetailRow(
              label: 'Branch Name',
              value: _getBankValue(
                _bankDetails?['branchName']?.toString(),
                user.branchName,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBankDetailsSheet(BuildContext context) {
    final user = ref.read(authViewModelProvider).currentUser;
    if (user == null) return;

    String getVal(String? apiVal, String? userVal) {
      if (apiVal != null && apiVal.trim().isNotEmpty) return apiVal;
      if (userVal != null && userVal.trim().isNotEmpty) return userVal;
      return '';
    }

    final bankNameCtrl = TextEditingController(
      text: getVal(_bankDetails?['bankName']?.toString(), user.bankName),
    );
    final accNoCtrl = TextEditingController(
      text: getVal(
        _bankDetails?['accountNumber']?.toString(),
        user.accountNumber,
      ),
    );
    final ifscCtrl = TextEditingController(
      text: getVal(_bankDetails?['ifscCode']?.toString(), user.ifscCode),
    );
    final branchCtrl = TextEditingController(
      text: getVal(_bankDetails?['branchName']?.toString(), user.branchName),
    );
    String accType = getVal(
      _bankDetails?['accountType']?.toString(),
      user.accountType,
    );
    if (accType.isEmpty) accType = 'Savings';

    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Update Bank Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (isSaving)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: bankNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Bank Name',
                      hintText: 'e.g. HDFC Bank',
                      prefixIcon: Icon(RemixIcons.bank_line),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Please enter bank name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: accNoCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Account Number',
                      hintText: 'e.g. 50100123456789',
                      prefixIcon: Icon(RemixIcons.wallet_3_line),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Please enter account number'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: ifscCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'IFSC Code',
                      hintText: 'e.g. HDFC0000123',
                      prefixIcon: Icon(RemixIcons.file_shield_2_line),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Please enter IFSC code'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: accType,
                    decoration: const InputDecoration(
                      labelText: 'Account Type',
                      prefixIcon: Icon(RemixIcons.contacts_line),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Savings',
                        child: Text('Savings'),
                      ),
                      DropdownMenuItem(
                        value: 'Current',
                        child: Text('Current'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setSheetState(() => accType = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: branchCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Branch Name',
                      hintText: 'e.g. Andheri West Branch',
                      prefixIcon: Icon(RemixIcons.map_pin_2_line),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Please enter branch name'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (formKey.currentState?.validate() ?? false) {
                                final navigator = Navigator.of(context);
                                final messenger = ScaffoldMessenger.of(context);

                                setSheetState(() => isSaving = true);
                                final result =
                                    await WalletService.updateBankDetails(
                                      bankName: bankNameCtrl.text.trim(),
                                      accountNumber: accNoCtrl.text.trim(),
                                      ifscCode: ifscCtrl.text
                                          .trim()
                                          .toUpperCase(),
                                      accountType: accType,
                                      branchName: branchCtrl.text.trim(),
                                    );
                                if (mounted) {
                                  if (result != null) {
                                    setState(() {
                                      _bankDetails = result;
                                    });
                                    navigator.pop();
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Bank details updated successfully.',
                                        ),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  } else {
                                    setSheetState(() => isSaving = false);
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Failed to update bank details. Please try again.',
                                        ),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                      child: const Text(
                        'Save Details',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SalesActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SalesActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
      ),
      trailing: Icon(
        RemixIcons.arrow_right_s_line,
        color: AppColors.textHint,
        size: 18,
      ),
      onTap: onTap,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;

  const _DetailRow({required this.label, required this.value, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Salary Advance Form Sheet (Kept from original code) ───────────────────
class _RequestAdvanceSheet extends StatefulWidget {
  final double maxLimit;
  final Function(double amount, int months, String reason) onSubmit;

  const _RequestAdvanceSheet({required this.maxLimit, required this.onSubmit});

  @override
  State<_RequestAdvanceSheet> createState() => _RequestAdvanceSheetState();
}

class _RequestAdvanceSheetState extends State<_RequestAdvanceSheet> {
  double _amount = 0.0;
  final _amountCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  int _repaymentMonths = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repaymentMonths = 1;
    final defaultAmt = widget.maxLimit >= 10000.0 ? 10000.0 : widget.maxLimit;
    _amount = (defaultAmt / 1000).round() * 1000.0;
    if (_amount < 0.0) _amount = 0.0;
    _amountCtrl.text = _amount == 0.0 ? '' : NumberFormat('#,##,###').format(_amount);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  void _onAmountChanged(String valStr) {
    final cleanStr = valStr.replaceAll(RegExp(r'[^\d]'), '');
    final val = double.tryParse(cleanStr) ?? 0.0;
    
    setState(() {
      if (val > widget.maxLimit) {
        _amount = widget.maxLimit;
      } else {
        _amount = val;
      }
      
      final formatted = _amount == 0 ? '' : NumberFormat('#,##,###').format(_amount);
      if (_amountCtrl.text != formatted) {
        _amountCtrl.text = formatted;
        _amountCtrl.selection = TextSelection.fromPosition(
          TextPosition(offset: _amountCtrl.text.length),
        );
      }
    });
  }

  void _onSliderChanged(double val) {
    setState(() {
      _amount = val;
      final formatted = _amount == 0 ? '' : NumberFormat('#,##,###').format(_amount);
      _amountCtrl.text = formatted;
    });
  }

  void _submit() {
    setState(() => _error = null);
    final amt = _amount;
    if (amt <= 0) {
      setState(() => _error = 'Please select a valid amount');
      return;
    }
    if (amt > widget.maxLimit) {
      setState(
        () => _error =
            'Amount exceeds your limit of ₹${NumberFormat('#,##,###').format(widget.maxLimit)}',
      );
      return;
    }
    if (_reasonCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a reason');
      return;
    }
    widget.onSubmit(amt, _repaymentMonths, _reasonCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final maxVal = widget.maxLimit <= 0 ? 1000.0 : widget.maxLimit;
    final divisions = maxVal > 1000 ? (maxVal / 1000).floor() : 1;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF9333EA).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  RemixIcons.hand_coin_line,
                  color: Color(0xFF9333EA),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Salary Advance Request',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    RemixIcons.error_warning_line,
                    color: AppColors.error,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Amount Input Header
          Text(
            'AMOUNT (MAX ₹${NumberFormat('#,##,###').format(widget.maxLimit)})',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),

          // Custom White Rounded Amount TextField
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _amountCtrl,
              textAlign: TextAlign.end,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
              onChanged: _onAmountChanged,
              decoration: InputDecoration(
                prefixIcon: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Text(
                    '₹',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9333EA),
                    ),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF9333EA), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Custom Slider with Dotted Snapping Tick Marks
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF9333EA),
              inactiveTrackColor: const Color(0xFF9333EA).withValues(alpha: 0.15),
              thumbColor: const Color(0xFF9333EA),
              overlayColor: const Color(0xFF9333EA).withValues(alpha: 0.2),
              trackHeight: 5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              activeTickMarkColor: const Color(0xFF9333EA),
              inactiveTickMarkColor: const Color(0xFF9333EA),
            ),
            child: Slider(
              value: _amount,
              min: 0,
              max: maxVal,
              divisions: divisions,
              onChanged: widget.maxLimit <= 0 ? null : _onSliderChanged,
            ),
          ),
          const SizedBox(height: 16),

          // Payback Duration Section
          const Text(
            'PAYBACK DURATION',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [1, 2, 3].map((m) {
              final isSel = _repaymentMonths == m;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _repaymentMonths = m),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSel
                          ? const Color(0xFF9333EA).withValues(alpha: 0.08)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSel ? const Color(0xFF9333EA) : const Color(0xFFE2E8F0),
                        width: isSel ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$m ${m == 1 ? 'Month' : 'Months'}',
                          style: TextStyle(
                            color: isSel ? const Color(0xFF9333EA) : const Color(0xFF1E293B),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'EMI Payback',
                          style: TextStyle(
                            color: isSel
                                ? const Color(0xFF9333EA).withValues(alpha: 0.7)
                                : const Color(0xFF64748B),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Reason for Advance Section
          const Text(
            'REASON FOR ADVANCE',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _reasonCtrl,
              maxLines: 3,
              style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Enter reason (e.g. medical emergency)...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF9333EA), width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9333EA),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Submit Request',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SalesTransactionFormSheet extends StatefulWidget {
  final String type;
  final List<dynamic> stores;
  final Function(Map<String, dynamic> payload) onSubmit;

  const _SalesTransactionFormSheet({
    required this.type,
    required this.stores,
    required this.onSubmit,
  });

  @override
  State<_SalesTransactionFormSheet> createState() =>
      _SalesTransactionFormSheetState();
}

class _SalesTransactionFormSheetState
    extends State<_SalesTransactionFormSheet> {
  final _invoiceCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _returnAmountCtrl = TextEditingController(); // for exchange
  final _notesCtrl = TextEditingController();
  String? _selectedStoreId;
  String? _error;

  @override
  void dispose() {
    _invoiceCtrl.dispose();
    _amountCtrl.dispose();
    _returnAmountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _error = null);

    final invoice = _invoiceCtrl.text.trim();
    if (invoice.isEmpty) {
      setState(() => _error = 'Enter Invoice Number or Bill ID');
      return;
    }

    final amt = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (widget.type != 'Exchange') {
      if (amt == null || amt <= 0) {
        setState(() => _error = 'Enter a valid amount');
        return;
      }
    } else {
      // Exchange validation
      if (amt == null || amt < 0) {
        setState(() => _error = 'Enter a valid purchase amount');
        return;
      }
      final retAmt = double.tryParse(
        _returnAmountCtrl.text.replaceAll(',', ''),
      );
      if (retAmt == null || retAmt < 0) {
        setState(() => _error = 'Enter a valid return amount');
        return;
      }
    }

    if (widget.type == 'AddSale' || widget.type == 'UpdateSale') {
      if (_selectedStoreId == null) {
        setState(() => _error = 'Please select a store');
        return;
      }
    }

    final Map<String, dynamic> payload = {
      'invoiceNumber': invoice,
      'billId': invoice, // pass both to satisfy backend controller checks
      'notes': _notesCtrl.text.trim(),
    };

    if (widget.type == 'AddSale' || widget.type == 'UpdateSale') {
      payload['saleAmount'] = amt;
      payload['storeId'] = _selectedStoreId;
    } else if (widget.type == 'CreditNote') {
      payload['creditAmount'] = amt;
    } else if (widget.type == 'Exchange') {
      payload['newSaleAmount'] = amt;
      payload['returnAmount'] = double.parse(
        _returnAmountCtrl.text.replaceAll(',', ''),
      );
    }

    widget.onSubmit(payload);
  }

  @override
  Widget build(BuildContext context) {
    String title = '';
    String amountLabel = '';
    if (widget.type == 'AddSale') {
      title = 'Add New Sale';
      amountLabel = 'Sale Amount';
    } else if (widget.type == 'UpdateSale') {
      title = 'Update Sale';
      amountLabel = 'New Sale Amount';
    } else if (widget.type == 'CreditNote') {
      title = 'Add Credit Note';
      amountLabel = 'Credit Amount';
    } else if (widget.type == 'Exchange') {
      title = 'Sales Exchange';
      amountLabel = 'New Purchase Amount';
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    RemixIcons.error_warning_line,
                    color: AppColors.error,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _invoiceCtrl,
            decoration: const InputDecoration(labelText: 'Invoice / Bill ID'),
          ),
          const SizedBox(height: 16),
          if (widget.type == 'AddSale' || widget.type == 'UpdateSale') ...[
            DropdownButtonFormField<String>(
              initialValue: _selectedStoreId,
              hint: const Text('Select Store'),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: widget.stores.map((s) {
                return DropdownMenuItem<String>(
                  value: s['id'].toString(),
                  child: Text(s['name'] ?? 'Store'),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedStoreId = val),
            ),
            const SizedBox(height: 16),
          ],
          if (widget.type == 'Exchange') ...[
            TextField(
              controller: _returnAmountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Return Amount',
                prefixText: '₹ ',
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: amountLabel,
              prefixText: '₹ ',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Notes'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _submit,
              child: const Text(
                'Submit',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BankDetailsSheet extends StatelessWidget {
  final Map<String, dynamic>? bankDetails;
  final String userName;

  const _BankDetailsSheet({required this.bankDetails, required this.userName});

  String _maskAccountNumber(String? accountNumber) {
    if (accountNumber == null || accountNumber.length < 4) return 'XXXX';
    final lastFour = accountNumber.substring(accountNumber.length - 4);
    return 'XXXX XXXX XXXX $lastFour';
  }

  @override
  Widget build(BuildContext context) {
    final bankName = _getBankValue(bankDetails?['bankName']);
    final accountNumber = _getBankValue(bankDetails?['accountNumber']);
    final ifscCode = _getBankValue(bankDetails?['ifscCode']);
    final accountType = _getBankValue(bankDetails?['accountType']);

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Linked Bank Account',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          _BankDetailRow(label: 'Account Holder', value: userName),
          const SizedBox(height: 16),
          _BankDetailRow(label: 'Bank Name', value: bankName),
          const SizedBox(height: 16),
          _BankDetailRow(
            label: 'Account Number',
            value: _maskAccountNumber(
              accountNumber != 'Not Configured' ? accountNumber : null,
            ),
          ),
          const SizedBox(height: 16),
          _BankDetailRow(label: 'IFSC Code', value: ifscCode),
          const SizedBox(height: 16),
          _BankDetailRow(label: 'Account Type', value: accountType),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.cardBorder),
                ),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close Details',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getBankValue(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return 'Not Configured';
    }
    return value.toString();
  }
}

class _BankDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _BankDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
