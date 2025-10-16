import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/clean_card.dart';
import '../../providers/auth_provider.dart' as app_auth;
import 'package:timeago/timeago.dart' as timeago;

/// Announcements Screen - View all announcements for student's classroom
/// Features: Pinning, attachments, viewed tracking
class AnnouncementsScreen extends StatefulWidget {
  final String? classroomId;

  const AnnouncementsScreen({Key? key, this.classroomId}) : super(key: key);

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  String? _classroomId;
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _classroomId = widget.classroomId;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = Provider.of<app_auth.AuthProvider>(context, listen: false).currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });

      if (_classroomId == null && user.classroomIds.isNotEmpty) {
        setState(() {
          _classroomId = user.classroomIds.first;
        });
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _markAsViewed(String announcementId) async {
    if (_currentUserId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('announcements')
          .doc(announcementId)
          .update({
        'viewedBy': FieldValue.arrayUnion([_currentUserId])
      });
    } catch (e) {
      print('Error marking announcement as viewed: $e');
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return AppColors.error;
      case 'important':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  String _getPriorityIcon(String priority) {
    switch (priority) {
      case 'urgent':
        return '🔴';
      case 'important':
        return '🟢';
      default:
        return '🔵';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Announcements'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_classroomId == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Announcements'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            child: CleanCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.campaign_outlined,
                    size: 64,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No Classroom',
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Join a classroom to see announcements from your teacher.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Announcements'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('announcements')
            .where('classroomId', isEqualTo: _classroomId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final announcements = snapshot.data?.docs ?? [];

          if (announcements.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                child: CleanCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.campaign_outlined,
                        size: 64,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'No Announcements',
                        style: AppTextStyles.h3,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Your teacher hasn\'t posted any announcements yet.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Separate pinned and regular announcements
          final pinnedAnnouncements = announcements.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['isPinned'] == true;
          }).toList();
          
          final regularAnnouncements = announcements.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['isPinned'] != true;
          }).toList();
          
          final allAnnouncements = [...pinnedAnnouncements, ...regularAnnouncements];

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            itemCount: allAnnouncements.length,
            itemBuilder: (context, index) {
              final doc = allAnnouncements[index];
              final data = doc.data() as Map<String, dynamic>;
              final announcementId = doc.id;
              final priority = data['priority'] ?? 'normal';
              final createdAt = (data['createdAt'] as Timestamp).toDate();
              final isPinned = data['isPinned'] == true;
              final attachmentUrls = List<String>.from(data['attachmentUrls'] ?? []);
              final viewedBy = List<String>.from(data['viewedBy'] ?? []);
              final isViewed = _currentUserId != null && viewedBy.contains(_currentUserId);
              
              // Mark as viewed when displayed
              if (!isViewed && _currentUserId != null) {
                Future.delayed(Duration.zero, () => _markAsViewed(announcementId));
              }
              
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.cardSpacing),
                child: CleanCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pinned indicator
                      if (isPinned)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.push_pin, size: 14, color: AppColors.warning),
                              const SizedBox(width: 4),
                              Text(
                                'Pinned',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Header
                      Row(
                        children: [
                          Text(
                            _getPriorityIcon(priority),
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              data['title'] ?? 'Announcement',
                              style: AppTextStyles.cardTitle.copyWith(
                                color: _getPriorityColor(priority),
                              ),
                            ),
                          ),
                          if (!isViewed)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Message
                      Text(
                        data['message'] ?? '',
                        style: AppTextStyles.bodyMedium,
                      ),
                      
                      // Attachments
                      if (attachmentUrls.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ...attachmentUrls.map((url) {
                          final fileName = url.split('/').last.split('?').first;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.attach_file, size: 18, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    fileName,
                                    style: AppTextStyles.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.download, size: 18),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    // TODO: Implement download
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Download coming soon!')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                      
                      const SizedBox(height: 12),
                      const Divider(),
                      
                      // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.person,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                data['teacherName'] ?? 'Teacher',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              if (viewedBy.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.visibility, size: 14, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${viewedBy.length}',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Text(
                                timeago.format(createdAt),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
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
