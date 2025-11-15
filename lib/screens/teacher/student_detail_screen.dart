import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/clean_card.dart';
import '../../widgets/progress_bar.dart';
import '../../widgets/loading_skeleton.dart';
import '../../services/simplified_chat_service.dart';
import '../chat/chat_screen.dart';

class StudentDetailScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  const StudentDetailScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  Map<String, dynamic>? _studentData;
  List<String> _badges = [];
  Map<String, dynamic> _progressSummary = {};
  bool _isLoading = true;
  final SimplifiedChatService _chatService = SimplifiedChatService();

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.studentId)
          .get();

      if (userDoc.exists) {
        _studentData = userDoc.data();
        _badges = List<String>.from(_studentData?['badges'] ?? []);
        _progressSummary = Map<String, dynamic>.from(_studentData?['progressSummary'] ?? {});
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      // print('Error loading student data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _startChat() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to send messages'),
              backgroundColor: AppDesignSystem.error,
            ),
          );
        }
        return;
      }

      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Create or get existing chat
      final chatId = await _chatService.createTeacherStudentChat(
        teacherId: currentUser.uid,
        studentId: widget.studentId,
      );

      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Navigate to chat screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chatId,
              otherUserName: widget.studentName,
              otherUserAvatar: _studentData?['avatarUrl'],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog if open
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start chat: ${e.toString()}'),
            backgroundColor: AppDesignSystem.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppDesignSystem.backgroundLight,
        appBar: AppBar(
          title: Text(widget.studentName),
        ),
        body: const SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: ProfileSkeleton(),
        ),
      );
    }

    if (_studentData == null) {
      return Scaffold(
        backgroundColor: AppDesignSystem.backgroundLight,
        appBar: AppBar(
          title: Text(widget.studentName),
        ),
        body: const Center(child: Text('Student data not found')),
      );
    }

    final totalXP = _studentData?['totalXP'] ?? 0;
    final currentStreak = _studentData?['currentStreak'] ?? 0;
    final userLevel = (totalXP / 200).floor() + 1;

    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startChat,
        backgroundColor: AppDesignSystem.primaryIndigo,
        icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
        label: const Text(
          'Message',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.studentName),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          widget.studentName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Level $userLevel',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        Icons.stars,
                        '$totalXP',
                        'Total XP',
                        AppDesignSystem.primaryAmber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        Icons.local_fire_department,
                        '$currentStreak',
                        'Day Streak',
                        AppDesignSystem.warning,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        Icons.emoji_events,
                        '${_badges.length}',
                        'Badges',
                        AppDesignSystem.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        Icons.school,
                        '${_progressSummary.length}',
                        'Realms',
                        AppDesignSystem.primaryIndigo,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Badges Section
                Text(
                  'Badges Earned',
                  style: AppTextStyles.sectionHeader,
                ),

                const SizedBox(height: 12),

                if (_badges.isEmpty)
                  CleanCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.emoji_events_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No badges earned yet',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _badges.map((badgeId) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppDesignSystem.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppDesignSystem.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.emoji_events,
                              color: AppDesignSystem.success,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              badgeId,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 24),

                // Realm Progress Section
                Text(
                  'Realm Progress',
                  style: AppTextStyles.sectionHeader,
                ),

                const SizedBox(height: 12),

                if (_progressSummary.isEmpty)
                  CleanCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.school_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No progress yet',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ..._progressSummary.entries.map((entry) {
                    final realmId = entry.key;
                    final realmData = entry.value as Map<String, dynamic>;
                    final completed = realmData['completed'] ?? false;
                    final progress = (realmData['completedLevels'] ?? 0) / (realmData['totalLevels'] ?? 1);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CleanCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    completed ? Icons.check_circle : Icons.circle_outlined,
                                    color: completed ? AppDesignSystem.success : Colors.grey,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      realmId,
                                      style: AppTextStyles.cardTitle,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ProgressBar(
                                progress: progress,
                                color: completed ? AppDesignSystem.success : AppDesignSystem.primaryIndigo,
                                backgroundColor: Colors.grey[300]!,
                                height: 8,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${realmData['completedLevels']} / ${realmData['totalLevels']} levels completed',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return CleanCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.h2.copyWith(color: color),
            ),
            Text(
              label,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

