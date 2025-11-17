import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:confetti/confetti.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../services/game_integration_service.dart';
import '../../widgets/primary_button.dart';

/// GI Mapper - Drag GI products to their correct states on India map
class GIMapperGame extends StatefulWidget {
  const GIMapperGame({super.key});

  @override
  State<GIMapperGame> createState() => _GIMapperGameState();
}

class _GIMapperGameState extends State<GIMapperGame> with TickerProviderStateMixin {
  final GameIntegrationService _gameService = GameIntegrationService();
  final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 3),
  );
  
  bool _gameStarted = false;
  bool _gameEnded = false;
  bool _loading = true;
  
  List<GIProduct> _allProducts = [];
  List<GIProduct> _selectedProducts = [];
  final Map<String, GIProduct?> _placements = {}; // productId -> placed product
  Map<String, Map<String, double>> _statePlaceholders = {}; // stateCode -> {x, y}
  double _referenceImageWidth = 500; // Default reference size
  double _referenceImageHeight = 800;
  int _score = 0;
  int _correctPlacements = 0;
  int _timeRemaining = 120; 
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadGameData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadGameData() async {
    try {
      final String jsonString = await rootBundle.loadString('content/games/gi_mapper.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      
      final List<dynamic> productsJson = data['giProducts'] ?? [];
      _allProducts = productsJson.map((json) => GIProduct.fromJson(json)).toList();
      
      // Load state placeholder positions
      final Map<String, dynamic> mapData = data['mapData'] ?? {};
      
      // Load reference image size if provided
      final Map<String, dynamic>? refSize = mapData['referenceImageSize'];
      if (refSize != null) {
        _referenceImageWidth = (refSize['width'] as num).toDouble();
        _referenceImageHeight = (refSize['height'] as num).toDouble();
      }
      
      final List<dynamic> statesJson = mapData['states'] ?? [];
      
      for (var state in statesJson) {
        final String code = state['code'] ?? '';
        final Map<String, dynamic>? position = state['placeholderPosition'];
        
        if (code.isNotEmpty && position != null) {
          _statePlaceholders[code] = {
            'x': (position['x'] as num).toDouble(),
            'y': (position['y'] as num).toDouble(),
          };
        }
      }
      
      setState(() {
        _loading = false;
      });
    } catch (e) {
      print('Error loading GI Mapper data: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  void _initializeGame() {
    // Select 8 random products
    final random = Random();
    final shuffled = List<GIProduct>.from(_allProducts)..shuffle(random);
    _selectedProducts = shuffled.take(8).toList();
    
    // Initialize placements - use product ID as key instead of state code
    _placements.clear();
    for (var product in _selectedProducts) {
      _placements[product.id] = null;
    }
    
    setState(() {
      _score = 0;
      _correctPlacements = 0;
      _timeRemaining = 120;
    });
  }

  void _startGame() {
    _initializeGame();
    setState(() {
      _gameStarted = true;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
        });
        
        if (_timeRemaining == 0) {
          _endGame(timeUp: true);
        }
      }
    });
  }

  void _submitAnswers() {
    _timer?.cancel();
    
    // Calculate score - check if placed products match their correct states
    int correctCount = 0;
    for (var product in _selectedProducts) {
      final placedProduct = _placements[product.id];
      // Check if product is placed AND in the correct state
      if (placedProduct != null && placedProduct.stateCode == product.stateCode) {
        correctCount++;
      }
    }
    
    setState(() {
      _correctPlacements = correctCount;
      _score = correctCount * 10; // 10 points per correct placement
    });
    
    // End game immediately
    _endGame();
  }

  void _playConfettiMultipleTimes() {
    // Play confetti 3 times with delays
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _confettiController.play();
    });
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) _confettiController.play();
    });
    Future.delayed(const Duration(milliseconds: 4500), () {
      if (mounted) _confettiController.play();
    });
  }

  void _endGame({bool timeUp = false}) {
    _timer?.cancel();
    
    if (timeUp) {
      // Auto-calculate score if time ran out
      int correctCount = 0;
      for (var product in _selectedProducts) {
        final placedProduct = _placements[product.id];
        if (placedProduct?.id == product.id) {
          correctCount++;
        }
      }
      setState(() {
        _correctPlacements = correctCount;
        _score = correctCount * 10;
      });
    }
    
    setState(() {
      _gameEnded = true;
    });
    _saveScore();
  }

  Future<void> _saveScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        const gameId = 'gi_mapper';
        final baseXP = _score;
        
        final isFirstCompletion = await _gameService.isFirstCompletion(gameId);
        final isPerfectScore = _correctPlacements == _selectedProducts.length;
        
        // Award XP with automatic bonuses
        await _gameService.awardGameXP(
          gameId: gameId,
          baseXP: baseXP,
          score: (_correctPlacements / _selectedProducts.length * 100).round(),
          isPerfectScore: isPerfectScore,
          isFirstCompletion: isFirstCompletion,
        );
        
        // Save progress
        await _gameService.saveGameProgress(
          gameId: gameId,
          score: _score,
          timeSpentSeconds: 120 - _timeRemaining,
          completed: true,
        );
        
        print('Game score saved: $_score');
      } catch (e) {
        print('Error saving game score: $e');
      }
    }
  }

  void _restartGame() {
    setState(() {
      _gameEnded = false;
      _gameStarted = false;
      _score = 0;
      _correctPlacements = 0;
    });
    _initializeGame();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppDesignSystem.backgroundLight,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
        title: const Text('GI Mapper', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFFFC107),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
                      color: const Color(0xFFFFC107).withOpacity(0.4),
                      blurRadius: 40,
                      spreadRadius: 5,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: const Color(0xFFFFC107).withOpacity(0.2),
                      blurRadius: 60,
                      spreadRadius: 10,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Image.asset(
                  'assets/logos/gi_mapper.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.map,
                      size: 60,
                      color: Color(0xFFFFC107),
                    );
                  },
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
                'Drag GI products to their correct state placeholders!',
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
                    _buildRuleItem('🎯', 'Fill placeholders with correct products'),
                    _buildRuleItem('⏱️', '5 minutes to complete'),
                    _buildRuleItem('✅', 'Only correct products fit each slot'),
                    _buildRuleItem('⭐', '10 points per correct match'),
                  ],
                ),
              ),

              const Spacer(),

              // Start button (Spacer pushes it down, adjust Spacer to move button)
              Padding(
                padding: const EdgeInsets.only(bottom: 10), // 10px from bottom
                child: PrimaryButton(
                  text: 'Start Game',
                  onPressed: _startGame,
                  fullWidth: true,
                  icon: Icons.play_arrow,
                  color: const Color(0xFFFFC107),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

    Widget _buildGameScreen() {
    final minutes = _timeRemaining ~/ 60;
    final seconds = _timeRemaining % 60;
    final placedCount = _placements.values.where((p) => p != null).length;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFFC107).withOpacity(0.05),
              const Color(0xFFFF9800).withOpacity(0.05),
            ],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // Top bar with back button and stats
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // Back button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
                            onPressed: () {
                              _timer?.cancel();
                              Navigator.pop(context);
                            },
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // Stats badges
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Timer badge
                              _buildModernStatBadge(
                                icon: Icons.timer_outlined,
                                value: '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                                color: _timeRemaining < 60 ? const Color(0xFFEF5350) : const Color(0xFFF59E0B),
                              ),
                              // Placed badge
                              _buildModernStatBadge(
                                icon: Icons.check_circle_outline,
                                value: '$placedCount/${_selectedProducts.length}',
                                color: const Color(0xFFE91E63),
                              ),
                              // Score badge
                              _buildModernStatBadge(
                                icon: Icons.star_outline,
                                value: '$_score',
                                color: const Color(0xFF10B981),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // India Map - Fixed, non-scrollable
                  Expanded(
                    flex: 7,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(4),
                      child: _buildIndiaMapWithSVG(),
                    ),
                  ),

                  // Products section - Fixed at bottom
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
                          child: Row(
                            children: [
                              const Icon(Icons.inventory_2, color: Color(0xFFFFC107), size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Drag Products to Placeholders',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: const Color(0xFFFFC107),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: _selectedProducts.map((product) {
                                // Check if THIS product is placed somewhere (not if something is in its slot)
                                final isPlaced = _placements.values.any((p) => p?.id == product.id);
                                
                                // Make all chips draggable, even if placed
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Draggable<GIProduct>(
                                    data: product,
                                    feedback: Material(
                                      elevation: 8,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(colors: [Color(0xFFFFC107), Color(0xFFFF9800)]),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFFFC107).withOpacity(0.5),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.location_on, color: Colors.white, size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              product.name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    childWhenDragging: Opacity(
                                      opacity: 0.3,
                                      child: _buildProductChip(product, false),
                                    ),
                                    child: _buildProductChip(product, isPlaced),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Submit button
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: PrimaryButton(
                      text: placedCount == _selectedProducts.length 
                          ? 'Submit Answers' 
                          : 'Submit ($placedCount/${_selectedProducts.length})',
                      onPressed: placedCount > 0 ? _submitAnswers : null,
                      fullWidth: true,
                      icon: Icons.check_circle,
                      color: const Color(0xFFFFC107),
                    ),
                  ),
                ],
              ),
            ),

            // Confetti overlay
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 2,
                maxBlastForce: 5,
                minBlastForce: 2,
                emissionFrequency: 0.05,
                numberOfParticles: 50,
                gravity: 0.1,
              ),
            ),
          ], 
        ), 
      ), 
    ); 
  }

  Widget _buildModernStatBadge({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductChip(GIProduct product, bool isPlaced) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFC107), Color(0xFFFF9800)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFC107).withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPlaced ? Icons.check_circle : Icons.location_on,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            product.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndiaMapWithSVG() {
    return LayoutBuilder(
      builder: (context, mapConstraints) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                // India Map PNG
                Positioned.fill(
                  child: Image.asset(
                    'assets/maps/india_map.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildMapFallback();
                    },
                  ),
                ),
                
                // Show placeholder drop zones for selected products
                ..._buildPlaceholderDropZones(mapConstraints),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildPlaceholderDropZones(BoxConstraints constraints) {
    final List<Widget> dropZones = [];
    
    // If constraints are invalid, return empty list
    if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
      return dropZones;
    }
    
    // Track how many products per state to offset overlapping placeholders
    final Map<String, int> stateProductCount = {};
    final Map<String, int> stateProductIndex = {};
    
    for (var product in _selectedProducts) {
      stateProductCount[product.stateCode] = (stateProductCount[product.stateCode] ?? 0) + 1;
    }
    
    for (var product in _selectedProducts) {
      final stateCode = product.stateCode;
      final position = _statePlaceholders[stateCode];
      
      if (position == null) {
        continue;
      }
      
      // Calculate position - center the placeholder
      final double placeholderWidth = 100;
      final double placeholderHeight = 32;
      
      // Get index for this product in its state
      final int index = stateProductIndex[stateCode] ?? 0;
      stateProductIndex[stateCode] = index + 1;
      
      // Offset if multiple products from same state
      final int totalForState = stateProductCount[stateCode] ?? 1;
      final double offsetY = totalForState > 1 ? (index - (totalForState - 1) / 2) * 36 : 0;
      
      // Convert position based on type
      final double posX = position['x']!;
      final double posY = position['y']!;
      
      double left, top;
      
      if (posX > 1) {
        // Pixel coordinates - scale from reference image to actual display size
        final double scaleX = constraints.maxWidth / _referenceImageWidth;
        final double scaleY = constraints.maxHeight / _referenceImageHeight;
        
        left = (posX * scaleX) - (placeholderWidth / 2);
        top = (posY * scaleY) - (placeholderHeight / 2) + offsetY;
      } else {
        // Percentage coordinates (0-1)
        left = (constraints.maxWidth * posX) - (placeholderWidth / 2);
        top = (constraints.maxHeight * posY) - (placeholderHeight / 2) + offsetY;
      }
      
      final placedProduct = _placements[product.id];
      final bool isFilled = placedProduct != null;
      final bool isCorrect = isFilled && placedProduct?.stateCode == product.stateCode;
      
      dropZones.add(
        Positioned(
          left: left,
          top: top,
          child: DragTarget<GIProduct>(
            onAcceptWithDetails: (details) {
              setState(() {
                // Remove from previous placement if any
                _placements.forEach((key, value) {
                  if (value?.id == details.data.id) {
                    _placements[key] = null;
                  }
                });
                
                // Place in this slot (allow any product)
                _placements[product.id] = details.data;
              });
            },
            builder: (context, candidateData, rejectedData) {
              final isHovering = candidateData.isNotEmpty;
              
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: placeholderWidth,
                height: placeholderHeight,
                decoration: BoxDecoration(
                  color: isFilled
                      ? const Color(0xFFFFC107).withOpacity(0.9)
                      : isHovering
                          ? const Color(0xFFFFC107).withOpacity(0.5)
                          : Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isFilled
                        ? const Color(0xFFFF9800)
                        : isHovering
                            ? const Color(0xFFFFC107)
                            : Colors.grey[400]!,
                    width: 2,
                  ),
                  boxShadow: isFilled || isHovering
                      ? [
                          BoxShadow(
                            color: (isFilled ? const Color(0xFFFFC107) : Colors.grey)
                                .withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: isFilled
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                placedProduct!.name.length > 10
                                    ? '${placedProduct.name.substring(0, 8)}..'
                                    : placedProduct.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          product.state.length > 10
                              ? '${product.state.substring(0, 8)}..'
                              : product.state,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              );
            },
          ),
        ),
      );
    }
    
    return dropZones;
  }

  Widget _buildResultScreen() {
    final percentage = (_correctPlacements / _selectedProducts.length * 100).round();
    final isPerfect = _correctPlacements == _selectedProducts.length;
    final passed = percentage >= 60;
    final timeSpent = 120 - _timeRemaining;
    final minutes = timeSpent ~/ 60;
    final seconds = timeSpent % 60;

    // Trigger confetti when result screen is shown
    if (passed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _playConfettiMultipleTimes();
      });
    }

    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('Game Over', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFFFC107),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 1),
                  
                  // Animated Result icon
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 600),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isPerfect
                                  ? [
                                      const Color(0xFFFFC107),
                                      const Color(0xFFFF9800),
                                    ]
                                  : passed
                                      ? [
                                          AppDesignSystem.success,
                                          AppDesignSystem.success.withOpacity(0.7),
                                        ]
                                      : [
                                          Colors.orange,
                                          Colors.orange.withOpacity(0.7),
                                        ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (isPerfect
                                        ? const Color(0xFFFFC107)
                                        : passed
                                            ? AppDesignSystem.success
                                            : Colors.orange)
                                    .withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            isPerfect
                                ? Icons.emoji_events
                                : passed
                                    ? Icons.check_circle
                                    : Icons.refresh,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Animated Title
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 400),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Column(
                            children: [
                              Text(
                                isPerfect
                                    ? 'Perfect Score!'
                                    : passed
                                        ? 'Great Job!'
                                        : 'Good Try!',
                                style: AppTextStyles.h1.copyWith(
                                  color: isPerfect
                                      ? const Color(0xFFFFC107)
                                      : passed
                                          ? AppDesignSystem.success
                                          : Colors.orange,
                                  fontSize: 28,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  '$_correctPlacements/${_selectedProducts.length} correct',
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    color: AppDesignSystem.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Animated Stats Card
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 600),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 30 * (1 - value)),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFFFC107).withOpacity(0.2),
                                  const Color(0xFFFF9800).withOpacity(0.2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(2),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFC107).withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  _buildFancyStatRow(
                                    Icons.check_circle,
                                    'Correct',
                                    '$_correctPlacements/${_selectedProducts.length}',
                                    AppDesignSystem.success,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildFancyStatRow(
                                    Icons.speed,
                                    'Accuracy',
                                    '$percentage%',
                                    const Color(0xFF2196F3),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildFancyStatRow(
                                    Icons.timer,
                                    'Time',
                                    '${minutes}m ${seconds}s',
                                    const Color(0xFFFF9800),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildFancyStatRow(
                                    Icons.military_tech,
                                    'XP Earned',
                                    '+$_score XP',
                                    const Color(0xFFFFC107),
                                    isHighlight: true,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const Spacer(flex: 1),

                  // Animated Buttons
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 800),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Column(
                          children: [
                            PrimaryButton(
                              text: 'Play Again',
                              onPressed: _restartGame,
                              fullWidth: true,
                              icon: Icons.refresh,
                              color: const Color(0xFFFFC107),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: Color(0xFFFFC107), width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const SizedBox(
                                width: double.infinity,
                                child: Text(
                                  'Back to Games',
                                  style: TextStyle(color: Color(0xFFFFC107)),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          
          // Confetti overlay
          if (passed)
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

  Widget _buildFancyStatRow(IconData icon, String label, String value, Color color, {bool isHighlight = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.2),
                color.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppDesignSystem.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isHighlight ? color : AppDesignSystem.textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (isHighlight)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.star, color: Colors.white, size: 16),
          ),
      ],
    );
  }

  Widget _buildRuleItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange[50]!,
            Colors.amber[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.public, size: 80, color: Color(0xFFFFC107)),
            SizedBox(height: 16),
            Text(
              'INDIA',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFC107),
                letterSpacing: 8,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Drop GI Products Here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange[50]!,
            Colors.amber[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomPaint(
        painter: IndiaMapPainter(),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.public, size: 60, color: Color(0xFFFFC107)),
              SizedBox(height: 12),
              Text(
                'INDIA',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFC107),
                  letterSpacing: 4,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Drop GI Products Here',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Simple India map outline painter
class IndiaMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFC107).withOpacity(0.2)
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = const Color(0xFFFFC107).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Simplified India shape (approximate)
    final path = Path();
    
    // Starting from top (Kashmir)
    path.moveTo(size.width * 0.3, size.height * 0.1);
    path.lineTo(size.width * 0.35, size.height * 0.05);
    path.lineTo(size.width * 0.4, size.height * 0.1);
    
    // Northeast
    path.lineTo(size.width * 0.7, size.height * 0.25);
    path.lineTo(size.width * 0.75, size.height * 0.35);
    
    // East coast
    path.lineTo(size.width * 0.7, size.height * 0.5);
    path.lineTo(size.width * 0.65, size.height * 0.7);
    
    // South (Tamil Nadu)
    path.lineTo(size.width * 0.55, size.height * 0.85);
    path.lineTo(size.width * 0.45, size.height * 0.9);
    path.lineTo(size.width * 0.35, size.height * 0.85);
    
    // West coast (Kerala, Goa, Gujarat)
    path.lineTo(size.width * 0.3, size.height * 0.75);
    path.lineTo(size.width * 0.25, size.height * 0.6);
    path.lineTo(size.width * 0.2, size.height * 0.4);
    path.lineTo(size.width * 0.25, size.height * 0.25);
    
    // Back to Kashmir
    path.close();
    
    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GIProduct {
  final String id;
  final String name;
  final String state;
  final String stateCode;
  final String category;
  final String description;
  final String hint;
  final int points;

  GIProduct({
    required this.id,
    required this.name,
    required this.state,
    required this.stateCode,
    required this.category,
    required this.description,
    required this.hint,
    required this.points,
  });

  factory GIProduct.fromJson(Map<String, dynamic> json) {
    return GIProduct(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      state: json['state'] ?? '',
      stateCode: json['stateCode'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      hint: json['hint'] ?? '',
      points: json['points'] ?? 10,
    );
  }
}