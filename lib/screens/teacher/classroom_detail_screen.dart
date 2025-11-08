import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_strings.dart';
import '../../models/classroom_model.dart';
import '../../widgets/clean_card.dart';
import '../leaderboard/unified_leaderboard_screen.dart';
import '../announcements/unified_announcements_screen.dart';
import '../classroom/join_requests_screen.dart';
import '../../core/services/join_request_service.dart';
import '../../core/services/notification_service.dart';

class ClassroomDetailScreen extends StatefulWidget {
  final ClassroomModel classroom;

  const ClassroomDetailScreen({super.key, required this.classroom});

  @override
  State<ClassroomDetailScreen> createState() => _ClassroomDetailScreenState();
}

class _ClassroomDetailScreenState extends State<ClassroomDetailScreen> {
  
  void _showQRCode(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Scan to Join Classroom',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.classroom.name,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppDesignSystem.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.2)),
                ),
                child: QrImageView(
                  data: widget.classroom.joinCode,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.classroom.joinCode,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: AppDesignSystem.primaryIndigo,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppDesignSystem.primaryIndigo,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareInviteLink(BuildContext context) {
    // Generate deep link for classroom
    final inviteLink = 'iplay://classroom/join/${widget.classroom.joinCode}?source=link';
    
    // Create shareable message
    final message = '''
Join my classroom on IPlay! 🎓

Classroom: ${widget.classroom.name}
Teacher: ${widget.classroom.teacherName}
${widget.classroom.school != null ? 'School: ${widget.classroom.school}\n' : ''}
Join Code: ${widget.classroom.joinCode}

Click the link to join instantly:
$inviteLink

Or enter the code manually in the IPlay app.
''';

    // Share the invite
    Share.share(
      message,
      subject: 'Join ${widget.classroom.name} on IPlay',
    );

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invite link ready to share!'),
        backgroundColor: AppDesignSystem.success,
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  Future<void> _editClassroom() async {
    // TODO: Navigate to edit classroom screen or show edit dialog
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _EditClassroomDialog(
        currentName: widget.classroom.name,
        currentGrade: widget.classroom.grade.toString(),
      ),
    );

    if (result != null) {
      try {
        await FirebaseFirestore.instance
            .collection('classrooms')
            .doc(widget.classroom.id)
            .update({
          'name': result['name'],
          'grade': result['grade'],
          'updatedAt': Timestamp.now(),
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Classroom updated successfully'),
            backgroundColor: AppDesignSystem.success,
          ),
        );

        Navigator.pop(context); // Go back to refresh
      } catch (e) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppDesignSystem.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteClassroom() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Classroom'),
        content: Text('Are you sure you want to delete "${widget.classroom.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppDesignSystem.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Remove classroom from all students
      for (String studentId in widget.classroom.studentIds) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(studentId)
            .update({
          'classroomIds': FieldValue.arrayRemove([widget.classroom.id]),
          'updatedAt': Timestamp.now(),
        });
      }

      // Delete the classroom
      await FirebaseFirestore.instance
          .collection('classrooms')
          .doc(widget.classroom.id)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Classroom deleted successfully'),
          backgroundColor: AppDesignSystem.success,
        ),
      );

      Navigator.pop(context); // Go back
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppDesignSystem.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppDesignSystem.gradientPrimary,
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: _editClassroom,
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteClassroom();
                      } else if (value == 'requests') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => JoinRequestsScreen(classroomId: widget.classroom.id),
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'requests',
                        child: Row(
                          children: [
                            Icon(Icons.pending_actions, size: 20),
                            SizedBox(width: 12),
                            Text('Manage Join Requests'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: AppDesignSystem.error),
                            SizedBox(width: 12),
                            Text('Delete Classroom', style: TextStyle(color: AppDesignSystem.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    widget.classroom.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Grade ${widget.classroom.grade}${widget.classroom.school != null ? ' • ${widget.classroom.school}' : ''}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.all(20.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Class Code Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppDesignSystem.backgroundWhite,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            AppStrings.classCode,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppDesignSystem.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                widget.classroom.joinCode,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppDesignSystem.primaryIndigo,
                                  letterSpacing: 4,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: widget.classroom.joinCode),
                                );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(AppStrings.codeCopied),
                                      backgroundColor: AppDesignSystem.success,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.copy),
                                color: AppDesignSystem.primaryIndigo,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Share this code with students to join your classroom',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppDesignSystem.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Action Buttons Row
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _showQRCode(context),
                                  icon: const Icon(Icons.qr_code_2),
                                  label: const Text('QR Code'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppDesignSystem.primaryIndigo,
                                    side: const BorderSide(color: AppDesignSystem.primaryIndigo),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _shareInviteLink(context),
                                  icon: const Icon(Icons.share),
                                  label: const Text('Share Link'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppDesignSystem.primaryIndigo,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Quick Actions
                    Row(
                      children: [
                        Expanded(
                          child: CleanCard(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const UnifiedAnnouncementsScreen(),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.campaign, color: Color(0xFF10B981), size: 28),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Announcements',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CleanCard(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const UnifiedLeaderboardScreen(),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.leaderboard, color: Color(0xFFF59E0B), size: 28),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Leaderboard',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),

                    // Stats
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.people,
                            value: '${widget.classroom.studentIds.length}',
                            label: AppStrings.students,
                            color: AppDesignSystem.primaryIndigo,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.pending,
                            value: '${widget.classroom.pendingStudentIds.length}',
                            label: 'Pending',
                            color: AppDesignSystem.warning,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Pending Approvals
                    if (widget.classroom.pendingStudentIds.isNotEmpty) ...[
                      const Text(
                        AppStrings.pendingApprovals,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppDesignSystem.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...widget.classroom.pendingStudentIds.map(
                        (studentId) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _StudentCard(
                            studentId: studentId,
                            classroomId: widget.classroom.id,
                            isPending: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Students List
                    const Text(
                      AppStrings.students,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppDesignSystem.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (widget.classroom.studentIds.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 60,
                                color: AppDesignSystem.textSecondary.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No students yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppDesignSystem.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...widget.classroom.studentIds.map(
                        (studentId) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _StudentCard(
                            studentId: studentId,
                            classroomId: widget.classroom.id,
                            isPending: false,
                          ),
                        ),
                      ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppDesignSystem.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppDesignSystem.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentCard extends StatefulWidget {
  final String studentId;
  final String classroomId;
  final bool isPending;

  const _StudentCard({
    required this.studentId,
    required this.classroomId,
    required this.isPending,
  });

  @override
  State<_StudentCard> createState() => _StudentCardState();
}

class _StudentCardState extends State<_StudentCard> {
  final JoinRequestService _joinRequestService = JoinRequestService();
  final NotificationService _notificationService = NotificationService();
  bool _isProcessing = false;

  Future<void> _approveStudent() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // Get the join request for this student and classroom
      final requests = await _joinRequestService.getPendingRequests(widget.classroomId);
      final request = requests.firstWhere(
        (r) => r.studentId == widget.studentId,
        orElse: () => throw Exception('Join request not found'),
      );

      final teacherId = FirebaseAuth.instance.currentUser!.uid;

      // Approve the request
      await _joinRequestService.approveRequest(
        requestId: request.id,
        teacherId: teacherId,
      );

      // Send notification to student
      await _notificationService.sendToUser(
        userId: widget.studentId,
        title: 'Join Request Approved',
        body: 'Your request to join the classroom has been approved!',
        data: {
          'type': 'join_request_approved',
          'classroomId': widget.classroomId,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student approved successfully'),
          backgroundColor: AppDesignSystem.success,
        ),
      );

      // Refresh the screen by popping and letting parent rebuild
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving student: ${e.toString()}'),
          backgroundColor: AppDesignSystem.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _rejectStudent() async {
    if (_isProcessing) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Student'),
        content: const Text('Are you sure you want to reject this join request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppDesignSystem.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      // Get the join request for this student and classroom
      final requests = await _joinRequestService.getPendingRequests(widget.classroomId);
      final request = requests.firstWhere(
        (r) => r.studentId == widget.studentId,
        orElse: () => throw Exception('Join request not found'),
      );

      final teacherId = FirebaseAuth.instance.currentUser!.uid;

      // Reject the request
      await _joinRequestService.rejectRequest(
        requestId: request.id,
        teacherId: teacherId,
        reason: 'Rejected by teacher',
      );

      // Send notification to student
      await _notificationService.sendToUser(
        userId: widget.studentId,
        title: 'Join Request Rejected',
        body: 'Your request to join the classroom was not approved.',
        data: {
          'type': 'join_request_rejected',
          'classroomId': widget.classroomId,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student rejected'),
          backgroundColor: AppDesignSystem.warning,
        ),
      );

      // Refresh the screen by popping and letting parent rebuild
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting student: ${e.toString()}'),
          backgroundColor: AppDesignSystem.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.studentId)
          .get(),
      builder: (context, snapshot) {
        String studentName = 'Student';
        String? avatarUrl;

        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          studentName = userData['displayName'] ?? 'Student';
          avatarUrl = userData['avatarUrl'];
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppDesignSystem.backgroundWhite,
            borderRadius: BorderRadius.circular(16),
            border: widget.isPending
                ? Border.all(color: AppDesignSystem.warning, width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  image: avatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(avatarUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: avatarUrl == null
                    ? const Icon(
                        Icons.person,
                        color: AppDesignSystem.primaryIndigo,
                        size: 28,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppDesignSystem.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.isPending ? 'Waiting for approval' : 'Active',
                      style: TextStyle(
                        fontSize: 13,
                        color: widget.isPending ? AppDesignSystem.warning : AppDesignSystem.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isPending)
                _isProcessing
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppDesignSystem.primaryIndigo),
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          IconButton(
                            onPressed: _approveStudent,
                            icon: const Icon(Icons.check_circle),
                            color: AppDesignSystem.success,
                            tooltip: 'Approve',
                          ),
                          IconButton(
                            onPressed: _rejectStudent,
                            icon: const Icon(Icons.cancel),
                            color: AppDesignSystem.error,
                            tooltip: 'Reject',
                          ),
                        ],
                      )
              else
                IconButton(
                  onPressed: () {
                    // TODO: View student details
                  },
                  icon: const Icon(Icons.arrow_forward_ios),
                  color: AppDesignSystem.textSecondary,
                ),
            ],
          ),
        );
      },
    );
  }
}

// Edit Classroom Dialog
class _EditClassroomDialog extends StatefulWidget {
  final String currentName;
  final String currentGrade;

  const _EditClassroomDialog({
    required this.currentName,
    required this.currentGrade,
  });

  @override
  State<_EditClassroomDialog> createState() => _EditClassroomDialogState();
}

class _EditClassroomDialogState extends State<_EditClassroomDialog> {
  late TextEditingController _nameController;
  late TextEditingController _gradeController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _gradeController = TextEditingController(text: widget.currentGrade);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Classroom'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Classroom Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a classroom name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _gradeController,
              decoration: const InputDecoration(
                labelText: 'Grade',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a grade';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'name': _nameController.text.trim(),
                'grade': _gradeController.text.trim(),
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppDesignSystem.primaryIndigo,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

