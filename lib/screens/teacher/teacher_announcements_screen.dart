import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/clean_card.dart';
import 'create_announcement_screen.dart';

class TeacherAnnouncementsScreen extends StatefulWidget {
  final String classroomId;
  
  const TeacherAnnouncementsScreen({super.key, required this.classroomId});

  @override
  State<TeacherAnnouncementsScreen> createState() => _TeacherAnnouncementsScreenState();
}

class _TeacherAnnouncementsScreenState extends State<TeacherAnnouncementsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _announcements = [];
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    try {
      print('Loading announcements for classroom: ${widget.classroomId}');
      
      final snapshot = await FirebaseFirestore.instance
          .collection('announcements')
          .where('classroomId', isEqualTo: widget.classroomId)
          .orderBy('createdAt', descending: true)
          .get();

      print('Found ${snapshot.docs.length} announcements');

      _announcements = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('Announcement data: $data');
        
        _announcements.add({
          'id': doc.id,
          ...data,
        });
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading announcements: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
            const SnackBar(
              content: Text('Announcement deleted successfully'),
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

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadAnnouncements,
                child: CustomScrollView(
                  slivers: [
                    // Header with green gradient
                    SliverToBoxAdapter(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
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
                                      builder: (context) => CreateAnnouncementScreen(
                                        isSchoolWide: false,
                                        classroomId: widget.classroomId,
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
                      SliverFillRemaining(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
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
                            SizedBox(height: 8),
                            Text(
                              'Tap + to create your first announcement',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final announcement = _announcements[index];
                              final isOwnAnnouncement = announcement['authorId'] == _currentUserId;
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: CleanCard(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                announcement['title'] ?? '',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            if (isOwnAnnouncement)
                                              PopupMenuButton<String>(
                                                onSelected: (value) {
                                                  if (value == 'delete') {
                                                    _deleteAnnouncement(
                                                      announcement['id'],
                                                      announcement['title'] ?? '',
                                                    );
                                                  }
                                                },
                                                itemBuilder: (context) => [
                                                  const PopupMenuItem(
                                                    value: 'delete',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.delete, color: Colors.red, size: 20),
                                                        SizedBox(width: 8),
                                                        Text('Delete', style: TextStyle(color: Colors.red)),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          announcement['message'] ?? '',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.grey[700],
                                            height: 1.5,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Icon(Icons.person, size: 14, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text(
                                              announcement['authorName'] ?? 'Unknown',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatTimestamp(announcement['createdAt']),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
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

