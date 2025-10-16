import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/clean_card.dart';
import '../../widgets/avatar_widget.dart';

/// Leaderboard Screen - Rankings with podium
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _selectedFilter = 'State';
  List<LeaderboardEntry> _leaderboard = [];
  LeaderboardEntry? _currentUserEntry;
  bool _isLoading = true;
  String? _userClassroomId;
  String? _userState;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          setState(() {
            _userClassroomId = userDoc.data()?['classroomId'];
            _userState = userDoc.data()?['state'];
          });
          await _loadLeaderboard();
        }
      } catch (e) {
        print('Error loading user info: $e');
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    
    try {
      Query query = FirebaseFirestore.instance.collection('users');
      
      // Apply filters based on selected filter
      switch (_selectedFilter) {
        case 'Class':
          if (_userClassroomId != null) {
            query = query.where('classroomId', isEqualTo: _userClassroomId);
          } else {
            // No classroom, show message
            setState(() {
              _leaderboard = [];
              _isLoading = false;
            });
            return;
          }
          break;
        case 'School':
          // For now, same as classroom since we don't have school structure yet
          if (_userClassroomId != null) {
            final classroomDoc = await FirebaseFirestore.instance
                .collection('classrooms')
                .doc(_userClassroomId)
                .get();
            
            if (classroomDoc.exists) {
              final schoolTag = classroomDoc.data()?['schoolTag'];
              if (schoolTag != null) {
                query = query.where('schoolTag', isEqualTo: schoolTag);
              }
            }
          }
          break;
        case 'State':
          if (_userState != null) {
            query = query.where('state', isEqualTo: _userState);
          }
          break;
        case 'National':
          // No filter, all users
          break;
      }
      
      // Order by totalXP and limit to top 50
      query = query.orderBy('totalXP', descending: true).limit(50);
      
      final snapshot = await query.get();
      final currentUser = FirebaseAuth.instance.currentUser;
      
      final entries = <LeaderboardEntry>[];
      LeaderboardEntry? currentEntry;
      
      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data() as Map<String, dynamic>;
        
        final entry = LeaderboardEntry(
          rank: i + 1,
          userId: doc.id,
          displayName: data['displayName'] ?? 'Unknown',
          avatarUrl: data['avatarUrl'],
          totalXP: data['totalXP'] ?? 0,
          badgeCount: (data['badges'] as List?)?.length ?? 0,
          isCurrentUser: doc.id == currentUser?.uid,
        );
        
        entries.add(entry);
        
        if (doc.id == currentUser?.uid) {
          currentEntry = entry;
        }
      }
      
      setState(() {
        _leaderboard = entries;
        _currentUserEntry = currentEntry;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading leaderboard: $e');
      setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Class',
                    isSelected: _selectedFilter == 'Class',
                    onTap: () {
                      setState(() => _selectedFilter = 'Class');
                      _loadLeaderboard();
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'School',
                    isSelected: _selectedFilter == 'School',
                    onTap: () {
                      setState(() => _selectedFilter = 'School');
                      _loadLeaderboard();
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'State',
                    isSelected: _selectedFilter == 'State',
                    onTap: () {
                      setState(() => _selectedFilter = 'State');
                      _loadLeaderboard();
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '🇮🇳 National',
                    isSelected: _selectedFilter == 'National',
                    onTap: () {
                      setState(() => _selectedFilter = 'National');
                      _loadLeaderboard();
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // User rank card
            if (_currentUserEntry != null)
              ColoredCard(
                color: AppColors.primary,
                child: Row(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Rank: #${_currentUserEntry!.rank}',
                            style: AppTextStyles.cardTitle.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_currentUserEntry!.totalXP} XP • ${_currentUserEntry!.badgeCount} Badges',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else if (!_isLoading)
              CleanCard(
                child: Text(
                  _selectedFilter == 'Class' && _userClassroomId == null
                      ? 'Join a classroom to see class rankings!'
                      : 'Not ranked yet. Complete more levels to appear!',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            
            const SizedBox(height: AppSpacing.lg),
            
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_leaderboard.isEmpty)
              CleanCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'No users found for this leaderboard.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else ...[
              if (_leaderboard.length >= 3) ...[
                Text(
                  'Top 3',
                  style: AppTextStyles.sectionHeader,
                ),
                const SizedBox(height: AppSpacing.sm),
                
                // Podium
                SizedBox(
                  height: 200,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 2nd place
                      if (_leaderboard.length >= 2)
                        Expanded(
                          child: _PodiumPosition(
                            rank: 2,
                            name: _leaderboard[1].displayName,
                            xp: _leaderboard[1].totalXP,
                            avatarUrl: _leaderboard[1].avatarUrl,
                            color: AppColors.textSecondary,
                            height: 140,
                          ),
                        ),
                      const SizedBox(width: 8),
                      // 1st place
                      Expanded(
                        child: _PodiumPosition(
                          rank: 1,
                          name: _leaderboard[0].displayName,
                          xp: _leaderboard[0].totalXP,
                          avatarUrl: _leaderboard[0].avatarUrl,
                          color: AppColors.accent,
                          height: 180,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 3rd place
                      if (_leaderboard.length >= 3)
                        Expanded(
                          child: _PodiumPosition(
                            rank: 3,
                            name: _leaderboard[2].displayName,
                            xp: _leaderboard[2].totalXP,
                            avatarUrl: _leaderboard[2].avatarUrl,
                            color: const Color(0xFFCD7F32),
                            height: 120,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              
              // Rankings list (4th onwards)
              ...(_leaderboard.skip(3).map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.cardSpacing),
                child: _RankingItem(
                  rank: entry.rank,
                  name: entry.displayName,
                  xp: entry.totalXP,
                  badges: entry.badgeCount,
                  avatarUrl: entry.avatarUrl,
                  isCurrentUser: entry.isCurrentUser,
                ),
              )).toList()),
            ],
            
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

/// Leaderboard entry model
class LeaderboardEntry {
  final int rank;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int totalXP;
  final int badgeCount;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.totalXP,
    required this.badgeCount,
    this.isCurrentUser = false,
  });
}

/// Filter chip
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _FilterChip({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/// Podium position
class _PodiumPosition extends StatelessWidget {
  final int rank;
  final String name;
  final int xp;
  final String? avatarUrl;
  final Color color;
  final double height;

  const _PodiumPosition({
    Key? key,
    required this.rank,
    required this.name,
    required this.xp,
    this.avatarUrl,
    required this.color,
    required this.height,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    String medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : '🥉';
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Avatar
        AvatarWidget(
          initials: name[0],
          size: rank == 1 ? 56 : 48,
          backgroundColor: color.withOpacity(0.2),
        ),
        const SizedBox(height: 8),
        // Name
        Text(
          name,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        // XP
        Text(
          '$xp',
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        // Podium
        Container(
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              medal,
              style: TextStyle(
                fontSize: rank == 1 ? 48 : 36,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Ranking list item
class _RankingItem extends StatelessWidget {
  final int rank;
  final String name;
  final int xp;
  final int badges;
  final String? avatarUrl;
  final bool isCurrentUser;

  const _RankingItem({
    Key? key,
    required this.rank,
    required this.name,
    required this.xp,
    required this.badges,
    this.avatarUrl,
    this.isCurrentUser = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return CleanCard(
      color: isCurrentUser ? AppColors.primary.withOpacity(0.1) : null,
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.backgroundGrey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: AppTextStyles.h4.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Avatar
          AvatarWidget(
            initials: name[0],
            size: 40,
          ),
          
          const SizedBox(width: 12),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      size: 14,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$badges badges',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // XP
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$xp XP',
                style: AppTextStyles.cardTitle.copyWith(
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
