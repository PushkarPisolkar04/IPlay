import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/design/app_design_system.dart';
import '../../services/simplified_chat_service.dart';
import '../../widgets/loading_skeleton.dart';
import 'chat_screen.dart';

class SelectStudentScreen extends StatefulWidget {
  const SelectStudentScreen({super.key});

  @override
  State<SelectStudentScreen> createState() => _SelectStudentScreenState();
}

class _SelectStudentScreenState extends State<SelectStudentScreen> {
  final SimplifiedChatService _chatService = SimplifiedChatService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _allStudents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Get teacher's classrooms
      final classroomsSnapshot = await FirebaseFirestore.instance
          .collection('classrooms')
          .where('teacherId', isEqualTo: currentUser.uid)
          .get();

      if (classroomsSnapshot.docs.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      Set<String> studentIds = {};
      Map<String, Map<String, dynamic>> studentClassroomInfo = {};

      // Get students from classrooms
      for (var classroomDoc in classroomsSnapshot.docs) {
        final classroomData = classroomDoc.data();
        final classroomName = classroomData['name'] as String;
        final grade = classroomData['grade'] ?? '';
        final section = classroomData['section'] ?? '';
        final studentIdsList = List<String>.from(
          classroomData['studentIds'] ?? [],
        );

        for (String studentId in studentIdsList) {
          studentIds.add(studentId);
          studentClassroomInfo[studentId] = {
            'name': classroomName,
            'grade': grade,
            'section': section,
          };
        }
      }

      List<Map<String, dynamic>> students = [];

      // Load each student's data
      for (String studentId in studentIds) {
        final studentDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(studentId)
            .get();

        if (!studentDoc.exists) continue;

        final studentData = studentDoc.data()!;

        // Only include actual students (not teachers)
        if (studentData['role'] != 'student') continue;

        final classroomInfo = studentClassroomInfo[studentId]!;

        students.add({
          'id': studentId,
          'displayName': studentData['displayName'] ?? 'Student',
          'email': studentData['email'] ?? '',
          'avatarUrl': studentData['avatarUrl'],
          'classroomName': classroomInfo['name'],
          'grade': classroomInfo['grade'],
          'section': classroomInfo['section'],
        });
      }

      // Sort by name
      students.sort(
        (a, b) =>
            (a['displayName'] as String).compareTo(b['displayName'] as String),
      );

      if (mounted) {
        setState(() {
          _allStudents = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredStudents {
    if (_searchQuery.isEmpty) return _allStudents;

    return _allStudents.where((student) {
      final name = (student['displayName'] as String).toLowerCase();
      final classroom = (student['classroomName'] as String).toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || classroom.contains(query);
    }).toList();
  }

  Future<void> _startChat(Map<String, dynamic> student) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final chatId = await _chatService.createTeacherStudentChat(
        teacherId: currentUser.uid,
        studentId: student['id'],
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chatId,
              otherUserName: student['displayName'],
              otherUserAvatar: student['avatarUrl'],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting chat: $e'),
            backgroundColor: AppDesignSystem.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom gradient app bar
            Container(
              decoration: BoxDecoration(
                gradient: AppDesignSystem.gradientPrimary,
                boxShadow: [
                  BoxShadow(
                    color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Select Student',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search students...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppDesignSystem.primaryIndigo,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
            ),

            // Students list
            Expanded(
              child: _isLoading
                  ? const ListSkeleton(itemCount: 8)
                  : _filteredStudents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 80,
                            color: AppDesignSystem.textTertiary,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No students found'
                                : 'No students match your search',
                            style: AppDesignSystem.h4.copyWith(
                              color: AppDesignSystem.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 48),
                            child: Text(
                              _searchQuery.isEmpty
                                  ? 'Students from your classrooms will appear here'
                                  : 'Try a different search term',
                              style: AppDesignSystem.bodyMedium.copyWith(
                                color: AppDesignSystem.textTertiary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _filteredStudents.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final student = _filteredStudents[index];
                        final avatarUrl = student['avatarUrl'];

                        return ListTile(
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: AppDesignSystem.primaryIndigo
                                .withValues(alpha: 0.1),
                            backgroundImage: avatarUrl != null
                                ? (avatarUrl.startsWith('http')
                                      ? NetworkImage(avatarUrl)
                                      : AssetImage(avatarUrl) as ImageProvider)
                                : null,
                            child: avatarUrl == null
                                ? Text(
                                    student['displayName'][0].toUpperCase(),
                                    style: AppDesignSystem.h6.copyWith(
                                      color: AppDesignSystem.primaryIndigo,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(
                            student['displayName'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            student['classroomName'],
                            style: TextStyle(
                              fontSize: 14,
                              color: AppDesignSystem.textSecondary,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chat_bubble_outline,
                            color: AppDesignSystem.primaryIndigo,
                          ),
                          onTap: () => _startChat(student),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
