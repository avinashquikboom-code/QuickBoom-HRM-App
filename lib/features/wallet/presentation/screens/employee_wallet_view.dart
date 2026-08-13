// ignore_for_file: prefer_final_fields, use_build_context_synchronously

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
import 'package:quickboom_hrm/core/services/hopkid_sales_dto.dart';
import 'package:quickboom_hrm/core/services/permission_service.dart';
import 'package:quickboom_hrm/core/widgets/permission_protected_widget.dart';
import 'package:quickboom_hrm/core/services/notification_service.dart';
import 'package:quickboom_hrm/features/auth/presentation/providers/auth_viewmodel.dart';
import 'package:quickboom_hrm/features/auth/data/models/user_model.dart';
import 'package:quickboom_hrm/features/payroll/presentation/providers/employee_payroll_viewmodel.dart';
import 'package:quickboom_hrm/features/expense/presentation/screens/employee_expenses_view.dart';
import 'package:quickboom_hrm/features/expense/presentation/providers/expense_viewmodel.dart';
import 'package:quickboom_hrm/features/payroll/presentation/screens/employee_payroll_view.dart';
import 'package:quickboom_hrm/features/wallet/presentation/screens/request_advance_view.dart';
import 'package:quickboom_hrm/screens/commission/commission_detail_screen.dart';
import 'package:quickboom_hrm/core/services/mobile_commission_service.dart';
import 'package:quickboom_hrm/core/services/websocket_service.dart';
import 'dart:async';

class EmployeeWalletView extends ConsumerStatefulWidget {
  const EmployeeWalletView({super.key});

  @override
  ConsumerState<EmployeeWalletView> createState() => _EmployeeWalletViewState();
}

class _EmployeeWalletViewState extends ConsumerState<EmployeeWalletView> {
  Map<String, dynamic>? _advanceData;

  List<dynamic> _payslips = [];
  bool _isLoadingPayslips = false;
  int? _downloadingPayslipId;

  Map<String, dynamic>? _bankDetails;

  // Salary slip state
  Map<String, dynamic>? _salarySlipData;
  bool _isLoadingSalarySlip = false;
  int _salarySlipMonth = DateTime.now().month;
  int _salarySlipYear = DateTime.now().year;

  // Stores list for transaction form
  List<dynamic> _stores = [];
  int _refreshKey = 0;

  // Commission report state
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 90));
  DateTime _toDate = DateTime.now();
  bool _isLoadingComm = false;
  List<dynamic> _commissionData = [];
  String _groupBy = 'day';

  void _selectPeriodFilter(String period) {
    final now = DateTime.now();
    setState(() {
      _groupBy = period;
      if (period == 'day') {
        // Show all past days (last 90 days) grouped day-by-day
        _fromDate = now.subtract(const Duration(days: 90));
        _toDate = now;
      } else if (period == 'week') {
        // Show all weeks (last 180 days) grouped week-by-week
        _fromDate = now.subtract(const Duration(days: 180));
        _toDate = now;
      } else if (period == 'month') {
        // Show all months (last 365 days) grouped month-by-month
        _fromDate = now.subtract(const Duration(days: 365));
        _toDate = now;
      }
    });
    _fetchCommissionReport();
  }

  StreamSubscription? _commissionSub;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSalarySlip();
      _fetchCommissionReport();
    });

    _loadWalletData();

    _commissionSub = WebSocketService().commissionUpdates.listen((_) {
      if (mounted) {
        setState(() {
          _refreshKey++;
        });
        _loadWalletData();
        _fetchCommissionReport();
      }
    });
  }

  @override
  void dispose() {
    _commissionSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchSalarySlip() async {
    setState(() => _isLoadingSalarySlip = true);
    try {
      final res = await WalletService.fetchSalarySlip(
        month: _salarySlipMonth,
        year: _salarySlipYear,
      );
      if (mounted) {
        setState(() {
          _salarySlipData = res;
        });
      }
    } catch (e) {
      debugPrint('Error fetching salary slip: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingSalarySlip = false);
      }
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

  double _getCardNetSalary() {
    // 1. Prioritize wallet response net (upcomingSalary + commission from backend)
    final netAdv = (_advanceData?['netSalary'] as num?)?.toDouble() ??
                   (_advanceData?['upcomingSalary'] as num?)?.toDouble() ??
                   (_advanceData?['net'] as num?)?.toDouble();
    if (netAdv != null && netAdv > 0) return netAdv;

    // 2. Fallback to salary slip net (net includes commission)
    final netSlip = (_salarySlipData?['net'] as num?)?.toDouble() ??
                    (_salarySlipData?['netSalary'] as num?)?.toDouble();
    if (netSlip != null && netSlip > 0) return netSlip;

    final base = (_salarySlipData?['base_salary'] as num?)?.toDouble();
    final deductions = (_salarySlipData?['deductions'] as num?)?.toDouble() ?? 0.0;
    final comm = (_salarySlipData?['commission_amount'] as num?)?.toDouble() ?? 0.0;
    if (base != null && base > 0) {
      final estNet = (base - deductions) + comm;
      if (estNet > 0) return estNet;
    }

    return 0.0;
  }

  double _getCardGrossSalary() {
    // 1. Check HR registered gross salary from wallet response (_advanceData)
    final registeredGross = (_advanceData?['grossSalary'] as num?)?.toDouble() ??
                            (_advanceData?['registeredSalary'] as num?)?.toDouble();
    if (registeredGross != null && registeredGross > 0) return registeredGross;

    // 2. Check base_salary / registeredSalary from salary slip API
    final base = (_salarySlipData?['registeredSalary'] as num?)?.toDouble() ??
                 (_salarySlipData?['base_salary'] as num?)?.toDouble();
    if (base != null && base > 0) return base;

    // 3. Fallback to monthly gross slip amount if present
    final grossSlip = (_salarySlipData?['gross'] as num?)?.toDouble() ??
                      (_salarySlipData?['grossSalary'] as num?)?.toDouble();
    if (grossSlip != null && grossSlip > 0) return grossSlip;

    return 0.0;
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
        final list = List<dynamic>.from(body['data'] ?? []);
        // Sort descending by periodStart so recent days/weeks/months are at top
        list.sort((a, b) {
          final dtA = DateTime.tryParse(a['periodStart'] ?? '') ?? DateTime(1970);
          final dtB = DateTime.tryParse(b['periodStart'] ?? '') ?? DateTime(1970);
          return dtB.compareTo(dtA);
        });

        // Filter out zero sales entries for cleaner list
        final filteredList = list.where((item) {
          final net = (item['netSales'] as num?)?.toDouble() ?? 0.0;
          final comm = (item['commissionAmount'] as num?)?.toDouble() ?? 0.0;
          return net > 0 || comm > 0;
        }).toList();

        setState(() {
          _commissionData = filteredList.isNotEmpty ? filteredList : list;
        });
      }
    } catch (e) {
      debugPrint('Error fetching commission report: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingComm = false);
      }
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



  void _showRequestAdvanceSheet(BuildContext context) async {
    final advanceLimit =
        (_advanceData?['advanceLimit'] as num?)?.toDouble() ?? 25000.0;
    final activeAdvance =
        _advanceData?['activeAdvance'] as Map<String, dynamic>?;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RequestAdvanceView(
          maxLimit: advanceLimit,
          activeAdvance: activeAdvance,
        ),
      ),
    );

    if (result == true && mounted) {
      _loadWalletData();
    }
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
        onEditPressed: () => _handleEditBankDetails(context),
      ),
    );
  }

  void _handleEditBankDetails(BuildContext context) async {
    final response = await WalletService.fetchBankDetails();
    final bankData = response?['bankDetails'] as Map<String, dynamic>?;
    final latestReq = response?['latestRequest'] as Map<String, dynamic>?;
    final canEditDirectly = (response?['canEditDirectly'] as bool?) ?? false;

    final status = latestReq?['status']?.toString();

    if (!mounted) return;

    if (status == 'PENDING') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(RemixIcons.time_line, color: Color(0xFFF59E0B)),
              SizedBox(width: 8),
              Text(
                'Edit Request Pending',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Your request to edit bank details has been submitted and is currently pending HR approval.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    if (canEditDirectly || status == 'APPROVED') {
      _showUpdateBankDetailsDialog(context, bankData ?? _bankDetails);
    } else {
      _showRequestBankEditPermissionDialog(context);
    }
  }

  void _showRequestBankEditPermissionDialog(BuildContext context) {
    final reasonController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Request Edit Permission',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Updating bank account details requires HR approval. Submit a request to HR to unlock editing.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    labelText: 'Reason for Edit (Optional)',
                    hintText: 'e.g., Changing salary bank account',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setState(() => isSubmitting = true);
                        final res = await WalletService.requestBankDetailsEdit(
                          reason: reasonController.text.trim(),
                        );
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          if (res?['success'] == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Bank edit request sent to HR successfully.',
                                ),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            NotificationService().showLocalNotification(
                              title: 'Bank Edit Request Sent',
                              body:
                                  'Your request to edit bank details has been submitted to HR.',
                            );
                            _loadWalletData();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  res?['message'] ??
                                      'Failed to submit request.',
                                ),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Send to HR',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showUpdateBankDetailsDialog(
    BuildContext context,
    Map<String, dynamic>? currentDetails,
  ) {
    final bankNameCtrl = TextEditingController(
      text: currentDetails?['bankName'] ?? '',
    );
    final accNumCtrl = TextEditingController(
      text: currentDetails?['accountNumber'] ?? '',
    );
    final ifscCtrl = TextEditingController(
      text: currentDetails?['ifscCode'] ?? '',
    );
    final accTypeCtrl = TextEditingController(
      text: currentDetails?['accountType'] ?? 'Savings',
    );
    final branchCtrl = TextEditingController(
      text: currentDetails?['branchName'] ?? '',
    );
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Edit Bank Account Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: bankNameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Bank Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: accNumCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Account Number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ifscCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'IFSC Code',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: accTypeCtrl,
                    decoration: InputDecoration(
                      labelText: 'Account Type (Savings / Current)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: branchCtrl,
                    decoration: InputDecoration(
                      labelText: 'Branch Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (bankNameCtrl.text.trim().isEmpty ||
                            accNumCtrl.text.trim().isEmpty ||
                            ifscCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please fill all required bank fields.',
                              ),
                            ),
                          );
                          return;
                        }
                        setState(() => isSaving = true);
                        final res = await WalletService.updateBankDetails(
                          bankName: bankNameCtrl.text.trim(),
                          accountNumber: accNumCtrl.text.trim(),
                          ifscCode: ifscCtrl.text.trim(),
                          accountType: accTypeCtrl.text.trim(),
                          branchName: branchCtrl.text.trim(),
                        );
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          if (res?['success'] == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Bank account details updated successfully!',
                                ),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            NotificationService().showLocalNotification(
                              title: 'Bank Account Updated',
                              body:
                                  'Your bank details have been saved and updated successfully.',
                            );
                            _loadWalletData();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  res?['message'] ??
                                      'Failed to update bank details.',
                                ),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save Details',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
          );
        },
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
    final user = ref.read(authViewModelProvider).currentUser;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SalesTransactionFormSheet(
        type: type,
        stores: _stores,
        preselectedStoreId: user?.storeId ?? user?.branchName ?? user?.officeName,
        preselectedStoreName: user?.storeName ?? user?.branchName ?? user?.officeName,
        onSubmit: (Map<String, dynamic> payload) async {
          Navigator.pop(ctx);

          final messenger = ScaffoldMessenger.of(context);
          final salesmanGuid = await SalesService.getSalesmanGuid();
          final invoiceNo = payload['invoiceNumber'] as String? ?? '';
          final salesId =
              payload['salesId'] as String? ?? HopkidSalesConstants.zeroGuid;

          Map<String, dynamic> result;

          if (type == 'AddSale') {
            final amt = (payload['saleAmount'] as num).toDouble();
            final dto = AddSalesDto.minimal(
              invoiceNo: invoiceNo,
              salesmanGuid: salesmanGuid,
              grossAmount: amt,
              netAmount: amt,
            );
            result = await SalesService.addSales(dto);
          } else if (type == 'UpdateSale') {
            final amt = (payload['saleAmount'] as num).toDouble();
            final addDto = AddSalesDto.minimal(
              invoiceNo: invoiceNo,
              salesmanGuid: salesmanGuid,
              grossAmount: amt,
              netAmount: amt,
            );
            final dto = UpdateSalesDto.fromAdd(addDto, salesId);
            result = await SalesService.updateSales(dto);
          } else if (type == 'CreditNote') {
            final amt = (payload['creditAmount'] as num).toDouble();
            final dto = AddCreditNoteDto(
              SalesID: salesId,
              CNNo: invoiceNo.startsWith('CN-') ? invoiceNo : 'CN-$invoiceNo',
              CNAmount: amt,
              Salesman: salesmanGuid,
              CreditNoteProducts: [
                HopkidSalesProductItem.minimal(
                  salesmanGuid: salesmanGuid,
                  qty: 1.0,
                  price: amt,
                  total: amt,
                ),
              ],
            );
            result = await SalesService.addCreditNote(dto);
          } else if (type == 'Exchange') {
            final returnAmt = (payload['returnAmount'] as num).toDouble();
            final newAmt = (payload['newSaleAmount'] as num).toDouble();
            final dto = AddSalesExchangeDto(
              SalesID: salesId,
              ExchangeInvoiceNo: invoiceNo.startsWith('EX-')
                  ? invoiceNo
                  : 'EX-$invoiceNo',
              SalesExchangeProductList: [
                HopkidSalesProductItem.minimal(
                  salesmanGuid: salesmanGuid,
                  qty: 1.0,
                  price: returnAmt,
                  total: returnAmt,
                  isOld: true,
                ),
                HopkidSalesProductItem.minimal(
                  salesmanGuid: salesmanGuid,
                  qty: 1.0,
                  price: newAmt,
                  total: newAmt,
                  isOld: false,
                ),
              ],
            );
            result = await SalesService.addSalesExchange(dto);
          } else {
            result = await SalesService.submitTransaction(
              endpoint: '/api/Sales/AddSales',
              payload: payload,
            );
          }

          if (mounted) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Transaction processed'),
                backgroundColor: result['success'] == true
                    ? (result['offline'] == true
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

    if (!isSalesman) {
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
        ),
        body: _buildSalaryTab(user),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: 'Salary & Advance'),
              Tab(text: 'Commission & Sales'),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildSalaryTab(user), _buildCommissionTab()],
        ),
      ),
    );
  }

  Widget _buildCommissionTab() {
    final netSales = _commissionData.fold<double>(
      0.0,
      (sum, item) => sum + ((item['netSales'] as num?)?.toDouble() ?? 0.0),
    );
    final commissionEarned = _commissionData.fold<double>(
      0.0,
      (sum, item) => sum + ((item['commissionAmount'] as num?)?.toDouble() ?? 0.0),
    );

    return RefreshIndicator(
      onRefresh: () async {
        await _fetchCommissionReport();
        await SalesService.syncOfflineQueue();
      },
      child: Column(
        children: [
          // Filter bar + Add Sale button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                // Add Sale prominent button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showSalesActionSheet(context),
                    icon: const Icon(
                      RemixIcons.add_circle_fill,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Add Sale',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 3,
                      shadowColor: AppColors.primary.withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Period Filter: Day | Week | Month
                Row(
                  children: [
                    _PeriodFilterChip(
                      label: 'Day',
                      isSelected: _groupBy == 'day',
                      onTap: () => _selectPeriodFilter('day'),
                    ),
                    const SizedBox(width: 8),
                    _PeriodFilterChip(
                      label: 'Week',
                      isSelected: _groupBy == 'week',
                      onTap: () => _selectPeriodFilter('week'),
                    ),
                    const SizedBox(width: 8),
                    _PeriodFilterChip(
                      label: 'Month',
                      isSelected: _groupBy == 'month',
                      onTap: () => _selectPeriodFilter('month'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
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

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showPeriodSalesBottomSheet(context, item),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
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
                                    Row(
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
                                        const SizedBox(width: 6),
                                        Icon(
                                          RemixIcons.arrow_right_s_line,
                                          size: 16,
                                          color: AppColors.textHint,
                                        ),
                                      ],
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
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showPeriodSalesBottomSheet(BuildContext context, Map<String, dynamic> item) {
    final startStr = item['periodStart']?.toString() ?? '';
    final endStr = item['periodEnd']?.toString() ?? startStr;
    
    final displayPeriod = startStr == endStr
        ? DateFormat('dd MMMM yyyy').format(DateTime.parse(startStr))
        : '${DateFormat('dd MMM').format(DateTime.parse(startStr))} - ${DateFormat('dd MMM yyyy').format(DateTime.parse(endStr))}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textHint.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayPeriod,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Individual Sales & Commission Invoices',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(RemixIcons.close_line, color: AppColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              // Period Stats Header Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Net Sales', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            const SizedBox(height: 2),
                            Text(
                              '₹${NumberFormat('#,##,###.00').format((item['netSales'] as num?)?.toDouble() ?? 0.0)}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 30, color: AppColors.divider),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Commission Earned', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                              '₹${NumberFormat('#,##,###.00').format((item['commissionAmount'] as num?)?.toDouble() ?? 0.0)}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Transactions list
              Expanded(
                child: FutureBuilder<Map<String, dynamic>?>(
                  key: ValueKey(_refreshKey),
                  future: MobileCommissionService.getCommissionTransactions(
                    startDate: startStr,
                    endDate: endStr,
                    limit: 100,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: AppColors.primary));
                    }
                    final rawList = snapshot.data?['data']?['transactions'] as List?;
                    if (rawList == null || rawList.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(RemixIcons.receipt_line, size: 40, color: AppColors.textHint),
                            const SizedBox(height: 8),
                            Text('No invoices recorded for this period', style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      );
                    }

                    // Strict local device IST date filter
                    final startDay = startStr.split('T')[0];
                    final endDay = endStr.split('T')[0];
                    final filteredList = rawList.where((tx) {
                      final dateStr = tx['createdAt'] ?? tx['date'];
                      if (dateStr == null) return true;
                      final txDateLocal = DateTime.parse(dateStr.toString()).toLocal();
                      final txDayStr = DateFormat('yyyy-MM-dd').format(txDateLocal);
                      if (startDay == endDay) {
                        return txDayStr == startDay;
                      }
                      return txDayStr.compareTo(startDay) >= 0 && txDayStr.compareTo(endDay) <= 0;
                    }).toList();

                    if (filteredList.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(RemixIcons.receipt_line, size: 40, color: AppColors.textHint),
                            const SizedBox(height: 8),
                            Text('No invoices recorded for this period', style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredList.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, idx) {
                        final tx = filteredList[idx];
                        final billId = tx['billId'] ?? tx['invoiceNumber'] ?? 'TXN-${tx['id']}';
                        final amount = (tx['saleAmount'] ?? tx['amount'] ?? 0.0).toDouble();
                        final comm = (tx['commissionAmount'] ?? tx['commission'] ?? 0.0).toDouble();
                        final rate = (tx['commissionPercent'] ?? 0.0).toDouble();
                        final status = (tx['status'] ?? 'APPROVED').toString();
                        final dateStr = tx['createdAt'] ?? tx['date'];
                        final formattedDate = dateStr != null
                            ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(dateStr.toString()))
                            : '';

                        final isPaid = status.toUpperCase() == 'PAID';

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CommissionDetailScreen(billId: billId),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.cardBorder, width: 1),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: (isPaid ? AppColors.success : AppColors.primary).withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      RemixIcons.file_list_3_line,
                                      color: isPaid ? AppColors.success : AppColors.primary,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          billId,
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Net Sale: ₹${NumberFormat('#,##,###.00').format(amount)}',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (formattedDate.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            formattedDate,
                                            style: TextStyle(
                                              color: AppColors.textHint,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₹${NumberFormat('#,##,###.00').format(comm)}',
                                        style: TextStyle(
                                          color: isPaid ? AppColors.success : AppColors.primary,
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '($rate%)',
                                        style: TextStyle(
                                          color: AppColors.textHint,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSalaryTab(UserModel user) {
    return PermissionProtectedWidget(
      user: user,
      permission: PermissionService.canViewSalary,
      moduleName: 'Salary & Payroll Details',
      child: _buildSalaryTabContent(user),
    );
  }

  Widget _buildSalaryTabContent(UserModel user) {
    final isSalesman = PermissionService.canViewCommissionWidget(user);
    final expenseState = ref.watch(expenseViewModelProvider);
    final walletPending =
        (_advanceData?['pendingClaims'] as num?)?.toDouble() ?? 0.0;
    final pendingClaims = walletPending > 0
        ? walletPending
        : expenseState.totalPending;
    final phoneStr = user.phone.toString();
    final phoneLast4 = phoneStr.length >= 4
        ? phoneStr.substring(phoneStr.length - 4)
        : phoneStr;

    return RefreshIndicator(
      onRefresh: () async {
        await _loadWalletData();
        await ref.read(expenseViewModelProvider.notifier).fetchExpenses();
        if (!isSalesman) {
          await _fetchPayslips();
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).padding.bottom + 110,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Green Wallet Card
            Container(
              width: double.infinity,
              height: 215,
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
                      padding: const EdgeInsets.all(20),
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
                                  const SizedBox(height: 4),
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
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NET SALARY',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₹${NumberFormat('#,##,###').format(_getCardNetSalary())}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'GROSS SALARY',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.65,
                                      ),
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    '₹${NumberFormat('#,##,###').format(_getCardGrossSalary())}',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.95,
                                      ),
                                      fontSize: 12,
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
                      mainAxisSize: MainAxisSize.min,
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
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EmployeeExpensesView(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
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
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: RemixIcons.hand_coin_line,
                    label: 'Request\nAdvance',
                    color: const Color(0xFF8B5CF6),
                    onTap: () => _showRequestAdvanceSheet(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionButton(
                    icon: RemixIcons.coupon_line,
                    label: 'Claim\nExpense',
                    color: const Color(0xFFF59E0B),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EmployeeExpensesView(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: RemixIcons.file_text_line,
                    label: 'Payslips &\nPayroll',
                    color: const Color(0xFF10B981),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EmployeePayrollView(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionButton(
                    icon: RemixIcons.bank_line,
                    label: 'Bank\nDetails',
                    color: const Color(0xFF3B82F6),
                    onTap: () => _showBankDetailsSheet(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Salary Slip Breakdown Card
            _buildSalarySlipBreakdownCard(),
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
          ],
        ),
      ),
    );
  }

  Widget _buildSalaryDetailRow(
    String label,
    String value, {
    IconData? icon,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                      color: isBold
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 13 : 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  bool _isEarningsExpanded = true;
  bool _isDeductionsExpanded = true;
  bool _isAttendanceExpanded = true;

  Widget _buildSalarySlipBreakdownCard() {
    final user = ref.watch(authViewModelProvider).currentUser;
    final earnings = (_salarySlipData?['earnings'] as Map<String, dynamic>?) ?? {};
    final deductions = (_salarySlipData?['deductions'] as Map<String, dynamic>?) ?? {};
    final details = (_salarySlipData?['details'] as Map<String, dynamic>?) ?? {};

    final canShowComm = (earnings['canViewCommission'] as bool?) ?? PermissionService.canViewCommissionWidget(user);

    final baseSalary = (earnings['baseSalary'] as num?)?.toDouble() ??
                       (earnings['basicSalary'] as num?)?.toDouble() ??
                       (_salarySlipData?['base_salary'] as num?)?.toDouble() ?? 0.0;
    final commission = canShowComm
        ? ((earnings['commission'] as num?)?.toDouble() ?? (_salarySlipData?['commission_amount'] as num?)?.toDouble() ?? 0.0)
        : 0.0;
    final hra = (earnings['hra'] as num?)?.toDouble() ?? 0.0;
    final medical = (earnings['medical'] as num?)?.toDouble() ?? 0.0;
    final travel = (earnings['travel'] as num?)?.toDouble() ?? 0.0;
    final special = (earnings['special'] as num?)?.toDouble() ?? 0.0;
    final otherBenefits = (earnings['otherBenefits'] as num?)?.toDouble() ?? (hra + medical + travel + special);
    final calcGross = (earnings['grossTotal'] as num?)?.toDouble() ??
                      (_salarySlipData?['grossSalary'] as num?)?.toDouble() ??
                      (baseSalary + otherBenefits);
    final grossSalary = (calcGross == 0.0 && baseSalary > 0.0) ? baseSalary : calcGross;

    final halfDayDeduction = (deductions['halfDayDeduction'] as num?)?.toDouble() ?? 0.0;
    final leaveDeduction = (deductions['leaveDeduction'] as num?)?.toDouble() ?? 0.0;
    final totalDeductions = (deductions['totalDeductions'] as num?)?.toDouble() ?? (halfDayDeduction + leaveDeduction);

    final netSalary = (_salarySlipData?['netSalary'] as num?)?.toDouble() ?? (grossSalary - totalDeductions);

    final presentDays = (details['presentDays'] as num?)?.toInt() ?? 20;
    final halfDays = (details['halfDays'] as num?)?.toInt() ?? 2;
    final leaveDays = (details['leaveDays'] as num?)?.toInt() ?? 3;
    final int rawWorkingDays = (details['workingDays'] as num?)?.toInt() ?? 25;
    final workingDays = rawWorkingDays > 0 ? rawWorkingDays : 25;

    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final currentMonthName = monthNames[(_salarySlipMonth - 1) % 12];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Selector Header: [◄ Month Year ►]
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 22, color: AppColors.primary),
                  onPressed: () {
                    setState(() {
                      if (_salarySlipMonth == 1) {
                        _salarySlipMonth = 12;
                        _salarySlipYear--;
                      } else {
                        _salarySlipMonth--;
                      }
                    });
                    _fetchSalarySlip();
                  },
                ),
                Expanded(
                  child: Text(
                    '${currentMonthName.toUpperCase()} $_salarySlipYear SALARY',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.5,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 22, color: AppColors.primary),
                  onPressed: () {
                    setState(() {
                      if (_salarySlipMonth == 12) {
                        _salarySlipMonth = 1;
                        _salarySlipYear++;
                      } else {
                        _salarySlipMonth++;
                      }
                    });
                    _fetchSalarySlip();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_isLoadingSalarySlip)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            // ── EARNINGS SECTION (Expandable) ───────────────────
            InkWell(
              onTap: () => setState(() => _isEarningsExpanded = !_isEarningsExpanded),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.arrow_upward, color: Colors.green, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'EARNINGS',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green),
                        ),
                      ],
                    ),
                    Icon(
                      _isEarningsExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ),
            if (_isEarningsExpanded) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  children: [
                    _buildSalaryDetailRow('Base Salary', '₹${NumberFormat('#,##,###').format(baseSalary)}'),
                    if (canShowComm)
                      _buildSalaryDetailRow('Commission', '₹${NumberFormat('#,##,###').format(commission)}', valueColor: Colors.green),
                    _buildSalaryDetailRow('Other Benefits', '₹${NumberFormat('#,##,###').format(otherBenefits)}'),
                    const Divider(height: 12),
                    _buildSalaryDetailRow('GROSS TOTAL', '₹${NumberFormat('#,##,###').format(grossSalary)}', isBold: true, valueColor: Colors.green),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),

            // ── DEDUCTIONS SECTION (Expandable) ─────────────────
            InkWell(
              onTap: () => setState(() => _isDeductionsExpanded = !_isDeductionsExpanded),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.arrow_downward, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'DEDUCTIONS',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red),
                        ),
                      ],
                    ),
                    Icon(
                      _isDeductionsExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
            if (_isDeductionsExpanded) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  children: [
                    _buildSalaryDetailRow('Half Days ($halfDays × ₹${(baseSalary / workingDays / 2).round()})', '₹(${NumberFormat('#,##,###').format(halfDayDeduction)})', valueColor: Colors.red),
                    _buildSalaryDetailRow('Leaves ($leaveDays × ₹${(baseSalary / workingDays).round()})', '₹(${NumberFormat('#,##,###').format(leaveDeduction)})', valueColor: Colors.red),
                    const Divider(height: 12),
                    _buildSalaryDetailRow('TOTAL DEDUCTIONS', '₹(${NumberFormat('#,##,###').format(totalDeductions)})', isBold: true, valueColor: Colors.red),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),

            // ── ATTENDANCE SECTION (Expandable) ────────────────
            InkWell(
              onTap: () => setState(() => _isAttendanceExpanded = !_isAttendanceExpanded),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.blue, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'ATTENDANCE',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue),
                        ),
                      ],
                    ),
                    Icon(
                      _isAttendanceExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
            if (_isAttendanceExpanded) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  children: [
                    _buildSalaryDetailRow('Present Days', '$presentDays Days', valueColor: Colors.green),
                    _buildSalaryDetailRow('Half Days', '$halfDays Days', valueColor: Colors.orange),
                    _buildSalaryDetailRow('Leaves', '$leaveDays Days', valueColor: Colors.red),
                    _buildSalaryDetailRow('Working Days', '$workingDays Days'),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),

            // ── NET SALARY PAYABLE BANNER ────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.85)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NET SALARY PAYABLE',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white70, letterSpacing: 0.5),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Gross - Total Deductions',
                        style: TextStyle(fontSize: 10, color: Colors.white54),
                      ),
                    ],
                  ),
                  Text(
                    '₹${NumberFormat('#,##,###').format(netSalary)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Download PDF Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _downloadCurrentSalarySlip,
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text('Download Official PDF Salary Slip'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _downloadCurrentSalarySlip() async {
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final currentMonthName = monthNames[(_salarySlipMonth - 1) % 12];
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      SnackBar(content: Text('Downloading Salary Slip PDF for $currentMonthName $_salarySlipYear...')),
    );

    final matchingSlip = _payslips.firstWhere(
      (s) => s['month'] == _salarySlipMonth && s['year'] == _salarySlipYear,
      orElse: () => null,
    );

    if (matchingSlip != null && matchingSlip['id'] != null) {
      await _downloadPayslip((matchingSlip['id'] as num).toInt());
    } else {
      final success = await ref
          .read(employeePayrollViewModelProvider.notifier)
          .downloadPayslipByMonthYear(_salarySlipMonth, _salarySlipYear);
      if (!success && mounted) {
        final errorMsg = ref.read(employeePayrollViewModelProvider).errorMessage;
        messenger.showSnackBar(
          SnackBar(
            content: Text(errorMsg ?? 'Failed to download payslip PDF.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
    return Material(
      color: Colors.transparent,
      child: ListTile(
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    _amountCtrl.text = _amount == 0.0
        ? ''
        : NumberFormat('#,##,###').format(_amount);
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

      final formatted = _amount == 0
          ? ''
          : NumberFormat('#,##,###').format(_amount);
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
      final formatted = _amount == 0
          ? ''
          : NumberFormat('#,##,###').format(_amount);
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
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
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
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
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
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
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
                    borderSide: const BorderSide(
                      color: Color(0xFF9333EA),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Custom Slider with Dotted Snapping Tick Marks
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF9333EA),
                inactiveTrackColor: const Color(
                  0xFF9333EA,
                ).withValues(alpha: 0.15),
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
                          color: isSel
                              ? const Color(0xFF9333EA)
                              : const Color(0xFFE2E8F0),
                          width: isSel ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$m ${m == 1 ? 'Month' : 'Months'}',
                            style: TextStyle(
                              color: isSel
                                  ? const Color(0xFF9333EA)
                                  : const Color(0xFF1E293B),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'EMI Payback',
                            style: TextStyle(
                              color: isSel
                                  ? const Color(
                                      0xFF9333EA,
                                    ).withValues(alpha: 0.7)
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
                  hintStyle: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 14,
                  ),
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
                    borderSide: const BorderSide(
                      color: Color(0xFF9333EA),
                      width: 1.5,
                    ),
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
      ),
    );
  }
}

class _SalesTransactionFormSheet extends StatefulWidget {
  final String type;
  final List<dynamic> stores;
  final String? preselectedStoreId;
  final String? preselectedStoreName;
  final Function(Map<String, dynamic> payload) onSubmit;

  const _SalesTransactionFormSheet({
    required this.type,
    required this.stores,
    this.preselectedStoreId,
    this.preselectedStoreName,
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
  void initState() {
    super.initState();
    // Pre-select the employee's allotted store
    if (widget.preselectedStoreId != null) {
      _selectedStoreId = widget.preselectedStoreId;
    }
  }

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

    final effectiveStoreId = _selectedStoreId ?? widget.preselectedStoreId ?? widget.preselectedStoreName;
    if (effectiveStoreId == null || effectiveStoreId.isEmpty) {
      setState(() => _error = 'Please select a store or contact HR.');
      return;
    }

    final Map<String, dynamic> payload = {
      'invoiceNumber': invoice,
      'billId': invoice,
      'notes': _notesCtrl.text.trim(),
      'storeId': effectiveStoreId,
    };

    if (widget.type == 'AddSale' || widget.type == 'UpdateSale') {
      payload['saleAmount'] = amt;
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

    final hasPreselectedStore =
        widget.preselectedStoreId != null &&
        widget.preselectedStoreName != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).viewInsets.bottom + 24,
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                // Store badge — always visible in header
                if (hasPreselectedStore)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          RemixIcons.store_2_line,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          widget.preselectedStoreName!,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
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
            // Store dropdown — shown only if employee has NO pre-assigned store
            if (!hasPreselectedStore) ...[
              DropdownButtonFormField<String>(
                initialValue:
                    widget.stores.any(
                      (s) => s['id'].toString() == _selectedStoreId,
                    )
                    ? _selectedStoreId
                    : null,
                hint: const Text('Select Store'),
                decoration: const InputDecoration(
                  labelText: 'Store',
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
      ),
    );
  }
}

class _BankDetailsSheet extends StatelessWidget {
  final Map<String, dynamic>? bankDetails;
  final String userName;
  final VoidCallback onEditPressed;

  const _BankDetailsSheet({
    required this.bankDetails,
    required this.userName,
    required this.onEditPressed,
  });

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
                  'Linked Bank Account',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    RemixIcons.edit_line,
                    color: AppColors.primary,
                  ),
                  tooltip: 'Edit Bank Details',
                  onPressed: () {
                    Navigator.pop(context);
                    onEditPressed();
                  },
                ),
              ],
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

class _PeriodFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

