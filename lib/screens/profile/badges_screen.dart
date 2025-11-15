import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/badge_service.dart';
import '../../models/badge_model.dart';
import '../../widgets/clean_card.dart';
import '../../widgets/loading_skeleton.dart';

/// Badges Screen - Display all badges (earned and locked)
class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

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
          print('User has ${_earnedBadges.length} earned badges: $_earnedBadges');
        }

        final allBadges = await _badgeService.getAllBadges();
        print('Loaded ${allBadges.length} total badges from JSON');

        _badgesByCategory = {};
        for (var badge in allBadges) {
          if (!_badgesByCategory.containsKey(badge.category)) {
            _badgesByCategory[badge.category] = [];
          }
          _badgesByCategory[badge.category]!.add(badge);
        }

        if (mounted) {
          setState(() => _isLoading = false);
        }
      } catch (e) {
        print('Error loading badges: $e');
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createBadgeNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _badgeService.createNotificationsForEarnedBadges(user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Badge notifications created! Check your notifications.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppDesignSystem.backgroundLight,
        appBar: AppBar(
          title: const Text('My Badges'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const GridSkeleton(itemCount: 6, crossAxisCount: 3, childAspectRatio: 0.75),
      );
    }

    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Gradient app bar
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
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'My Badges',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AMBER/GOLD STATS CARD WITH GRADIENT
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)], // Darker amber gradient
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StatItem(
                              label: 'Earned',
                              value: '${_earnedBadges.length}',
                              icon: Icons.emoji_events,
                              color: Colors.white,
                            ),
                            _verticalDivider(),
                            _StatItem(
                              label: 'Total',
                              value: '${_getTotalBadgeCount(_badgesByCategory)}',
                              icon: Icons.military_tech,
                              color: Colors.white,
                            ),
                            _verticalDivider(),
                            _StatItem(
                              label: 'Progress',
                              value:
                                  '${_getTotalBadgeCount(_badgesByCategory) > 0 ? (_earnedBadges.length / _getTotalBadgeCount(_badgesByCategory) * 100).toInt() : 0}%',
                              icon: Icons.trending_up,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // No badges message
                    if (_badgesByCategory.isEmpty)
                      CleanCard(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            children: [
                              const Icon(Icons.emoji_events, size: 64, color: AppDesignSystem.textTertiary),
                              const SizedBox(height: AppSpacing.md),
                              Text('No Badges Available',
                                  style: AppTextStyles.h3.copyWith(color: AppDesignSystem.textPrimary)),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Badges will appear here once they are added to the system. Complete levels and challenges to earn badges!',
                                style: AppTextStyles.bodyMedium.copyWith(color: AppDesignSystem.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Owned Badges Section
                    if (_getOwnedBadges().isNotEmpty) ...[
                      Text('Owned Badges', style: AppTextStyles.sectionHeader),
                      const SizedBox(height: AppSpacing.sm),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: _getOwnedBadges().length,
                        itemBuilder: (context, index) {
                          final badge = _getOwnedBadges()[index];
                          return _BadgeCard(badge: badge, isEarned: true);
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],

                    // Locked Badges Section
                    if (_getLockedBadges().isNotEmpty) ...[
                      Text('Locked Badges', style: AppTextStyles.sectionHeader),
                      const SizedBox(height: AppSpacing.sm),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: _getLockedBadges().length,
                        itemBuilder: (context, index) {
                          final badge = _getLockedBadges()[index];
                          return _BadgeCard(badge: badge, isEarned: false);
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _verticalDivider() => Container(
        width: 1,
        height: 40,
        color: Colors.white.withOpacity(0.3),
      );

  int _getTotalBadgeCount(Map<String, List<BadgeModel>> badgesByCategory) {
    return badgesByCategory.values.fold(0, (sum, badges) => sum + badges.length);
  }

  List<BadgeModel> _getOwnedBadges() {
    final allBadges = _badgesByCategory.values.expand((badges) => badges).toList();
    return allBadges.where((badge) => _earnedBadges.contains(badge.id)).toList();
  }

  List<BadgeModel> _getLockedBadges() {
    final allBadges = _badgesByCategory.values.expand((badges) => badges).toList();
    return allBadges.where((badge) => !_earnedBadges.contains(badge.id)).toList();
  }

  String _getCategoryTitle(String category) {
    return switch (category) {
      'milestone' => 'Milestone Badges',
      'xp' => 'XP Badges',
      'streak' => 'Streak Badges',
      'mastery' => 'Mastery Badges',
      'game' => 'Game Badges',
      'social' => 'Social Badges',
      'special' => 'Special Badges',
      _ => '${category[0].toUpperCase()}${category.substring(1)} Badges',
    };
  }
}

// STATS ITEM
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 6),
        Text(value, style: AppTextStyles.h2.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        Text(label, style: AppTextStyles.caption.copyWith(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

// BADGE CARD: NAME BELOW + DIALOG ON TAP
class _BadgeCard extends StatelessWidget {
  final BadgeModel badge;
  final bool isEarned;

  const _BadgeCard({required this.badge, required this.isEarned});

  Color _getRarityColor(String rarity) {
    return switch (rarity.toLowerCase()) {
      'legendary' => const Color(0xFFFFD700),
      'epic' => const Color(0xFF9333EA),
      'rare' => const Color(0xFF3B82F6),
      'uncommon' => const Color(0xFF10B981),
      _ => const Color(0xFF6B7280),
    };
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = isEarned ? _getRarityColor(badge.rarity).withOpacity(0.8) : Colors.transparent;

    return Column(
      children: [
        // Badge Image + Lock
        Expanded(
          child: GestureDetector(
            onTap: () => _showDetailDialog(context),
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isEarned ? Colors.white : AppDesignSystem.backgroundGrey.withOpacity(0.8),
                border: Border.all(color: borderColor, width: 3.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // BIG BADGE IMAGE
                  Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Image.asset(
                      badge.iconPath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.emoji_events,
                        size: 70,
                        color: isEarned ? _getRarityColor(badge.rarity) : AppDesignSystem.textTertiary,
                      ),
                    ),
                  ),

                  // LOCK CENTERED
                  if (!isEarned)
                    Center(
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                        ),
                        child: const Icon(Icons.lock, color: Colors.white, size: 20),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // NAME BELOW
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 0),
          child: Text(
            badge.name,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppDesignSystem.textPrimary,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // DIALOG BOX (FULLY RESTORED)
  void _showDetailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isEarned
                  ? [Colors.amber.shade50, Colors.white]
                  : [Colors.grey.shade100, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (_, value, __) => Transform.scale(
                  scale: value,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      color: isEarned ? Colors.amber.withOpacity(0.2) : Colors.grey.withOpacity(0.15),
                      shape: BoxShape.circle,
                      boxShadow: isEarned
                          ? [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 20, spreadRadius: 5)]
                          : [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 15, spreadRadius: 2)],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Image.asset(
                        badge.iconPath,
                        fit: BoxFit.contain,
                        errorBuilder: (_, error, __) {
                          debugPrint('Error: $error');
                          return Icon(Icons.emoji_events, size: 150, color: isEarned ? Colors.amber : Colors.grey);
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(badge.name,
                  style: AppTextStyles.h2.copyWith(
                      color: isEarned ? Colors.amber.shade900 : Colors.grey.shade700),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _chip(badge.rarity.toUpperCase(),
                      _getRarityColor(badge.rarity).withOpacity(0.15), _getRarityColor(badge.rarity)),
                  const SizedBox(width: 8),
                  _chip(
                    isEarned ? 'Earned' : 'Locked',
                    isEarned
                        ? AppDesignSystem.success.withOpacity(0.15)
                        : AppDesignSystem.textTertiary.withOpacity(0.15),
                    isEarned ? AppDesignSystem.success : AppDesignSystem.textTertiary,
                    icon: isEarned ? Icons.check_circle : Icons.lock,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(badge.description,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppDesignSystem.textSecondary),
                  textAlign: TextAlign.center),
              if (badge.xpBonus > 0) ...[
                const SizedBox(height: 12),
                _chip('+${badge.xpBonus} XP Bonus', Colors.amber.withOpacity(0.15), Colors.amber.shade900,
                    icon: Icons.stars),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEarned ? Colors.amber : const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String text, Color bg, Color fg, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: 4)],
          Text(text,
              style: AppTextStyles.bodySmall.copyWith(color: fg, fontWeight: FontWeight.bold, fontSize: 10)),
        ],
      ),
    );
  }
}