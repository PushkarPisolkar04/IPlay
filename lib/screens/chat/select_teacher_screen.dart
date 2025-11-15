import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/design/app_design_system.dart';
import '../../services/simplified_chat_service.dart';
import '../../widgets/loading_skeleton.dart';
import 'chat_screen.dart';

class SelectTeacherScreen extends StatefulWidget {
  const SelectTeacherScreen({super.key});

  @override
  State<SelectTeacherScreen> createState() => _SelectTeacherScreenState();
}

class _SelectTeacherScreenState extends State<SelectTeacherScreen> {
  final SimplifiedChatService _chatService = SimplifiedChatService();

  Future<List<Map<String, dynamic>>> _getTeachers() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    try {
      // Get student's classrooms
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) return [];

      final classroomIds = List<String>.from(userDoc.data()?['classroomIds'] ?? []);

      if (classroomIds.isEmpty) return [];

      Set<String> teacherIds = {};
      Map<String, Map<String, dynamic>> teacherClassroomInfo = {};

      // Get teachers from classrooms
      for (String classroomId in classroomIds) {
        final classroomDoc = await FirebaseFirestore.instance
            .collection('classrooms')
            .doc(classroomId)
            .get();

        if (!classroomDoc.exists) continue;

        final classroomData = classroomDoc.data()!;
        final teacherId = classroomData['teacherId'] as String;
        final classroomName = classroomData['name'] as String;
        final grade = classroomData['grade'] ?? '';
        final section = classroomData['section'] ?? '';

        teacherIds.add(teacherId);
        teacherClassroomInfo[teacherId] = {
          'name': classroomName,
          'grade': grade,
          'section': section,
        };
      }

      List<Map<String, dynamic>> teachers = [];

      // Load each teacher's data
      for (String teacherId in teacherIds) {
        final teacherDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(teacherId)
            .get();

        if (!teacherDoc.exists) continue;

        final teacherData = teacherDoc.data()!;

        final classroomInfo = teacherClassroomInfo[teacherId];
        teachers.add({
          'id': teacherId,
          'name': teacherData['displayName'] ?? 'Teacher',
          'avatarUrl': teacherData['avatarUrl'],
          'email': teacherData['email'],
          'classroom': classroomInfo?['name'] ?? 'Unknown',
          'grade': classroomInfo?['grade'] ?? '',
          'section': classroomInfo?['section'] ?? '',
        });
      }

      // Sort by name
      teachers.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

      return teachers;
    } catch (e) {
      return [];
    }
  }

  Future<void> _startChat(String teacherId, String teacherName, String? teacherAvatar) async {
    try {
      final studentId = FirebaseAuth.instance.currentUser!.uid;

      // Create or get existing chat
      final chatId = await _chatService.createTeacherStudentChat(
        teacherId: teacherId,
        studentId: studentId,
      );

      if (!mounted) return;

      // Navigate to chat screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatId,
            otherUserName: teacherName,
            otherUserAvatar: teacherAvatar,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting chat: ${e.toString()}'),
          backgroundColor: AppDesignSystem.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Teacher', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getTeachers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ListSkeleton(itemCount: 5);
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppDesignSystem.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading teachers',
                    style: TextStyle(
                      color: AppDesignSystem.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          final teachers = snapshot.data ?? [];

          if (teachers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 80,
                    color: AppDesignSystem.textTertiary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No teachers yet',
                    style: TextStyle(
                      color: AppDesignSystem.textSecondary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      'Join a classroom to see your teachers here',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppDesignSystem.textTertiary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: teachers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final teacher = teachers[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
                    backgroundImage: teacher['avatarUrl'] != null
                        ? (teacher['avatarUrl'].toString().startsWith('http')
                            ? NetworkImage(teacher['avatarUrl'])
                            : AssetImage(teacher['avatarUrl']) as ImageProvider)
                        : null,
                    child: teacher['avatarUrl'] == null
                        ? Text(
                            teacher['name'][0].toUpperCase(),
                            style: TextStyle(
                              color: AppDesignSystem.primaryIndigo,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          )
                        : null,
                  ),
                  title: Text(
                    teacher['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        teacher['classroom'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (teacher['grade'] != null && teacher['grade'].toString().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Grade ${teacher['grade']}${teacher['section'] != null && teacher['section'].toString().isNotEmpty ? ' - ${teacher['section']}' : ''}',
                          style: TextStyle(
                            color: AppDesignSystem.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.school,
                                  size: 12,
                                  color: AppDesignSystem.primaryIndigo,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Teacher',
                                  style: TextStyle(
                                    color: AppDesignSystem.primaryIndigo,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Container(
                    decoration: BoxDecoration(
                      gradient: AppDesignSystem.gradientPrimary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.message, color: Colors.white),
                      onPressed: () => _startChat(
                        teacher['id'],
                        teacher['name'],
                        teacher['avatarUrl'],
                      ),
                    ),
                  ),
                  onTap: () => _startChat(
                    teacher['id'],
                    teacher['name'],
                    teacher['avatarUrl'],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
