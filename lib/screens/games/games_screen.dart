import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/clean_card.dart';
import '../../widgets/loading_skeleton.dart';
import 'ipr_quiz_master_game.dart';
import 'match_ipr_game.dart';
import 'spot_the_original_game.dart';
import 'gi_mapper_game.dart';
import 'ip_defender_game.dart';
import 'patent_detective_game.dart';
import 'innovation_lab_game.dart';

/// Games Screen - List of available educational games
class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  final Map<String, dynamic> _gameStats = {};
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
        
        final spotDoc = await FirebaseFirestore.instance
            .collection('progress')
            .doc('${user.uid}__game_spot_original')
            .get();
        
        final giDoc = await FirebaseFirestore.instance
            .collection('progress')
            .doc('${user.uid}__game_gi_mapper')
            .get();
        
        final defenderDoc = await FirebaseFirestore.instance
            .collection('progress')
            .doc('${user.uid}__game_ip_defender')
            .get();
        
        final detectiveDoc = await FirebaseFirestore.instance
            .collection('progress')
            .doc('${user.uid}__game_patent_detective')
            .get();
        
        final innovationDoc = await FirebaseFirestore.instance
            .collection('progress')
            .doc('${user.uid}__game_innovation_lab')
            .get();
        
        setState(() {
          if (quizDoc.exists) {
            _gameStats['quiz_master'] = quizDoc.data();
          }
          if (matchDoc.exists) {
            _gameStats['match_ipr'] = matchDoc.data();
          }
          if (spotDoc.exists) {
            _gameStats['spot_original'] = spotDoc.data();
          }
          if (giDoc.exists) {
            _gameStats['gi_mapper'] = giDoc.data();
          }
          if (defenderDoc.exists) {
            _gameStats['ip_defender'] = defenderDoc.data();
          }
          if (detectiveDoc.exists) {
            _gameStats['patent_detective'] = detectiveDoc.data();
          }
          if (innovationDoc.exists) {
            _gameStats['innovation_lab'] = innovationDoc.data();
          }
          _isLoading = false;
        });
      } catch (e) {
        // print('Error loading game stats: $e');
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
        backgroundColor: AppDesignSystem.backgroundLight,
        appBar: AppBar(
          title: const Text('Games'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const GridSkeleton(itemCount: 6, crossAxisCount: 1),
      );
    }

    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
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
                color: AppDesignSystem.textSecondary,
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
                    if (_gameStats.containsKey('match_ipr') && _gameStats.containsKey('spot_original'))
                      const Divider(height: 24),
                    if (_gameStats.containsKey('spot_original'))
                      _StatItem(
                        icon: Icons.search,
                        title: 'Spot the Original',
                        stats: [
                          'Best: ${_gameStats['spot_original']['highScore']}/5',
                          'Played ${_gameStats['spot_original']['attemptsCount']} times',
                          'Accuracy: ${_gameStats['spot_original']['accuracy']}%',
                        ],
                      ),
                    if (_gameStats.containsKey('spot_original') && _gameStats.containsKey('gi_mapper'))
                      const Divider(height: 24),
                    if (_gameStats.containsKey('gi_mapper'))
                      _StatItem(
                        icon: Icons.map,
                        title: 'GI Mapper',
                        stats: [
                          'Best: ${_gameStats['gi_mapper']['highScore']}/8',
                          'Played ${_gameStats['gi_mapper']['attemptsCount']} times',
                          'Accuracy: ${_gameStats['gi_mapper']['accuracy']}%',
                        ],
                      ),
                    if (_gameStats.containsKey('gi_mapper') && _gameStats.containsKey('ip_defender'))
                      const Divider(height: 24),
                    if (_gameStats.containsKey('ip_defender'))
                      _StatItem(
                        icon: Icons.shield,
                        title: 'IP Defender',
                        stats: [
                          'Best: ${_gameStats['ip_defender']['highScore']} pts',
                          'Played ${_gameStats['ip_defender']['attemptsCount']} times',
                          'Defeated: ${_gameStats['ip_defender']['infringersDefeated']} infringers',
                        ],
                      ),
                    if (_gameStats.containsKey('ip_defender') && _gameStats.containsKey('patent_detective'))
                      const Divider(height: 24),
                    if (_gameStats.containsKey('patent_detective'))
                      _StatItem(
                        icon: Icons.search,
                        title: 'Patent Detective',
                        stats: [
                          'Best: ${_gameStats['patent_detective']['highScore']}/3',
                          'Played ${_gameStats['patent_detective']['attemptsCount']} times',
                          'Accuracy: ${_gameStats['patent_detective']['accuracy']}%',
                        ],
                      ),
                    if (_gameStats.containsKey('patent_detective') && _gameStats.containsKey('innovation_lab'))
                      const Divider(height: 24),
                    if (_gameStats.containsKey('innovation_lab'))
                      _StatItem(
                        icon: Icons.science,
                        title: 'Innovation Lab',
                        stats: [
                          'Inventions Created: ${_gameStats['innovation_lab']['attemptsCount']}',
                          'Last: ${_gameStats['innovation_lab']['inventionName']}',
                          'Category: ${_gameStats['innovation_lab']['inventionCategory']}',
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
              color: AppDesignSystem.primaryIndigo,
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
              color: AppDesignSystem.primaryPink,
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

            const SizedBox(height: AppSpacing.cardSpacing),

            // Game 3: Spot the Original
            _GameCard(
              title: 'Spot the Original',
              description: 'Identify original works among copies',
              icon: Icons.search,
              color: AppDesignSystem.primaryAmber,
              difficulty: 'Medium',
              xpReward: '15-75 XP',
              timeEstimate: '2-3 min',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SpotTheOriginalGame(),
                  ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.cardSpacing),

            // Game 4: GI Mapper
            _GameCard(
              title: 'GI Mapper',
              description: 'Match GI products to their states',
              icon: Icons.map,
              color: const Color(0xFF10B981),
              difficulty: 'Medium',
              xpReward: '10-80 XP',
              timeEstimate: '3-5 min',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GIMapperGame(),
                  ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.cardSpacing),

            // Game 5: IP Defender
            _GameCard(
              title: 'IP Defender',
              description: 'Defend your IP assets from infringers',
              icon: Icons.shield,
              color: AppDesignSystem.error,
              difficulty: 'Hard',
              xpReward: 'Up to 500 XP',
              timeEstimate: '5-10 min',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const IPDefenderGame(),
                  ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.cardSpacing),

            // Game 6: Patent Detective
            _GameCard(
              title: 'Patent Detective',
              description: 'Investigate patent cases and determine patentability',
              icon: Icons.search,
              color: const Color(0xFF8B5CF6),
              difficulty: 'Medium',
              xpReward: '20-60 XP',
              timeEstimate: '3-5 min',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PatentDetectiveGame(),
                  ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.cardSpacing),

            // Game 7: Innovation Lab
            _GameCard(
              title: 'Innovation Lab',
              description: 'Design your invention and learn IP protection',
              icon: Icons.science,
              color: Colors.teal,
              difficulty: 'Easy',
              xpReward: '100 XP',
              timeEstimate: '5-10 min',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InnovationLabGame(),
                  ),
                );
              },
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
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.difficulty,
    required this.xpReward,
    required this.timeEstimate,
    required this.onTap,
  });

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
                  color: Colors.white.withValues(alpha: 0.2),
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
                        color: Colors.white.withValues(alpha: 0.2),
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
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Icon(
                Icons.stars,
                size: 16,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 4),
              Text(
                xpReward,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.timer,
                size: 16,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 4),
              Text(
                timeEstimate,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
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
    required this.icon,
    required this.title,
    required this.description,
  });

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
              color: AppDesignSystem.backgroundGrey,
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Icon(
              icon,
              color: AppDesignSystem.textSecondary,
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
                    color: AppDesignSystem.textSecondary,
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
              color: AppDesignSystem.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppDesignSystem.info.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'Soon',
              style: AppTextStyles.caption.copyWith(
                color: AppDesignSystem.info,
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
    required this.icon,
    required this.title,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          child: Icon(
            icon,
            color: AppDesignSystem.primaryIndigo,
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
                        color: AppDesignSystem.textSecondary,
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
    super.key,
    required this.color,
    required this.child,
    this.onTap,
  });

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

