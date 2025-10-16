import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/clean_card.dart';
import '../../widgets/primary_button.dart';

/// Play/Games Screen - Hub for all mini games
class PlayScreen extends StatelessWidget {
  const PlayScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Play Games'),
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
              color: AppColors.primary.withOpacity(0.05),
              child: Row(
                children: [
                  const Icon(
                    Icons.emoji_events,
                    color: AppColors.accent,
                    size: 40,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Best Scores',
                          style: AppTextStyles.cardTitle,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '3,450 Total Game XP',
                          style: AppTextStyles.bodyMedium,
                        ),
                        Text(
                          '7 Games Played',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            Text(
              'All Games (7)',
              style: AppTextStyles.sectionHeader,
            ),
            
            const SizedBox(height: AppSpacing.sm),
            
            // Games grid (2 columns)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.cardSpacing,
              crossAxisSpacing: AppSpacing.cardSpacing,
              childAspectRatio: 0.75, // Increased height to prevent overflow
              children: [
                _GameCard(
                  title: 'IPR Quiz\nMaster',
                  icon: Icons.quiz,
                  color: AppColors.cardPurple,
                  bestScore: 850,
                  onTap: () {},
                ),
                _GameCard(
                  title: 'Memory\nMatch',
                  icon: Icons.style,
                  color: AppColors.cardOrange,
                  bestScore: 120,
                  onTap: () {},
                ),
                _GameCard(
                  title: 'Spot the\nOriginal',
                  icon: Icons.search,
                  color: AppColors.cardBlue,
                  bestScore: 600,
                  onTap: () {},
                ),
                _GameCard(
                  title: 'IP\nDefender',
                  icon: Icons.shield,
                  color: AppColors.cardGreen,
                  bestScore: 750,
                  onTap: () {},
                ),
                _GameCard(
                  title: 'Word\nPuzzle',
                  icon: Icons.abc,
                  color: AppColors.cardPink,
                  bestScore: 420,
                  onTap: () {},
                ),
                _GameCard(
                  title: 'True or\nFalse',
                  icon: Icons.check_circle,
                  color: AppColors.cardTeal,
                  bestScore: 680,
                  onTap: () {},
                ),
                _GameCard(
                  title: 'Timeline\nChallenge',
                  icon: Icons.timeline,
                  color: AppColors.cardIndigo,
                  bestScore: 520,
                  onTap: () {},
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

/// Game card
class _GameCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int bestScore;
  final VoidCallback onTap;
  
  const _GameCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.color,
    required this.bestScore,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return CleanCard(
      color: color.withOpacity(0.1),
      border: Border.all(
        color: color.withOpacity(0.3),
        width: 2,
      ),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Flexible(
              child: Text(
                title,
                style: AppTextStyles.cardTitle.copyWith(
                  fontSize: 14,
                  color: color,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: 6),
          
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Best: $bestScore',
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
            
            const SizedBox(height: 8),
            
            SizedBox(
              width: double.infinity,
              height: 28,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.zero,
              ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Play',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.play_arrow, size: 12),
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
