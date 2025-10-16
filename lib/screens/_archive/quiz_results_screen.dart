import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/clean_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/progress_bar.dart';

/// Quiz Results Screen - Shows score and achievements
class QuizResultsScreen extends StatelessWidget {
  const QuizResultsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int score = 5;
    final int total = 5;
    final bool isPerfect = score == total;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    
                    // Emoji/Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          '🎉',
                          style: TextStyle(fontSize: 64),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Title
                    Text(
                      'Excellent!',
                      style: AppTextStyles.h1.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Results card
                    CleanCard(
                      child: Column(
                        children: [
                          // Stars
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              5,
                              (index) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Icon(
                                  index < score ? Icons.star : Icons.star_border,
                                  color: AppColors.accent,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: AppSpacing.lg),
                          
                          // Score
                          Text(
                            'You scored $score/$total!',
                            style: AppTextStyles.h2,
                          ),
                          
                          const SizedBox(height: AppSpacing.md),
                          
                          // XP earned
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.stars,
                                  color: AppColors.accent,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '+150 XP earned',
                                  style: AppTextStyles.h4.copyWith(
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          if (isPerfect) ...[
                            const SizedBox(height: AppSpacing.lg),
                            
                            // Badge unlock
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '🏆',
                                        style: TextStyle(fontSize: 32),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Perfect Score!',
                                    style: AppTextStyles.h4.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Text(
                                    'Badge unlocked',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: AppSpacing.lg),
                          
                          const Divider(),
                          
                          const SizedBox(height: AppSpacing.md),
                          
                          // Level progress
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Level Progress:',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const ProgressBar(progress: 1.0, height: 10),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '100% Complete',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppColors.success,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: AppSpacing.md),
                          
                          const Divider(),
                          
                          const SizedBox(height: AppSpacing.md),
                          
                          // Streak
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                '🔥',
                                style: TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Current Streak: 8 days',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
            
            // Bottom buttons
            Container(
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryButton(
                    text: 'Next Level',
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    fullWidth: true,
                    icon: Icons.arrow_forward,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SecondaryButton(
                    text: 'Share Result',
                    onPressed: () {},
                    fullWidth: true,
                    icon: Icons.share,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
