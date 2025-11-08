                                                            
                                                            import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/progress_service.dart';
import '../../utils/haptic_feedback_util.dart';
import '../../widgets/primary_button.dart';

/// Patent Detective - Investigate patent cases and determine patentability
class PatentDetectiveGame extends StatefulWidget {
  const PatentDetectiveGame({super.key});

  @override
  State<PatentDetectiveGame> createState() => _PatentDetectiveGameState();
}

class _PatentDetectiveGameState extends State<PatentDetectiveGame> {
  final ProgressService _progressService = ProgressService();
  
  int _currentCase = 0;
  int _score = 0;
  bool _gameStarted = false;
  bool _gameEnded = false;
  bool _answerLocked = false;
  bool? _selectedAnswer; // true = patentable, false = not patentable
  List<PatentCase> _cases = [];

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  void _loadCases() {
    // Load 3 patent investigation cases
    _cases = _getPatentCases();
  }

  void _startGame() {
    setState(() {
      _gameStarted = true;
      _currentCase = 0;
      _score = 0;
    });
  }

  void _selectAnswer(bool isPatentable) {
    if (_answerLocked || _gameEnded) return;
    
    setState(() {
      _selectedAnswer = isPatentable;
      _answerLocked = true;
    });

    // Check if correct
    if (isPatentable == _cases[_currentCase].isPatentable) {
      setState(() {
        _score++;
      });
      // Haptic feedback for correct answer
      HapticFeedbackUtil.correctAnswer();
    } else {
      // Haptic feedback for incorrect answer
      HapticFeedbackUtil.incorrectAnswer();
    }

    // Move to next case after delay
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (_currentCase < _cases.length - 1) {
        setState(() {
          _currentCase++;
          _selectedAnswer = null;
          _answerLocked = false;
        });
      } else {
        _endGame();
      }
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
        final xpEarned = _score * 20;
        
        // Save to progress
        await _progressService.completeLevel(
          userId: user.uid,
          realmId: 'game_patent_detective',
          levelNumber: 1,
          xpEarned: xpEarned,
          quizScore: _score,
          totalQuestions: _cases.length,
        );
        
        // Save detailed game history
        await FirebaseFirestore.instance
            .collection('progress')
            .doc('${user.uid}__game_patent_detective')
            .set({
          'userId': user.uid,
          'contentId': 'game_patent_detective',
          'contentType': 'game',
          'status': 'completed',
          'xpEarned': xpEarned,
          'highScore': _score,
          'accuracy': (_score / _cases.length * 100).round(),
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
        final currentBestScore = currentScores['patent_detective'] as int? ?? 0;
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'gameProgress': {
            'totalXP': FieldValue.increment(xpEarned),
            'gamesPlayed': FieldValue.increment(1),
            'scores': {
              'patent_detective': _score > currentBestScore ? _score : currentBestScore,
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
      _currentCase = 0;
      _score = 0;
      _selectedAnswer = null;
      _answerLocked = false;
    });
    _loadCases();
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
        title: const Text('Patent Detective'),
        backgroundColor: AppDesignSystem.primaryIndigo,
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
                  color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search,
                  size: 60,
                  color: AppDesignSystem.primaryIndigo,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              Text(
                'Patent Detective',
                style: AppTextStyles.h1,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                'Investigate patent cases and determine if inventions are patentable!',
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
                    _buildRuleItem('🔍', '3 patent investigation cases'),
                    _buildRuleItem('📋', 'Examine clues (prior art, novelty, utility)'),
                    _buildRuleItem('⚖️', 'Decide: Patentable or Not Patentable'),
                    _buildRuleItem('⭐', '20 XP per correct decision (max 60 XP)'),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Start button
              PrimaryButton(
                text: 'Start Investigation',
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
    final patentCase = _cases[_currentCase];
    
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: Text('Case ${_currentCase + 1}/3'),
        backgroundColor: AppDesignSystem.primaryIndigo,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: (_currentCase + 1) / _cases.length,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(AppDesignSystem.primaryIndigo),
              minHeight: 6,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.md),

                    // Score display
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppDesignSystem.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppDesignSystem.success,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Correct Cases: $_score',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppDesignSystem.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Case title
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
                            AppDesignSystem.primaryPink.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                patentCase.icon,
                                color: AppDesignSystem.primaryIndigo,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  patentCase.title,
                                  style: AppTextStyles.h3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            patentCase.description,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Clues section
                    Text(
                      'Investigation Clues:',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Prior Art clue
                    _buildClueCard(
                      icon: Icons.history,
                      title: 'Prior Art',
                      content: patentCase.priorArt,
                      color: Colors.blue,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Novelty clue
                    _buildClueCard(
                      icon: Icons.lightbulb,
                      title: 'Novelty',
                      content: patentCase.novelty,
                      color: Colors.orange,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Utility clue
                    _buildClueCard(
                      icon: Icons.build,
                      title: 'Utility',
                      content: patentCase.utility,
                      color: Colors.green,
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Decision section
                    if (!_answerLocked) ...[
                      Text(
                        'Your Decision:',
                        style: AppTextStyles.h3,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildDecisionButton(
                              label: 'Patentable',
                              icon: Icons.check_circle,
                              color: AppDesignSystem.success,
                              onTap: () => _selectAnswer(true),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _buildDecisionButton(
                              label: 'Not Patentable',
                              icon: Icons.cancel,
                              color: Colors.red,
                              onTap: () => _selectAnswer(false),
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (_answerLocked) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: _selectedAnswer == patentCase.isPatentable
                              ? AppDesignSystem.success.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                          border: Border.all(
                            color: _selectedAnswer == patentCase.isPatentable
                                ? AppDesignSystem.success
                                : Colors.red,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _selectedAnswer == patentCase.isPatentable
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: _selectedAnswer == patentCase.isPatentable
                                      ? AppDesignSystem.success
                                      : Colors.red,
                                  size: 32,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _selectedAnswer == patentCase.isPatentable
                                        ? 'Correct!'
                                        : 'Incorrect',
                                    style: AppTextStyles.h3.copyWith(
                                      color: _selectedAnswer == patentCase.isPatentable
                                          ? AppDesignSystem.success
                                          : Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              patentCase.explanation,
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClueCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTextStyles.cardTitle.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            content,
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 48),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: AppTextStyles.button.copyWith(color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    final percentage = (_score / _cases.length * 100).round();
    final passed = percentage >= 60;
    final xpEarned = _score * 20;
    
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('Investigation Complete'),
        backgroundColor: AppDesignSystem.primaryIndigo,
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
                passed ? 'Excellent Detective Work!' : 'Keep Investigating!',
                style: AppTextStyles.h1,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                'You correctly determined $_score out of ${_cases.length} cases',
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
                    _buildStatRow('Cases Solved', '$_score/${_cases.length}'),
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
                text: 'Investigate Again',
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
            color: isHighlight ? AppDesignSystem.primaryIndigo : AppDesignSystem.textPrimary,
          ),
        ),
      ],
    );
  }

  // Patent cases data
  List<PatentCase> _getPatentCases() {
    return [
      PatentCase(
        title: 'Smart Water Bottle',
        description: 'A water bottle with LED indicators that remind users to drink water at regular intervals.',
        icon: Icons.water_drop,
        priorArt: 'Similar smart water bottles with hydration reminders exist in the market since 2018.',
        novelty: 'This invention uses a unique algorithm that adjusts reminder frequency based on weather and user activity.',
        utility: 'The invention has practical utility in helping people maintain proper hydration throughout the day.',
        isPatentable: true,
        explanation: 'This invention is PATENTABLE. While similar products exist, the unique algorithm for adaptive reminders provides novelty. The invention has clear utility and is not an obvious improvement.',
      ),
      PatentCase(
        title: 'Mathematical Formula for Calculating Interest',
        description: 'A new mathematical formula for calculating compound interest on loans.',
        icon: Icons.calculate,
        priorArt: 'Mathematical formulas and abstract ideas have been used for centuries in finance.',
        novelty: 'The formula uses a different approach to calculate interest, but it\'s still just a mathematical method.',
        utility: 'The formula can be used to calculate interest, which is useful in financial applications.',
        isPatentable: false,
        explanation: 'This invention is NOT PATENTABLE. Mathematical formulas, abstract ideas, and laws of nature cannot be patented. Even if the formula is novel, it falls under the category of non-patentable subject matter.',
      ),
      PatentCase(
        title: 'Self-Cleaning Solar Panel',
        description: 'A solar panel with a built-in mechanism that automatically cleans dust and debris using minimal water.',
        icon: Icons.solar_power,
        priorArt: 'Manual cleaning methods for solar panels are well-known, but no automated self-cleaning mechanism exists.',
        novelty: 'The invention introduces a novel mechanical system that uses vibration and minimal water spray to clean panels.',
        utility: 'The invention significantly improves solar panel efficiency by maintaining cleanliness without manual intervention.',
        isPatentable: true,
        explanation: 'This invention is PATENTABLE. It demonstrates novelty with its unique self-cleaning mechanism, has clear utility in improving solar panel efficiency, and represents a non-obvious improvement over existing manual cleaning methods.',
      ),
    ];
  }
}

class PatentCase {
  final String title;
  final String description;
  final IconData icon;
  final String priorArt;
  final String novelty;
  final String utility;
  final bool isPatentable;
  final String explanation;

  PatentCase({
    required this.title,
    required this.description,
    required this.icon,
    required this.priorArt,
    required this.novelty,
    required this.utility,
    required this.isPatentable,
    required this.explanation,
  });
}
