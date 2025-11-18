import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../services/game_integration_service.dart';
import '../../widgets/primary_button.dart';

class PatentDetectiveGame extends StatefulWidget {
  const PatentDetectiveGame({super.key});

  @override
  State<PatentDetectiveGame> createState() => _PatentDetectiveGameState();
}

class _PatentDetectiveGameState extends State<PatentDetectiveGame> with TickerProviderStateMixin {
  final GameIntegrationService _gameService = GameIntegrationService();
  final ConfettiController _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  
  Map<String, dynamic>? gameData;
  Map<String, dynamic>? currentCase;
  
  // Game state
  bool gameStarted = false;
  String currentPhase = 'story';
  int score = 0;
  
  // Phase tracking
  Set<String> readSuspects = {};
  Set<String> examinedEvidence = {};
  Map<String, String> deductionAnswers = {};
  String? selectedVerdict;
  
  // TTS state
  bool ttsEnabled = false;
  
  @override
  void initState() {
    super.initState();
    _loadGameData();
  }

  Future<void> _loadGameData() async {
    final String jsonString = await rootBundle.loadString('content/games/patent_detective.json');
    final data = json.decode(jsonString);
    
    // Randomly select 1 case
    final cases = data['cases'] as List;
    final random = Random();
    final selectedCase = cases[random.nextInt(cases.length)];
    
    setState(() {
      gameData = data;
      currentCase = selectedCase;
    });
  }

  void _nextPhase() {
    final phases = ['story', 'investigation', 'evidence', 'deduction', 'verdict', 'solution'];
    final currentIndex = phases.indexOf(currentPhase);
    
    if (currentIndex < phases.length - 1) {
      setState(() {
        currentPhase = phases[currentIndex + 1];
      });
    }
  }

  void _calculateScore() {
    int totalScore = 0;
    
    // Deduction questions: 25 points each (4 questions = 100 points max)
    totalScore += deductionAnswers.length * 25;
    
    // Correct verdict: 50 points
    final verdictOptions = currentCase!['verdictOptions'] as List;
    final correctVerdict = verdictOptions.firstWhere((v) => v['isCorrect'] == true);
    if (selectedVerdict == correctVerdict['id']) {
      totalScore += 50;
    }
    
    setState(() {
      score = totalScore;
    });
  }

  Future<void> _endGame() async {
    _calculateScore();
    
    final isFirstTime = await _gameService.isFirstCompletion('patent_detective');
    final isPerfect = score >= 150;
    
    // Base XP: 100-150 based on score
    // Score range: 0-150, map to 100-150 XP
    int baseXP = 100 + ((score / 150) * 50).round();
    
    final xpEarned = await _gameService.awardGameXP(
      gameId: 'patent_detective',
      baseXP: baseXP,
      score: score,
      isPerfectScore: isPerfect,
      isFirstCompletion: isFirstTime,
    );
    
    await _gameService.saveGameProgress(
      gameId: 'patent_detective',
      score: score,
      timeSpentSeconds: 0,
      completed: true,
    );
    
    _confettiController.play();
    _nextPhase();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (gameData == null) {
      return Scaffold(
        backgroundColor: AppDesignSystem.backgroundLight,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!gameStarted) {
      return _buildWelcomeScreen();
    }

    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildPhaseContent()),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('Patent Detective', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Image.asset(
                      'assets/logos/patent_detective.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.search, size: 60, color: Color(0xFF8B5CF6));
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Patent Detective', style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text('Solve IP crime cases like a real detective!', style: AppTextStyles.bodyMedium.copyWith(color: AppDesignSystem.textSecondary), textAlign: TextAlign.center),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppDesignSystem.backgroundGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('How to Play:', style: AppTextStyles.cardTitle),
                    const SizedBox(height: 12),
                    _buildRuleItem('📖', 'Read the case story'),
                    _buildRuleItem('🕵️', 'Interview 3 suspects'),
                    _buildRuleItem('🔍', 'Examine 6 pieces of evidence'),
                    _buildRuleItem('🧩', 'Answer 4 deduction questions'),
                    _buildRuleItem('⚖️', 'Choose the correct verdict'),
                    _buildRuleItem('⭐', 'Earn 100-250 XP based on performance'),
                  ],
                ),
              ),
              PrimaryButton(
                text: 'Start Investigation',
                onPressed: () => setState(() => gameStarted = true),
                fullWidth: true,
                icon: Icons.play_arrow,
                color: const Color(0xFF8B5CF6),
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

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)]),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(currentCase!['caseNumber'], style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(currentCase!['title'], style: AppTextStyles.h3.copyWith(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatChip(Icons.stars, '$score pts', const Color(0xFFFFA726)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPhaseContent() {
    switch (currentPhase) {
      case 'story':
        return _buildStoryPhase();
      case 'investigation':
        return _buildInvestigationPhase();
      case 'evidence':
        return _buildEvidencePhase();
      case 'deduction':
        return _buildDeductionPhase();
      case 'verdict':
        return _buildVerdictPhase();
      case 'solution':
        return _buildSolutionPhase();
      default:
        return const Center(child: Text('Unknown phase'));
    }
  }

  Widget _buildStoryPhase() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF8B5CF6).withValues(alpha: 0.1), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.menu_book, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('THE CASE', style: AppTextStyles.h2.copyWith(color: const Color(0xFF8B5CF6), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(currentCase!['story'], style: AppTextStyles.bodyLarge.copyWith(height: 1.6)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => ttsEnabled = !ttsEnabled),
                  icon: Icon(ttsEnabled ? Icons.volume_up : Icons.volume_off),
                  label: Text(ttsEnabled ? 'TTS On' : 'TTS Off'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(12),
                    side: const BorderSide(color: Color(0xFF8B5CF6)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _nextPhase,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Begin Investigation', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(18),
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
