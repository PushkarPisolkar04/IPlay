import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/models/user_model.dart';
import '../../widgets/clean_card.dart';
import '../../widgets/top_bar_with_avatar.dart';
import '../../widgets/progress_bar.dart';
import '../../widgets/primary_button.dart';

/// Home Screen - Loads real user data from Firebase
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? _user;
  bool _isLoading = true;
  String _greeting = 'Good Morning';

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
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        if (doc.exists && mounted) {
          setState(() {
            _user = UserModel.fromMap(doc.data()!);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getInitials() {
    if (_user == null) return 'U';
    final names = _user!.displayName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return _user!.displayName[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
            
            // Scrollable content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenHorizontal,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          
                          // Greeting (real user name)
                          Text(
                            '$_greeting!',
                            style: AppTextStyles.h1,
                          ),
                          Text(
                            _user?.displayName ?? 'Student',
                            style: AppTextStyles.h3.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                          
                          const SizedBox(height: AppSpacing.lg),
                          
                          // XP & Level Card
                          ColoredCard(
                            color: AppColors.primary,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total XP',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textWhite.withOpacity(0.8),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_user?.totalXP ?? 0}',
                                      style: AppTextStyles.h1.copyWith(
                                        color: AppColors.textWhite,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Streak',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textWhite.withOpacity(0.8),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.local_fire_department,
                                          color: AppColors.accent,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_user?.currentStreak ?? 0} days',
                                          style: AppTextStyles.h2.copyWith(
                                            color: AppColors.textWhite,
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
                          
                          // Featured card (Continue Learning)
                          ColoredCard(
                            color: AppColors.secondary,
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
                                            'Continue',
                                            style: AppTextStyles.h2.copyWith(
                                              color: AppColors.textWhite,
                                            ),
                                          ),
                                          Text(
                                            'Learning',
                                            style: AppTextStyles.h2.copyWith(
                                              color: AppColors.textWhite,
                                            ),
                                          ),
                                          Text(
                                            'IPR',
                                            style: AppTextStyles.h2.copyWith(
                                              color: AppColors.textWhite,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Logo
                                    Image.asset(
                                      'assets/logos/logo.png',
                                      width: 100,
                                      height: 100,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                SizedBox(
                                  height: 40,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Navigate to learn tab (index 1)
                                      DefaultTabController.of(context).animateTo(1);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppColors.secondary,
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
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: AppSpacing.sm),
                          
                          // Stats cards
                          Row(
                            children: [
                              Expanded(
                                child: CleanCard(
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.emoji_events,
                                        size: 32,
                                        color: AppColors.accent,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${_user?.badges.length ?? 0}',
                                        style: AppTextStyles.h2,
                                      ),
                                      Text(
                                        'Badges',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CleanCard(
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.workspace_premium,
                                        size: 32,
                                        color: AppColors.success,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${_user?.progressSummary.values.where((r) => r.completed).length ?? 0}',
                                        style: AppTextStyles.h2,
                                      ),
                                      Text(
                                        'Realms Done',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
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
    Key? key,
    required this.color,
    required this.child,
  }) : super(key: key);
  
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
