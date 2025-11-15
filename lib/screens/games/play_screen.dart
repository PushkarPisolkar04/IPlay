import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import 'ipr_quiz_master_game.dart';
import 'match_ipr_game.dart';
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
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      // print('Error loading game data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadGameData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('Play Games', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              color: const Color(0xFFEC4899),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                          color: const Color(0xFFEC4899).withValues(alpha: 0.3),
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
                          color: Colors.white.withValues(alpha: 0.5),
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
                    title: 'IPR Quiz Master',
                    description: 'Test your IPR knowledge in rapid-fire quiz',
                    iconPath: 'assets/logos/IPR_quiz_master.png',
                    color: const Color(0xFF6366F1),
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
                    iconPath: 'assets/logos/match_the_IPR.png',
                    color: const Color(0xFFEC4899),
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
                  
                  const SizedBox(height: 16),
                  
                  // Game 3: Spot the Original
                  _buildGameCard(
                    title: 'Spot the Original',
                    description: 'Identify genuine IP from counterfeits',
                    iconPath: 'assets/logos/spot_the_original.png',
                    color: const Color(0xFFF59E0B),
                    difficulty: 'Medium',
                    xpReward: '15-75 XP',
                    timeEstimate: '2-3 min',
                    isImplemented: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SpotTheOriginalGame()),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Game 4: IP Defender
                  _buildGameCard(
                    title: 'IP Defender',
                    description: 'Defend your IP rights from infringement',
                    iconPath: 'assets/logos/ip_defender.png',
                    color: const Color(0xFFEF4444),
                    difficulty: 'Hard',
                    xpReward: 'Up to 500 XP',
                    timeEstimate: '5-10 min',
                    isImplemented: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const IPDefenderGame()),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Game 5: GI Mapper
                  _buildGameCard(
                    title: 'GI Mapper',
                    description: 'Match GI products to their states',
                    iconPath: 'assets/logos/gi_mapper.png',
                    color: const Color(0xFF10B981),
                    difficulty: 'Medium',
                    xpReward: '10-80 XP',
                    timeEstimate: '3-5 min',
                    isImplemented: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GIMapperGame()),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Game 6: Patent Detective
                  _buildGameCard(
                    title: 'Patent Detective',
                    description: 'Investigate patent cases and determine patentability',
                    iconPath: 'assets/logos/patent_detective.png',
                    color: const Color(0xFF8B5CF6),
                    difficulty: 'Medium',
                    xpReward: '20-60 XP',
                    timeEstimate: '3-5 min',
                    isImplemented: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PatentDetectiveGame()),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Game 7: Innovation Lab
                  _buildGameCard(
                    title: 'Innovation Lab',
                    description: 'Design your invention and learn IP protection',
                    iconPath: 'assets/logos/innovation_lab.png',
                    color: Colors.teal,
                    difficulty: 'Easy',
                    xpReward: '100 XP',
                    timeEstimate: '5-10 min',
                    isImplemented: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const InnovationLabGame()),
                      );
                    },
                  ),
                ],
                ),
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
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isImplemented ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Image.asset(
                      iconPath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.games,
                          size: 40,
                          color: color,
                        );
                      },
                    ),
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
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!isImplemented)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Soon',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildInfoChip(difficulty, Icons.bar_chart, color),
                          _buildInfoChip(xpReward, Icons.stars, color),
                          _buildInfoChip(timeEstimate, Icons.access_time, color),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isImplemented) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: color,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
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

