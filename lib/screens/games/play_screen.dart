import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import 'ipr_quiz_master_game.dart';
import 'match_ipr_game.dart';

/// Play/Games Screen - All 7 Games
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

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        
        final gameProgress = userData['gameProgress'] as Map<String, dynamic>?;
        
        if (gameProgress != null) {
          _totalGameXP = (gameProgress['totalXP'] as num?)?.toInt() ?? 0;
          _gamesPlayed = (gameProgress['gamesPlayed'] as num?)?.toInt() ?? 0;
          
          final scores = gameProgress['scores'] as Map<String, dynamic>?;
          if (scores != null) {
            _gameScores = scores.map((key, value) => MapEntry(key, (value as num).toInt()));
          }
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading game data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Play Games', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEC4899).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const Icon(Icons.stars, color: Colors.white, size: 32),
                              const SizedBox(height: 8),
                              Text(
                                '$_totalGameXP',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                'Total XP',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 60,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              const Icon(Icons.games, color: Colors.white, size: 32),
                              const SizedBox(height: 8),
                              Text(
                                '$_gamesPlayed',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                'Games Played',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
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
                    title: 'IP Quiz Master',
                    description: 'Test your IPR knowledge in rapid-fire quiz',
                    icon: '🧠',
                    color: const Color(0xFF8B5CF6),
                    difficulty: 'Medium',
                    xpReward: '10-100 XP',
                    timeEstimate: '1-2 min',
                    isImplemented: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const IPRQuizMasterGame()),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Game 2: Match the IPR (Implemented)
                  _buildGameCard(
                    title: 'Match the IPR',
                    description: 'Memory card game matching IPR concepts',
                    icon: '🎯',
                    color: const Color(0xFF10B981),
                    difficulty: 'Easy',
                    xpReward: '60-100 XP',
                    timeEstimate: '2-5 min',
                    isImplemented: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MatchIPRGame()),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    'Coming Soon',
                    style: AppTextStyles.sectionHeader.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Game 3: Spot the Original
                  _buildGameCard(
                    title: 'Spot the Original',
                    description: 'Identify genuine IP from counterfeits',
                    icon: '🔍',
                    color: const Color(0xFFF59E0B),
                    difficulty: 'Hard',
                    xpReward: '15-75 XP',
                    timeEstimate: '3-5 min',
                    isImplemented: false,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Game 4: IP Defender
                  _buildGameCard(
                    title: 'IP Defender',
                    description: 'Defend your IP rights from infringement',
                    icon: '🛡️',
                    color: const Color(0xFFEF4444),
                    difficulty: 'Medium',
                    xpReward: 'Up to 50 XP',
                    timeEstimate: '3-5 min',
                    isImplemented: false,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Game 5: GI Mapper
                  _buildGameCard(
                    title: 'GI Mapper',
                    description: 'Drag GI products to correct locations on map',
                    icon: '🗺️',
                    color: const Color(0xFF3B82F6),
                    difficulty: 'Medium',
                    xpReward: '10-80 XP',
                    timeEstimate: '2-4 min',
                    isImplemented: false,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Game 6: Patent Detective
                  _buildGameCard(
                    title: 'Patent Detective',
                    description: 'Solve patent investigation cases',
                    icon: '🕵️',
                    color: const Color(0xFF6366F1),
                    difficulty: 'Hard',
                    xpReward: '20-60 XP',
                    timeEstimate: '5-8 min',
                    isImplemented: false,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Game 7: Innovation Lab
                  _buildGameCard(
                    title: 'Innovation Lab',
                    description: 'Draw & simulate your own invention',
                    icon: '🔬',
                    color: const Color(0xFFEC4899),
                    difficulty: 'Creative',
                    xpReward: '100 XP',
                    timeEstimate: '10-15 min',
                    isImplemented: false,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildGameCard({
    required String title,
    required String description,
    required String icon,
    required Color color,
    required String difficulty,
    required String xpReward,
    required String timeEstimate,
    required bool isImplemented,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isImplemented ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      icon,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
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
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!isImplemented)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Soon',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange[700],
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
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildInfoChip(difficulty, Icons.bar_chart, color),
                          const SizedBox(width: 8),
                          _buildInfoChip(xpReward, Icons.stars, color),
                          const SizedBox(width: 8),
                          _buildInfoChip(timeEstimate, Icons.access_time, color),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

