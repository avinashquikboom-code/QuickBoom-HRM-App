import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TestHrLeaveApprovalView extends ConsumerStatefulWidget {
  const TestHrLeaveApprovalView({super.key});

  @override
  ConsumerState<TestHrLeaveApprovalView> createState() =>
      _TestHrLeaveApprovalViewState();
}

class _TestHrLeaveApprovalViewState extends ConsumerState<TestHrLeaveApprovalView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test'),
        actions: [
          IconButton(
            onPressed: () => _downloadLeaveReport(),
            icon: const Icon(Icons.download),
          ),
        ],
      ),
      body: const Center(child: Text('Test')),
    );
  }

  Future<void> _downloadLeaveReport() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading leave report...')),
      );
      
      // Test the method works
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave report downloaded successfully!')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download report')),
        );
      }
    }
  }
}
