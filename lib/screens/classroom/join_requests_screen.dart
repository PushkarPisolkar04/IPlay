import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/join_request_service.dart';
import '../../core/models/join_request_model.dart';
import '../../providers/auth_provider.dart';
import 'package:intl/intl.dart';

class JoinRequestsScreen extends StatefulWidget {
  final String classroomId;
  final String classroomName;

  const JoinRequestsScreen({
    super.key,
    required this.classroomId,
    this.classroomName = '',
  });

  @override
  State<JoinRequestsScreen> createState() => _JoinRequestsScreenState();
}

class _JoinRequestsScreenState extends State<JoinRequestsScreen> {
  final JoinRequestService _requestService = JoinRequestService();
  
  List<JoinRequestModel> _pendingRequests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final requests = await _requestService.getPendingRequests(
        widget.classroomId,
      );
      
      setState(() {
        _pendingRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _approveRequest(JoinRequestModel request) async {
    try {
      final teacherId = Provider.of<AuthProvider>(context, listen: false).currentUser!.uid;
      
      await _requestService.approveRequest(
        requestId: request.id,
        teacherId: teacherId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${request.studentName} approved!')),
      );

      _loadRequests(); // Reload list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving request: $e')),
      );
    }
  }

  Future<void> _rejectRequest(JoinRequestModel request) async {
    // Show confirmation dialog with optional reason
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _RejectDialog(),
    );

    if (result == null) return; // User cancelled

    try {
      final teacherId = Provider.of<AuthProvider>(context, listen: false).currentUser!.uid;
      
      await _requestService.rejectRequest(
        requestId: request.id,
        teacherId: teacherId,
        reason: result.isEmpty ? null : result,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected')),
      );

      _loadRequests(); // Reload list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting request: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Join Requests'),
            Text(
              widget.classroomName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: AppDesignSystem.primaryIndigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _pendingRequests.isEmpty
                  ? _buildEmptyState()
                  : _buildRequestsList(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppDesignSystem.textSecondary),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadRequests,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 80,
              color: AppDesignSystem.textSecondary,
            ),
            const SizedBox(height: 24),
            Text(
              'No Pending Requests',
              style: AppTextStyles.h1,
            ),
            const SizedBox(height: 16),
            Text(
              'All join requests have been processed.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppDesignSystem.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _pendingRequests.length,
      itemBuilder: (context, index) {
        final request = _pendingRequests[index];
        return _RequestCard(
          request: request,
          onApprove: () => _approveRequest(request),
          onReject: () => _rejectRequest(request),
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  final JoinRequestModel request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  backgroundColor: AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
                  child: Text(
                    request.studentName[0].toUpperCase(),
                    style: AppTextStyles.h3.copyWith(color: AppDesignSystem.primaryIndigo),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Student info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.studentName,
                        style: AppTextStyles.h3,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Requested ${DateFormat('MMM dd, yyyy').format(request.requestedAt)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppDesignSystem.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppDesignSystem.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.cancel, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppDesignSystem.error,
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

class _RejectDialog extends StatefulWidget {
  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject Request'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Are you sure you want to reject this request?'),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            maxLength: 200,
            decoration: const InputDecoration(
              hintText: 'Reason for rejection (optional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, _reasonController.text.trim());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppDesignSystem.error,
            foregroundColor: Colors.white,
          ),
          child: const Text('Reject'),
        ),
      ],
    );
  }
}

