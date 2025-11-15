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
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar with gradient
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
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                child: Row(
                  children: [
                    // Back button on left
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    // Centered title
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Notifications',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Mark all button on right (icon only for symmetry)
                    IconButton(
                      icon: const Icon(Icons.done_all, color: Colors.white),
                      tooltip: 'Mark all as read',
                      onPressed: () async {
                        await _notificationService.markAllAsRead();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text('All marked as read'),
                                ],
                              ),
                              backgroundColor: AppDesignSystem.primaryGreen,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Filter chips with icons
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('all', 'All', Icons.notifications_active),
                    const SizedBox(width: 10),
                    _buildFilterChip('badge', 'Badges', Icons.emoji_events),
                    const SizedBox(width: 10),
                    _buildFilterChip('announcement', 'Announcements', Icons.campaign),
                    const SizedBox(width: 10),
                    _buildFilterChip('message', 'Messages', Icons.message),
                    const SizedBox(width: 10),
                    _buildFilterChip('certificate', 'Certificates', Icons.workspace_premium),
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
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label, IconData icon) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppDesignSystem.gradientPrimary : null,
          color: isSelected ? null : AppDesignSystem.backgroundGrey,
          borderRadius: BorderRadius.circular(25),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppDesignSystem.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppDesignSystem.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(String notificationId, Map<String, dynamic> data) {
    final title = data['title'] ?? 'Notification';
    var body = data['body'] ?? '';
    final isRead = data['read'] ?? false;
    final sentAt = (data['sentAt'] as Timestamp?)?.toDate();
    final notificationData = data['data'] as Map<String, dynamic>? ?? {};
    final type = notificationData['type'] ?? 'default';

    // Add badge/certificate details to body if available
    if (type == 'badge' && notificationData['badgeName'] != null) {
      body = 'You earned: ${notificationData['badgeName']}';
    } else if (type == 'certificate' && notificationData['certificateName'] != null) {
      body = 'Certificate: ${notificationData['certificateName']}';
    }

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
          gradient: isRead
              ? null
              : LinearGradient(
                  colors: [
                    Colors.white,
                    color.withValues(alpha: 0.03),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: isRead ? Colors.white : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead
                ? AppDesignSystem.backgroundGrey.withValues(alpha: 0.5)
                : color.withValues(alpha: 0.3),
            width: isRead ? 1 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isRead
                  ? Colors.black.withValues(alpha: 0.04)
                  : color.withValues(alpha: 0.1),
              blurRadius: isRead ? 4 : 12,
              offset: Offset(0, isRead ? 1 : 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              // Mark as read
              if (!isRead) {
                await _notificationService.markAsRead(notificationId);
              }

              // Navigate based on notification type
              _handleNotificationTap(notificationData);
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon with gradient background
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.2),
                          color.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: color.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
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
                                  fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            if (!isRead)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [color, color.withValues(alpha: 0.8)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'NEW',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          body,
                          style: TextStyle(
                            color: AppDesignSystem.textSecondary,
                            fontSize: 14,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (sentAt != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: AppDesignSystem.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatTimestamp(sentAt),
                                style: TextStyle(
                                  color: AppDesignSystem.textTertiary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
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
