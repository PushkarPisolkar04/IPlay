import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/content_service.dart';
import '../../core/models/user_model.dart';
import '../../widgets/clean_card.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/progress_bar.dart';

/// Profile Screen - User profile with stats and progress
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ContentService _contentService = ContentService();
  UserModel? _user;
  Map<String, dynamic> _progressSummary = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        if (doc.exists) {
          setState(() {
            _user = UserModel.fromMap(doc.data()!);
            _progressSummary = doc.data()?['progressSummary'] ?? {};
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Calculate user level from total XP
  int _getUserLevel() {
    if (_user == null) return 1;
    // Formula: level = floor(XP / 200) + 1
    // E.g., 0-199 XP = Level 1, 200-399 = Level 2, etc.
    return (_user!.totalXP / 200).floor() + 1;
  }

  // Calculate XP needed for next level
  int _getXPToNextLevel() {
    if (_user == null) return 200;
    final currentLevel = _getUserLevel();
    final xpForNextLevel = currentLevel * 200;
    return xpForNextLevel - _user!.totalXP;
  }

  // Calculate progress towards next level
  double _getLevelProgress() {
    if (_user == null) return 0.0;
    final currentLevel = _getUserLevel();
    final xpForCurrentLevel = (currentLevel - 1) * 200;
    final xpInCurrentLevel = _user!.totalXP - xpForCurrentLevel;
    return (xpInCurrentLevel / 200).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: Text('User not found'),
        ),
      );
    }

    final userLevel = _getUserLevel();
    final xpToNext = _getXPToNextLevel();
    final levelProgress = _getLevelProgress();
    final realms = _contentService.getAllRealms();
    final String initials = _user!.displayName.split(' ')
        .map((n) => n.isNotEmpty ? n[0] : '')
        .take(2)
        .join()
        .toUpperCase();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          children: [
            // Large avatar
            AvatarWidget(
              initials: initials,
              size: 120,
              backgroundColor: AppColors.secondary,
              imageUrl: _user!.avatarUrl,
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Name
            Text(
              _user!.displayName,
              style: AppTextStyles.h1,
            ),
            
            const SizedBox(height: 4),
            
            // Details
            Text(
              _user!.state,
              style: AppTextStyles.caption,
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Stats cards row
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: '🔥',
                    value: '${_user!.currentStreak}',
                    label: 'Streak',
                  ),
                ),
                const SizedBox(width: AppSpacing.cardSpacing),
                Expanded(
                  child: _StatCard(
                    icon: '🏅',
                    value: '${_user!.badges.length}',
                    label: 'Badges',
                  ),
                ),
                const SizedBox(width: AppSpacing.cardSpacing),
                Expanded(
                  child: _StatCard(
                    icon: '⭐',
                    value: '0', // TODO: Fetch from CertificateService
                    label: 'Certs',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Level card
            ColoredCard(
              color: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Level $userLevel',
                        style: AppTextStyles.h3.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.stars,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_user!.totalXP} XP',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ProgressBar(
                    progress: levelProgress,
                    color: Colors.white,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    height: 10,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$xpToNext XP to Level ${userLevel + 1}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // My Realms
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'My Realms',
                style: AppTextStyles.sectionHeader,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            
            CleanCard(
              child: Column(
                children: realms.asMap().entries.map((entry) {
                  final index = entry.key;
                  final realm = entry.value;
                  final realmProgress = _progressSummary[realm.id];
                  final progress = realmProgress != null && realmProgress is Map
                      ? (realmProgress['levelsCompleted'] ?? 0) / (realmProgress['totalLevels'] ?? 1)
                      : 0.0;
                  
                  return Column(
                    children: [
                      if (index > 0) const Divider(height: 24),
                      _RealmProgress(
                        icon: realm.iconEmoji,
                        title: realm.name,
                        progress: progress,
                        color: Color(realm.color),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // My Badges
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Badges (${_user!.badges.length})',
                  style: AppTextStyles.sectionHeader,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/badges');
                  },
                  child: Text(
                    'View All',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            
            // Badge grid
            if (_user!.badges.isNotEmpty)
              GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _user!.badges.length.clamp(0, 8),
                itemBuilder: (context, index) {
                  // TODO: Map badge IDs to icons
                  return _BadgeItem(icon: '🏅');
                },
              )
            else
              CleanCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      'No badges yet. Complete levels to earn badges!',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Certificates
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Certificates (0)', // TODO: Fetch from CertificateService
                  style: AppTextStyles.sectionHeader,
                ),
                if (false) // TODO: Fetch certificates
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to certificates screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Certificate details coming soon!'),
                        ),
                      );
                    },
                    child: Text(
                      'View All',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            
            if (false) // TODO: Fetch certificates
              ...([]/*.take(3)*/.map((cert) {
                // TODO: Parse certificate data properly
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: CleanCard(
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              '📜',
                              style: TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cert,
                                style: AppTextStyles.cardTitle.copyWith(
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap to view',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.download, size: 20),
                          onPressed: () {
                            // TODO: Download certificate
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Certificate download coming soon!'),
                              ),
                            );
                          },
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList())
            else
              CleanCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      'No certificates yet. Complete realms to earn certificates!',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

/// Stat card
class _StatCard extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  
  const _StatCard({
    Key? key,
    required this.icon,
    required this.value,
    required this.label,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return CleanCard(
      child: Column(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.h2,
          ),
          Text(
            label,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Realm progress item
class _RealmProgress extends StatelessWidget {
  final String icon; // Emoji string
  final String title;
  final double progress;
  final Color color;
  
  const _RealmProgress({
    Key? key,
    required this.icon,
    required this.title,
    required this.progress,
    required this.color,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          icon,
          style: TextStyle(fontSize: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              ProgressBar(
                progress: progress,
                color: color,
                height: 6,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${(progress * 100).toInt()}%',
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Badge item
class _BadgeItem extends StatelessWidget {
  final String icon;
  
  const _BadgeItem({
    Key? key,
    required this.icon,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return CleanCard(
      child: Center(
        child: Text(
          icon,
          style: const TextStyle(fontSize: 32),
        ),
      ),
    );
  }
}
