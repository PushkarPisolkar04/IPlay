import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/progress_service.dart';
import '../../widgets/primary_button.dart';

/// Innovation Lab - Design an invention and learn about IP protection
class InnovationLabGame extends StatefulWidget {
  const InnovationLabGame({super.key});

  @override
  State<InnovationLabGame> createState() => _InnovationLabGameState();
}

class _InnovationLabGameState extends State<InnovationLabGame> {
  final ProgressService _progressService = ProgressService();
  
  // Game state
  bool _gameStarted = false;
  bool _gameEnded = false;
  int _currentStep = 0;
  
  // Drawing state
  final List<DrawingPoint> _drawingPoints = [];
  Color _selectedColor = Colors.black;
  final double _strokeWidth = 3.0;
  
  // Invention details
  String _inventionName = '';
  String _inventionCategory = '';
  final List<String> _categories = [
    'Technology',
    'Healthcare',
    'Agriculture',
    'Education',
    'Entertainment',
    'Transportation',
  ];
  
  // Protection questions
  final Map<String, String?> _answers = {
    'isNew': null,
    'hasUtility': null,
    'isObvious': null,
  };
  
  // IP type matching
  String? _selectedIPType;
  final List<IPType> _ipTypes = [
    IPType(
      name: 'Patent',
      description: 'Protects new inventions and processes',
      icon: Icons.lightbulb,
      color: Colors.blue,
    ),
    IPType(
      name: 'Copyright',
      description: 'Protects creative works like art and writing',
      icon: Icons.palette,
      color: Colors.purple,
    ),
    IPType(
      name: 'Trademark',
      description: 'Protects brand names and logos',
      icon: Icons.copyright,
      color: Colors.orange,
    ),
    IPType(
      name: 'Industrial Design',
      description: 'Protects the appearance of products',
      icon: Icons.design_services,
      color: Colors.green,
    ),
  ];
  
  // Filing checklist
  final Map<String, bool> _checklistItems = {
    'Documented invention details': false,
    'Conducted prior art search': false,
    'Prepared technical drawings': false,
    'Identified claims': false,
    'Completed application form': false,
  };

  @override
  void initState() {
    super.initState();
  }

  void _startGame() {
    setState(() {
      _gameStarted = true;
      _currentStep = 0;
      _drawingPoints.clear();
      _inventionName = '';
      _inventionCategory = '';
      _answers.clear();
      _selectedIPType = null;
      _checklistItems.updateAll((key, value) => false);
    });
  }

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
      });
    } else {
      _endGame();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0: // Drawing
        return _drawingPoints.isNotEmpty;
      case 1: // Name and category
        return _inventionName.isNotEmpty && _inventionCategory.isNotEmpty;
      case 2: // Protection questions
        return _answers.values.every((answer) => answer != null);
      case 3: // IP type matching
        return _selectedIPType != null;
      case 4: // Filing checklist
        return _checklistItems.values.every((checked) => checked);
      default:
        return false;
    }
  }

  void _endGame() {
    setState(() {
      _gameEnded = true;
    });
    _saveScore();
  }

  Future<void> _saveScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        const xpEarned = 100; // Fixed 100 XP reward
        
        // Save to progress
        await _progressService.completeLevel(
          userId: user.uid,
          realmId: 'game_innovation_lab',
          levelNumber: 1,
          xpEarned: xpEarned,
          quizScore: 1,
          totalQuestions: 1,
        );
        
        // Save detailed game history
        await FirebaseFirestore.instance
            .collection('progress')
            .doc('${user.uid}__game_innovation_lab')
            .set({
          'userId': user.uid,
          'contentId': 'game_innovation_lab',
          'contentType': 'game',
          'status': 'completed',
          'xpEarned': xpEarned,
          'inventionName': _inventionName,
          'inventionCategory': _inventionCategory,
          'selectedIPType': _selectedIPType,
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
        final currentBestScore = currentScores['innovation_lab'] as int? ?? 0;
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'gameProgress': {
            'totalXP': FieldValue.increment(xpEarned),
            'gamesPlayed': FieldValue.increment(1),
            'scores': {
              'innovation_lab': 1 > currentBestScore ? 1 : currentBestScore,
            },
            'lastPlayedAt': Timestamp.now(),
          },
        }, SetOptions(merge: true));
        
        // print('✅ Game completed: XP earned: $xpEarned');
      } catch (e) {
        // print('❌ Error saving game progress: $e');
      }
    }
  }

  void _restartGame() {
    setState(() {
      _gameEnded = false;
      _gameStarted = false;
    });
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
        title: const Text('Innovation Lab'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Game icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.science,
                  size: 60,
                  color: Colors.teal,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              Text(
                'Innovation Lab',
                style: AppTextStyles.h1,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                'Design your own invention and learn how to protect it!',
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
                      'Game Steps:',
                      style: AppTextStyles.cardTitle,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildRuleItem('✏️', 'Draw your invention'),
                    _buildRuleItem('📝', 'Name and categorize it'),
                    _buildRuleItem('❓', 'Answer protection questions'),
                    _buildRuleItem('🎯', 'Match to correct IP type'),
                    _buildRuleItem('✅', 'Complete filing checklist'),
                    _buildRuleItem('⭐', 'Fixed 100 XP reward'),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Start button
              PrimaryButton(
                text: 'Start Innovation',
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
        title: Text('Step ${_currentStep + 1}/5'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: (_currentStep + 1) / 5,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
              minHeight: 6,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: _buildStepContent(),
              ),
            ),

            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                          ),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      text: _currentStep == 4 ? 'Complete' : 'Next',
                      onPressed: _canProceed() ? _nextStep : null,
                      fullWidth: true,
                      icon: _currentStep == 4 ? Icons.check : Icons.arrow_forward,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildDrawingStep();
      case 1:
        return _buildNamingStep();
      case 2:
        return _buildQuestionsStep();
      case 3:
        return _buildIPTypeStep();
      case 4:
        return _buildChecklistStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildDrawingStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        
        Text(
          'Draw Your Invention',
          style: AppTextStyles.h2,
        ),
        
        const SizedBox(height: AppSpacing.sm),
        
        Text(
          'Use the canvas below to sketch your innovative idea!',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppDesignSystem.textSecondary,
          ),
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Drawing canvas
        Container(
          height: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: Colors.grey[300]!, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            child: GestureDetector(
              onPanStart: (details) {
                setState(() {
                  _drawingPoints.add(
                    DrawingPoint(
                      offset: details.localPosition,
                      paint: Paint()
                        ..color = _selectedColor
                        ..strokeWidth = _strokeWidth
                        ..strokeCap = StrokeCap.round,
                    ),
                  );
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  _drawingPoints.add(
                    DrawingPoint(
                      offset: details.localPosition,
                      paint: Paint()
                        ..color = _selectedColor
                        ..strokeWidth = _strokeWidth
                        ..strokeCap = StrokeCap.round,
                    ),
                  );
                });
              },
              onPanEnd: (details) {
                setState(() {
                  _drawingPoints.add(DrawingPoint(offset: null, paint: Paint()));
                });
              },
              child: CustomPaint(
                painter: DrawingPainter(_drawingPoints),
                size: Size.infinite,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: AppSpacing.md),
        
        // Drawing tools
        Row(
          children: [
            // Color picker
            Expanded(
              child: Wrap(
                spacing: 8,
                children: [
                  Colors.black,
                  Colors.red,
                  Colors.blue,
                  Colors.green,
                  Colors.orange,
                  Colors.purple,
                ].map((color) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColor == color ? Colors.teal : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            // Clear button
            IconButton(
              onPressed: () {
                setState(() {
                  _drawingPoints.clear();
                });
              },
              icon: const Icon(Icons.delete),
              color: Colors.red,
              iconSize: 32,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNamingStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        
        Text(
          'Name Your Invention',
          style: AppTextStyles.h2,
        ),
        
        const SizedBox(height: AppSpacing.sm),
        
        Text(
          'Give your invention a catchy name and select its category.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppDesignSystem.textSecondary,
          ),
        ),
        
        const SizedBox(height: AppSpacing.xl),
        
        // Invention name
        TextField(
          onChanged: (value) {
            setState(() {
              _inventionName = value;
            });
          },
          decoration: InputDecoration(
            labelText: 'Invention Name',
            hintText: 'e.g., Smart Water Bottle',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            prefixIcon: const Icon(Icons.lightbulb),
          ),
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Category selection
        Text(
          'Select Category:',
          style: AppTextStyles.cardTitle,
        ),
        
        const SizedBox(height: AppSpacing.md),
        
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: _categories.map((category) {
            final isSelected = _inventionCategory == category;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _inventionCategory = category;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.teal : Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  border: Border.all(
                    color: isSelected ? Colors.teal : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: Text(
                  category,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected ? Colors.white : AppDesignSystem.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuestionsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        
        Text(
          'Protection Questions',
          style: AppTextStyles.h2,
        ),
        
        const SizedBox(height: AppSpacing.sm),
        
        Text(
          'Answer these questions to determine the best IP protection for your invention.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppDesignSystem.textSecondary,
          ),
        ),
        
        const SizedBox(height: AppSpacing.xl),
        
        _buildQuestionCard(
          question: 'Is your invention new and never seen before?',
          key: 'isNew',
        ),
        
        const SizedBox(height: AppSpacing.md),
        
        _buildQuestionCard(
          question: 'Does your invention have a practical use or utility?',
          key: 'hasUtility',
        ),
        
        const SizedBox(height: AppSpacing.md),
        
        _buildQuestionCard(
          question: 'Would your invention be obvious to someone skilled in the field?',
          key: 'isObvious',
        ),
      ],
    );
  }

  Widget _buildQuestionCard({required String question, required String key}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: Colors.grey[300]!, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          Row(
            children: [
              Expanded(
                child: _buildAnswerButton(
                  label: 'Yes',
                  value: 'yes',
                  key: key,
                  color: AppDesignSystem.success,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildAnswerButton(
                  label: 'No',
                  value: 'no',
                  key: key,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButton({
    required String label,
    required String value,
    required String key,
    required Color color,
  }) {
    final isSelected = _answers[key] == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _answers[key] = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.button.copyWith(
            color: isSelected ? color : AppDesignSystem.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildIPTypeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        
        Text(
          'Match to IP Type',
          style: AppTextStyles.h2,
        ),
        
        const SizedBox(height: AppSpacing.sm),
        
        Text(
          'Based on your invention, which type of IP protection is most suitable?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppDesignSystem.textSecondary,
          ),
        ),
        
        const SizedBox(height: AppSpacing.xl),
        
        ..._ipTypes.map((ipType) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _buildIPTypeCard(ipType),
        )),
      ],
    );
  }

  Widget _buildIPTypeCard(IPType ipType) {
    final isSelected = _selectedIPType == ipType.name;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIPType = ipType.name;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? ipType.color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: isSelected ? ipType.color : Colors.grey[300]!,
            width: isSelected ? 3 : 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: ipType.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              child: Icon(
                ipType.icon,
                color: ipType.color,
                size: 32,
              ),
            ),
            
            const SizedBox(width: AppSpacing.md),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ipType.name,
                    style: AppTextStyles.cardTitle.copyWith(
                      color: isSelected ? ipType.color : AppDesignSystem.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ipType.description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppDesignSystem.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: ipType.color,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        
        Text(
          'Filing Checklist',
          style: AppTextStyles.h2,
        ),
        
        const SizedBox(height: AppSpacing.sm),
        
        Text(
          'Complete all the steps required to file your IP application.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppDesignSystem.textSecondary,
          ),
        ),
        
        const SizedBox(height: AppSpacing.xl),
        
        ..._checklistItems.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _buildChecklistItem(entry.key, entry.value),
          );
        }),
      ],
    );
  }

  Widget _buildChecklistItem(String label, bool isChecked) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _checklistItems[label] = !isChecked;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isChecked ? AppDesignSystem.success.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: isChecked ? AppDesignSystem.success : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isChecked ? AppDesignSystem.success : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isChecked ? AppDesignSystem.success : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isChecked
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    )
                  : null,
            ),
            
            const SizedBox(width: AppSpacing.md),
            
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isChecked ? AppDesignSystem.success : AppDesignSystem.textPrimary,
                  fontWeight: isChecked ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    const xpEarned = 100;

    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('Innovation Complete!'),
        backgroundColor: Colors.teal,
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
                  color: AppDesignSystem.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events,
                  size: 60,
                  color: AppDesignSystem.success,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              Text(
                'Congratulations!',
                style: AppTextStyles.h1,
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                'You\'ve successfully designed and protected your invention!',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppDesignSystem.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Invention summary
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppDesignSystem.backgroundGrey,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Invention:',
                      style: AppTextStyles.cardTitle,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildSummaryRow('Name', _inventionName),
                    const Divider(height: 24),
                    _buildSummaryRow('Category', _inventionCategory),
                    const Divider(height: 24),
                    _buildSummaryRow('IP Type', _selectedIPType ?? 'N/A'),
                    const Divider(height: 24),
                    _buildSummaryRow('XP Earned', '+$xpEarned XP', isHighlight: true),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Buttons
              PrimaryButton(
                text: 'Create Another',
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

  Widget _buildSummaryRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppDesignSystem.textSecondary,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.h3.copyWith(
              color: isHighlight ? Colors.teal : AppDesignSystem.textPrimary,
              fontSize: 16,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

// Drawing point class for canvas
class DrawingPoint {
  final Offset? offset;
  final Paint paint;

  DrawingPoint({required this.offset, required this.paint});
}

// Custom painter for drawing canvas
class DrawingPainter extends CustomPainter {
  final List<DrawingPoint> points;

  DrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].offset != null && points[i + 1].offset != null) {
        canvas.drawLine(
          points[i].offset!,
          points[i + 1].offset!,
          points[i].paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}

// IP Type model
class IPType {
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  IPType({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}
