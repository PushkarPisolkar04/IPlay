import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/clean_card.dart';
import '../../widgets/loading_skeleton.dart';

/// My Progress Screen - Student's self-view of their progress
class MyProgressScreen extends StatefulWidget {
  const MyProgressScreen({super.key});

  @override
  State<MyProgressScreen> createState() => _MyProgressScreenState();
}

class _MyProgressScreenState extends State<MyProgressScreen>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  Map<String, dynamic> _progressSummary = {};
  int _globalRank = 0;

  @override
  bool get wantKeepAlive => false; // Don't keep state alive, always refresh

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mounted) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      final userData = userDoc.data()!;
      final userXP = userData['totalXP'] ?? 0;

      // Calculate global rank
      final higherXPUsers = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('totalXP', isGreaterThan: userXP)
          .get();

      // Get user's progress
      final userProgress =
          userData['progressSummary'] as Map<String, dynamic>? ?? {};

      // Define all available realms (6 realms)
      final allRealms = {
        'patent': {'totalLevels': 8, 'levelsCompleted': 0, 'completed': false},
        'trademark': {'totalLevels': 8, 'levelsCompleted': 0, 'completed': false},
        'copyright': {'totalLevels': 8, 'levelsCompleted': 0, 'completed': false},
        'trade_secrets': {
          'totalLevels': 8,
          'levelsCompleted': 0,
          'completed': false
        },
        'industrial_design': {
          'totalLevels': 8,
          'levelsCompleted': 0,
          'completed': false
        },
        'geographical_indications': {
          'totalLevels': 8,
          'levelsCompleted': 0,
          'completed': false
        },
      };

      // Merge user progress with all realms
      final mergedProgress = <String, dynamic>{};
      allRealms.forEach((key, value) {
        if (userProgress.containsKey(key)) {
          mergedProgress[key] = userProgress[key];
        } else {
          mergedProgress[key] = value;
        }
      });

      // Add games from user progress
      userProgress.forEach((key, value) {
        if (_isGame(key)) {
          mergedProgress[key] = value;
        }
      });

      if (mounted) {
        setState(() {
          _userData = userData;
          _progressSummary = mergedProgress;
          _globalRank = higherXPUsers.docs.length + 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading progress: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Calculate level from XP (100 XP per level)
  int _calculateLevel(int totalXP) {
    return (totalXP / 100).floor() + 1;
  }

  int _calculateLevelProgress(int totalXP) {
    return totalXP % 100;
  }

  int _calculateXPToNextLevel(int totalXP) {
    return 100 - (totalXP % 100);
  }

  // Dynamic aspect ratio based on screen size
  double _getCardAspectRatio(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = AppSpacing.screenHorizontal * 2;
    final availableWidth = screenWidth - padding - 12; // spacing
    final cardWidth = availableWidth / 2;
    final desiredHeight = cardWidth * 1.15; // slightly taller
    return cardWidth / desiredHeight;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppDesignSystem.backgroundLight,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: AppDesignSystem.gradientPrimary,
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'My Progress',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final totalXP = _userData?['totalXP'] ?? 0;
    final level = _calculateLevel(totalXP);
    final levelProgress = _calculateLevelProgress(totalXP);
    final xpToNextLevel = _calculateXPToNextLevel(totalXP);
    final dayStreak = _userData?['currentStreak'] ?? 0;
    final longestStreak = _userData?['longestStreak'] ?? 0;
    final badges = (_userData?['badges'] as List?)?.length ?? 0;

    // Calculate realm stats
    int completedRealms = 0;
    int totalRealms = _progressSummary.length;
    int totalLevels = 0;
    int completedLevels = 0;

    _progressSummary.forEach((key, value) {
      if (value is Map) {
        if (value['completed'] == true) {
          completedRealms++;
        }
        totalLevels += (value['totalLevels'] ?? 0) as int;
        completedLevels += (value['levelsCompleted'] ?? 0) as int;
      }
    });

    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                gradient: AppDesignSystem.gradientPrimary,
                boxShadow: [
                  BoxShadow(
                    color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'My Progress',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),

            // Scrollable Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                color: AppDesignSystem.primaryIndigo,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // Level Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppDesignSystem.primaryIndigo,
                              AppDesignSystem.secondaryPurple,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppDesignSystem.primaryIndigo.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _userData?['displayName'] ?? 'Student',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Global Rank #$_globalRank',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withValues(alpha: 0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'LVL',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppDesignSystem.primaryIndigo,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '$level',
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: AppDesignSystem.primaryIndigo,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Level $level Progress',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '$levelProgress / 100 XP',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: levelProgress / 100,
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.3),
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                      minHeight: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '$xpToNextLevel XP to Level ${level + 1}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ), // ← CORRECTLY CLOSED

                      const SizedBox(height: AppSpacing.lg),

                      // Stats Grid
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              Icons.stars,
                              '$totalXP',
                              'Total XP',
                              const Color(0xFFF59E0B),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              Icons.emoji_events,
                              '$badges',
                              'Badges',
                              const Color(0xFFEC4899),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              Icons.bar_chart,
                              '#$_globalRank',
                              'Rank',
                              const Color(0xFF6366F1),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Overall Progress
                      Text('Overall Progress', style: AppTextStyles.sectionHeader),
                      const SizedBox(height: AppSpacing.sm),
                      CleanCard(
                        child: Column(
                          children: [
                            _buildProgressRow(
                              'Levels Completed',
                              completedLevels,
                              totalLevels > 0 ? totalLevels : 1,
                              AppDesignSystem.primaryIndigo,
                            ),
                            const Divider(height: 24),
                            _buildProgressRow(
                              'Realms Completed',
                              completedRealms,
                              totalRealms > 0 ? totalRealms : 1,
                              AppDesignSystem.success,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // No Progress Yet
                      if (_progressSummary.isEmpty)
                        CleanCard(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.school_outlined,
                                  size: 48,
                                  color: AppDesignSystem.textTertiary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No Progress Yet',
                                  style: AppTextStyles.h3.copyWith(
                                    color: AppDesignSystem.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start learning to see your progress here!',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppDesignSystem.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Games Section
                      if (_progressSummary.entries.any((e) => _isGame(e.key))) ...[
                        Row(
                          children: [
                            Icon(Icons.videogame_asset,
                                color: AppDesignSystem.primaryIndigo, size: 22),
                            const SizedBox(width: 8),
                            Text('Games', style: AppTextStyles.sectionHeader),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: _getCardAspectRatio(context),
                          children: _progressSummary.entries
                              .where((entry) => _isGame(entry.key))
                              .map((entry) => _buildGameCard(entry))
                              .toList(),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],

                      // Realms Section
                      if (_progressSummary.entries.any((e) => !_isGame(e.key))) ...[
                        Row(
                          children: [
                            Icon(Icons.school,
                                color: AppDesignSystem.primaryIndigo, size: 22),
                            const SizedBox(width: 8),
                            Text('Realms', style: AppTextStyles.sectionHeader),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: _getCardAspectRatio(context),
                          children: _progressSummary.entries
                              .where((entry) => !_isGame(entry.key))
                              .map((entry) => _buildRealmCard(entry))
                              .toList(),
                        ),
                      ],

                      const SizedBox(height: AppSpacing.xl + 20),
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

  // ==================== CARD BUILDERS ====================

  Widget _buildGameCard(MapEntry<String, dynamic> entry) {
    final itemData = entry.value as Map;
    final itemName = entry.key;
    final highScore = (itemData['highScore'] ?? 0) as int;
    final itemColor = _getItemColor(itemName);
    final itemLogo = _getItemLogo(itemName);

    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [itemColor, itemColor.withValues(alpha: 0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: itemColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: constraints.maxWidth * 0.5,
                    height: constraints.maxWidth * 0.5,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Image.asset(
                      itemLogo,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.videogame_asset,
                              color: Colors.white, size: 32),
                    ),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _formatRealmName(itemName),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.emoji_events,
                          color: Colors.white, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        '$highScore',
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ],
                  ),
                  Text(
                    'High Score',
                    style: TextStyle(
                        fontSize: 9, color: Colors.white.withValues(alpha: 0.9)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRealmCard(MapEntry<String, dynamic> entry) {
    final itemData = entry.value as Map;
    final itemName = entry.key;
    final levelsCompleted = (itemData['levelsCompleted'] ?? 0) as int;
    final totalLevels = (itemData['totalLevels'] ?? 1) as int;
    final progress = totalLevels > 0 ? levelsCompleted / totalLevels : 0.0;
    final isCompleted = itemData['completed'] == true;
    final itemColor = _getItemColor(itemName);
    final itemLogo = _getItemLogo(itemName);

    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [itemColor, itemColor.withValues(alpha: 0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: itemColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: constraints.maxWidth * 0.5,
                    height: constraints.maxWidth * 0.5,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Image.asset(
                      itemLogo,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.school, color: Colors.white, size: 32),
                    ),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _formatRealmName(itemName),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$levelsCompleted',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      Text(
                        '/$totalLevels',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8)),
                      ),
                      if (isCompleted)
                        const Padding(
                          padding: EdgeInsets.only(left: 3),
                          child: Icon(Icons.check_circle,
                              color: Colors.white, size: 13),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
      IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(
      String label, int current, int total, Color color) {
    final progress = total > 0 ? current / total : 0.0;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('$current / $total',
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== HELPERS ====================

  bool _isGame(String name) {
    return name.toLowerCase().startsWith('game');
  }

  String _getItemLogo(String itemName) {
    final nameLower = itemName.toLowerCase();

    if (nameLower.contains('trademark') && nameLower.contains('game')) {
      return 'assets/logos/match_the_IPR.png';
    }
    if (nameLower.contains('ip') && nameLower.contains('defender')) {
      return 'assets/logos/ip_defender.png';
    }
    if (nameLower.contains('patent') && nameLower.contains('detective')) {
      return 'assets/logos/patent_detective.png';
    }
    if (nameLower.contains('spot') && nameLower.contains('original')) {
      return 'assets/logos/spot_the_original.png';
    }
    if (nameLower.contains('gi') && nameLower.contains('mapper')) {
      return 'assets/logos/gi_mapper.png';
    }
    if (nameLower.contains('quiz') || nameLower.contains('ipr')) {
      return 'assets/logos/IPR_quiz_master.png';
    }
    if (nameLower.contains('innovation') && nameLower.contains('lab')) {
      return 'assets/logos/innovation_lab.png';
    }

    final realmLogos = {
      'patent': 'assets/logos/patent_logo.png',
      'trademark': 'assets/logos/trademark_logo.png',
      'copyright': 'assets/logos/copyright_logo.png',
      'trade_secrets': 'assets/logos/trade_secrets_logo.png',
      'industrial_design': 'assets/logos/design_logo.png',
      'geographical_indications': 'assets/logos/gi_logo.png',
    };

    for (var entry in realmLogos.entries) {
      if (nameLower.contains(entry.key.replaceAll('_', ' '))) {
        return entry.value;
      }
    }

    return 'assets/logos/logo.png';
  }

  Color _getItemColor(String itemName) {
    final nameLower = itemName.toLowerCase();

    if (_isGame(itemName)) {
      if (nameLower.contains('trademark')) return const Color(0xFFEC4899);
      if (nameLower.contains('ip') || nameLower.contains('defender'))
        return const Color(0xFF6366F1);
      if (nameLower.contains('patent')) return const Color(0xFF8B5CF6);
      if (nameLower.contains('spot')) return const Color(0xFFF59E0B);
      if (nameLower.contains('gi')) return const Color(0xFF14B8A6);
      if (nameLower.contains('quiz')) return const Color(0xFF10B981);
      if (nameLower.contains('innovation')) return const Color(0xFFEC4899);
      return const Color(0xFF6366F1);
    }

    final colors = {
      'patent': const Color(0xFF6366F1),
      'trademark': const Color(0xFFEC4899),
      'copyright': const Color(0xFF8B5CF6),
      'trade_secrets': const Color(0xFF10B981),
      'industrial_design': const Color(0xFFF59E0B),
      'geographical_indications': const Color(0xFF14B8A6),
    };

    for (var entry in colors.entries) {
      if (nameLower.contains(entry.key.replaceAll('_', ' '))) {
        return entry.value;
      }
    }

    return const Color(0xFF6366F1);
  }

  String _formatRealmName(String name) {
    return name.split('_').map((word) =>
      word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }
}