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

class InnovationLabGame extends StatefulWidget {
  const InnovationLabGame({super.key});

  @override
  State<InnovationLabGame> createState() => _InnovationLabGameState();
}

class _InnovationLabGameState extends State<InnovationLabGame> with TickerProviderStateMixin {
  final GameIntegrationService _gameService = GameIntegrationService();
  final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 3),
  );
  
  Map<String, dynamic>? gameData;
  Map<String, dynamic>? currentChallenge;
  
  // Game state
  bool gameStarted = false;
  String currentPhase = 'brief';
  int phaseIndex = 0;
  int score = 0;
  int timeRemaining = 30; // Start with brief phase time
  Timer? gameTimer;
  
  // Phase time limits (in seconds)
  final Map<String, int> phaseTimeLimits = {
    'brief': 30,
    'creation': 180,
    'prior_art': 60,
    'ip_strategy': 60,
    'filing': 60,
  };
  
  // Drawing state
  List<DrawingStroke> strokes = [];
  DrawingStroke? currentStroke;
  String selectedTool = 'pencil';
  Color selectedColor = Colors.black;
  double strokeWidth = 2.0;
  bool isToolbarExpanded = false;
  bool fillShape = false;
  
  // Shape drawing state
  Offset? shapeStartPoint;
  Offset? shapeEndPoint;
  
  // Phase-specific state
  Map<String, List<String>> ipSelections = {};
  Map<String, String> filingAnswers = {};
  List<bool> priorArtAnswers = [];
  
  // Track what has been scored to prevent duplicate scoring
  Set<String> scoredIPSelections = {};
  Set<String> scoredFilingAnswers = {};
  
  // Preset color palette (20 colors)
  final List<Color> colorPalette = [
    Colors.black,
    const Color(0xFF424242), // Dark grey
    const Color(0xFF9E9E9E), // Grey
    Colors.white,
    const Color(0xFFF44336), // Red
    const Color(0xFFE91E63), // Pink
    const Color(0xFF9C27B0), // Purple
    const Color(0xFF673AB7), // Deep Purple
    const Color(0xFF3F51B5), // Indigo
    const Color(0xFF2196F3), // Blue
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFF009688), // Teal
    const Color(0xFF4CAF50), // Green
    const Color(0xFF8BC34A), // Light Green
    const Color(0xFFCDDC39), // Lime
    const Color(0xFFFFEB3B), // Yellow
    const Color(0xFFFFC107), // Amber
    const Color(0xFFFF9800), // Orange
    const Color(0xFFFF5722), // Deep Orange
    const Color(0xFF795548), // Brown
  ];
  

  
  @override
  void initState() {
    super.initState();
    _loadGameData();
  }

  Future<void> _loadGameData() async {
    final String jsonString = await rootBundle.loadString('content/games/innovation_lab.json');
    final data = json.decode(jsonString);
    
    // Randomly select 1 challenge from all available challenges
    final challenges = data['challenges'] as List;
    final random = Random();
    final selectedChallenge = challenges[random.nextInt(challenges.length)];
    
    setState(() {
      gameData = data;
      currentChallenge = selectedChallenge;
      timeRemaining = phaseTimeLimits['brief']!;
    });
  }

  void _startTimer() {
    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeRemaining > 0) {
        setState(() => timeRemaining--);
      } else {
        // Time's up for this phase - auto advance or end game
        _handlePhaseTimeout();
      }
    });
  }
  
  void _handlePhaseTimeout() {
    gameTimer?.cancel();
    
    // Show timeout message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Time\'s up for ${_getPhaseDisplayName(currentPhase)}!'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
    
    // Auto-advance to next phase or end game
    final phases = ['brief', 'creation', 'prior_art', 'ip_strategy', 'filing'];
    if (phaseIndex < phases.length - 1) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _nextPhase();
        }
      });
    } else {
      _endGame();
    }
  }
  
  String _getPhaseDisplayName(String phase) {
    switch (phase) {
      case 'brief': return 'The Brief';
      case 'creation': return 'Creation Studio';
      case 'prior_art': return 'Prior Art Challenge';
      case 'ip_strategy': return 'IP Strategy';
      case 'filing': return 'IP Filing';
      default: return phase;
    }
  }



  void _nextPhase() {
    final phases = ['brief', 'creation', 'prior_art', 'ip_strategy', 'filing'];
    
    // Stop current phase timer
    gameTimer?.cancel();
    
    if (phaseIndex < phases.length - 1) {
      setState(() {
        phaseIndex++;
        currentPhase = phases[phaseIndex];
        // Reset timer for new phase
        timeRemaining = phaseTimeLimits[currentPhase]!;
      });
      
      // Start timer for new phase
      _startTimer();
    } else {
      _endGame();
    }
  }

  Future<void> _endGame() async {
    gameTimer?.cancel();
    _calculateFinalScore();
    
    // Check if first completion
    final isFirstTime = await _gameService.isFirstCompletion('innovation_lab');
    final isPerfect = score >= 900;
    
    // Save game progress
    await _gameService.saveGameProgress(
      gameId: 'innovation_lab',
      score: score,
      timeSpentSeconds: 360 - timeRemaining,
      completed: true,
    );
    
    // Award XP
    await _gameService.awardGameXP(
      gameId: 'innovation_lab',
      baseXP: 100,
      score: score,
      isPerfectScore: isPerfect,
      isFirstCompletion: isFirstTime,
    );
    
    // Log analytics
    await _gameService.logGameComplete(
      gameId: 'innovation_lab',
      score: score,
      timeSpentSeconds: 360 - timeRemaining,
      isPerfectScore: isPerfect,
    );
    
    _confettiController.play();
    _showResultsScreen();
  }

  void _calculateFinalScore() {
    // Drawing phase scoring (30%)
    int drawingScore = 0;
    drawingScore += (strokes.length * 3).clamp(0, 300); // Tool variety & complexity
    
    // IP Knowledge scoring (70%)
    int ipScore = 0;
    ipScore += (priorArtAnswers.where((a) => a).length * 50); // Prior art analysis
    ipScore += (ipSelections.values.expand((e) => e).length * 50); // IP type selection
    ipScore += (filingAnswers.length * 40); // Filing answers
    
    // Bonus multipliers
    double multiplier = 1.0;
    if (timeRemaining > 60) multiplier += 0.1; // Speed bonus
    if (strokes.length >= 10) multiplier += 0.1; // Creativity bonus
    
    score = ((drawingScore * 0.3 + ipScore * 0.7) * multiplier).round().clamp(0, 1000);
  }

  void _showResultsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ResultsScreen(
          score: score,
          challengeTitle: currentChallenge!['title'],
          strokesUsed: strokes.length,
          priorArtAnalyzed: priorArtAnswers.length,
          ipProtections: ipSelections.values.expand((e) => e).length,
          questionsAnswered: filingAnswers.length,
          onPlayAgain: () {
            Navigator.pop(context);
            _resetGame();
          },
          onExit: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF00ACC1)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPerformanceColor() {
    if (score >= 800) return Colors.green;
    if (score >= 600) return Colors.blue;
    if (score >= 400) return Colors.orange;
    return Colors.red;
  }

  IconData _getPerformanceIcon() {
    if (score >= 800) return Icons.emoji_events;
    if (score >= 600) return Icons.thumb_up;
    if (score >= 400) return Icons.trending_up;
    return Icons.refresh;
  }

  String _getPerformanceMessage() {
    if (score >= 800) return 'Outstanding! You\'re an IP expert!';
    if (score >= 600) return 'Great job! You understand IP protection well!';
    if (score >= 400) return 'Good effort! Keep learning about IP!';
    return 'Keep practicing! Try again to improve!';
  }

  void _resetGame() {
    setState(() {
      phaseIndex = 0;
      currentPhase = 'brief';
      score = 0;
      strokes.clear();
      ipSelections.clear();
      filingAnswers.clear();
      priorArtAnswers.clear();
      scoredIPSelections.clear();
      scoredFilingAnswers.clear();
      timeRemaining = phaseTimeLimits['brief']!;
    });
    _startTimer();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
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
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF00ACC1), const Color(0xFF26C6DA)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00ACC1).withValues(alpha: 0.3),
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
                                  Text(
                                    currentChallenge!['title'],
                                    style: AppTextStyles.h3.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Phase ${phaseIndex + 1}/5: ${_getPhaseDisplayName(currentPhase)}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatChip(
                              Icons.timer, 
                              '${timeRemaining ~/ 60}:${(timeRemaining % 60).toString().padLeft(2, '0')}', 
                              timeRemaining <= 10 ? Colors.red : const Color(0xFF0277BD),
                            ),
                            _buildStatChip(Icons.stars, '$score', const Color(0xFFFFA726)),
                            _buildStatChip(Icons.brush, '${strokes.length}', const Color(0xFF00838F)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Phase progress bar
                        Row(
                          children: List.generate(5, (index) {
                            final isCompleted = index < phaseIndex;
                            final isCurrent = index == phaseIndex;
                            return Expanded(
                              child: Container(
                                height: 4,
                                margin: EdgeInsets.only(right: index < 4 ? 4 : 0),
                                decoration: BoxDecoration(
                                  color: isCompleted 
                                    ? Colors.white 
                                    : isCurrent 
                                      ? Colors.white70 
                                      : Colors.white30,
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
              ),
              Expanded(child: _buildPhaseContent()),
            ],
          ),
          // Confetti
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

  Widget _buildStatChip(IconData icon, String text, Color color) {
    final isTimerLow = icon == Icons.timer && timeRemaining <= 10;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isTimerLow ? 0.6 : 0.3),
            blurRadius: isTimerLow ? 12 : 8,
            offset: const Offset(0, 2),
            spreadRadius: isTimerLow ? 2 : 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isTimerLow ? 16 : 14,
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
        title: const Text('Innovation Lab', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF00ACC1),
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
                  // Game logo
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00ACC1).withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Image.asset(
                      'assets/logos/innovation_lab.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.lightbulb,
                          size: 60,
                          color: Color(0xFF00ACC1),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Innovation Lab',
                    style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Design products and learn IP protection!',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppDesignSystem.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              // Game rules
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppDesignSystem.backgroundGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Game Rules:',
                      style: AppTextStyles.cardTitle,
                    ),
                    const SizedBox(height: 12),
                    _buildRuleItem('🎨', 'Use drawing tools to create designs'),
                    _buildRuleItem('🔍', 'Compare with prior art'),
                    _buildRuleItem('🛡️', 'Choose IP protection types'),
                    _buildRuleItem('⏱️', '6 minutes total (5 phases)'),
                    _buildRuleItem('⭐', 'Up to 1000 XP based on performance'),
                  ],
                ),
              ),

              // Start button
              PrimaryButton(
                text: 'Start Creating',
                onPressed: () {
                  setState(() => gameStarted = true);
                  _startTimer(); // Start timer when game begins
                },
                fullWidth: true,
                icon: Icons.play_arrow,
                color: const Color(0xFF00ACC1),
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

  Widget _buildPhaseContent() {
    switch (currentPhase) {
      case 'brief':
        return _buildBriefPhase();
      case 'creation':
        return _buildCreationPhase();
      case 'prior_art':
        return _buildPriorArtPhase();
      case 'ip_strategy':
        return _buildIPStrategyPhase();
      case 'filing':
        return _buildFilingPhase();
      default:
        return const Center(child: Text('Unknown phase'));
    }
  }

  Widget _buildBriefPhase() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF00ACC1).withValues(alpha: 0.1), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00ACC1).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00ACC1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.lightbulb, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'THE BRIEF',
                        style: AppTextStyles.h2.copyWith(
                          color: const Color(0xFF00838F),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  currentChallenge!['brief'],
                  style: AppTextStyles.bodyLarge.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Market Context',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  currentChallenge!['marketContext'],
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _nextPhase,
              icon: const Icon(Icons.brush),
              label: const Text('Start Creating', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(18),
                backgroundColor: const Color(0xFF00ACC1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreationPhase() {
    return Stack(
      children: [
        // Main canvas area
        Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: CustomPaint(
                      painter: DrawingPainter(
                        strokes: strokes,
                        currentStroke: currentStroke,
                        shapeStart: shapeStartPoint,
                        shapeEnd: shapeEndPoint,
                        shapeTool: selectedTool,
                        shapeColor: selectedColor,
                        shapeStrokeWidth: strokeWidth,
                        fillShape: fillShape,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
            ),
            // Bottom action bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Strokes: ${strokes.length}',
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: strokes.isEmpty ? null : _nextPhase,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Continue'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00ACC1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        // Floating toolbar button - overlaying canvas
        Positioned(
          right: 24,
          top: 24,
          child: FloatingActionButton(
            onPressed: _showToolsModal,
            backgroundColor: const Color(0xFF00ACC1),
            elevation: 8,
            child: const Icon(Icons.palette, color: Colors.white),
          ),
        ),
      ],
    );
  }
  
  void _showToolsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Drawing Tools',
                      style: AppTextStyles.h2.copyWith(
                        color: const Color(0xFF00ACC1),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Tools content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tools
                      _buildSectionLabel('Tools'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildModalToolButton('pencil', Icons.edit, 'Pencil')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildModalToolButton('brush', Icons.brush, 'Brush')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildModalToolButton('eraser', Icons.auto_fix_high, 'Eraser')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildModalToolButton('fill', Icons.format_color_fill, 'Fill')),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      _buildSectionLabel('Shapes'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildModalToolButton('line', Icons.remove, 'Line')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildModalToolButton('rectangle', Icons.crop_square, 'Rectangle')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildModalToolButton('circle', Icons.circle_outlined, 'Circle')),
                          const Expanded(child: SizedBox()),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      _buildSectionLabel('Brush Size: ${strokeWidth.round()}'),
                      Slider(
                        value: strokeWidth,
                        min: 1,
                        max: 30,
                        divisions: 29,
                        activeColor: const Color(0xFF00ACC1),
                        onChanged: (value) {
                          setState(() => strokeWidth = value);
                          setModalState(() {});
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      _buildSectionLabel('Colors'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: colorPalette.map((color) => InkWell(
                          onTap: () {
                            setState(() => selectedColor = color);
                            setModalState(() {});
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selectedColor == color ? const Color(0xFF00ACC1) : Colors.grey.shade300,
                                width: selectedColor == color ? 3 : 1,
                              ),
                              boxShadow: selectedColor == color ? [
                                BoxShadow(
                                  color: const Color(0xFF00ACC1).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ] : null,
                            ),
                          ),
                        )).toList(),
                      ),
                      
                      const SizedBox(height: 24),
                      _buildSectionLabel('Actions'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: strokes.isEmpty ? null : () {
                                setState(() {
                                  strokes.removeLast();
                                  // Only decrease if we haven't hit the cap yet
                                  if (strokes.length < 100) {
                                    score = (score - 3).clamp(0, 1000);
                                  }
                                });
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.undo),
                              label: const Text('Undo'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: strokes.isEmpty ? null : () {
                                setState(() => strokes.clear());
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Clear'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  IconData _getToolIcon(String tool) {
    switch (tool) {
      case 'pencil': return Icons.edit;
      case 'brush': return Icons.brush;
      case 'eraser': return Icons.auto_fix_high;
      case 'fill': return Icons.format_color_fill;
      case 'line': return Icons.remove;
      case 'rectangle': return Icons.crop_square;
      case 'circle': return Icons.circle_outlined;
      default: return Icons.edit;
    }
  }
  
  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
    );
  }
  
  Widget _buildModalToolButton(String tool, IconData icon, String label) {
    final isSelected = selectedTool == tool;
    return InkWell(
      onTap: () {
        setState(() => selectedTool = tool);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00ACC1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF00ACC1) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade700,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildColorButton(Color color) {
    final isSelected = selectedColor == color;
    return InkWell(
      onTap: () => setState(() => selectedColor = color),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF00ACC1) : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF00ACC1).withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ] : null,
        ),
      ),
    );
  }





  void _onPanStart(DragStartDetails details) {
    if (selectedTool == 'fill') {
      // Fill bucket - instant fill on tap
      setState(() {
        strokes.add(DrawingStroke(
          tool: 'fill',
          color: selectedColor,
          strokeWidth: strokeWidth,
          points: [details.localPosition],
          filled: true,
        ));
        // Cap drawing score at 300 (100 strokes max)
        if (strokes.length <= 100) {
          score += 3;
        }
      });
    } else if (selectedTool == 'rectangle' || selectedTool == 'circle' || selectedTool == 'line') {
      // Shape tools - store start point
      setState(() {
        shapeStartPoint = details.localPosition;
        shapeEndPoint = details.localPosition;
      });
    } else {
      // Freehand tools
      setState(() {
        currentStroke = DrawingStroke(
          tool: selectedTool,
          color: selectedColor,
          strokeWidth: strokeWidth,
          points: [details.localPosition],
        );
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (selectedTool == 'fill') {
      // Fill bucket doesn't need update
      return;
    } else if (selectedTool == 'rectangle' || selectedTool == 'circle' || selectedTool == 'line') {
      // Update shape end point
      setState(() {
        shapeEndPoint = details.localPosition;
      });
    } else {
      // Add point to freehand stroke
      setState(() {
        currentStroke?.points.add(details.localPosition);
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (selectedTool == 'fill') {
      // Fill bucket already added stroke in onPanStart
      return;
    } else if (selectedTool == 'rectangle' || selectedTool == 'circle' || selectedTool == 'line') {
      // Finalize shape
      if (shapeStartPoint != null && shapeEndPoint != null) {
        setState(() {
          strokes.add(DrawingStroke(
            tool: selectedTool,
            color: selectedColor,
            strokeWidth: strokeWidth,
            points: [shapeStartPoint!, shapeEndPoint!],
            filled: fillShape,
          ));
          shapeStartPoint = null;
          shapeEndPoint = null;
          // Cap drawing score at 300 (100 strokes max)
          if (strokes.length <= 100) {
            score += 3;
          }
        });
      }
    } else {
      // Finalize freehand stroke
      if (currentStroke != null) {
        setState(() {
          strokes.add(currentStroke!);
          currentStroke = null;
          // Cap drawing score at 300 (100 strokes max)
          if (strokes.length <= 100) {
            score += 3;
          }
        });
      }
    }
  }

  Widget _buildPriorArtPhase() {
    final priorArt = currentChallenge!['priorArtDescriptions'] as List;
    final priorArtImages = currentChallenge!['priorArtImages'] as List;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade50, Colors.white],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.search, color: Colors.orange.shade700, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'PRIOR ART CHALLENGE',
                      style: AppTextStyles.h3.copyWith(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Compare your design with existing products',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: priorArt.length,
            itemBuilder: (context, index) {
              final answered = priorArtAnswers.length > index;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: answered ? Colors.green.shade300 : Colors.grey.shade300,
                    width: answered ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppDesignSystem.primaryIndigo,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              priorArt[index],
                              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Prior art image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.asset(
                            priorArtImages[index],
                            width: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image_not_supported, size: 40, color: Colors.grey.shade400),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Image not available',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Is your design too similar to this?',
                        style: AppTextStyles.bodySmall.copyWith(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: answered ? null : () {
                                setState(() {
                                  if (priorArtAnswers.length == index) {
                                    priorArtAnswers.add(false);
                                    score += 20;
                                  }
                                });
                              },
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Different'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: answered ? null : () {
                                setState(() {
                                  if (priorArtAnswers.length == index) {
                                    priorArtAnswers.add(true);
                                  }
                                });
                              },
                              icon: const Icon(Icons.warning),
                              label: const Text('Similar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
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
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: priorArtAnswers.length >= priorArt.length ? _nextPhase : null,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Continue to IP Strategy'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: AppDesignSystem.primaryIndigo,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIPStrategyPhase() {
    final ipElements = currentChallenge!['ipElements'] as List;
    final ipTypes = gameData!['ipTypes'] as List;
    
    return Column(
      children: [
        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFF00ACC1).withValues(alpha: 0.1), Colors.white],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF00ACC1).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00ACC1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.shield, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'IP STRATEGY',
                              style: AppTextStyles.h3.copyWith(
                                color: const Color(0xFF00838F),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose the best IP protection for each element',
                        style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
        
                const SizedBox(height: 8),
        
                // Elements list with improved cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 12),
                        child: Text(
                          'Select Protection for Each Element:',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      ...List.generate(ipElements.length, (index) {
                        final element = ipElements[index];
                        final elementId = element['id'];
                        final selected = ipSelections[elementId] ?? [];
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected.isNotEmpty 
                                ? const Color(0xFF00ACC1) 
                                : Colors.grey.shade300,
                              width: selected.isNotEmpty ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: selected.isNotEmpty
                                  ? const Color(0xFF00ACC1).withValues(alpha: 0.15)
                                  : Colors.black.withValues(alpha: 0.05),
                                blurRadius: selected.isNotEmpty ? 12 : 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: selected.isNotEmpty
                                            ? [const Color(0xFF00ACC1), const Color(0xFF26C6DA)]
                                            : [Colors.grey.shade300, Colors.grey.shade400],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            element['name'],
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          if (selected.isNotEmpty)
                                            Text(
                                              '${selected.length} selected',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: const Color(0xFF00ACC1),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (selected.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00ACC1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: ipTypes.map<Widget>((type) {
                                    final typeId = type['id'];
                                    final isSelected = selected.contains(typeId);
                                    final colorValue = int.parse(
                                      type['color'].toString().replaceAll('0x', ''),
                                      radix: 16,
                                    );
                                    final typeColor = Color(colorValue);
                                    
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            final selectionKey = '${elementId}_$typeId';
                                            if (isSelected) {
                                              // Unselecting - remove from list and decrease score
                                              ipSelections[elementId] = 
                                                selected.where((id) => id != typeId).toList();
                                              if (scoredIPSelections.contains(selectionKey)) {
                                                score -= 25;
                                                scoredIPSelections.remove(selectionKey);
                                              }
                                            } else {
                                              // Selecting - add to list and increase score
                                              ipSelections[elementId] = [...selected, typeId];
                                              if (!scoredIPSelections.contains(selectionKey)) {
                                                score += 25;
                                                scoredIPSelections.add(selectionKey);
                                              }
                                            }
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            gradient: isSelected
                                              ? LinearGradient(
                                                  colors: [typeColor, typeColor.withValues(alpha: 0.8)],
                                                )
                                              : null,
                                            color: isSelected ? null : Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isSelected 
                                                ? typeColor 
                                                : typeColor.withValues(alpha: 0.3),
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: isSelected 
                                                  ? typeColor.withValues(alpha: 0.3)
                                                  : Colors.black.withValues(alpha: 0.05),
                                                blurRadius: isSelected ? 12 : 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: isSelected 
                                                    ? Colors.white.withValues(alpha: 0.2)
                                                    : typeColor.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  type['icon'],
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    color: isSelected ? Colors.white : typeColor,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      type['name'],
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.bold,
                                                        color: isSelected 
                                                          ? Colors.white 
                                                          : typeColor,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      type['description'],
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: isSelected 
                                                          ? Colors.white.withValues(alpha: 0.9)
                                                          : Colors.black87,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (isSelected)
                                                Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withValues(alpha: 0.3),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.check,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        
        // Bottom bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00ACC1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00ACC1).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: const Color(0xFF00ACC1),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Selected: ${ipSelections.values.expand((e) => e).length} protections',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF00ACC1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: ipSelections.isNotEmpty ? _nextPhase : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Continue to Filing', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(18),
                    backgroundColor: const Color(0xFF00ACC1),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilingPhase() {
    final questions = currentChallenge!['filingQuestions'] as List;
    
    return Column(
      children: [
        // Scrollable content - starts from top
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade50, Colors.white],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.description, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'IP FILING SIMULATOR',
                      style: AppTextStyles.h3.copyWith(
                        color: Colors.green.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Answer questions to complete your IP application',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
        
        // Questions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: List.generate(questions.length, (index) {
              final question = questions[index];
              final isAnswered = filingAnswers.containsKey(question['id']);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isAnswered ? Colors.green.shade300 : Colors.grey.shade300,
                    width: isAnswered ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Q${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              question['question'],
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // All questions are multiple choice now
                        Column(
                          children: (question['options'] as List).asMap().entries.map((entry) {
                            final isSelected = filingAnswers[question['id']] == entry.key.toString();
                            final correctIndex = question['correctIndex'] as int;
                            final isCorrect = entry.key == correctIndex;
                            final isAnswered = filingAnswers.containsKey(question['id']);
                            
                            // Determine colors based on correctness
                            Color bgColor = Colors.grey.shade50;
                            Color borderColor = Colors.grey.shade300;
                            Color iconColor = Colors.grey.shade400;
                            Color textColor = Colors.black87;
                            IconData icon = Icons.circle_outlined;
                            
                            if (isSelected) {
                              if (isCorrect) {
                                // Correct answer - green
                                bgColor = Colors.green.shade50;
                                borderColor = Colors.green.shade400;
                                iconColor = Colors.green.shade600;
                                textColor = Colors.green.shade900;
                                icon = Icons.check;
                              } else {
                                // Wrong answer - red
                                bgColor = Colors.red.shade50;
                                borderColor = Colors.red.shade400;
                                iconColor = Colors.red.shade600;
                                textColor = Colors.red.shade900;
                                icon = Icons.close;
                              }
                            }
                            
                            return InkWell(
                              onTap: () {
                                // Don't allow changing answer once selected
                                if (isAnswered) return;
                                
                                setState(() {
                                  final questionId = question['id'];
                                  filingAnswers[questionId] = entry.key.toString();
                                  // Only score if correct answer
                                  if (!scoredFilingAnswers.contains(questionId)) {
                                    if (isCorrect) {
                                      score += 25;
                                    }
                                    scoredFilingAnswers.add(questionId);
                                  }
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: borderColor,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: iconColor,
                                          width: 2,
                                        ),
                                        color: isSelected ? iconColor : Colors.transparent,
                                      ),
                                      child: isSelected
                                        ? Icon(icon, size: 14, color: Colors.white)
                                        : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        entry.value,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),
              ],
            ),
          ),
            ),
        ),
        
        // Submit button
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    filingAnswers.length >= questions.length ? Icons.check_circle : Icons.pending,
                    color: filingAnswers.length >= questions.length ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Answered: ${filingAnswers.length}/${questions.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: filingAnswers.length >= questions.length ? _endGame : null,
                  icon: const Icon(Icons.send),
                  label: const Text('Submit Application', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DrawingStroke {
  final String tool;
  final Color color;
  final double strokeWidth;
  final List<Offset> points;
  final bool filled;

  DrawingStroke({
    required this.tool,
    required this.color,
    required this.strokeWidth,
    required this.points,
    this.filled = false,
  });
}

class DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final DrawingStroke? currentStroke;
  final Offset? shapeStart;
  final Offset? shapeEnd;
  final String? shapeTool;
  final Color? shapeColor;
  final double? shapeStrokeWidth;
  final bool fillShape;

  DrawingPainter({
    required this.strokes,
    this.currentStroke,
    this.shapeStart,
    this.shapeEnd,
    this.shapeTool,
    this.shapeColor,
    this.shapeStrokeWidth,
    this.fillShape = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw white background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // Draw all completed strokes
    for (var stroke in strokes) {
      _drawStroke(canvas, stroke);
    }

    // Draw current stroke (freehand)
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!);
    }

    // Draw shape preview
    if (shapeStart != null && shapeEnd != null && shapeTool != null) {
      final paint = Paint()
        ..color = shapeColor ?? Colors.black
        ..strokeWidth = shapeStrokeWidth ?? 2.0
        ..strokeCap = StrokeCap.round
        ..style = fillShape ? PaintingStyle.fill : PaintingStyle.stroke;

      if (shapeTool == 'rectangle') {
        final rect = Rect.fromPoints(shapeStart!, shapeEnd!);
        canvas.drawRect(rect, paint);
      } else if (shapeTool == 'circle') {
        final center = Offset(
          (shapeStart!.dx + shapeEnd!.dx) / 2,
          (shapeStart!.dy + shapeEnd!.dy) / 2,
        );
        final radius = (shapeEnd! - shapeStart!).distance / 2;
        canvas.drawCircle(center, radius, paint);
      } else if (shapeTool == 'line') {
        canvas.drawLine(shapeStart!, shapeEnd!, paint);
      }
    }
  }

  void _drawStroke(Canvas canvas, DrawingStroke stroke) {
    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = stroke.filled ? PaintingStyle.fill : PaintingStyle.stroke;

    if (stroke.tool == 'eraser') {
      paint.color = Colors.white;
    }

    if (stroke.tool == 'rectangle' && stroke.points.length == 2) {
      final rect = Rect.fromPoints(stroke.points[0], stroke.points[1]);
      canvas.drawRect(rect, paint);
    } else if (stroke.tool == 'circle' && stroke.points.length == 2) {
      final center = Offset(
        (stroke.points[0].dx + stroke.points[1].dx) / 2,
        (stroke.points[0].dy + stroke.points[1].dy) / 2,
      );
      final radius = (stroke.points[1] - stroke.points[0]).distance / 2;
      canvas.drawCircle(center, radius, paint);
    } else if (stroke.tool == 'line' && stroke.points.length == 2) {
      canvas.drawLine(stroke.points[0], stroke.points[1], paint);
    } else if (stroke.tool == 'fill' && stroke.points.length >= 1) {
      // Fill bucket - draw a filled rectangle at tap point
      final tapPoint = stroke.points[0];
      final fillRect = Rect.fromCenter(
        center: tapPoint,
        width: 50,
        height: 50,
      );
      canvas.drawRect(fillRect, paint..style = PaintingStyle.fill);
    } else if (stroke.points.length > 1) {
      // Freehand path
      final path = Path();
      path.moveTo(stroke.points[0].dx, stroke.points[0].dy);
      
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      
      canvas.drawPath(path, paint);
    } else if (stroke.points.length == 1) {
      // Single point
      canvas.drawCircle(stroke.points[0], stroke.strokeWidth / 2, paint..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


// Full-screen Results Screen - Matches other games style
class _ResultsScreen extends StatefulWidget {
  final int score;
  final String challengeTitle;
  final int strokesUsed;
  final int priorArtAnalyzed;
  final int ipProtections;
  final int questionsAnswered;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  const _ResultsScreen({
    required this.score,
    required this.challengeTitle,
    required this.strokesUsed,
    required this.priorArtAnalyzed,
    required this.ipProtections,
    required this.questionsAnswered,
    required this.onPlayAgain,
    required this.onExit,
  });

  @override
  State<_ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<_ResultsScreen> {
  late ConfettiController _confettiController;
  final List<Timer> _confettiTimers = [];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    // Trigger confetti multiple times if good score (like other games)
    if (widget.score >= 600) {
      _playConfettiMultipleTimes();
    }
  }
  
  void _playConfettiMultipleTimes() {
    // Play confetti 4 times with delays using Timers so we can cancel them
    _confettiTimers.add(Timer(const Duration(milliseconds: 500), () {
      if (mounted) _confettiController.play();
    }));
    _confettiTimers.add(Timer(const Duration(milliseconds: 2000), () {
      if (mounted) _confettiController.play();
    }));
    _confettiTimers.add(Timer(const Duration(milliseconds: 3500), () {
      if (mounted) _confettiController.play();
    }));
    _confettiTimers.add(Timer(const Duration(milliseconds: 5000), () {
      if (mounted) _confettiController.play();
    }));
  }

  @override
  void dispose() {
    // Cancel all confetti timers to prevent playing after navigation
    for (var timer in _confettiTimers) {
      timer.cancel();
    }
    _confettiController.dispose();
    super.dispose();
  }

  Color _getPerformanceColor() {
    if (widget.score >= 800) return const Color(0xFF10B981);
    if (widget.score >= 600) return const Color(0xFF2196F3);
    if (widget.score >= 400) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  IconData _getPerformanceIcon() {
    if (widget.score >= 800) return Icons.emoji_events;
    if (widget.score >= 600) return Icons.thumb_up;
    if (widget.score >= 400) return Icons.trending_up;
    return Icons.refresh;
  }

  String _getPerformanceMessage() {
    if (widget.score >= 800) return 'Outstanding! You\'re an IP expert!';
    if (widget.score >= 600) return 'Great job! You understand IP protection well!';
    if (widget.score >= 400) return 'Good effort! Keep learning about IP!';
    return 'Keep practicing! Try again to improve!';
  }

  String _getPerformanceTitle() {
    if (widget.score >= 800) return 'IP Master!';
    if (widget.score >= 600) return 'IP Strategist!';
    if (widget.score >= 400) return 'IP Learner';
    return 'Keep Trying!';
  }

  @override
  Widget build(BuildContext context) {
    final isGoodScore = widget.score >= 600;
    
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      body: Stack(
        children: [
          Column(
            children: [
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                  const SizedBox(height: 32),

                  // Animated Trophy Icon
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 600),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getPerformanceColor(),
                                _getPerformanceColor().withValues(alpha: 0.7),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _getPerformanceColor().withValues(alpha: 0.4),
                                blurRadius: 20,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Icon(
                            _getPerformanceIcon(),
                            size: 56,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Title
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 800),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Text(
                          _getPerformanceTitle(),
                          style: AppTextStyles.h1.copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: _getPerformanceColor(),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  Text(
                    widget.challengeTitle,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppDesignSystem.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Score Card
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1000),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${widget.score}',
                                  style: AppTextStyles.h1.copyWith(
                                    fontSize: 64,
                                    fontWeight: FontWeight.bold,
                                    color: _getPerformanceColor(),
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'XP Earned',
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    color: AppDesignSystem.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _getPerformanceColor().withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getPerformanceMessage(),
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: _getPerformanceColor(),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _buildStatRow(Icons.brush, 'Strokes Used', '${widget.strokesUsed}', const Color(0xFF8B5CF6)),
                                const SizedBox(height: 12),
                                _buildStatRow(Icons.search, 'Prior Art Analyzed', '${widget.priorArtAnalyzed}', const Color(0xFFF59E0B)),
                                const SizedBox(height: 12),
                                _buildStatRow(Icons.shield, 'IP Protections', '${widget.ipProtections}', const Color(0xFF2196F3)),
                                const SizedBox(height: 12),
                                _buildStatRow(Icons.description, 'Questions Answered', '${widget.questionsAnswered}', const Color(0xFF10B981)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                    ],
                  ),
                ),
              ),
              
              // Fixed Buttons at bottom
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 800),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PrimaryButton(
                              text: 'Play Again',
                              onPressed: widget.onPlayAgain,
                              fullWidth: true,
                              icon: Icons.refresh,
                              color: const Color(0xFF00ACC1),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: widget.onExit,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                side: const BorderSide(color: Color(0xFF00ACC1), width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                                ),
                              ),
                              child: const SizedBox(
                                width: double.infinity,
                                child: Text(
                                  'Back to Games',
                                  style: TextStyle(color: Color(0xFF00ACC1)),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          // Confetti overlay
          if (isGoodScore)
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

  Widget _buildStatRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppDesignSystem.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
