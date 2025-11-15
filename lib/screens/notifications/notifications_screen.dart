import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/design/app_design_system.dart';
import '../../core/services/notification_service.dart';
import '../../widgets/loading_skeleton.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  String _selectedFilter = 'all';

  final Map<String, IconData> _notificationIcons = {
    'badge': Icons.emoji_events,
    'announcement': Icons.campaign,
    'assignment': Icons.assignment,
    'join_request': Icons.person_add,
    'join_approved': Icons.check_circle,
    'join_rejected': Icons.cancel,
    'message': Icons.message,
    'certificate': Icons.workspace_premium,
    'level_complete': Icons.check_circle_outline,
    'realm_complete': Icons.stars,
    'daily_challenge': Icons.emoji_events,
    'streak': Icons.local_fire_department,
    'rank_change': Icons.trending_up,
    'default': Icons.notifications,
  };

  final Map<String, Color> _notificationColors = {
    'badge': AppDesignSystem.primaryAmber,
    'announcement': AppDesignSystem.primaryIndigo,
    'assignment': AppDesignSystem.primaryPink,
    'join_request': AppDesignSystem.secondaryPurple,
    'join_approved': AppDesignSystem.primaryGreen,
    'join_rejected': AppDesignSystem.secondaryRed,
    'message': AppDesignSystem.secondaryBlue,
    'certificate': AppDesignSystem.primaryAmber,
    'level_complete': AppDesignSystem.primaryGreen,
    'realm_complete': AppDesignSystem.primaryAmber,
    'daily_challenge': AppDesignSystem.primaryAmber,
    'streak': AppDesignSystem.secondaryRed,
    'rank_change': AppDesignSystem.primaryIndigo,
    'default': AppDesignSystem.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppDesignSystem.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: AppDesignSystem.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _notificationService.markAllAsRead();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications marked as read'),
                    backgroundColor: AppDesignSystem.primaryGreen,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text(
              'Mark all read',
              style: TextStyle(
                color: AppDesignSystem.primaryIndigo,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('badge', 'Badges'),
                  const SizedBox(width: 8),
                  _buildFilterChip('announcement', 'Announcements'),
                  const SizedBox(width: 8),
                  _buildFilterChip('assignment', 'Assignments'),
                  const SizedBox(width: 8),
                  _buildFilterChip('message', 'Messages'),
                  const SizedBox(width: 8),
                  _buildFilterChip('certificate', 'Certificates'),
                ],
              ),
            ),
          ),
          
          // Notifications list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _notificationService.getNotificationsStream(),
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
                          'Error loading notifications',
                          style: TextStyle(
                            color: AppDesignSystem.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 80,
                          color: AppDesignSystem.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications yet',
                          style: TextStyle(
                            color: AppDesignSystem.textSecondary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You\'ll see updates about badges,\nassignments, and more here',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppDesignSystem.textSecondary.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter notifications
                final allNotifications = snapshot.data!.docs;
                final filteredNotifications = _selectedFilter == 'all'
                    ? allNotifications
                    : allNotifications.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final type = data['data']?['type'] ?? 'default';
                        return type == _selectedFilter;
                      }).toList();

                if (filteredNotifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_list_off,
                          size: 64,
                          color: AppDesignSystem.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No $_selectedFilter notifications',
                          style: TextStyle(
                            color: AppDesignSystem.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredNotifications.length,
                  itemBuilder: (context, index) {
                    final doc = filteredNotifications[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildNotificationTile(doc.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppDesignSystem.primaryIndigo
              : AppDesignSystem.backgroundGrey,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppDesignSystem.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationTile(String notificationId, Map<String, dynamic> data) {
    final title = data['title'] ?? 'Notification';
    final body = data['body'] ?? '';
    final isRead = data['read'] ?? false;
    final sentAt = (data['sentAt'] as Timestamp?)?.toDate();
    final notificationData = data['data'] as Map<String, dynamic>? ?? {};
    final type = notificationData['type'] ?? 'default';

    final icon = _notificationIcons[type] ?? _notificationIcons['default']!;
    final color = _notificationColors[type] ?? _notificationColors['default']!;

    return Dismissible(
      key: Key(notificationId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppDesignSystem.secondaryRed,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) async {
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(notificationId)
            .delete();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification dismissed'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead
                ? AppDesignSystem.backgroundGrey
                : color.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              // Mark as read
              if (!isRead) {
                await _notificationService.markAsRead(notificationId);
              }

              // Navigate based on notification type
              _handleNotificationTap(notificationData);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  color: AppDesignSystem.textPrimary,
                                  fontSize: 16,
                                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                ),
                              ),
                            ),
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          body,
                          style: TextStyle(
                            color: AppDesignSystem.textSecondary,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (sentAt != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _formatTimestamp(sentAt),
                            style: TextStyle(
                              color: AppDesignSystem.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    
    switch (type) {
      case 'badge':
        Navigator.pushNamed(context, '/badges');
        break;
      case 'announcement':
        // Navigate to announcements screen
        Navigator.pushNamed(context, '/announcements');
        break;
      case 'assignment':
        if (data['assignmentId'] != null) {
          Navigator.pushNamed(
            context,
            '/assignment-detail',
            arguments: {'assignmentId': data['assignmentId']},
          );
        }
        break;
      case 'join_request':
      case 'join_approved':
      case 'join_rejected':
        if (data['classroomId'] != null) {
          Navigator.pushNamed(
            context,
            '/classroom-detail',
            arguments: {'classroomId': data['classroomId']},
          );
        }
        break;
      case 'message':
        if (data['chatId'] != null) {
          Navigator.pushNamed(
            context,
            '/chat',
            arguments: {
              'chatId': data['chatId'],
              'otherUserName': data['senderName'] ?? 'User',
              'otherUserAvatar': data['senderAvatar'],
            },
          );
        }
        break;
      case 'certificate':
        Navigator.pushNamed(context, '/certificates');
        break;
      case 'level_complete':
      case 'realm_complete':
        if (data['realmId'] != null) {
          Navigator.pushNamed(
            context,
            '/realm-detail',
            arguments: {'realmId': data['realmId']},
          );
        }
        break;
      case 'daily_challenge':
        Navigator.pushNamed(context, '/daily-challenge');
        break;
      case 'rank_change':
        Navigator.pushNamed(context, '/leaderboard');
        break;
      default:
        // Do nothing for unknown types
        break;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
