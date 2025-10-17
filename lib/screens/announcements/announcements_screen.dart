import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/clean_card.dart';

/// Announcements Screen for Students and Teachers
/// Students: View only
/// Teachers: View all, edit/delete only their own
class AnnouncementsScreen extends StatefulWidget {
  final bool canEdit; // false for students, true for teachers
  
  const AnnouncementsScreen({super.key, this.canEdit = false});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _announcements = [];
  String? _currentUserId;
  String? _schoolId;
  String? _classroomId;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    try {
      _currentUserId = FirebaseAuth.instance.currentUser?.uid;
      
      print('🔔 Loading announcements for user: $_currentUserId');
      
      // Get user's school and classroom
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        _schoolId = userData['schoolId'];
        
        print('🏫 User schoolId: $_schoolId');
        
        // For students, get their classrooms
        if (!widget.canEdit) {
          final classroomIds = List<String>.from(userData['classroomIds'] ?? []);
          print('🏫 User classroomIds: $classroomIds');
          if (classroomIds.isNotEmpty) {
            _classroomId = classroomIds.first;
            print('🏫 Selected classroomId: $_classroomId');
            
            // If student doesn't have schoolId in profile, fetch it from classroom
            if (_schoolId == null || _schoolId!.isEmpty) {
              print('⚠️ Student missing schoolId, fetching from classroom...');
              final classroomDoc = await FirebaseFirestore.instance
                  .collection('classrooms')
                  .doc(_classroomId)
                  .get();
              if (classroomDoc.exists) {
                _schoolId = classroomDoc.data()?['schoolId'];
                print('✅ Fetched schoolId from classroom: $_schoolId');
                
                // Update user document with schoolId for future use
                if (_schoolId != null && _schoolId!.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(_currentUserId)
                      .update({'schoolId': _schoolId});
                  print('✅ Updated user profile with schoolId');
                }
              }
            }
          }
        }
      }

      _announcements = [];

      // Load announcements
      // STUDENTS: Get school-wide announcements (from principal) if user is in a school
      if (_schoolId != null && _schoolId!.isNotEmpty) {
        print('🔍 Fetching school-wide announcements from principal...');
        final schoolQuery = await FirebaseFirestore.instance
            .collection('announcements')
            .where('schoolId', isEqualTo: _schoolId)
            .where('isSchoolWide', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .get();
        
        print('📢 Found ${schoolQuery.docs.length} school-wide announcements (from principal)');
        
        for (var doc in schoolQuery.docs) {
          await _addAnnouncementWithAuthor(doc);
        }
      }
      
      // STUDENTS: Get classroom announcements (from teacher) if applicable
      if (_classroomId != null && _classroomId!.isNotEmpty) {
        print('🔍 Fetching classroom announcements from teacher...');
        final classroomQuery = await FirebaseFirestore.instance
            .collection('announcements')
            .where('classroomId', isEqualTo: _classroomId)
            .orderBy('createdAt', descending: true)
            .get();
        
        print('📢 Found ${classroomQuery.docs.length} classroom announcements (from teacher)');
        
        for (var doc in classroomQuery.docs) {
          // Avoid duplicates
          if (!_announcements.any((a) => a['id'] == doc.id)) {
            await _addAnnouncementWithAuthor(doc);
          }
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

  Future<void> _addAnnouncementWithAuthor(QueryDocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    
    print('Loading announcement: ${doc.id}');
    print('Title: ${data['title']}');
    print('Message: ${data['message']}');
    
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
            const SnackBar(
              content: Text('Announcement updated'),
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

    titleController.dispose();
    messageController.dispose();
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
    if (!widget.canEdit) return false;
    return announcement['authorId'] == _currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Announcements'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnnouncements,
              child: _announcements.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Column(
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
                      ],
                    )
                  : ListView.builder(
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
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header - Responsive layout
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.campaign,
                                                color: AppColors.primary,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    announcement['title'] ?? 'Untitled',
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        announcement['authorRole'] == 'principal'
                                                            ? Icons.admin_panel_settings
                                                            : Icons.person,
                                                        size: 12,
                                                        color: Colors.grey,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          '${announcement['authorName']} • ${_formatDate(announcement['createdAt'])}',
                                                          style: const TextStyle(
                                                            fontSize: 11,
                                                            color: Colors.grey,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
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
                                              color: Colors.amber.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Colors.amber.withOpacity(0.5)),
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
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Message - with proper wrapping
                                    Text(
                                      announcement['message'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.5,
                                      ),
                                      softWrap: true,
                                    ),
                                  
                                  // Actions (only for teachers on their own announcements)
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
                                            foregroundColor: AppColors.primary,
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
}
