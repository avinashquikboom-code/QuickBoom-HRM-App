import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_url.dart';
import '../../../../core/services/storage_service.dart';

class CompanyPoliciesView extends StatefulWidget {
  const CompanyPoliciesView({super.key});

  @override
  State<CompanyPoliciesView> createState() => _CompanyPoliciesViewState();
}

class _CompanyPoliciesViewState extends State<CompanyPoliciesView> {
  String _selectedCategory = 'ALL';
  String _searchQuery = '';
  bool _isLoading = true;
  List<dynamic> _policies = [];
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _categories = [
    {'label': 'All Policies', 'value': 'ALL'},
    {'label': 'Attendance', 'value': 'ATTENDANCE'},
    {'label': 'Leaves', 'value': 'LEAVE'},
    {'label': 'Deductions', 'value': 'DEDUCTION'},
    {'label': 'Code of Conduct', 'value': 'CONDUCT'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchPolicies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPolicies() async {
    setState(() => _isLoading = true);
    try {
      final token = await StorageService.getToken();
      String url = '${AppUrl.baseUrl}/api/mobile/policies?type=$_selectedCategory';
      if (_searchQuery.trim().isNotEmpty) {
        url += '&search=${Uri.encodeComponent(_searchQuery.trim())}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _policies = data['policies'] ?? [];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching policies: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'ATTENDANCE':
        return Colors.blue;
      case 'LEAVE':
        return Colors.green;
      case 'DEDUCTION':
        return Colors.amber;
      case 'CONDUCT':
        return Colors.purple;
      default:
        return AppColors.primary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toUpperCase()) {
      case 'ATTENDANCE':
        return Icons.access_time_filled;
      case 'LEAVE':
        return Icons.event_available;
      case 'DEDUCTION':
        return Icons.account_balance_wallet;
      case 'CONDUCT':
        return Icons.gavel;
      default:
        return Icons.article;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Policies'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar & Filter Section
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                // Search TextField
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() => _searchQuery = val);
                    _fetchPolicies();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search policy title or keywords...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              _fetchPolicies();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Category Chips Bar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat['value'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(cat['label']!),
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primary : Colors.grey.shade700,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = cat['value']!;
                            });
                            _fetchPolicies();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Policy List Body with RefreshIndicator
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchPolicies,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _policies.isEmpty
                      ? LayoutBuilder(
                          builder: (context, constraints) => SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minHeight: constraints.maxHeight),
                              child: const Center(
                                child: Text(
                                  'No policies found matching criteria.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _policies.length,
                          itemBuilder: (context, index) {
                            final policy = _policies[index];
                            final catColor = _getCategoryColor(policy['category'] ?? '');
                            final effectiveStr = policy['effectiveDate'] != null
                                ? DateFormat('MMM dd, yyyy').format(DateTime.parse(policy['effectiveDate']))
                                : 'Immediate';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12.0),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                              child: ExpansionTile(
                                shape: const Border(),
                                collapsedShape: const Border(),
                                leading: CircleAvatar(
                                  backgroundColor: catColor.withValues(alpha: 0.15),
                                  child: Icon(
                                    _getCategoryIcon(policy['category'] ?? ''),
                                    color: catColor,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  policy['title'] ?? 'Company Policy',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: catColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          policy['category'] ?? 'GENERAL',
                                          style: TextStyle(color: catColor, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Text(
                                        'Effective: $effectiveStr',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          policy['description'] ?? '',
                                          style: const TextStyle(
                                            fontStyle: FontStyle.italic,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        const Divider(),
                                        const SizedBox(height: 8),
                                        Text(
                                          policy['content'] ?? '',
                                          style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
                                        ),
                                        if (policy['documentUrl'] != null && policy['documentUrl'].toString().isNotEmpty) ...[
                                          const SizedBox(height: 14),
                                          ElevatedButton.icon(
                                            onPressed: () async {
                                              final urlStr = policy['documentUrl'].toString();
                                              final uri = Uri.parse(urlStr);
                                              if (await canLaunchUrl(uri)) {
                                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                                              } else {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Could not open document: $urlStr')),
                                                  );
                                                }
                                              }
                                            },
                                            icon: const Icon(Icons.picture_as_pdf, size: 16),
                                            label: const Text('Download Official PDF Policy'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

