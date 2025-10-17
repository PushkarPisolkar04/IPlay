import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/clean_card.dart';
import '../../widgets/primary_button.dart';

/// Play/Games Screen - Hub for all mini games (REAL DATA from Firebase)
class PlayScreen extends StatefulWidget {
  const PlayScreen({Key? key}) : super(key: key);

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  bool _isLoading = true;
  int _totalGameXP = 0;
  int _gamesPlayed = 0;
  Map<String, int> _gameScores = {};

  @override
  void initState() {
    super.initState();
    _loadGameData();
  }

  Future<void> _loadGameData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      print('Loading game data for user: ${currentUser.uid}');

      // Load user document to get game progress
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        
        // Get game scores from user data (if stored there)
        final gameProgress = userData['gameProgress'] as Map<String, dynamic>?;
        
        if (gameProgress != null) {
          _totalGameXP = (gameProgress['totalXP'] as num?)?.toInt() ?? 0;
          _gamesPlayed = (gameProgress['gamesPlayed'] as num?)?.toInt() ?? 0;
          
          final scores = gameProgress['scores'] as Map<String, dynamic>?;
          if (scores != null) {
            _gameScores = scores.map((key, value) => MapEntry(key, (value as num).toInt()));
          }
        }

        print('Total Game XP: $_totalGameXP');
        print('Games Played: $_gamesPlayed');
        print('Game Scores: $_gameScores');
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading game data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
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
            // Stats card - REAL DATA
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
                          _gamesPlayed > 0 ? 'Your Game Stats' : 'No Games Played Yet',
                          style: AppTextStyles.cardTitle,
                        ),
                        const SizedBox(height: 4),
                        if (_gamesPlayed > 0) ...[
                          Text(
                            '$_totalGameXP Total Game XP',
                            style: AppTextStyles.bodyMedium,
                          ),
                          Text(
                            '$_gamesPlayed Games Played',
                            style: AppTextStyles.bodySmall,
                          ),
                        ] else ...[
                          Text(
                            'Play games to earn XP and unlock achievements!',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            Text(
              'All Games',
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
                  bestScore: _gameScores['ipr_quiz_master'],
                  onTap: () {},
                ),
                _GameCard(
                  title: 'Memory\nMatch',
                  icon: Icons.style,
                  color: AppColors.cardOrange,
                  bestScore: _gameScores['memory_match'],
                  onTap: () {},
                ),
                _GameCard(
                  title: 'Spot the\nOriginal',
                  icon: Icons.search,
                  color: AppColors.cardBlue,
                  bestScore: _gameScores['spot_original'],
                  onTap: () {},
                ),
                _GameCard(
                  title: 'IP\nDefender',
                  icon: Icons.shield,
                  color: AppColors.cardGreen,
                  bestScore: _gameScores['ip_defender'],
                  onTap: () {},
                ),
                _GameCard(
                  title: 'Word\nPuzzle',
                  icon: Icons.abc,
                  color: AppColors.cardPink,
                  bestScore: _gameScores['word_puzzle'],
                  onTap: () {},
                ),
                _GameCard(
                  title: 'True or\nFalse',
                  icon: Icons.check_circle,
                  color: AppColors.cardTeal,
                  bestScore: _gameScores['true_false'],
                  onTap: () {},
                ),
                _GameCard(
                  title: 'Timeline\nChallenge',
                  icon: Icons.timeline,
                  color: AppColors.cardIndigo,
                  bestScore: _gameScores['timeline_challenge'],
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

/// Game card - Shows REAL score or "Not Played"
class _GameCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int? bestScore;  // Nullable - null means not played
  final VoidCallback onTap;
  
  const _GameCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.color,
    this.bestScore,
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
              bestScore != null ? 'Best: $bestScore' : 'Not Played',
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
