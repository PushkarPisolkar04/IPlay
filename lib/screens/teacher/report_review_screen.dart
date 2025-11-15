import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/design/app_design_system.dart';
import '../../widgets/app_button.dart';
import '../../widgets/loading_skeleton.dart';
import '../../utils/content_moderator.dart';
import '../../core/services/notification_service.dart';

/// Report Review Screen for Teachers and Principals
/// Implements requirement 59: Content Moderation and Safety
/// Allows teachers/principals to review reported and flagged content
class ReportReviewScreen extends StatefulWidget {
  const ReportReviewScreen({super.key});

  @override
  State<ReportReviewScreen> createState() => _ReportReviewScreenState();
}

class _ReportReviewScreenState extends State<ReportReviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  
  String? _userSchoolId;
  bool _isPrincipal = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserInfo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      if (userData != null) {
        setState(() {
          _userSchoolId = userData['schoolId'] as String?;
          _isPrincipal = userData['isPrincipal'] as bool? ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      // print('Error loading user info: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Content Review'),
        ),
        body: const SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: ListSkeleton(itemCount: 5),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('Content Review'),
        backgroundColor: AppDesignSystem.backgroundWhite,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppDesignSystem.primaryIndigo,
          unselectedLabelColor: AppDesignSystem.textSecondary,
          indicatorColor: AppDesignSystem.primaryIndigo,
          tabs: const [
            Tab(
              icon: Icon(Icons.report),
              text: 'User Reports',
            ),
            Tab(
              icon: Icon(Icons.flag),
              text: 'Auto-Flagged',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserReportsTab(),
          _buildFlaggedContentTab(),
        ],
      ),
    );
  }

  Widget _buildUserReportsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: ContentModerator.getPendingReportsStream(
        schoolId: _userSchoolId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorWidget('Error loading reports: ${snapshot.error}');
        }

        final reports = snapshot.data?.docs ?? [];

        if (reports.isEmpty) {
          return _buildEmptyState(
            icon: Icons.check_circle_outline,
            title: 'No Pending Reports',
            message: 'All user reports have been reviewed.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(AppDesignSystem.spacingMD),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              final data = report.data() as Map<String, dynamic>;
              return _buildReportCard(report.id, data, isUserReport: true);
            },
          ),
        );
      },
    );
  }

  Widget _buildFlaggedContentTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: ContentModerator.getFlaggedContentStream(
        schoolId: _userSchoolId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorWidget('Error loading flagged content: ${snapshot.error}');
        }

        final flaggedItems = snapshot.data?.docs ?? [];

        if (flaggedItems.isEmpty) {
          return _buildEmptyState(
            icon: Icons.verified_user,
            title: 'No Flagged Content',
            message: 'No content has been automatically flagged.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(AppDesignSystem.spacingMD),
            itemCount: flaggedItems.length,
            itemBuilder: (context, index) {
              final item = flaggedItems[index];
              final data = item.data() as Map<String, dynamic>;
              return _buildReportCard(item.id, data, isUserReport: false);
            },
          ),
        );
      },
    );
  }

  Widget _buildReportCard(String id, Map<String, dynamic> data, {required bool isUserReport}) {
    final contentType = data['contentType'] as String? ?? 'Unknown';
    final content = data['content'] as String? ?? '';
    final reason = data['reason'] as String? ?? 'No reason provided';
    final creatorId = data['creatorId'] as String? ?? '';
    final timestamp = isUserReport
        ? (data['reportedAt'] as Timestamp?)
        : (data['flaggedAt'] as Timestamp?);
    final reporterId = isUserReport ? (data['reporterId'] as String?) : null;

    return Card(
      margin: const EdgeInsets.only(bottom: AppDesignSystem.spacingMD),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: AppDesignSystem.borderRadiusMD,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDesignSystem.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDesignSystem.spacingSM,
                    vertical: AppDesignSystem.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: _getContentTypeColor(contentType).withValues(alpha: 0.1),
                    borderRadius: AppDesignSystem.borderRadiusSM,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getContentTypeIcon(contentType),
                        size: 16,
                        color: _getContentTypeColor(contentType),
                      ),
                      const SizedBox(width: AppDesignSystem.spacingXS),
                      Text(
                        contentType.toUpperCase(),
                        style: AppDesignSystem.caption.copyWith(
                          color: _getContentTypeColor(contentType),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (timestamp != null)
                  Text(
                    _formatTimestamp(timestamp),
                    style: AppDesignSystem.caption,
                  ),
              ],
            ),
            const SizedBox(height: AppDesignSystem.spacingMD),

            // Reason
            Container(
              padding: const EdgeInsets.all(AppDesignSystem.spacingSM),
              decoration: BoxDecoration(
                color: AppDesignSystem.warning.withValues(alpha: 0.1),
                borderRadius: AppDesignSystem.borderRadiusSM,
                border: Border.all(
                  color: AppDesignSystem.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    size: 16,
                    color: AppDesignSystem.warning,
                  ),
                  const SizedBox(width: AppDesignSystem.spacingSM),
                  Expanded(
                    child: Text(
                      reason,
                      style: AppDesignSystem.bodySmall.copyWith(
                        color: AppDesignSystem.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDesignSystem.spacingMD),

            // Content
            Text(
              'Content:',
              style: AppDesignSystem.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppDesignSystem.textSecondary,
              ),
            ),
            const SizedBox(height: AppDesignSystem.spacingXS),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDesignSystem.spacingMD),
              decoration: BoxDecoration(
                color: AppDesignSystem.backgroundGrey,
                borderRadius: AppDesignSystem.borderRadiusSM,
              ),
              child: Text(
                content,
                style: AppDesignSystem.bodyMedium,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: AppDesignSystem.spacingMD),

            // User info
            FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('users').doc(creatorId).get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final creatorData = snapshot.data?.data() as Map<String, dynamic>?;
                final creatorName = creatorData?['displayName'] as String? ?? 'Unknown User';
                final creatorRole = creatorData?['role'] as String? ?? 'unknown';

                return Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppDesignSystem.getRoleColor(creatorRole),
                      child: Text(
                        creatorName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDesignSystem.spacingSM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            creatorName,
                            style: AppDesignSystem.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Content Creator • ${creatorRole.toUpperCase()}',
                            style: AppDesignSystem.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            if (isUserReport && reporterId != null) ...[
              const SizedBox(height: AppDesignSystem.spacingSM),
              FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(reporterId).get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final reporterData = snapshot.data?.data() as Map<String, dynamic>?;
                  final reporterName = reporterData?['displayName'] as String? ?? 'Unknown User';

                  return Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 16,
                        color: AppDesignSystem.textSecondary,
                      ),
                      const SizedBox(width: AppDesignSystem.spacingSM),
                      Text(
                        'Reported by: $reporterName',
                        style: AppDesignSystem.caption,
                      ),
                    ],
                  );
                },
              ),
            ],

            const SizedBox(height: AppDesignSystem.spacingMD),
            const Divider(),
            const SizedBox(height: AppDesignSystem.spacingSM),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: AppButton.outline(
                    text: 'Approve',
                    icon: Icons.check,
                    onPressed: () => _handleApprove(id, data, isUserReport),
                  ),
                ),
                const SizedBox(width: AppDesignSystem.spacingSM),
                Expanded(
                  child: AppButton(
                    text: 'Reject',
                    icon: Icons.close,
                    onPressed: () => _handleReject(id, data, isUserReport),
                    type: AppButtonType.secondary,
                  ),
                ),
              ],
            ),

            // Escalate button for serious violations
            if (_isPrincipal) ...[
              const SizedBox(height: AppDesignSystem.spacingSM),
              SizedBox(
                width: double.infinity,
                child: AppButton.text(
                  text: 'Escalate to Admin',
                  icon: Icons.arrow_upward,
                  onPressed: () => _handleEscalate(id, data, isUserReport),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleApprove(String id, Map<String, dynamic> data, bool isUserReport) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Approve Content'),
          content: const Text(
            'Are you sure you want to approve this content? It will be marked as reviewed and allowed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Approve'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Update status
      final collection = isUserReport ? 'reports' : 'flagged_content';
      await _firestore.collection(collection).doc(id).update({
        'status': isUserReport ? 'resolved' : 'approved',
        'reviewedBy': user.uid,
        'reviewedAt': Timestamp.now(),
        'resolution': 'approved',
        'resolutionNotes': 'Content approved by reviewer',
      });

      // Unhide content if it was hidden
      final contentId = data['contentId'] as String?;
      final contentType = data['contentType'] as String?;
      if (contentId != null && contentType != null) {
        await _unhideContent(contentId, contentType);
      }

      // Notify content creator
      final creatorId = data['creatorId'] as String?;
      if (creatorId != null) {
        await _notificationService.sendToUser(
          userId: creatorId,
          title: 'Content Approved',
          body: 'Your ${contentType ?? 'content'} has been reviewed and approved.',
          data: {'type': 'content_approved'},
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Content approved successfully'),
            backgroundColor: AppDesignSystem.success,
          ),
        );
      }
    } catch (e) {
      // print('Error approving content: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppDesignSystem.error,
          ),
        );
      }
    }
  }

  Future<void> _handleReject(String id, Map<String, dynamic> data, bool isUserReport) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Show confirmation dialog with reason input
      String? rejectionReason;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          final controller = TextEditingController();
          return AlertDialog(
            title: const Text('Reject Content'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Are you sure you want to reject this content? The content will be removed or hidden.',
                ),
                const SizedBox(height: AppDesignSystem.spacingMD),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Reason for rejection',
                    hintText: 'Explain why this content is inappropriate',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) => rejectionReason = value,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppDesignSystem.error,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Reject'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) return;

      // Update status
      final collection = isUserReport ? 'reports' : 'flagged_content';
      await _firestore.collection(collection).doc(id).update({
        'status': isUserReport ? 'resolved' : 'rejected',
        'reviewedBy': user.uid,
        'reviewedAt': Timestamp.now(),
        'resolution': 'rejected',
        'resolutionNotes': rejectionReason ?? 'Content rejected by reviewer',
      });

      // Hide content
      final contentId = data['contentId'] as String?;
      final contentType = data['contentType'] as String?;
      if (contentId != null && contentType != null) {
        await _hideContent(contentId, contentType, rejectionReason ?? 'Inappropriate content');
      }

      // Notify content creator
      final creatorId = data['creatorId'] as String?;
      if (creatorId != null) {
        await _notificationService.sendToUser(
          userId: creatorId,
          title: 'Content Removed',
          body: 'Your ${contentType ?? 'content'} has been removed for violating community guidelines.',
          data: {'type': 'content_rejected'},
        );
      }

      // Check if user has multiple violations
      await _checkUserViolations(creatorId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Content rejected and removed'),
            backgroundColor: AppDesignSystem.error,
          ),
        );
      }
    } catch (e) {
      // print('Error rejecting content: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppDesignSystem.error,
          ),
        );
      }
    }
  }

  Future<void> _handleEscalate(String id, Map<String, dynamic> data, bool isUserReport) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Show confirmation dialog
      String? escalationNotes;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          final controller = TextEditingController();
          return AlertDialog(
            title: const Text('Escalate to Admin'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This will escalate the report to platform administrators for serious violations.',
                ),
                const SizedBox(height: AppDesignSystem.spacingMD),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Escalation notes',
                    hintText: 'Explain why this requires admin attention',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) => escalationNotes = value,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppDesignSystem.warning,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Escalate'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) return;

      // Update status to escalated
      final collection = isUserReport ? 'reports' : 'flagged_content';
      await _firestore.collection(collection).doc(id).update({
        'status': 'escalated',
        'escalatedBy': user.uid,
        'escalatedAt': Timestamp.now(),
        'escalationNotes': escalationNotes ?? 'Escalated for admin review',
      });

      // Create escalation record for admins
      await _firestore.collection('escalations').add({
        'reportId': id,
        'reportType': isUserReport ? 'user_report' : 'auto_flagged',
        'contentId': data['contentId'],
        'contentType': data['contentType'],
        'content': data['content'],
        'creatorId': data['creatorId'],
        'escalatedBy': user.uid,
        'escalatedAt': Timestamp.now(),
        'escalationNotes': escalationNotes,
        'status': 'pending',
        'schoolId': data['schoolId'],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report escalated to administrators'),
            backgroundColor: AppDesignSystem.warning,
          ),
        );
      }
    } catch (e) {
      // print('Error escalating report: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppDesignSystem.error,
          ),
        );
      }
    }
  }

  Future<void> _hideContent(String contentId, String contentType, String reason) async {
    try {
      String collection;
      switch (contentType) {
        case 'announcement':
          collection = 'announcements';
          break;
        case 'assignment':
          collection = 'assignments';
          break;
        case 'message':
          collection = 'messages';
          break;
        default:
          return;
      }

      await _firestore.collection(collection).doc(contentId).update({
        'hidden': true,
        'hiddenReason': reason,
        'hiddenAt': Timestamp.now(),
        'hiddenBy': FirebaseAuth.instance.currentUser?.uid,
      });
    } catch (e) {
      // print('Error hiding content: $e');
    }
  }

  Future<void> _unhideContent(String contentId, String contentType) async {
    try {
      String collection;
      switch (contentType) {
        case 'announcement':
          collection = 'announcements';
          break;
        case 'assignment':
          collection = 'assignments';
          break;
        case 'message':
          collection = 'messages';
          break;
        default:
          return;
      }

      await _firestore.collection(collection).doc(contentId).update({
        'hidden': false,
        'hiddenReason': null,
        'hiddenAt': null,
        'hiddenBy': null,
      });
    } catch (e) {
      // print('Error unhiding content: $e');
    }
  }

  Future<void> _checkUserViolations(String? userId) async {
    if (userId == null) return;

    try {
      // Count rejected reports for this user
      final rejectedReports = await _firestore
          .collection('reports')
          .where('creatorId', isEqualTo: userId)
          .where('resolution', isEqualTo: 'rejected')
          .get();

      final rejectedFlagged = await _firestore
          .collection('flagged_content')
          .where('creatorId', isEqualTo: userId)
          .where('status', isEqualTo: 'rejected')
          .get();

      final totalViolations = rejectedReports.docs.length + rejectedFlagged.docs.length;

      // If user has 3+ violations, restrict posting
      if (totalViolations >= 3) {
        await _firestore.collection('users').doc(userId).update({
          'postingRestricted': true,
          'restrictionReason': 'Multiple content violations',
          'restrictedAt': Timestamp.now(),
        });

        // Notify user
        await _notificationService.sendToUser(
          userId: userId,
          title: 'Posting Restricted',
          body: 'Your posting privileges have been temporarily restricted due to multiple violations.',
          data: {'type': 'posting_restricted'},
        );
      }
    } catch (e) {
      // print('Error checking user violations: $e');
    }
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesignSystem.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppDesignSystem.textTertiary,
            ),
            const SizedBox(height: AppDesignSystem.spacingMD),
            Text(
              title,
              style: AppDesignSystem.h4.copyWith(
                color: AppDesignSystem.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDesignSystem.spacingSM),
            Text(
              message,
              style: AppDesignSystem.bodyMedium.copyWith(
                color: AppDesignSystem.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesignSystem.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: AppDesignSystem.error,
            ),
            const SizedBox(height: AppDesignSystem.spacingMD),
            Text(
              'Error',
              style: AppDesignSystem.h4.copyWith(
                color: AppDesignSystem.error,
              ),
            ),
            const SizedBox(height: AppDesignSystem.spacingSM),
            Text(
              message,
              style: AppDesignSystem.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDesignSystem.spacingLG),
            AppButton.outline(
              text: 'Retry',
              icon: Icons.refresh,
              onPressed: () => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  Color _getContentTypeColor(String contentType) {
    switch (contentType.toLowerCase()) {
      case 'announcement':
        return AppDesignSystem.info;
      case 'assignment':
        return AppDesignSystem.primaryPink;
      case 'message':
        return AppDesignSystem.secondaryPurple;
      default:
        return AppDesignSystem.textSecondary;
    }
  }

  IconData _getContentTypeIcon(String contentType) {
    switch (contentType.toLowerCase()) {
      case 'announcement':
        return Icons.campaign;
      case 'assignment':
        return Icons.assignment;
      case 'message':
        return Icons.message;
      default:
        return Icons.description;
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
