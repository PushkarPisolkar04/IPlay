import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/progress_service.dart';
import '../../utils/haptic_feedback_util.dart';
import '../../widgets/primary_button.dart';

/// GI Mapper - Drag GI products to their correct states on India map
class GIMapperGame extends StatefulWidget {
  const GIMapperGame({super.key});

  @override
  State<GIMapperGame> createState() => _GIMapperGameState();
}

class _GIMapperGameState extends State<GIMapperGame> {
  final ProgressService _progressService = ProgressService();
  
  bool _gameStarted = false;
  bool _gameEnded = false;
  bool _showingResults = false;
  
  List<GIProduct> _products = [];
  final Map<String, String?> _placements = {}; // productId -> stateId
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    // Load 8 GI products
    _products = _getGIProducts();
    for (var product in _products) {
      _placements[product.id] = null;
    }
  }

  void _startGame() {
    setState(() {
      _gameStarted = true;
    });
  }

  void _submitAnswers() {
    // Calculate score
    int correctCount = 0;
    for (var product in _products) {
      if (_placements[product.id] == product.correctState) {
        correctCount++;
      }
    }
    
    // Haptic feedback based on score
    if (correctCount >= 6) {
      HapticFeedbackUtil.success();
    } else if (correctCount >= 4) {
      HapticFeedbackUtil.mediumImpact();
    } else {
      HapticFeedbackUtil.lightImpact();
    }
    
    setState(() {
      _score = correctCount;
      _showingResults = true;
    });
    
    // Wait a moment then end game
    Future.delayed(const Duration(seconds: 2), () {
      _endGame();
    });
  }

  void _endGame() {
    // Haptic feedback for XP gain
    HapticFeedbackUtil.xpGain();
    
    setState(() {
      _gameEnded = true;
    });
    _saveScore();
  }

  Future<void> _saveScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final xpEarned = _score * 10;
        
        // Save to progress
        await _progressService.completeLevel(
          userId: user.uid,
          realmId: 'game_gi_mapper',
          levelNumber: 1,
          xpEarned: xpEarned,
          quizScore: _score,
          totalQuestions: _products.length,
        );
        
        // Save detailed game history
        await FirebaseFirestore.instance
            .collection('progress')
            .doc('${user.uid}__game_gi_mapper')
            .set({
          'userId': user.uid,
          'contentId': 'game_gi_mapper',
          'contentType': 'game',
          'status': 'completed',
          'xpEarned': xpEarned,
          'highScore': _score,
          'accuracy': (_score / _products.length * 100).round(),
          'attemptsCount': FieldValue.increment(1),
          'lastAttemptAt': Timestamp.now(),
          'completedAt': Timestamp.now(),
        }, SetOptions(merge: true));
        
        // Update user's gameProgress
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        final currentGameProgress = userDoc.data()?['gameProgress'] as Map<String, dynamic>? ?? {};
        final currentScores = currentGameProgress['scores'] as Map<String, dynamic>? ?? {};
        final currentBestScore = currentScores['gi_mapper'] as int? ?? 0;
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'gameProgress': {
            'totalXP': FieldValue.increment(xpEarned),
            'gamesPlayed': FieldValue.increment(1),
            'scores': {
              'gi_mapper': _score > currentBestScore ? _score : currentBestScore,
            },
            'lastPlayedAt': Timestamp.now(),
          },
        }, SetOptions(merge: true));
        
        // print('✅ Game score saved: $_score, XP earned: $xpEarned');
      } catch (e) {
        // print('❌ Error saving game score: $e');
      }
    }
  }

  void _restartGame() {
    setState(() {
      _gameEnded = false;
      _gameStarted = false;
      _showingResults = false;
      _score = 0;
    });
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    if (!_gameStarted) {
      return _buildStartScreen();
    }

    if (_gameEnded) {
      return _buildResultScreen();
    }

    return _buildGameScreen();
  }

  Widget _buildStartScreen() {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('GI Mapper'),
        backgroundColor: AppDesignSystem.primaryAmber,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Game icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppDesignSystem.primaryAmber.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.map,
                  size: 60,
                  color: AppDesignSystem.primaryAmber,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              Text(
                'GI Mapper',
                style: AppTextStyles.h1,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                'Match Geographical Indication products to their correct states!',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppDesignSystem.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Game rules
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppDesignSystem.backgroundGrey,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Game Rules:',
                      style: AppTextStyles.cardTitle,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildRuleItem('🗺️', '8 GI products to place'),
                    _buildRuleItem('📍', 'Drag each product to its state'),
                    _buildRuleItem('🎯', 'Match all products correctly'),
                    _buildRuleItem('⭐', '10 XP per correct placement (max 80 XP)'),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Start button
              PrimaryButton(
                text: 'Start Game',
                onPressed: _startGame,
                fullWidth: true,
                icon: Icons.play_arrow,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('GI Mapper'),
        backgroundColor: AppDesignSystem.primaryAmber,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    // Instructions
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppDesignSystem.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.sm),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppDesignSystem.info),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Drag each GI product to its correct state',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppDesignSystem.info,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // India Map (simplified representation)
                    _buildIndiaMap(),

                    const SizedBox(height: AppSpacing.xl),

                    // Products to drag
                    Text(
                      'GI Products',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _products.map((product) {
                        final isPlaced = _placements[product.id] != null;
                        
                        return Draggable<GIProduct>(
                          data: product,
                          feedback: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(AppSpacing.sm),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppDesignSystem.primaryAmber,
                                borderRadius: BorderRadius.circular(AppSpacing.sm),
                              ),
                              child: Text(
                                product.name,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: _buildProductChip(product, isPlaced),
                          ),
                          child: _buildProductChip(product, isPlaced),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            // Submit button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: PrimaryButton(
                text: 'Submit Answers',
                onPressed: _placements.values.every((v) => v != null)
                    ? _submitAnswers
                    : null,
                fullWidth: true,
                icon: Icons.check,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductChip(GIProduct product, bool isPlaced) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: isPlaced ? Colors.grey[300] : AppDesignSystem.primaryAmber,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Text(
        product.name,
        style: AppTextStyles.bodySmall.copyWith(
          color: isPlaced ? AppDesignSystem.textSecondary : Colors.white,
        ),
      ),
    );
  }

  Widget _buildIndiaMap() {
    // Simplified India map with major states as drop targets
    final states = [
      'Kashmir', 'Punjab', 'Rajasthan', 'Gujarat',
      'Maharashtra', 'Karnataka', 'Tamil Nadu', 'Kerala',
      'West Bengal', 'Assam', 'Uttar Pradesh', 'Madhya Pradesh',
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppDesignSystem.backgroundGrey),
      ),
      child: Column(
        children: [
          Text(
            'India Map',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Grid of states
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.5,
            ),
            itemCount: states.length,
            itemBuilder: (context, index) {
              final state = states[index];
              final placedProduct = _products.firstWhere(
                (p) => _placements[p.id] == state,
                orElse: () => GIProduct(id: '', name: '', correctState: '', icon: Icons.help),
              );
              final hasProduct = placedProduct.id.isNotEmpty;
              
              return DragTarget<GIProduct>(
                onAcceptWithDetails: (details) {
                  setState(() {
                    final product = details.data;
                    // Remove from previous placement
                    _placements.forEach((key, value) {
                      if (value == state) {
                        _placements[key] = null;
                      }
                    });
                    // Place in new state
                    _placements[product.id] = state;
                  });
                },
                builder: (context, candidateData, rejectedData) {
                  final isHovering = candidateData.isNotEmpty;
                  
                  Color bgColor = Colors.white;
                  Color borderColor = AppDesignSystem.backgroundGrey;
                  
                  if (_showingResults && hasProduct) {
                    if (placedProduct.correctState == state) {
                      bgColor = AppDesignSystem.success.withValues(alpha: 0.1);
                      borderColor = AppDesignSystem.success;
                    } else {
                      bgColor = Colors.red.withValues(alpha: 0.1);
                      borderColor = Colors.red;
                    }
                  } else if (isHovering) {
                    bgColor = AppDesignSystem.primaryAmber.withValues(alpha: 0.1);
                    borderColor = AppDesignSystem.primaryAmber;
                  } else if (hasProduct) {
                    bgColor = AppDesignSystem.primaryAmber.withValues(alpha: 0.05);
                  }
                  
                  return Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: Border.all(color: borderColor, width: 2),
                      borderRadius: BorderRadius.circular(AppSpacing.sm),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          state,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (hasProduct) ...[
                          const SizedBox(height: 4),
                          Icon(
                            placedProduct.icon,
                            size: 16,
                            color: AppDesignSystem.primaryAmber,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    final percentage = (_score / _products.length * 100).round();
    final passed = percentage >= 60;
    final xpEarned = _score * 10;

    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('Game Over'),
        backgroundColor: AppDesignSystem.primaryAmber,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Result icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: passed ? AppDesignSystem.success.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  passed ? Icons.emoji_events : Icons.refresh,
                  size: 60,
                  color: passed ? AppDesignSystem.success : Colors.orange,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              Text(
                passed ? 'Excellent!' : 'Good Try!',
                style: AppTextStyles.h1,
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                'You placed $_score out of ${_products.length} products correctly',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppDesignSystem.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Stats
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppDesignSystem.backgroundGrey,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: Column(
                  children: [
                    _buildStatRow('Score', '$_score/${_products.length}'),
                    const Divider(height: 24),
                    _buildStatRow('Accuracy', '$percentage%'),
                    const Divider(height: 24),
                    _buildStatRow('XP Earned', '+$xpEarned XP', isHighlight: true),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Buttons
              PrimaryButton(
                text: 'Play Again',
                onPressed: _restartGame,
                fullWidth: true,
                icon: Icons.refresh,
              ),

              const SizedBox(height: AppSpacing.md),

              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Back to Games',
                    style: AppTextStyles.button,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppDesignSystem.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.h3.copyWith(
            color: isHighlight ? AppDesignSystem.primaryAmber : AppDesignSystem.textPrimary,
          ),
        ),
      ],
    );
  }

  // GI Products data
  List<GIProduct> _getGIProducts() {
    return [
      GIProduct(
        id: '1',
        name: 'Darjeeling Tea',
        correctState: 'West Bengal',
        icon: Icons.local_cafe,
      ),
      GIProduct(
        id: '2',
        name: 'Basmati Rice',
        correctState: 'Punjab',
        icon: Icons.rice_bowl,
      ),
      GIProduct(
        id: '3',
        name: 'Alphonso Mango',
        correctState: 'Maharashtra',
        icon: Icons.food_bank,
      ),
      GIProduct(
        id: '4',
        name: 'Mysore Silk',
        correctState: 'Karnataka',
        icon: Icons.checkroom,
      ),
      GIProduct(
        id: '5',
        name: 'Kanchipuram Silk',
        correctState: 'Tamil Nadu',
        icon: Icons.checkroom,
      ),
      GIProduct(
        id: '6',
        name: 'Kashmir Pashmina',
        correctState: 'Kashmir',
        icon: Icons.checkroom,
      ),
      GIProduct(
        id: '7',
        name: 'Assam Tea',
        correctState: 'Assam',
        icon: Icons.local_cafe,
      ),
      GIProduct(
        id: '8',
        name: 'Banganapalle Mango',
        correctState: 'Andhra Pradesh',
        icon: Icons.food_bank,
      ),
    ];
  }
}

class GIProduct {
  final String id;
  final String name;
  final String correctState;
  final IconData icon;

  GIProduct({
    required this.id,
    required this.name,
    required this.correctState,
    required this.icon,
  });
}
