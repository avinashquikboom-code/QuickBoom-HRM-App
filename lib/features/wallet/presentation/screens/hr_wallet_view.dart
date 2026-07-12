import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/core/constants/app_url.dart';
import 'package:quickboom_hrm/core/services/api_service.dart';
import 'package:quickboom_hrm/features/auth/data/models/user_model.dart';
import 'package:quickboom_hrm/features/employees/presentation/providers/employee_list_viewmodel.dart';

class HrWalletView extends ConsumerStatefulWidget {
  const HrWalletView({super.key});

  @override
  ConsumerState<HrWalletView> createState() => _HrWalletViewState();
}

class _HrWalletViewState extends ConsumerState<HrWalletView> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employeeState = ref.watch(employeeListViewModelProvider);
    final employeeNotifier = ref.read(employeeListViewModelProvider.notifier);

    // Apply local search filter in addition to VM's filters
    final filtered = employeeState.filteredEmployees.where((emp) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return emp.name.toLowerCase().contains(q) ||
          emp.employeeId.toLowerCase().contains(q) ||
          (emp.branchName?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          'Wallets & Commissions',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search employee by name, ID or branch...',
                prefixIcon: const Icon(RemixIcons.search_line),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(RemixIcons.close_line),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                isDense: true,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Branch Filter Chips ──────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _BranchChip(
                  label: 'All Branches',
                  isSelected: employeeState.selectedBranch == null,
                  onTap: () => employeeNotifier.filterByBranch(null),
                ),
                const SizedBox(width: 8),
                ...employeeState.branches.map(
                  (branch) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _BranchChip(
                      label: branch,
                      isSelected: employeeState.selectedBranch == branch,
                      onTap: () => employeeNotifier.filterByBranch(branch),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── Count Label ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              '${filtered.length} employees',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),

          // ─── Employees List ───────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(RemixIcons.group_line, size: 48, color: AppColors.textHint),
                        const SizedBox(height: 12),
                        Text(
                          'No employees found',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final emp = filtered[i];
                      return _HrEmployeeWalletCard(
                        employee: emp,
                        onTap: () => _showWalletDetailSheet(context, emp),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showWalletDetailSheet(BuildContext context, UserModel employee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HrWalletDetailBottomSheet(employee: employee),
    );
  }
}

class _BranchChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BranchChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.inputBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _HrEmployeeWalletCard extends StatelessWidget {
  final UserModel employee;
  final VoidCallback onTap;

  const _HrEmployeeWalletCard({
    required this.employee,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  employee.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${employee.branchName ?? 'No Branch'} · Code ${employee.employeeId}',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(RemixIcons.arrow_right_s_line, color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}

class _HrWalletDetailBottomSheet extends StatefulWidget {
  final UserModel employee;

  const _HrWalletDetailBottomSheet({required this.employee});

  @override
  State<_HrWalletDetailBottomSheet> createState() => _HrWalletDetailBottomSheetState();
}

class _HrWalletDetailBottomSheetState extends State<_HrWalletDetailBottomSheet> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<dynamic> _commissionData = [];
  bool _isLoadingComm = false;
  String _groupBy = 'day';
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchCommissionReport();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _fetchCommissionReport() async {
    setState(() => _isLoadingComm = true);
    try {
      final fromStr = DateFormat('yyyy-MM-dd').format(_fromDate);
      final toStr = DateFormat('yyyy-MM-dd').format(_toDate);
      final url = '${AppUrl.commissionReport}?employeeId=${widget.employee.id}&from=$fromStr&to=$toStr&groupBy=$_groupBy';
      
      final res = await ApiService.get(url);
      final body = jsonDecode(res.body);
      if (body['success'] == true) {
        setState(() {
          _commissionData = body['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching report: $e');
    } finally {
      setState(() => _isLoadingComm = false);
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
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
          // User Card Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    widget.employee.initials,
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.employee.name,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                      ),
                      Text(
                        '${widget.employee.branchName ?? 'No Branch'} · Code: ${widget.employee.employeeId}',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Tab bar
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Commission'),
              Tab(text: 'Salary'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCommissionTab(),
                _buildSalaryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionTab() {
    final netSales = _commissionData.fold<double>(0.0, (sum, item) => sum + (item['netSales'] as num).toDouble());
    final commissionEarned = _commissionData.fold<double>(0.0, (sum, item) => sum + (item['commissionAmount'] as num).toDouble());

    return Column(
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
                  DropdownMenuItem(value: 'day', child: Text('Daily', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'week', child: Text('Weekly', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'month', child: Text('Monthly', style: TextStyle(fontSize: 13))),
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
                      Text('Net Sales', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text('₹${NumberFormat('#,##,###').format(netSales)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
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
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Commission', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('₹${NumberFormat('#,##,###').format(commissionEarned)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
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
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(RemixIcons.bar_chart_box_line, size: 40, color: AppColors.textHint),
                          const SizedBox(height: 8),
                          Text('No report data found', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: _commissionData.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
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
                                        ? DateFormat('dd MMM yyyy').format(DateTime.parse(item['periodStart']))
                                        : '${DateFormat('dd MMM').format(DateTime.parse(item['periodStart']))} - ${DateFormat('dd MMM yyyy').format(DateTime.parse(item['periodEnd']))}',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Net Sales: ₹${NumberFormat('#,##,###').format(net)} (Rate: $rate%)',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                              Text(
                                '₹${NumberFormat('#,##,###').format(comm)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildSalaryTab() {
    final emp = widget.employee;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Salary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Monthly Salary', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  '₹${NumberFormat('#,##,###').format(emp.salary)}',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                if (emp.commissionPercentage != null && emp.commissionPercentage! > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Default Commission Rate: ${emp.commissionPercentage}%',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('BANK & ACCOUNT DETAILS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textSecondary, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          _DetailRow(label: 'Bank Name', value: emp.bankName ?? 'Not Configured'),
          _DetailRow(label: 'Account Number', value: emp.accountNumber ?? 'Not Configured'),
          _DetailRow(label: 'IFSC Code', value: emp.ifscCode ?? 'Not Configured'),
          _DetailRow(label: 'Account Type', value: emp.accountType ?? 'Not Configured'),
          _DetailRow(label: 'Branch Name', value: emp.branchName ?? 'Not Configured'),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(
            value,
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
