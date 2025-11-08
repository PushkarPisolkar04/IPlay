import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/design/app_design_system.dart';
import '../../widgets/clean_card.dart';
import '../teacher/create_announcement_screen.dart';

/// Unified Announcements Screen - Handles ALL roles (Student, Teacher, Principal)
/// Dynamically shows appropriate announcements and edit permissions based on user role
class UnifiedAnnouncementsScreen extends StatefulWidget {
  const UnifiedAnnouncementsScreen({super.key});

  @override
  State<UnifiedAnnouncementsScreen> createState() => _UnifiedAnnouncementsScreenState();
}

class _UnifiedAnnouncementsScreenState extends State<UnifiedAnnouncementsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _announcements = [];
  
  // User info
  String? _currentUserId;
  String? _userRole;
  bool _isPrincipal = false;
  String? _userSchoolId;
  List<String> _userClassroomIds = [];
  List<String> _teacherClassroomIds = [];
  bool _canCreate = false;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() => _isLoading = true);
    
    try {
      _currentUserId = FirebaseAuth.instance.currentUser?.uid;
      
      // Get user info
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        _userRole = userData['role'];
        _isPrincipal = userData['isPrincipal'] ?? false;
        _userSchoolId = userData['schoolId'];
        
        final classroomIds = userData['classroomIds'] as List?;
        if (classroomIds != null) {
          _userClassroomIds = classroomIds.cast<String>();
        }
        
        // For teachers, get their classrooms
        if (_userRole == 'teacher') {
          final classroomsSnapshot = await FirebaseFirestore.instance
              .collection('classrooms')
              .where('teacherId', isEqualTo: _currentUserId)
              .get();
          _teacherClassroomIds = classroomsSnapshot.docs.map((doc) => doc.id).toList();
        }
        
        // Determine if user can create announcements
        _canCreate = _userRole == 'teacher' || _isPrincipal;
      }
      
      _announcements = [];
      
      // Load announcements based on role
      if (_userRole == 'student') {
        await _loadStudentAnnouncements();
      } else if (_userRole == 'teacher') {
        await _loadTeacherAnnouncements();
      } else if (_isPrincipal) {
        await _loadPrincipalAnnouncements();
      }
      
      // Sort by date
      _announcements.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });
      
      setState(() => _isLoading = false);
    } catch (e) {
      // print('Error loading announcements: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStudentAnnouncements() async {
    // Load from student's classrooms
    for (var classroomId in _userClassroomIds) {
      final classroomQuery = await FirebaseFirestore.instance
          .collection('announcements')
          .where('classroomId', isEqualTo: classroomId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      
      for (var doc in classroomQuery.docs) {
        await _addAnnouncementWithAuthor(doc);
      }
    }
    
    // Load school-wide announcements
    if (_userSchoolId != null) {
      final schoolQuery = await FirebaseFirestore.instance
          .collection('announcements')
          .where('schoolId', isEqualTo: _userSchoolId)
          .where('isSchoolWide', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      
      for (var doc in schoolQuery.docs) {
        if (!_announcements.any((a) => a['id'] == doc.id)) {
          await _addAnnouncementWithAuthor(doc);
        }
      }
    }
  }

  Future<void> _loadTeacherAnnouncements() async {
    // Load from teacher's classrooms
    for (var classroomId in _teacherClassroomIds) {
      final classroomQuery = await FirebaseFirestore.instance
          .collection('announcements')
          .where('classroomId', isEqualTo: classroomId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      
      for (var doc in classroomQuery.docs) {
        await _addAnnouncementWithAuthor(doc);
      }
    }
    
    // Load school-wide announcements
    if (_userSchoolId != null) {
      final schoolQuery = await FirebaseFirestore.instance
          .collection('announcements')
          .where('schoolId', isEqualTo: _userSchoolId)
          .where('isSchoolWide', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      
      for (var doc in schoolQuery.docs) {
        if (!_announcements.any((a) => a['id'] == doc.id)) {
          await _addAnnouncementWithAuthor(doc);
        }
      }
    }
  }

  Future<void> _loadPrincipalAnnouncements() async {
    // Load all school-wide announcements
    if (_userSchoolId != null) {
      final schoolQuery = await FirebaseFirestore.instance
          .collection('announcements')
          .where('schoolId', isEqualTo: _userSchoolId)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();
      
      for (var doc in schoolQuery.docs) {
        await _addAnnouncementWithAuthor(doc);
      }
    }
  }

  Future<void> _addAnnouncementWithAuthor(QueryDocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    
    // Get author name
    String authorName = 'Unknown';
    String authorRole = 'User';
    if (data['authorId'] != null) {
      final authorDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(data['authorId'])
          .get();
      if (authorDoc.exists) {
        authorName = authorDoc.data()?['displayName'] ?? 'Unknown';
        authorRole = authorDoc.data()?['role'] ?? 'User';
      }
    }
    
    _announcements.add({
      'id': doc.id,
      'authorName': authorName,
      'authorRole': authorRole,
      ...data,
    });
  }

  Future<void> _deleteAnnouncement(String announcementId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: Text('Are you sure you want to delete "$title"?'),
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

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('announcements')
            .doc(announcementId)
            .delete();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Announcement deleted')),
          );
          _loadAnnouncements();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _editAnnouncement(Map<String, dynamic> announcement) async {
    final titleController = TextEditingController(text: announcement['title']);
    final messageController = TextEditingController(text: announcement['message']);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Announcement'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await FirebaseFirestore.instance
            .collection('announcements')
            .doc(announcement['id'])
            .update({
          'title': titleController.text.trim(),
          'message': messageController.text.trim(),
          'updatedAt': Timestamp.now(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Announcement updated')),
          );
          _loadAnnouncements();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }

    titleController.dispose();
    messageController.dispose();
  }

  bool _canEditAnnouncement(Map<String, dynamic> announcement) {
    // Principals can edit/delete any announcement in their school
    if (_isPrincipal) return true;
    
    // Teachers can only edit/delete their own announcements
    return announcement['authorId'] == _currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('Announcements'),
        backgroundColor: AppDesignSystem.backgroundWhite,
        elevation: 0,
        actions: [
          if (_canCreate)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateAnnouncementScreen(
                      schoolId: _userSchoolId,
                    ),
                  ),
                );
                _loadAnnouncements();
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _announcements.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.campaign_outlined,
                        size: 64,
                        color: AppDesignSystem.textTertiary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No announcements yet',
                        style: AppDesignSystem.h3.copyWith(
                          color: AppDesignSystem.textSecondary,
                        ),
                      ),
                      if (_canCreate) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to create one',
                          style: AppDesignSystem.bodyMedium.copyWith(
                            color: AppDesignSystem.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAnnouncements,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _announcements.length,
                    itemBuilder: (context, index) {
                      final announcement = _announcements[index];
                      final isSchoolWide = announcement['isSchoolWide'] ?? false;
                      final canEdit = _canEditAnnouncement(announcement);
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: CleanCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.campaign,
                                        color: AppDesignSystem.primaryIndigo,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            announcement['title'] ?? 'Untitled',
                                            style: AppDesignSystem.h4,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                announcement['authorRole'] == 'principal'
                                                    ? Icons.admin_panel_settings
                                                    : Icons.person,
                                                size: 12,
                                                color: AppDesignSystem.textSecondary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${announcement['authorName']} • ${_formatDate(announcement['createdAt'])}',
                                                style: AppDesignSystem.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                
                                if (isSchoolWide) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.school, size: 12, color: Colors.orange),
                                        SizedBox(width: 4),
                                        Text(
                                          'School-Wide',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                
                                const SizedBox(height: 12),
                                
                                // Message
                                Text(
                                  announcement['message'] ?? '',
                                  style: AppDesignSystem.bodyMedium,
                                ),
                                
                                // Actions (only for own announcements)
                                if (canEdit) ...[
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _editAnnouncement(announcement),
                                        icon: const Icon(Icons.edit, size: 16),
                                        label: const Text('Edit'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppDesignSystem.primaryIndigo,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        onPressed: () => _deleteAnnouncement(
                                          announcement['id'],
                                          announcement['title'] ?? 'this announcement',
                                        ),
                                        icon: const Icon(Icons.delete, size: 16),
                                        label: const Text('Delete'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    
    try {
      final date = (timestamp as Timestamp).toDate();
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes}m ago';
        }
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return '';
    }
  }
}
