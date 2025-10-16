import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/clean_card.dart';
import 'ipr_quiz_master_game.dart';
import 'match_ipr_game.dart';

/// Games Screen - List of available educational games
class GamesScreen extends StatefulWidget {
  const GamesScreen({Key? key}) : super(key: key);

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  Map<String, dynamic> _gameStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGameStats();
  }

  Future<void> _loadGameStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final quizDoc = await FirebaseFirestore.instance
            .collection('progress')
            .doc('${user.uid}__game_quiz_master')
            .get();
        
        final matchDoc = await FirebaseFirestore.instance
            .collection('progress')
            .doc('${user.uid}__game_match_ipr')
            .get();
        
        setState(() {
          if (quizDoc.exists) {
            _gameStats['quiz_master'] = quizDoc.data();
          }
          if (matchDoc.exists) {
            _gameStats['match_ipr'] = matchDoc.data();
          }
          _isLoading = false;
        });
      } catch (e) {
        print('Error loading game stats: $e');
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Games'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Educational Games',
              style: AppTextStyles.h1,
            ),

            const SizedBox(height: AppSpacing.sm),

            Text(
              'Learn IPR concepts through fun and interactive games!',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // My Stats (if any games played)
            if (!_isLoading && _gameStats.isNotEmpty) ...[
              Text(
                'My Stats',
                style: AppTextStyles.sectionHeader,
              ),
              const SizedBox(height: AppSpacing.sm),
              CleanCard(
                child: Column(
                  children: [
                    if (_gameStats.containsKey('quiz_master'))
                      _StatItem(
                        icon: Icons.speed,
                        title: 'IPR Quiz Master',
                        stats: [
                          'Best: ${_gameStats['quiz_master']['highScore']}/10',
                          'Played ${_gameStats['quiz_master']['attemptsCount']} times',
                          'Accuracy: ${_gameStats['quiz_master']['accuracy']}%',
                        ],
                      ),
                    if (_gameStats.containsKey('quiz_master') && _gameStats.containsKey('match_ipr'))
                      const Divider(height: 24),
                    if (_gameStats.containsKey('match_ipr'))
                      _StatItem(
                        icon: Icons.grid_4x4,
                        title: 'Match the IPR',
                        stats: [
                          'Best: ${_gameStats['match_ipr']['highScore']} pts',
                          'Played ${_gameStats['match_ipr']['attemptsCount']} times',
                          'Best Time: ${_gameStats['match_ipr']['lastTime']}s',
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],

            // Game 1: IPR Quiz Master
            _GameCard(
              title: 'IPR Quiz Master',
              description: 'Test your IPR knowledge in a rapid-fire quiz',
              icon: Icons.speed,
              color: AppColors.primary,
              difficulty: 'Medium',
              xpReward: '10-100 XP',
              timeEstimate: '1-2 min',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const IPRQuizMasterGame(),
                  ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.cardSpacing),

            // Game 2: Match the IPR
            _GameCard(
              title: 'Match the IPR',
              description: 'Memory card game matching IPR concepts',
              icon: Icons.grid_4x4,
              color: AppColors.secondary,
              difficulty: 'Easy',
              xpReward: '60-100 XP',
              timeEstimate: '2-5 min',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MatchIPRGame(),
                  ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.xl),

            // Coming soon section
            Text(
              'Coming Soon',
              style: AppTextStyles.sectionHeader,
            ),

            const SizedBox(height: AppSpacing.sm),

            CleanCard(
              child: Column(
                children: [
                  _ComingSoonItem(
                    icon: Icons.search,
                    title: 'IPR Detective',
                    description: 'Solve IPR cases and mysteries',
                  ),
                  const Divider(height: 24),
                  _ComingSoonItem(
                    icon: Icons.build,
                    title: 'Patent Builder',
                    description: 'Create and patent your inventions',
                  ),
                  const Divider(height: 24),
                  _ComingSoonItem(
                    icon: Icons.gavel,
                    title: 'IPR Court',
                    description: 'Argue infringement cases',
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String difficulty;
  final String xpReward;
  final String timeEstimate;
  final VoidCallback onTap;

  const _GameCard({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.difficulty,
    required this.xpReward,
    required this.timeEstimate,
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
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.h3.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        difficulty,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
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

          const SizedBox(height: 16),

          Row(
            children: [
              Icon(
                Icons.stars,
                size: 16,
                color: Colors.white.withOpacity(0.9),
              ),
              const SizedBox(width: 4),
              Text(
                xpReward,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.timer,
                size: 16,
                color: Colors.white.withOpacity(0.9),
              ),
              const SizedBox(width: 4),
              Text(
                timeEstimate,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),

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
                children: const [
                  Text(
                    'Play Now',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.play_arrow, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _ComingSoonItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.6,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.backgroundGrey,
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Icon(
              icon,
              color: AppColors.textSecondary,
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
                  style: AppTextStyles.cardTitle.copyWith(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.info.withOpacity(0.3),
              ),
            ),
            child: Text(
              'Soon',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.info,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> stats;

  const _StatItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.stats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.sm),
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
                style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 4),
              ...stats.map((stat) => Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      stat,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

/// Colored card widget
class ColoredCard extends StatelessWidget {
  final Color color;
  final Widget child;
  final VoidCallback? onTap;

  const ColoredCard({
    Key? key,
    required this.color,
    required this.child,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: child,
        ),
      ),
    );
  }
}

