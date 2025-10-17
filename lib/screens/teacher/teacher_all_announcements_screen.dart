import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/clean_card.dart';
import 'create_announcement_screen.dart';

class TeacherAllAnnouncementsScreen extends StatefulWidget {
  const TeacherAllAnnouncementsScreen({super.key});

  @override
  State<TeacherAllAnnouncementsScreen> createState() => _TeacherAllAnnouncementsScreenState();
}

class _TeacherAllAnnouncementsScreenState extends State<TeacherAllAnnouncementsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _announcements = [];
  String? _currentUserId;
  String? _schoolId;
  List<String> _classroomIds = [];

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    try {
      _currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (_currentUserId == null) return;

      print('🔔 Loading announcements for teacher: $_currentUserId');

      // Get teacher's school and classrooms
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .get();

      if (userDoc.exists) {
        _schoolId = userDoc.data()?['schoolId'];
        print('🏫 Teacher schoolId: $_schoolId');
      }

      // Get teacher's classrooms
      final classroomsSnapshot = await FirebaseFirestore.instance
          .collection('classrooms')
          .where('teacherId', isEqualTo: _currentUserId)
          .get();

      _classroomIds = classroomsSnapshot.docs.map((doc) => doc.id).toList();
      print('📚 Teacher classroomIds: $_classroomIds');

      _announcements = [];

      // Load school-wide announcements if teacher is in a school
      if (_schoolId != null && _schoolId!.isNotEmpty) {
        print('🔍 Fetching school-wide announcements...');
        final schoolQuery = await FirebaseFirestore.instance
            .collection('announcements')
            .where('schoolId', isEqualTo: _schoolId)
            .where('isSchoolWide', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .get();

        print('📢 Found ${schoolQuery.docs.length} school-wide announcements');

        for (var doc in schoolQuery.docs) {
          await _addAnnouncementWithAuthor(doc, 'School-Wide');
        }
      }

      // Load classroom announcements for all teacher's classrooms
      for (var classroomId in _classroomIds) {
        print('🔍 Fetching announcements for classroom: $classroomId');
        final classroomQuery = await FirebaseFirestore.instance
            .collection('announcements')
            .where('classroomId', isEqualTo: classroomId)
            .orderBy('createdAt', descending: true)
            .get();

        print('📢 Found ${classroomQuery.docs.length} announcements for classroom $classroomId');

        // Get classroom name
        final classroomDoc = await FirebaseFirestore.instance
            .collection('classrooms')
            .doc(classroomId)
            .get();
        final classroomName = classroomDoc.data()?['name'] ?? 'Unknown Class';

        for (var doc in classroomQuery.docs) {
          await _addAnnouncementWithAuthor(doc, classroomName);
        }
      }

      // Sort by date
      _announcements.sort((a, b) {
        final aDate = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        final bDate = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });

      print('✅ Total announcements loaded: ${_announcements.length}');

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Error loading announcements: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addAnnouncementWithAuthor(QueryDocumentSnapshot doc, String scope) async {
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
        if (authorDoc.data()?['isPrincipal'] == true) {
          authorRole = 'principal';
        }
      }
    }

    _announcements.add({
      'id': doc.id,
      'authorName': authorName,
      'authorRole': authorRole,
      'scope': scope,
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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
            const SnackBar(
              content: Text('Announcement deleted'),
              backgroundColor: Colors.green,
            ),
          );
          _loadAnnouncements();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  bool _canEditAnnouncement(Map<String, dynamic> announcement) {
    return announcement['authorId'] == _currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEF4444)))
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadAnnouncements,
                child: CustomScrollView(
                  slivers: [
                    // Header with red gradient
                    SliverToBoxAdapter(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const Center(
                              child: Text(
                                'Announcements',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                icon: const Icon(Icons.add, color: Colors.white, size: 24),
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const CreateAnnouncementScreen(
                                        isSchoolWide: false,
                                      ),
                                    ),
                                  );
                                  _loadAnnouncements();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Content
                    if (_announcements.isEmpty)
                      const SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.campaign, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No announcements yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final announcement = _announcements[index];
                              final isSchoolWide = announcement['isSchoolWide'] ?? false;
                              final canEdit = _canEditAnnouncement(announcement);
                              final scope = announcement['scope'] ?? '';

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
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: isSchoolWide
                                                    ? const Color(0xFF8B5CF6).withValues(alpha: 0.1)
                                                    : const Color(0xFFEF4444).withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Icon(
                                                Icons.campaign,
                                                color: isSchoolWide
                                                    ? const Color(0xFF8B5CF6)
                                                    : const Color(0xFFEF4444),
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    announcement['title'] ?? 'Untitled',
                                                    style: const TextStyle(
                                                      fontSize: 17,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        announcement['authorRole'] == 'principal'
                                                            ? Icons.admin_panel_settings
                                                            : Icons.person,
                                                        size: 14,
                                                        color: Colors.grey,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          '${announcement['authorName']} • ${_formatDate(announcement['createdAt'])}',
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: isSchoolWide
                                                    ? Colors.amber.withOpacity(0.2)
                                                    : const Color(0xFFEF4444).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                scope,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: isSchoolWide ? Colors.orange : const Color(0xFFEF4444),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),

                                        // Message
                                        Text(
                                          announcement['message'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            height: 1.5,
                                          ),
                                        ),

                                        // Actions (only for teacher's own announcements)
                                        if (canEdit) ...[
                                          const SizedBox(height: 16),
                                          const Divider(),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
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
                            childCount: _announcements.length,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

