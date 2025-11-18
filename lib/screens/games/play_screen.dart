import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/game_progress_model.dart';
import 'ipr_quiz_master_game.dart';
import 'trademark_match_game.dart';
import 'spot_the_original_game.dart';
import 'gi_mapper_game.dart';
import 'ip_defender_game.dart';
import 'patent_detective_game.dart';
import 'innovation_lab_game.dart';

/// Play/Games Screen - All 7 Games
class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  bool _isLoading = true;
  int _totalGameXP = 0;
  int _gamesPlayed = 0;
  Map<String, int> _gameHighScores = {};

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

      // Load individual game progress and calculate total game XP
      final gameProgressDocs = await FirebaseFirestore.instance
          .collection('game_progress')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      print('Found ${gameProgressDocs.docs.length} game progress documents');

      int totalGameXP = 0;
      
      for (final doc in gameProgressDocs.docs) {
        final data = doc.data();
        final gameId = data['gameId'] as String?;
        final highScore = (data['highScore'] as num?)?.toInt() ?? 0;
        final totalXPEarned = (data['totalXPEarned'] as num?)?.toInt() ?? 0;
        
        if (gameId != null) {
          _gameHighScores[gameId] = highScore;
          totalGameXP += totalXPEarned;
          print('Game: $gameId, High Score: $highScore, XP Earned: $totalXPEarned');
        }
      }
      
      // Set total game XP from sum of all games
      _totalGameXP = totalGameXP;
      
      // Count unique games played
      _gamesPlayed = _gameHighScores.length;
      
      print('Total games played: $_gamesPlayed');
      print('Total game XP (from games only): $_totalGameXP');

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading game data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadGameData();
  }

  Widget _buildStatChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 150,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                ...List.generate(7, (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Gradient App Bar with stats
            Container(
              decoration: BoxDecoration(
                gradient: AppDesignSystem.gradientPrimary,
                boxShadow: [
                  BoxShadow(
                    color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  children: [
                    // Title - centered
                    Center(
                      child: Text(
                        'Play Games',
                        style: AppTextStyles.h2.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Stats chips - centered
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatChip(Icons.games, '$_gamesPlayed Played'),
                        const SizedBox(width: 12),
                        _buildStatChip(Icons.stars, '$_totalGameXP XP'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Body content
            Expanded(
              child:
              _isLoading
          ? _buildSkeletonLoader()
          : RefreshIndicator(
              onRefresh: _refreshData,
              color: const Color(0xFFEC4899),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  
                  Text(
                    'Available Games',
                    style: AppTextStyles.sectionHeader.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Game 1: IP Quiz Master (Implemented)
                  _buildGameCard(
                    title: 'IPR Quiz Master',
                    description: 'Test your IPR knowledge in rapid-fire quiz',
                    iconPath: 'assets/logos/IPR_quiz_master.png',
                    color: const Color(0xFF6366F1),
                    difficulty: 'Easy',
                    xpReward: '10-250 XP',
                    timeEstimate: '1 min',
                    isImplemented: true,
                    gameId: 'quiz_master',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const IPRQuizMasterGame()),
                      ).then((_) => _refreshData());
                    },
                  ),
                  
                  // Game 2: Trademark Match (Implemented)
                  _buildGameCard(
                    title: 'Trademark Match',
                    description: 'Match famous trademarks with their companies',
                    iconPath: 'assets/logos/trademark_match.png',
                    color: const Color(0xFF2196F3),
                    difficulty: 'Medium',
                    xpReward: '60-180 XP',
                    timeEstimate: '2 min',
                    isImplemented: true,
                    gameId: 'trademark_match',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TrademarkMatchScreen()),
                      ).then((_) => _refreshData());
                    },
                  ),
                  
                  // Game 3: Spot the Original
                  _buildGameCard(
                    title: 'Spot the Original',
                    description: 'Identify genuine IP from counterfeits',
                    iconPath: 'assets/logos/spot_the_original.png',
                    color: const Color(0xFFF59E0B),
                    difficulty: 'Medium',
                    xpReward: '15-150 XP',
                    timeEstimate: '2 min',
                    isImplemented: true,
                    gameId: 'spot_original',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SpotTheOriginalGame()),
                      ).then((_) => _refreshData());
                    },
                  ),
                  
                  // Game 4: IP Defender
                  _buildGameCard(
                    title: 'IP Defender',
                    description: 'Defend your IP through 5 waves of infringers',
                    iconPath: 'assets/logos/ip_defender.png',
                    color: const Color(0xFFEF4444),
                    difficulty: 'Hard',
                    xpReward: '800-1500 XP',
                    timeEstimate: '8-10 min',
                    isImplemented: true,
                    gameId: 'ip_defender',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const IPDefenderGame()),
                      ).then((_) => _refreshData());
                    },
                  ),
                  
                  // Game 5: GI Mapper
                  _buildGameCard(
                    title: 'GI Mapper',
                    description: 'Match India\'s GI products to their states',
                    iconPath: 'assets/logos/gi_mapper.png',
                    color: const Color(0xFFFFC107),
                    difficulty: 'Medium',
                    xpReward: '10-80 XP',
                    timeEstimate: '2 min',
                    isImplemented: true,
                    gameId: 'gi_mapper',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GIMapperGame()),
                      ).then((_) => _refreshData());
                    },
                  ),
                  
                  // Game 6: Patent Detective
                  _buildGameCard(
                    title: 'Patent Detective',
                    description: 'Solve IP crime cases by investigating suspects and evidence',
                    iconPath: 'assets/logos/patent_detective.png',
                    color: const Color(0xFF8B5CF6),
                    difficulty: 'Medium',
                    xpReward: '100-250 XP',
                    timeEstimate: '3 min',
                    isImplemented: true,
                    gameId: 'patent_detective',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PatentDetectiveGame()),
                      ).then((_) => _refreshData());
                    },
                  ),
                  
                  // Game 7: Innovation Lab
                  _buildGameCard(
                    title: 'Innovation Lab',
                    description: 'Design your invention and learn IP protection',
                    iconPath: 'assets/logos/innovation_lab.png',
                    color: const Color(0xFF00ACC1),
                    difficulty: 'Hard',
                    xpReward: '100-200 XP',
                    timeEstimate: '5-10 min',
                    isImplemented: true,
                    gameId: 'innovation_lab',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const InnovationLabGame()),
                      ).then((_) => _refreshData());
                    },
                  ),
                ],
                ),
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard({
    required String title,
    required String description,
    required String iconPath,
    required Color color,
    required String difficulty,
    required String xpReward,
    required String timeEstimate,
    required bool isImplemented,
    required String gameId,
    VoidCallback? onTap,
  }) {
    final highScore = _gameHighScores[gameId] ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            color.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isImplemented ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Image.asset(
                      iconPath,
                      width: 48,
                      height: 48,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.games,
                          size: 48,
                          color: Colors.white,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!isImplemented)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Soon',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _buildInfoChip(difficulty, Icons.bar_chart),
                            _buildInfoChip(xpReward, Icons.stars),
                            _buildInfoChip(timeEstimate, Icons.access_time),
                            if (highScore > 0)
                              _buildInfoChip('Best: $highScore', Icons.emoji_events),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isImplemented) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                      color: Colors.white,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

