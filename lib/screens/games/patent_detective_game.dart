import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_tts/flutter_tts.dart';
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
  final FlutterTts _flutterTts = FlutterTts();
  
  Map<String, dynamic>? gameData;
  Map<String, dynamic>? currentCase;
  
  bool gameStarted = false;
  String currentPhase = 'story';
  int score = 0;
  int xpEarned = 0;
  
  // Timer
  Timer? _gameTimer;
  int _timeLeft = 180; // 3 minutes = 180 seconds
  int _timeSpent = 0;
  
  Set<String> readSuspects = {};
  Set<String> examinedEvidence = {};
  Map<String, String> deductionAnswers = {};
  String? selectedVerdict;
  
  bool ttsEnabled = false;
  bool isSpeaking = false;
  
  // Animation controllers
  late AnimationController _caseOpenController;
  late AnimationController _evidenceRevealController;
  
  // Scroll controllers
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _loadGameData();
    _initTts();
    _caseOpenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _evidenceRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    if (ttsEnabled && !isSpeaking) {
      setState(() => isSpeaking = true);
      await _flutterTts.speak(text);
      setState(() => isSpeaking = false);
    }
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    setState(() => isSpeaking = false);
  }

  Future<void> _loadGameData() async {
    final String jsonString = await rootBundle.loadString('content/games/patent_detective.json');
    final data = json.decode(jsonString);
    
    final cases = data['cases'] as List;
    final random = Random();
    final selectedCase = cases[random.nextInt(cases.length)];
    
    setState(() {
      gameData = data;
      currentCase = selectedCase;
    });
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
          _timeSpent++;
        });
      } else {
        _endGame();
      }
    });
  }

  void _nextPhase() {
    _stopSpeaking();
    final phases = ['story', 'investigation', 'evidence', 'deduction', 'verdict', 'solution'];
    final currentIndex = phases.indexOf(currentPhase);
    
    if (currentIndex < phases.length - 1) {
      setState(() => currentPhase = phases[currentIndex + 1]);
      
      // Scroll to top when changing phases
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      
      // Trigger animations
      if (currentPhase == 'investigation') {
        _caseOpenController.forward(from: 0);
      } else if (currentPhase == 'evidence') {
        _evidenceRevealController.forward(from: 0);
      }
    }
  }

  void _calculateScore() {
    int totalScore = 0;
    
    // Calculate deduction score
    final deductions = currentCase!['deductions'] as List;
    for (final deduction in deductions) {
      final userAnswer = deductionAnswers[deduction['question']];
      if (userAnswer == deduction['correctEvidenceId']) {
        totalScore += 25;
      }
    }
    
    // Calculate verdict score
    final verdictOptions = currentCase!['verdictOptions'] as List;
    final correctVerdict = verdictOptions.firstWhere((v) => v['isCorrect'] == true);
    if (selectedVerdict == correctVerdict['id']) {
      totalScore += 50;
    }
    
    setState(() => score = totalScore);
  }

  Future<void> _endGame() async {
    _gameTimer?.cancel();
    _calculateScore();
    
    try {
      // Use consistent game ID format (underscore, not hyphen)
      const gameId = 'patent_detective';
      
      final isFirstTime = await _gameService.isFirstCompletion(gameId);
      final isPerfect = score >= 150;
      
      // Base XP: 100-150 based on score
      int baseXP = 100 + ((score / 150) * 50).round();
      
      // Save progress first (this creates the document)
      await _gameService.saveGameProgress(
        gameId: gameId,
        score: score,
        timeSpentSeconds: _timeSpent,
        completed: true,
      );
      
      // Then award XP and check for badges
      final result = await _gameService.awardGameXP(
        gameId: gameId,
        baseXP: baseXP,
        score: score,
        isPerfectScore: isPerfect,
        isFirstCompletion: isFirstTime,
      );
      
      final earnedXP = result['xp'] as int;
      final newBadges = result['newBadges'] as List<String>;
      
      // Show badge animations if any badges were unlocked
      if (newBadges.isNotEmpty && mounted) {
        await _gameService.showBadgeAnimations(context, newBadges);
      }
      
      // Log analytics
      await _gameService.logGameComplete(
        gameId: gameId,
        score: score,
        timeSpentSeconds: _timeSpent,
        isPerfectScore: isPerfect,
      );
      
      setState(() => xpEarned = earnedXP);
      
      // Move to results screen first, then play confetti
      _nextPhase();
      
      // Play confetti after a short delay (after screen transition)
      await Future.delayed(const Duration(milliseconds: 300));
      _confettiController.play();
      await Future.delayed(const Duration(milliseconds: 800));
      _confettiController.play();
      await Future.delayed(const Duration(milliseconds: 800));
      _confettiController.play();
    } catch (e) {
      print('Error ending game: $e');
      // Still show results even if save failed
      setState(() => xpEarned = 0);
      _nextPhase();
      
      // Play confetti even if save failed
      await Future.delayed(const Duration(milliseconds: 300));
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _confettiController.dispose();
    _flutterTts.stop();
    _caseOpenController.dispose();
    _evidenceRevealController.dispose();
    _scrollController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    if (gameData == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!gameStarted) return _buildWelcomeScreen();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              // Hide header on solution/results screen
              if (currentPhase != 'solution') _buildHeader(),
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: _buildPhaseContent(),
                ),
              ),
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
      backgroundColor: Colors.white,
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
                    Text('Game Rules:', style: AppTextStyles.cardTitle),
                    const SizedBox(height: 12),
                    _buildRuleItem('⏱️', '3 minutes to solve the case'),
                    _buildRuleItem('📖', 'Read the case story'),
                    _buildRuleItem('🕵️', 'Interview 3 suspects'),
                    _buildRuleItem('🔍', 'Examine 6 pieces of evidence'),
                    _buildRuleItem('🧩', 'Answer 4 deduction questions'),
                    _buildRuleItem('⚖️', 'Choose the correct verdict'),
                    _buildRuleItem('⭐', '100-250 XP based on performance'),
                  ],
                ),
              ),
              PrimaryButton(
                text: 'Start Investigation',
                onPressed: () {
                  setState(() => gameStarted = true);
                  _startTimer();
                },
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
    final phases = ['story', 'investigation', 'evidence', 'deduction', 'verdict', 'solution'];
    final currentIndex = phases.indexOf(currentPhase);
    
    // Format time as MM:SS
    final minutes = _timeLeft ~/ 60;
    final seconds = _timeLeft % 60;
    final timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    
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
                  _buildStatChip(Icons.timer, timeString, _timeLeft < 30 ? Colors.red : const Color(0xFF4CAF50)),
                  const SizedBox(width: 8),
                  _buildStatChip(Icons.stars, '$score pts', const Color(0xFFFFA726)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: List.generate(6, (index) {
                  final isCompleted = index < currentIndex;
                  final isCurrent = index == currentIndex;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: index < 5 ? 4 : 0),
                      decoration: BoxDecoration(
                        color: isCompleted ? Colors.white : isCurrent ? Colors.white70 : Colors.white30,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
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
      case 'story': return _buildStoryPhase();
      case 'investigation': return _buildInvestigationPhase();
      case 'evidence': return _buildEvidencePhase();
      case 'deduction': return _buildDeductionPhase();
      case 'verdict': return _buildVerdictPhase();
      case 'solution': return _buildSolutionPhase();
      default: return const Center(child: Text('Unknown phase'));
    }
  }


  Widget _buildStoryPhase() {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: _caseOpenController, curve: Curves.easeOut),
            ),
            child: Container(
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
                        decoration: BoxDecoration(color: const Color(0xFF8B5CF6), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.folder_open, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text('CASE FILE OPENED', style: AppTextStyles.h2.copyWith(color: const Color(0xFF8B5CF6), fontWeight: FontWeight.bold))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(currentCase!['story'], style: AppTextStyles.bodyLarge.copyWith(height: 1.6)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() => ttsEnabled = !ttsEnabled);
                    if (ttsEnabled) {
                      _speak(currentCase!['story']);
                    } else {
                      _stopSpeaking();
                    }
                  },
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
              onPressed: () {
                _caseOpenController.forward(from: 0);
                _nextPhase();
              },
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
        ),
    );
  }


  Widget _buildInvestigationPhase() {
    final suspects = currentCase!['suspects'] as List;
    
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Interview Suspects', style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Read each suspect\'s statement carefully', style: AppTextStyles.bodyMedium.copyWith(color: AppDesignSystem.textSecondary)),
          const SizedBox(height: 20),
          ...suspects.asMap().entries.map((entry) {
            final index = entry.key;
            return AnimatedBuilder(
              animation: _caseOpenController,
              builder: (context, child) {
                final delay = index * 0.2;
                final animValue = (_caseOpenController.value - delay).clamp(0.0, 1.0);
                return Transform.translate(
                  offset: Offset(0, 50 * (1 - animValue)),
                  child: Opacity(
                    opacity: animValue,
                    child: child,
                  ),
                );
              },
              child: _buildSuspectCard(entry.value),
            );
          }).toList(),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _evidenceRevealController.forward(from: 0);
                _nextPhase();
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Examine Evidence', style: TextStyle(fontSize: 18)),
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
        ),
    );
  }

  Widget _buildSuspectCard(Map<String, dynamic> suspect) {
    final isRead = readSuspects.contains(suspect['id']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isRead ? const Color(0xFF8B5CF6) : Colors.grey.shade300, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: ExpansionTile(
            key: PageStorageKey<String>(suspect['id']),
            initiallyExpanded: false,
            backgroundColor: Colors.white,
            collapsedBackgroundColor: Colors.white,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            childrenPadding: EdgeInsets.zero,
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Center(child: Text(suspect['avatar'], style: const TextStyle(fontSize: 28))),
          ),
          title: Text(suspect['name'], style: AppTextStyles.cardTitle),
          subtitle: Text(suspect['role'], style: AppTextStyles.bodySmall.copyWith(color: AppDesignSystem.textSecondary)),
          trailing: isRead ? const Icon(Icons.check_circle, color: Color(0xFF8B5CF6)) : const Icon(Icons.expand_more),
          onExpansionChanged: (expanded) {
            if (expanded && !isRead) {
              setState(() => readSuspects.add(suspect['id']));
            }
          },
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(suspect['statement'], style: AppTextStyles.bodyMedium.copyWith(height: 1.5)),
                  ),
                  const SizedBox(height: 12),
                  Text('Key Claims:', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...(suspect['keyClaims'] as List).map((claim) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Expanded(child: Text(claim, style: AppTextStyles.bodySmall)),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
        ),
    );
  }


  Widget _buildEvidencePhase() {
    final evidence = currentCase!['evidence'] as List;
    
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Examine Evidence', style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Review all evidence carefully', style: AppTextStyles.bodyMedium.copyWith(color: AppDesignSystem.textSecondary)),
          const SizedBox(height: 20),
          ...evidence.asMap().entries.map((entry) {
            final index = entry.key;
            return AnimatedBuilder(
              animation: _evidenceRevealController,
              builder: (context, child) {
                final delay = index * 0.15;
                final animValue = (_evidenceRevealController.value - delay).clamp(0.0, 1.0);
                return Transform.scale(
                  scale: 0.8 + (0.2 * animValue),
                  child: Opacity(
                    opacity: animValue,
                    child: child,
                  ),
                );
              },
              child: _buildEvidenceCard(entry.value),
            );
          }).toList(),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _nextPhase,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Make Deductions', style: TextStyle(fontSize: 18)),
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
        ),
    );
  }

  Widget _buildEvidenceCard(Map<String, dynamic> item) {
    final isExamined = examinedEvidence.contains(item['id']);
    final importance = item['importance'] as String;
    Color importanceColor = importance == 'critical' ? Colors.red : importance == 'high' ? Colors.orange : Colors.blue;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isExamined ? const Color(0xFF8B5CF6) : Colors.grey.shade300, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: ExpansionTile(
            key: PageStorageKey<String>(item['id']),
            initiallyExpanded: false,
            backgroundColor: Colors.white,
            collapsedBackgroundColor: Colors.white,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            childrenPadding: EdgeInsets.zero,
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: importanceColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Text(item['icon'], style: const TextStyle(fontSize: 28))),
          ),
          title: Text(item['name'], style: AppTextStyles.cardTitle),
          subtitle: Text(item['description'], style: AppTextStyles.bodySmall.copyWith(color: AppDesignSystem.textSecondary)),
          trailing: isExamined ? const Icon(Icons.check_circle, color: Color(0xFF8B5CF6)) : const Icon(Icons.expand_more),
          onExpansionChanged: (expanded) {
            if (expanded && !isExamined) {
              setState(() => examinedEvidence.add(item['id']));
            }
          },
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: importanceColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.priority_high, size: 16, color: importanceColor),
                        const SizedBox(width: 4),
                        Text('${importance.toUpperCase()} IMPORTANCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: importanceColor)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(item['content'], style: AppTextStyles.bodyMedium.copyWith(height: 1.5)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
        ),
    );
  }


  Widget _buildDeductionPhase() {
    final deductions = currentCase!['deductions'] as List;
    final evidence = currentCase!['evidence'] as List;
    
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Make Your Deductions', style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Answer each question using the evidence', style: AppTextStyles.bodyMedium.copyWith(color: AppDesignSystem.textSecondary)),
          const SizedBox(height: 20),
          ...deductions.asMap().entries.map((entry) {
            final index = entry.key;
            final deduction = entry.value;
            final isAnswered = deductionAnswers.containsKey(deduction['question']);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isAnswered ? const Color(0xFF8B5CF6) : Colors.grey.shade300, width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(deduction['question'], style: AppTextStyles.cardTitle)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...evidence.map((item) {
                    final isSelected = deductionAnswers[deduction['question']] == item['id'];
                    final isLocked = deductionAnswers.containsKey(deduction['question']);
                    final isCorrect = isLocked && item['id'] == deduction['correctEvidenceId'];
                    final isWrong = isLocked && isSelected && item['id'] != deduction['correctEvidenceId'];
                    
                    Color borderColor = Colors.grey.shade300;
                    Color bgColor = Colors.white;
                    Widget? trailingIcon;
                    
                    if (isCorrect) {
                      borderColor = Colors.green;
                      bgColor = Colors.green.withValues(alpha: 0.1);
                      trailingIcon = const Icon(Icons.check_circle, color: Colors.green, size: 28);
                    } else if (isWrong) {
                      borderColor = Colors.red;
                      bgColor = Colors.red.withValues(alpha: 0.1);
                      trailingIcon = const Icon(Icons.cancel, color: Colors.red, size: 28);
                    } else if (isSelected) {
                      borderColor = const Color(0xFF8B5CF6);
                      bgColor = const Color(0xFF8B5CF6).withValues(alpha: 0.1);
                      trailingIcon = const Icon(Icons.check_circle, color: Color(0xFF8B5CF6));
                    }
                    
                    return GestureDetector(
                      onTap: isLocked ? null : () {
                        setState(() {
                          deductionAnswers[deduction['question']] = item['id'];
                          // Update score instantly
                          if (item['id'] == deduction['correctEvidenceId']) {
                            score += 25;
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor, width: 2),
                        ),
                        child: Row(
                          children: [
                            Text(item['icon'], style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 12),
                            Expanded(child: Text(item['name'], style: AppTextStyles.bodyMedium)),
                            if (trailingIcon != null) trailingIcon,
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _nextPhase,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Choose Verdict', style: TextStyle(fontSize: 18)),
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
        ),
    );
  }


  Widget _buildVerdictPhase() {
    final verdictOptions = currentCase!['verdictOptions'] as List;
    
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text('Final Verdict', style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Choose the correct verdict based on your investigation', style: AppTextStyles.bodyMedium.copyWith(color: AppDesignSystem.textSecondary)),
          const SizedBox(height: 20),
          ...verdictOptions.map((option) {
            final isSelected = selectedVerdict == option['id'];
            return GestureDetector(
              onTap: () => setState(() => selectedVerdict = option['id']),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF8B5CF6).withValues(alpha: 0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey.shade300, width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey, width: 2),
                        color: isSelected ? const Color(0xFF8B5CF6) : Colors.transparent,
                      ),
                      child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(option['text'], style: AppTextStyles.bodyMedium)),
                  ],
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _endGame,
              icon: const Icon(Icons.gavel),
              label: const Text('Submit Verdict', style: TextStyle(fontSize: 18)),
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
        ),
    );
  }


  Widget _buildSolutionPhase() {
    final solution = currentCase!['solution'];
    final percentage = (score / 150 * 100).round();
    final passed = percentage >= 60;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
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
              const SizedBox(height: 20),
              Text(
                passed ? 'Case Solved!' : 'Keep Investigating!',
                style: AppTextStyles.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You scored $score out of 150 points',
                style: AppTextStyles.bodyLarge.copyWith(color: AppDesignSystem.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppDesignSystem.backgroundGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildStatRow('Score', '$score/150'),
                    const Divider(height: 24),
                    _buildStatRow('Accuracy', '$percentage%'),
                    const Divider(height: 24),
                    _buildStatRow('Time Spent', '${_timeSpent ~/ 60}:${(_timeSpent % 60).toString().padLeft(2, '0')}'),
                    const Divider(height: 24),
                    _buildStatRow('XP Earned', '+$xpEarned XP', isHighlight: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.gavel, color: Color(0xFF8B5CF6)),
                        const SizedBox(width: 8),
                        Text('Verdict', style: AppTextStyles.cardTitle.copyWith(color: const Color(0xFF8B5CF6))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(solution['verdict'], style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(solution['explanation'], style: AppTextStyles.bodyMedium.copyWith(height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.account_balance, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text('Legal Outcome', style: AppTextStyles.cardTitle.copyWith(color: Colors.blue.shade900)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...(solution['legalOutcome'] as List).map((outcome) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Expanded(child: Text(outcome, style: AppTextStyles.bodyMedium)),
                        ],
                      ),
                    )).toList(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Text('IP Lesson', style: AppTextStyles.cardTitle.copyWith(color: Colors.green.shade900)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(solution['ipLesson'], style: AppTextStyles.bodyMedium.copyWith(height: 1.5)),
                  ],
                ),
              ),
                  ],
                ),
              ),
            ),
            // Fixed buttons at bottom
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryButton(
                    text: 'Investigate Again',
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatentDetectiveGame()));
                    },
                    fullWidth: true,
                    icon: Icons.refresh,
                    color: const Color(0xFF8B5CF6),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Color(0xFF8B5CF6)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: Text('Back to Games', style: AppTextStyles.button.copyWith(color: const Color(0xFF8B5CF6)), textAlign: TextAlign.center),
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

  Widget _buildStatRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppDesignSystem.textSecondary)),
        Text(value, style: AppTextStyles.h3.copyWith(color: isHighlight ? const Color(0xFF8B5CF6) : AppDesignSystem.textPrimary)),
      ],
    );
  }
}
