import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/badge_service.dart';
import '../../core/models/badge_model.dart';
import '../../widgets/clean_card.dart';

/// Badges Screen - Display all badges (earned and locked)
class BadgesScreen extends StatefulWidget {
  const BadgesScreen({Key? key}) : super(key: key);

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  final BadgeService _badgeService = BadgeService();
  List<String> _earnedBadges = [];
  Map<String, List<BadgeModel>> _badgesByCategory = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          _earnedBadges = List<String>.from(userDoc.data()?['badges'] ?? []);
        }
        
        // Load all badges and group by category
        final allBadges = await _badgeService.getAllBadges();
        _badgesByCategory = {};
        for (var badge in allBadges) {
          if (!_badgesByCategory.containsKey(badge.category)) {
            _badgesByCategory[badge.category] = [];
          }
          _badgesByCategory[badge.category]!.add(badge);
        }
        
        setState(() {
          _isLoading = false;
        });
      } catch (e) {
        print('Error loading badges: $e');
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('My Badges'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Badges'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats card
            CleanCard(
              color: AppColors.primary.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    label: 'Earned',
                    value: '${_earnedBadges.length}',
                    icon: Icons.emoji_events,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.border,
                  ),
                  _StatItem(
                    label: 'Total',
                    value: '${_getTotalBadgeCount(_badgesByCategory)}',
                    icon: Icons.military_tech,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.border,
                  ),
                  _StatItem(
                    label: 'Progress',
                    value: '${_getTotalBadgeCount(_badgesByCategory) > 0 ? (_earnedBadges.length / _getTotalBadgeCount(_badgesByCategory) * 100).toInt() : 0}%',
                    icon: Icons.trending_up,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Badges by category
            ..._badgesByCategory.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getCategoryTitle(entry.key),
                    style: AppTextStyles.sectionHeader,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: AppSpacing.sm,
                      mainAxisSpacing: AppSpacing.sm,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: entry.value.length,
                    itemBuilder: (context, index) {
                      final badge = entry.value[index];
                      final isEarned = _earnedBadges.contains(badge.id);
                      return _BadgeCard(
                        badge: badge,
                        isEarned: isEarned,
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  int _getTotalBadgeCount(Map<String, List<BadgeModel>> badgesByCategory) {
    return badgesByCategory.values.fold(0, (sum, badges) => sum + badges.length);
  }

  String _getCategoryTitle(String category) {
    switch (category) {
      case 'xp':
        return '⭐ XP Badges';
      case 'streak':
        return '🔥 Streak Badges';
      case 'realm':
        return '🏆 Realm Badges';
      case 'level':
        return '📚 Level Badges';
      case 'game':
        return '🎮 Game Badges';
      case 'achievement':
        return '💯 Achievement Badges';
      default:
        return category;
    }
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.h2.copyWith(color: AppColors.primary),
        ),
        Text(
          label,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final BadgeModel badge;
  final bool isEarned;

  const _BadgeCard({
    Key? key,
    required this.badge,
    required this.isEarned,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Text(
                  badge.iconEmoji,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    badge.name,
                    style: AppTextStyles.h3,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badge.description,
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isEarned
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.textTertiary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isEarned ? '✓ Earned' : '🔒 Locked',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isEarned ? AppColors.success : AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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
      },
      child: CleanCard(
        color: isEarned ? Colors.white : AppColors.backgroundGrey,
        child: Opacity(
          opacity: isEarned ? 1.0 : 0.5,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  badge.iconEmoji,
                  style: const TextStyle(fontSize: 40),
                ),
                const SizedBox(height: 6),
                Flexible(
                  child: Text(
                    badge.name,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isEarned) ...[
                  const SizedBox(height: 2),
                  const Icon(
                    Icons.lock,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

