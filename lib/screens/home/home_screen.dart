import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/models/user_model.dart';
import '../../core/services/content_service.dart';
import '../../models/classroom_model.dart';
import '../../widgets/clean_card.dart';
import '../../widgets/top_bar_with_avatar.dart';
import '../../widgets/streak_indicator.dart';
import '../../widgets/loading_skeleton.dart';
import '../student/my_progress_screen.dart';
import '../learn/learn_screen.dart';
import '../leaderboard/unified_leaderboard_screen.dart';
import '../teacher/classroom_detail_screen.dart';

/// Home Screen - Loads real user data from Firebase
class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  
  const HomeScreen({super.key, this.onNavigateToTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ContentService _contentService = ContentService();
  UserModel? _user;
  bool _isLoading = true;
  String _greeting = 'Good Morning';
  Map<String, dynamic>? _classroomInfo;
  Map<String, dynamic>? _schoolInfo;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _setGreeting();
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good Morning';
    } else if (hour < 17) {
      _greeting = 'Good Afternoon';
    } else {
      _greeting = 'Good Evening';
    }
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // print('Loading user data for: ${currentUser.uid}');
        
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        if (doc.exists && mounted) {
          final userData = doc.data()!;
          // print('User data loaded: ${userData['displayName']}');
          // print('Total XP: ${userData['totalXP']}');
          // print('Current Streak: ${userData['currentStreak']}');
          // print('Badges: ${userData['badges']?.length ?? 0}');
          
          setState(() {
            _user = UserModel.fromMap(userData);
          });
          
          // Load classroom info if student is in a classroom
          await _loadClassroomInfo(userData);
          
          setState(() => _isLoading = false);
        } else {
          // print('User document does not exist!');
        }
      } else {
        // print('No current user!');
      }
    } catch (e) {
      // print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadClassroomInfo(Map<String, dynamic> userData) async {
    try {
      // Check if user has classroomIds
      final classroomIds = userData['classroomIds'] as List?;
      if (classroomIds != null && classroomIds.isNotEmpty) {
        final classroomId = classroomIds.first;
        
        // print('Loading classroom info: $classroomId');
        
        final classroomDoc = await FirebaseFirestore.instance
            .collection('classrooms')
            .doc(classroomId)
            .get();
        
        if (classroomDoc.exists) {
          _classroomInfo = classroomDoc.data()!;
          // print('Classroom loaded: ${_classroomInfo!['name']}');
          
          // Load school info if classroom has schoolId
          final schoolId = _classroomInfo!['schoolId'];
          if (schoolId != null) {
            final schoolDoc = await FirebaseFirestore.instance
                .collection('schools')
                .doc(schoolId)
                .get();
            
            if (schoolDoc.exists) {
              _schoolInfo = schoolDoc.data()!;
              // print('School loaded: ${_schoolInfo!['name']}');
            }
          }
        }
      }
    } catch (e) {
      // print('Error loading classroom info: $e');
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await _loadUserData();
  }

  String _getInitials() {
    if (_user == null) return 'U';
    final names = _user!.displayName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return _user!.displayName[0].toUpperCase();
  }

  Future<int> _getUserRank(int userXP) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return 1;
      
      // Get all students with higher XP
      final higherXPSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('totalXP', isGreaterThan: userXP)
          .get();
      
      // Rank is number of students with higher XP + 1
      return higherXPSnapshot.docs.length + 1;
    } catch (e) {
      // print('Error getting user rank: $e');
      return 1;
    }
  }

  Future<List<Map<String, dynamic>>> _getRecommendedLevels() async {
    try {
      if (_user == null) return [];
      
      final recommendations = <Map<String, dynamic>>[];
      final realms = await _contentService.getAllRealms();
      
      // Show all realms that user hasn't completed (up to 3)
      for (final realm in realms) {
        final realmProgress = _user!.progressSummary[realm.id];
        if (realmProgress == null || !realmProgress.completed) {
          recommendations.add({
            'title': realm.name,
            'subtitle': 'Start learning • ${realm.totalLevels} levels',
            'levelId': realm.id,
            'color': realm.color,
          });
          
          // Stop after 3 recommendations
          if (recommendations.length >= 3) break;
        }
      }
      
      // If all realms are completed, show the first 2 anyway
      if (recommendations.isEmpty && realms.isNotEmpty) {
        for (final realm in realms.take(2)) {
          recommendations.add({
            'title': realm.name,
            'subtitle': 'Review • ${realm.totalLevels} levels',
            'levelId': realm.id,
            'color': realm.color,
          });
        }
      }
      
      return recommendations;
    } catch (e) {
      print('Error loading recommendations: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getRecentActivity() async {
    try {
      if (_user == null) return [];
      
      final activities = <Map<String, dynamic>>[];
      
      // Get recent progress updates (level completions) - WITHOUT orderBy to avoid index requirement
      try {
        final progressUpdates = await FirebaseFirestore.instance
            .collection('progress')
            .where('userId', isEqualTo: _user!.uid)
            .get();
        
        // Sort in memory by lastAccessedAt
        final sortedDocs = progressUpdates.docs.toList()
          ..sort((a, b) {
            final aTime = (a.data()['lastAccessedAt'] as Timestamp?)?.toDate();
            final bTime = (b.data()['lastAccessedAt'] as Timestamp?)?.toDate();
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });
        
        for (final doc in sortedDocs.take(3)) {
          final data = doc.data();
          final realmId = data['realmId'];
          final lastAccessedAt = (data['lastAccessedAt'] as Timestamp?)?.toDate();
          final completedLevels = List<int>.from(data['completedLevels'] ?? []);
          
          if (lastAccessedAt != null && completedLevels.isNotEmpty) {
            final realms = await _contentService.getAllRealms();
            final realm = realms.firstWhere(
              (r) => r.id == realmId,
              orElse: () => realms.first,
            );
            
            activities.add({
              'title': 'Level Completed!',
              'subtitle': '${realm.name} - Level ${completedLevels.last}',
              'time': _getTimeAgo(lastAccessedAt),
              'icon': Icons.check_circle,
              'color': 0xFF10B981,
              'timestamp': lastAccessedAt,
            });
          }
        }
      } catch (e) {
        print('Error loading progress: $e');
      }
      
      // Get recent game plays - WITHOUT orderBy to avoid index requirement
      try {
        final gameProgress = await FirebaseFirestore.instance
            .collection('progress')
            .doc(_user!.uid)
            .collection('games')
            .get();
        
        // Sort in memory by lastPlayedAt
        final sortedDocs = gameProgress.docs.toList()
          ..sort((a, b) {
            final aTime = (a.data()['lastPlayedAt'] as Timestamp?)?.toDate();
            final bTime = (b.data()['lastPlayedAt'] as Timestamp?)?.toDate();
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });
        
        for (final doc in sortedDocs.take(3)) {
          final data = doc.data();
          final gameId = data['gameId'] as String?;
          final lastPlayedAt = (data['lastPlayedAt'] as Timestamp?)?.toDate();
          final highScore = data['highScore'] as int? ?? 0;
          
          if (lastPlayedAt != null && gameId != null) {
            // Format game name from ID
            final gameName = gameId.split('_').map((word) => 
              word[0].toUpperCase() + word.substring(1)
            ).join(' ');
            
            activities.add({
              'title': 'Game Played!',
              'subtitle': '$gameName • Score: $highScore',
              'time': _getTimeAgo(lastPlayedAt),
              'icon': Icons.videogame_asset,
              'color': 0xFFEC4899,
              'timestamp': lastPlayedAt,
            });
          }
        }
      } catch (e) {
        print('Error loading games: $e');
      }
      
      // Get recent badge unlocks - WITHOUT orderBy to avoid index requirement
      try {
        final badgeUnlocks = await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .collection('badge_unlocks')
            .get();
        
        // Sort in memory by unlockedAt
        final sortedDocs = badgeUnlocks.docs.toList()
          ..sort((a, b) {
            final aTime = (a.data()['unlockedAt'] as Timestamp?)?.toDate();
            final bTime = (b.data()['unlockedAt'] as Timestamp?)?.toDate();
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });
        
        for (final doc in sortedDocs.take(3)) {
          final data = doc.data();
          final badgeId = data['badgeId'];
          final unlockedAt = (data['unlockedAt'] as Timestamp).toDate();
          
          final badgeDoc = await FirebaseFirestore.instance
              .collection('badges')
              .doc(badgeId)
              .get();
          
          if (badgeDoc.exists) {
            activities.add({
              'title': 'Badge Unlocked!',
              'subtitle': badgeDoc.data()?['name'] ?? 'New Badge',
              'time': _getTimeAgo(unlockedAt),
              'icon': Icons.emoji_events,
              'color': 0xFFF59E0B,
              'timestamp': unlockedAt,
            });
          }
        }
      } catch (e) {
        print('Error loading badges: $e');
      }
      
      // Get recent daily challenge attempts
      try {
        final challengeAttempts = await FirebaseFirestore.instance
            .collection('daily_challenge_attempts')
            .where('userId', isEqualTo: _user!.uid)
            .orderBy('attemptedAt', descending: true)
            .limit(3)
            .get();
        
        for (final doc in challengeAttempts.docs) {
          final data = doc.data();
          final attemptedAt = (data['attemptedAt'] as Timestamp).toDate();
          final score = data['score'] as int;
          final xpEarned = data['xpEarned'] as int;
          
          activities.add({
            'title': 'Daily Challenge',
            'subtitle': 'Score: $score/5 • +$xpEarned XP',
            'time': _getTimeAgo(attemptedAt),
            'icon': Icons.calendar_today,
            'color': 0xFF6366F1,
            'timestamp': attemptedAt,
          });
        }
      } catch (e) {
        print('Error loading challenges: $e');
      }
      
      // Sort all activities by timestamp (most recent first)
      activities.sort((a, b) {
        final aTime = a['timestamp'] as DateTime?;
        final bTime = b['timestamp'] as DateTime?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });
      
      // Take only the most recent 5 activities
      final recentActivities = activities.take(5).toList();
      
      // If no activities, show a welcome message
      if (recentActivities.isEmpty) {
        return [{
          'title': 'Welcome!',
          'subtitle': 'Start learning to see your activity here',
          'time': 'Now',
          'icon': Icons.celebration,
          'color': 0xFF10B981,
        }];
      }
      
      return recentActivities;
    } catch (e) {
      print('Error loading recent activity: $e');
      return [];
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Not authenticated')),
      );
    }

    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      body: SafeArea(
          child: Column(
            children: [
              // Top bar with avatar (navigates to profile)
              TopBarWithAvatar(
                avatarUrl: _user?.avatarUrl,
                initials: _getInitials(),
                showOnlineBadge: true,
                onAvatarTap: () {
                  Navigator.pushNamed(context, '/profile');
                },
              ),
              
              // Scrollable content with pull-to-refresh and real-time updates
              Expanded(
                child: _isLoading
                    ? const SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          LoadingSkeleton(height: 120, borderRadius: BorderRadius.all(Radius.circular(12))),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: LoadingSkeleton(height: 100, borderRadius: BorderRadius.all(Radius.circular(12)))),
                              SizedBox(width: 12),
                              Expanded(child: LoadingSkeleton(height: 100, borderRadius: BorderRadius.all(Radius.circular(12)))),
                            ],
                          ),
                          SizedBox(height: 16),
                          LoadingSkeleton(height: 200, borderRadius: BorderRadius.all(Radius.circular(12))),
                        ],
                      ),
                    )
                    : StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUser.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        // Use cached data while waiting for stream
                        UserModel? streamUser = _user;
                        
                        if (snapshot.hasData && snapshot.data!.exists) {
                          streamUser = UserModel.fromMap(
                            snapshot.data!.data() as Map<String, dynamic>,
                          );
                        }
                        
                        return RefreshIndicator(
                          onRefresh: _refreshData,
                          color: AppDesignSystem.primaryIndigo,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.screenHorizontal,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                
                                // Greeting with streak (real-time)
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF6366F1), // Indigo
                                        const Color(0xFF8B5CF6), // Purple
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '$_greeting!',
                                              style: AppTextStyles.h2.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              streamUser?.displayName ?? 'Student',
                                              style: AppTextStyles.h3.copyWith(
                                                color: Colors.white.withValues(alpha: 0.95),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('🔥', style: TextStyle(fontSize: 24)),
                                            const SizedBox(width: 8),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  '${streamUser?.currentStreak ?? 0}',
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFFF59E0B),
                                                  ),
                                                ),
                                                const Text(
                                                  'Day Streak',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF6B7280),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: AppSpacing.lg),
                                
                                // Quick Stats Row with animated XP
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(AppSpacing.md),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color(0xFFFBBF24),
                                              const Color(0xFFF59E0B),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: InkWell(
                                          onTap: () => Navigator.pushNamed(context, '/profile'),
                                          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.stars,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${streamUser?.totalXP ?? 0}',
                                                style: AppTextStyles.h2.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                'Total XP',
                                                style: AppTextStyles.caption.copyWith(
                                                  color: Colors.white.withValues(alpha: 0.9),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.cardSpacing),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(AppSpacing.md),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color(0xFFEC4899),
                                              const Color(0xFFDB2777),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFEC4899).withValues(alpha: 0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: InkWell(
                                          onTap: () => Navigator.pushNamed(context, '/badges'),
                                          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.emoji_events,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${streamUser?.badges.length ?? 0}',
                                                style: AppTextStyles.h2.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                'Badges',
                                                style: AppTextStyles.caption.copyWith(
                                                  color: Colors.white.withValues(alpha: 0.9),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.cardSpacing),
                                    Expanded(
                                      child: FutureBuilder<int>(
                                        future: _getUserRank(streamUser?.totalXP ?? 0),
                                        builder: (context, rankSnapshot) {
                                          return Container(
                                            padding: const EdgeInsets.all(AppSpacing.md),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  const Color(0xFF6366F1),
                                                  const Color(0xFF4F46E5),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: InkWell(
                                              onTap: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => const UnifiedLeaderboardScreen(),
                                                ),
                                              ),
                                              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                                              child: Column(
                                                children: [
                                                  Icon(
                                                    Icons.leaderboard,
                                                    color: Colors.white,
                                                    size: 28,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    rankSnapshot.hasData && rankSnapshot.data! > 0 ? '#${rankSnapshot.data}' : '#1',
                                                    style: AppTextStyles.h2.copyWith(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Rank',
                                                    style: AppTextStyles.caption.copyWith(
                                                      color: Colors.white.withValues(alpha: 0.9),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                          
                          const SizedBox(height: AppSpacing.lg),
                          
                          // Daily Challenge Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFF59E0B),
                                  const Color(0xFFEF4444),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.emoji_events,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Daily Challenge',
                                            style: AppTextStyles.h4.copyWith(
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            'Complete today\'s challenge for bonus XP!',
                                            style: AppTextStyles.bodySmall.copyWith(
                                              color: Colors.white.withValues(alpha: 0.9),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/daily-challenge');
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppDesignSystem.primaryAmber,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Start Challenge',
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: AppSpacing.lg),
                          
                          // Classroom & School Info Card (if exists)
                          if (_classroomInfo != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.school,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _classroomInfo!['name'] ?? 'Classroom',
                                              style: AppTextStyles.h3.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (_schoolInfo != null)
                                              Text(
                                                _schoolInfo!['name'] ?? '',
                                                style: AppTextStyles.bodySmall.copyWith(
                                                  color: Colors.white.withValues(alpha: 0.9),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                'Grade',
                                                style: AppTextStyles.caption.copyWith(
                                                  color: Colors.white.withValues(alpha: 0.9),
                                                ),
                                              ),
                                              Text(
                                                '${_classroomInfo!['grade'] ?? '-'}',
                                                style: AppTextStyles.h3.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                'Students',
                                                style: AppTextStyles.caption.copyWith(
                                                  color: Colors.white.withValues(alpha: 0.9),
                                                ),
                                              ),
                                              Text(
                                                '${(_classroomInfo!['studentIds'] as List?)?.length ?? 0}',
                                                style: AppTextStyles.h3.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                          
                          // Continue Learning Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Continue Learning',
                                style: AppTextStyles.sectionHeader,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          
                          // Featured card (Continue Learning) with gradient
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Start Your',
                                            style: AppTextStyles.h2.copyWith(
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            'IPR Journey',
                                            style: AppTextStyles.h2.copyWith(
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '6 Realms • 40+ Levels',
                                            style: AppTextStyles.bodySmall.copyWith(
                                              color: Colors.white.withValues(alpha: 0.9),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Logo
                                    Image.asset(
                                      'assets/logos/logo.png',
                                      width: 80,
                                      height: 80,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Navigate to Learn tab (index 1)
                                      widget.onNavigateToTab?.call(1);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF10B981),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Start Learning →',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: AppSpacing.lg),
                          
                          // Quick Actions Section
                          Text(
                            'Quick Actions',
                            style: AppTextStyles.sectionHeader,
                          ),
                          
                          const SizedBox(height: AppSpacing.sm),
                          
                          GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 1.6,
                            children: [
                              // Join Classroom
                              _buildActionCard(
                                context,
                                icon: Icons.add_circle_outline,
                                title: 'Join\nClassroom',
                                color: const Color(0xFF10B981),
                                onTap: () {
                                  Navigator.pushNamed(context, '/join-classroom');
                                },
                              ),
                              // Messages
                              _buildActionCard(
                                context,
                                icon: Icons.chat_bubble_outline,
                                title: 'Messages',
                                color: const Color(0xFF3B82F6),
                                onTap: () {
                                  Navigator.pushNamed(context, '/chat-list');
                                },
                              ),
                              // My Badges
                              _buildActionCard(
                                context,
                                icon: Icons.emoji_events_outlined,
                                title: 'My\nBadges',
                                color: const Color(0xFF8B5CF6),
                                onTap: () {
                                  Navigator.pushNamed(context, '/badges');
                                },
                              ),
                              // Progress Report
                              _buildActionCard(
                                context,
                                icon: Icons.assessment_outlined,
                                title: 'My\nProgress',
                                color: const Color(0xFFEC4899),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const MyProgressScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: AppSpacing.lg),
                          
                          // Recommended for You Section (Dynamic - based on user progress)
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: _getRecommendedLevels(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                final recommendations = snapshot.data!;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Recommended for You',
                                      style: AppTextStyles.sectionHeader,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    CleanCard(
                                      child: Column(
                                        children: recommendations.asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final item = entry.value;
                                          return Column(
                                            children: [
                                              if (index > 0) const Divider(height: 1),
                                              ListTile(
                                                leading: Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: Color(item['color']).withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Icon(
                                                    Icons.play_circle_outline,
                                                    color: Color(item['color']),
                                                    size: 24,
                                                  ),
                                                ),
                                                title: Text(item['title']),
                                                subtitle: Text(item['subtitle']),
                                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                                onTap: () {
                                                  // Navigate to the specific realm
                                                  Navigator.pushNamed(
                                                    context,
                                                    '/realm',
                                                    arguments: {'realmId': item['levelId']},
                                                  );
                                                },
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                  ],
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                          
                          // Recent Activity (Dynamic - based on user's actual progress)
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: _getRecentActivity(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                final activities = snapshot.data!.take(3).toList();
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Recent Activity',
                                      style: AppTextStyles.sectionHeader,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    CleanCard(
                                      child: Column(
                                        children: activities.asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final activity = entry.value;
                                          return Column(
                                            children: [
                                              if (index > 0) const Divider(height: 1),
                                              ListTile(
                                                leading: CircleAvatar(
                                                  backgroundColor: Color(activity['color']).withValues(alpha: 0.1),
                                                  child: Icon(
                                                    activity['icon'],
                                                    color: Color(activity['color']),
                                                    size: 20,
                                                  ),
                                                ),
                                                title: Text(activity['title']),
                                                subtitle: Text(activity['subtitle']),
                                                trailing: Text(
                                                  activity['time'],
                                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                  ],
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                          
                          // My Stats section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'My Stats',
                                style: AppTextStyles.sectionHeader,
                              ),
                              TextButton(
                                onPressed: () {
                                  // Navigate to profile
                                  Navigator.pushNamed(context, '/profile');
                                },
                                child: Text(
                                  'View Profile',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppDesignSystem.primaryPink,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: AppSpacing.sm),
                          
                          // Stats cards with improved styling
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFF59E0B),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                        Icons.emoji_events,
                                          size: 24,
                                          color: Color(0xFFF59E0B),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${_user?.badges.length ?? 0}',
                                        style: AppTextStyles.h3.copyWith(
                                          color: const Color(0xFFF59E0B),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Badges',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppDesignSystem.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF8B5CF6),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                        Icons.workspace_premium,
                                          size: 24,
                                          color: Color(0xFF8B5CF6),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${_user?.progressSummary.values.where((r) => r.completed).length ?? 0}',
                                        style: AppTextStyles.h3.copyWith(
                                          color: const Color(0xFF8B5CF6),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Realms Done',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppDesignSystem.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: AppSpacing.xl),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProgressDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('My Progress'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total XP: ${_user?.totalXP ?? 0}'),
            const SizedBox(height: 8),
            Text('Current Streak: ${_user?.currentStreak ?? 0} days'),
            const SizedBox(height: 8),
            Text('Badges Earned: ${_user?.badges.length ?? 0}'),
            const SizedBox(height: 8),
            Text('Realms Completed: ${_user?.progressSummary.values.where((r) => r.completed).length ?? 0}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Helper method to build action cards
  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppDesignSystem.textPrimary,
                fontSize: 12,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Colored card widget
class ColoredCard extends StatelessWidget {
  final Color color;
  final Widget child;
  
  const ColoredCard({
    super.key,
    required this.color,
    required this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: child,
    );
  }
}
