import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/clean_card.dart';
import '../../widgets/loading_skeleton.dart';

class StudentProgressScreen extends StatefulWidget {
  const StudentProgressScreen({super.key});

  @override
  State<StudentProgressScreen> createState() => _StudentProgressScreenState();
}

class _StudentProgressScreenState extends State<StudentProgressScreen> {
  final List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  String? _selectedClassroomId;
  List<Map<String, dynamic>> _classrooms = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Load teacher's classrooms
      final classroomsSnapshot = await FirebaseFirestore.instance
          .collection('classrooms')
          .where('teacherId', isEqualTo: currentUser.uid)
          .get();

      _classrooms = classroomsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      if (_classrooms.isNotEmpty) {
        _selectedClassroomId = _classrooms.first['id'];
        await _loadStudents();
      }
    } catch (e) {
      // print('Error loading data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStudents() async {
    if (_selectedClassroomId == null) return;

    try {
      // Get classroom data
      final classroomDoc = await FirebaseFirestore.instance
          .collection('classrooms')
          .doc(_selectedClassroomId)
          .get();

      if (!classroomDoc.exists) return;

      final studentIds = List<String>.from(classroomDoc.data()?['studentIds'] ?? []);
      
      _students.clear();
      
      for (String studentId in studentIds) {
        // Get student data
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(studentId)
            .get();

        if (!userDoc.exists) continue;

        final userData = userDoc.data()!;
        
        // Get student's progress
        final progressSnapshot = await FirebaseFirestore.instance
            .collection('progress')
            .where('userId', isEqualTo: studentId)
            .where('status', isEqualTo: 'completed')
            .get();

        // Calculate stats
        int totalXP = userData['totalXP'] ?? 0;
        int completedLevels = progressSnapshot.docs.length;
        int currentStreak = userData['currentStreak'] ?? 0;
        
        // Calculate average score
        int totalScore = 0;
        int quizCount = 0;
        for (var doc in progressSnapshot.docs) {
          if (doc.data()['accuracy'] != null) {
            totalScore += (doc.data()['accuracy'] as int);
            quizCount++;
          }
        }
        double avgScore = quizCount > 0 ? totalScore / quizCount : 0;

        _students.add({
          'id': studentId,
          'name': userData['displayName'] ?? 'Unknown',
          'email': userData['email'] ?? '',
          'totalXP': totalXP,
          'completedLevels': completedLevels,
          'currentStreak': currentStreak,
          'avgScore': avgScore,
          'lastActive': userData['lastActiveDate'] != null 
              ? (userData['lastActiveDate'] as Timestamp).toDate()
              : null,
        });
      }

      // Sort by XP (highest first)
      _students.sort((a, b) => (b['totalXP'] as int).compareTo(a['totalXP'] as int));

      if (mounted) setState(() {});
    } catch (e) {
      // print('Error loading students: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              gradient: AppDesignSystem.gradientPrimary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Student Progress',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                
                // Classroom selector
                if (_classrooms.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedClassroomId,
                        dropdownColor: AppDesignSystem.primaryIndigo,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        items: _classrooms.map((classroom) {
                          return DropdownMenuItem<String>(
                            value: classroom['id'],
                            child: Text(
                              classroom['name'] ?? 'Classroom',
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedClassroomId = value;
                          });
                          _loadStudents();
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Students List
          Expanded(
            child: _isLoading
                ? const ListSkeleton(itemCount: 5)
                : _students.isEmpty
                    ? const Center(child: Text('No students enrolled'))
                    : RefreshIndicator(
                        onRefresh: _loadStudents,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _students.length,
                          itemBuilder: (context, index) {
                            final student = _students[index];
                            final isTop3 = index < 3;
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: isTop3
                                      ? LinearGradient(
                                          colors: [
                                            AppDesignSystem.primaryAmber.withValues(alpha: 0.1),
                                            Colors.white,
                                          ],
                                        )
                                      : null,
                                  color: isTop3 ? null : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isTop3 
                                        ? AppDesignSystem.primaryAmber.withValues(alpha: 0.3)
                                        : AppDesignSystem.backgroundWhite,
                                  ),
                                ),
                                child: CleanCard(
                                  color: Colors.transparent,
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          // Rank badge
                                          if (isTop3)
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: index == 0
                                                    ? const Color(0xFFFFD700)
                                                    : index == 1
                                                        ? const Color(0xFFC0C0C0)
                                                        : const Color(0xFFCD7F32),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.emoji_events,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            )
                                          else
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: AppDesignSystem.backgroundWhite,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '${index + 1}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
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
                                                  student['name'],
                                                  style: AppTextStyles.cardTitle,
                                                ),
                                                Text(
                                                  student['email'],
                                                  style: AppTextStyles.bodySmall,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: 12),
                                      const Divider(),
                                      const SizedBox(height: 12),
                                      
                                      // Stats Grid
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildStatItem(
                                              Icons.stars,
                                              '${student['totalXP']}',
                                              'Total XP',
                                              AppDesignSystem.primaryAmber,
                                            ),
                                          ),
                                          Expanded(
                                            child: _buildStatItem(
                                              Icons.check_circle,
                                              '${student['completedLevels']}',
                                              'Levels',
                                              AppDesignSystem.success,
                                            ),
                                          ),
                                          Expanded(
                                            child: _buildStatItem(
                                              Icons.local_fire_department,
                                              '${student['currentStreak']}',
                                              'Streak',
                                              AppDesignSystem.error,
                                            ),
                                          ),
                                          Expanded(
                                            child: _buildStatItem(
                                              Icons.school,
                                              '${student['avgScore'].toStringAsFixed(0)}%',
                                              'Avg Score',
                                              AppDesignSystem.primaryIndigo,
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      if (student['lastActive'] != null) ...[
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Icon(Icons.access_time, size: 14, color: AppDesignSystem.textSecondary),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Last active: ${_formatDate(student['lastActive'])}',
                                              style: AppTextStyles.bodySmall.copyWith(
                                                color: AppDesignSystem.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      
                                      // Message button
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: () async {
                                            // Get or create chat with student
                                            try {
                                              final currentUser = FirebaseAuth.instance.currentUser;
                                              if (currentUser == null) return;
                                              
                                              // Query for existing chat
                                              final chatsQuery = await FirebaseFirestore.instance
                                                  .collection('chats')
                                                  .where('participants', arrayContains: currentUser.uid)
                                                  .get();
                                              
                                              String? chatId;
                                              for (var doc in chatsQuery.docs) {
                                                final participants = List<String>.from(doc.data()['participants'] ?? []);
                                                if (participants.contains(student['id'])) {
                                                  chatId = doc.id;
                                                  break;
                                                }
                                              }
                                              
                                              // Create chat if doesn't exist
                                              if (chatId == null) {
                                                final newChat = await FirebaseFirestore.instance.collection('chats').add({
                                                  'participants': [currentUser.uid, student['id']],
                                                  'createdAt': FieldValue.serverTimestamp(),
                                                  'lastMessage': '',
                                                  'lastMessageAt': FieldValue.serverTimestamp(),
                                                });
                                                chatId = newChat.id;
                                              }
                                              
                                              if (mounted) {
                                                Navigator.pushNamed(
                                                  context,
                                                  '/chat',
                                                  arguments: {
                                                    'chatId': chatId,
                                                    'otherUserName': student['name'],
                                                  },
                                                );
                                              }
                                            } catch (e) {
                                              // print('Error opening chat: $e');
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Failed to open chat')),
                                                );
                                              }
                                            }
                                          },
                                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                                          label: const Text('Message Student'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppDesignSystem.primaryIndigo,
                                            side: BorderSide(color: AppDesignSystem.primaryIndigo),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppDesignSystem.textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

