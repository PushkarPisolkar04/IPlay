import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/content_service.dart';
import '../../core/models/realm_model.dart';
import '../../widgets/clean_card.dart';
import '../../widgets/progress_bar.dart';
import '../../widgets/primary_button.dart';

/// Learn Screen - All realms with search and progress
class LearnScreen extends StatefulWidget {
  const LearnScreen({Key? key}) : super(key: key);

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ContentService _contentService = ContentService();
  List<RealmModel> _realms = [];
  Map<String, dynamic> _userProgress = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Load realms from ContentService
      setState(() {
        _realms = _contentService.getAllRealms();
      });

      // Load user progress from Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          setState(() {
            _userProgress = userDoc.data()?['progressSummary'] ?? {};
          });
        }
      }
    } catch (e) {
      print('Error loading realms: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  double _getRealmProgress(String realmId) {
    if (_userProgress.containsKey(realmId)) {
      final realmProgress = _userProgress[realmId];
      if (realmProgress != null && realmProgress is Map) {
        final completed = realmProgress['levelsCompleted'] ?? 0;
        final total = realmProgress['totalLevels'] ?? 1;
        return completed / total;
      }
    }
    return 0.0;
  }

  int _getTotalXP() {
    int totalXP = 0;
    _userProgress.forEach((key, value) {
      if (value is Map && value.containsKey('xpEarned')) {
        totalXP += (value['xpEarned'] as num).toInt();
      }
    });
    return totalXP;
  }

  int _getCompletedRealms() {
    int count = 0;
    _userProgress.forEach((key, value) {
      if (value is Map && value['completed'] == true) {
        count++;
      }
    });
    return count;
  }

  double _getOverallProgress() {
    if (_realms.isEmpty) return 0.0;
    double totalProgress = 0.0;
    for (final realm in _realms) {
      totalProgress += _getRealmProgress(realm.id);
    }
    return totalProgress / _realms.length;
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Learn IPR'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final totalXP = _getTotalXP();
    final completedRealms = _getCompletedRealms();
    final overallProgress = _getOverallProgress();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Learn IPR'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            CleanCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search realms...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Your Progress card
            Text(
              'Your Progress',
              style: AppTextStyles.sectionHeader,
            ),
            const SizedBox(height: AppSpacing.sm),
            
            CleanCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall: ${(overallProgress * 100).toInt()}% Complete',
                    style: AppTextStyles.cardTitle,
                  ),
                  const SizedBox(height: 12),
                  ProgressBar(progress: overallProgress, height: 10),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '$completedRealms/${_realms.length} Realms',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '•',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.stars,
                            size: 16,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$totalXP XP',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // All Realms section
            Text(
              'All Realms (${_realms.length})',
              style: AppTextStyles.sectionHeader,
            ),
            const SizedBox(height: AppSpacing.sm),
            
            // Realm cards from ContentService
            ...(_realms.map((realm) {
              final progress = _getRealmProgress(realm.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.cardSpacing),
                child: _RealmCard(
                  title: realm.name,
                  description: realm.description,
                  levelCount: realm.totalLevels,
                  xp: realm.totalXP,
                  progress: progress,
                  color: Color(realm.color),
                  icon: realm.iconEmoji,
                  isStarted: progress > 0,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/realm-detail',
                      arguments: {
                        'realmId': realm.id,
                        'title': realm.name,
                        'color': realm.color,
                        'description': realm.description,
                        'totalLevels': realm.totalLevels,
                        'totalXP': realm.totalXP,
                      },
                    );
                  },
                ),
              );
            }).toList()),
            
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

/// Realm card with progress
class _RealmCard extends StatelessWidget {
  final String title;
  final String description;
  final int levelCount;
  final int xp;
  final double progress;
  final Color color;
  final String icon; // Emoji string
  final bool isStarted;
  final VoidCallback onTap;
  
  const _RealmCard({
    Key? key,
    required this.title,
    required this.description,
    required this.levelCount,
    required this.xp,
    required this.progress,
    required this.color,
    required this.icon,
    required this.isStarted,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ColoredCard(
      color: color,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.textWhite,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              Text(
                '$levelCount levels',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '•',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.stars,
                size: 14,
                color: Colors.white.withOpacity(0.9),
              ),
              const SizedBox(width: 4),
              Text(
                '$xp XP',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          
          if (isStarted) ...[
            const SizedBox(height: 16),
            ProgressBar(
              progress: progress,
              color: Colors.white,
              backgroundColor: Colors.white.withOpacity(0.3),
              height: 8,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${(progress * 100).toInt()}%',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: color,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isStarted ? 'Continue' : 'Start',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
