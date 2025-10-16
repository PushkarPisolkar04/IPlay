import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/progress_bar.dart';

/// Level Content Screen - Displays lesson content
class LevelScreen extends StatelessWidget {
  final Map<String, dynamic>? levelData;
  
  const LevelScreen({Key? key, this.levelData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar with progress
          SliverAppBar(
            title: const Text('Level 3: Copyright Duration'),
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            pinned: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const ProgressBar(progress: 0.25, height: 6),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '25%',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
          
          // Scrollable content
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Main heading
                Text(
                  'Copyright Duration',
                  style: AppTextStyles.h1,
                ),
                
                const SizedBox(height: AppSpacing.md),
                
                // Introduction
                Text(
                  'Copyright protection lasts for a specific period of time before works enter the public domain.',
                  style: AppTextStyles.bodyLarge,
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Content image placeholder
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGrey,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 64,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Illustration',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Section heading
                Text(
                  'Key Points',
                  style: AppTextStyles.h2,
                ),
                
                const SizedBox(height: AppSpacing.sm),
                
                // Bullet points
                _BulletPoint(text: 'Lifetime + 60 years'),
                const SizedBox(height: AppSpacing.sm),
                _BulletPoint(text: 'Anonymous: 60 years from publication'),
                const SizedBox(height: AppSpacing.sm),
                _BulletPoint(text: 'Applies from creation, not registration'),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Video player placeholder
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGrey,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary.withOpacity(0.3),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.play_circle_outline,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Watch: Duration Explained',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '3:45',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Info box
                Text(
                  'Did You Know?',
                  style: AppTextStyles.h2,
                ),
                
                const SizedBox(height: AppSpacing.sm),
                
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(
                      color: AppColors.info.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.info,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'In India, copyright lasts for the lifetime of the author plus 60 years after death.',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // More content
                Text(
                  'Public Domain',
                  style: AppTextStyles.h2,
                ),
                
                const SizedBox(height: AppSpacing.sm),
                
                Text(
                  'After copyright expires, the work enters the public domain. This means anyone can use, copy, distribute, or adapt the work without permission or payment.',
                  style: AppTextStyles.bodyLarge,
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                Text(
                  'Examples of Public Domain Works',
                  style: AppTextStyles.h3,
                ),
                
                const SizedBox(height: AppSpacing.sm),
                
                _ExampleCard(
                  title: 'Shakespeare\'s Plays',
                  description: 'Written in the 1500s-1600s',
                  icon: Icons.theater_comedy,
                ),
                
                const SizedBox(height: AppSpacing.sm),
                
                _ExampleCard(
                  title: 'Classical Music',
                  description: 'Bach, Mozart, Beethoven',
                  icon: Icons.music_note,
                ),
                
                const SizedBox(height: AppSpacing.xl),
              ]),
            ),
          ),
        ],
      ),
      
      // Bottom button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: PrimaryButton(
            text: 'Take Quiz',
            onPressed: () {
              // Navigate to quiz
            },
            fullWidth: true,
            icon: Icons.quiz,
          ),
        ),
      ),
    );
  }
}

/// Bullet point widget
class _BulletPoint extends StatelessWidget {
  final String text;
  
  const _BulletPoint({Key? key, required this.text}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 8, right: 12),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyLarge,
          ),
        ),
      ],
    );
  }
}

/// Example card widget
class _ExampleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  
  const _ExampleCard({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
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
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
