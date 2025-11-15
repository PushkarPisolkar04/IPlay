import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/progress_service.dart';
import '../../widgets/primary_button.dart';
import '../../services/game_content_service.dart';
import '../../services/game_integration_service.dart';
import '../../models/innovation_lab_model.dart' as model;
import '../../widgets/drawing_canvas/drawing_canvas_widgets.dart';

/// Enhanced Innovation Lab with full drawing canvas functionality
class InnovationLabEnhancedScreen extends StatefulWidget {
  const InnovationLabEnhancedScreen({super.key});

  @override
  State<InnovationLabEnhancedScreen> createState() => _InnovationLabEnhancedScreenState();
}

class _InnovationLabEnhancedScreenState extends State<InnovationLabEnhancedScreen> {
  final ProgressService _progressService = ProgressService();
  final GameContentService _gameService = GameContentService();
  
  // Game data from CMS
  model.InnovationLabGame? _gameData;
  bool _loading = true;
  String? _error;
  
  // Game state
  bool _gameStarted = false;
  bool _gameEnded = false;
  
  // Drawing system
  late DrawingController _drawingController;
  late LayerManager _layerManager;
  bool _showGrid = false;
  int _gridSize = 20;
  
  // Selected template
  model.DesignTemplate? _selectedTemplate;
  
  // Quiz results
  int _quizScore = 0;
  int _quizTotalPoints = 0;

  @override
  void initState() {
    super.initState();
    _drawingController = DrawingController();
    _layerManager = LayerManager(drawingController: _drawingController);
    _loadGameContent();
  }

  @override
  void dispose() {
    _drawingController.dispose();
    _layerManager.dispose();
    super.dispose();
  }

  Future<void> _loadGameContent() async {
    try {
      final game = await _gameService.loadInnovationLab();
      setState(() {
        _gameData = game;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _startGame() {
    setState(() {
      _gameStarted = true;
      _drawingController.clearAllLayers();
    });
  }

  void _selectTemplate(model.DesignTemplate template) {
    setState(() {
      _selectedTemplate = template;
      _showGrid = template.templateData.gridEnabled;
      _gridSize = template.templateData.gridSize ?? 20;
    });
  }

  Future<void> _completeDesign() async {
    if (_gameData == null) return;

    // Show IP filing quiz
    final questions = _gameData!.selectRandomQuestions();
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => IPQuizModal(
        questions: questions,
        onComplete: (score, totalPoints) {
          setState(() {
            _quizScore = score;
            _quizTotalPoints = totalPoints;
            _gameEnded = true;
          });
          _saveScore();
        },
      ),
    );
  }

  Future<void> _saveScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _gameData != null) {
      try {
        final gameIntegrationService = GameIntegrationService();
        
        final isFirstCompletion = await gameIntegrationService.isFirstCompletion(_gameData!.id);
        final isPerfectScore = _quizScore == _quizTotalPoints;
        
        // Award XP with automatic bonuses
        final xpEarned = await gameIntegrationService.awardGameXP(
          gameId: _gameData!.id,
          baseXP: _gameData!.xpReward,
          score: _quizTotalPoints > 0 ? (_quizScore / _quizTotalPoints * 100).round() : 0,
          isPerfectScore: isPerfectScore,
          isFirstCompletion: isFirstCompletion,
        );
        
        // Save progress
        await gameIntegrationService.saveGameProgress(
          gameId: _gameData!.id,
          score: _quizScore,
          timeSpentSeconds: 0,
          completed: true,
        );
        
        // Submit to leaderboards (if enabled)
        if (_gameData!.leaderboard.enabled) {
          await gameIntegrationService.submitToLeaderboards(
            gameId: _gameData!.id,
            score: _quizScore,
            scopes: _gameData!.leaderboard.scope,
          );
        }
        
        // Log analytics
        await gameIntegrationService.logGameComplete(
          gameId: _gameData!.id,
          score: _quizScore,
          timeSpentSeconds: 0,
          isPerfectScore: isPerfectScore,
        );
      } catch (e) {
        // Error handling
      }
    }
  }

  void _restartGame() {
    setState(() {
      _gameEnded = false;
      _gameStarted = false;
      _selectedTemplate = null;
      _quizScore = 0;
      _quizTotalPoints = 0;
      _drawingController.clearAllLayers();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _buildLoadingScreen();
    }

    if (_error != null || _gameData == null) {
      return _buildErrorScreen();
    }

    if (!_gameStarted) {
      return _buildStartScreen();
    }

    if (_gameEnded) {
      return _buildResultScreen();
    }

    return _buildDrawingScreen();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('Innovation Lab'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('Innovation Lab'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: AppSpacing.lg),
              Text('Failed to load game content', style: AppTextStyles.h2),
              const SizedBox(height: AppSpacing.md),
              Text(_error ?? 'Unknown error', style: AppTextStyles.bodyMedium),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                text: 'Retry',
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _loadGameContent();
                },
                icon: Icons.refresh,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartScreen() {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: Text(_gameData?.name ?? 'Innovation Lab'),
        backgroundColor: _gameData?.color ?? Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: (_gameData?.color ?? Colors.teal).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.science,
                  size: 60,
                  color: _gameData?.color ?? Colors.teal,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(_gameData?.name ?? 'Innovation Lab', style: AppTextStyles.h1),
              const SizedBox(height: AppSpacing.md),
              Text(
                _gameData?.description ?? 'Design and protect your innovations!',
                style: AppTextStyles.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              
              // Template selection
              if (_gameData != null && _gameData!.templates.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppDesignSystem.backgroundGrey,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Choose a Template', style: AppTextStyles.cardTitle),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Start with a professional template or create from scratch',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.grid_view),
                        label: const Text('Browse Templates'),
                        onPressed: () async {
                          final template = await showDialog<model.DesignTemplate>(
                            context: context,
                            builder: (context) => TemplateSelectionDialog(
                              templates: _gameData!.templates,
                            ),
                          );
                          if (template != null) {
                            _selectTemplate(template);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      if (_selectedTemplate != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        TemplatePreview(
                          template: _selectedTemplate!,
                          onUse: null,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
              
              PrimaryButton(
                text: 'Start Creating',
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

  Widget _buildDrawingScreen() {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('Design Your Innovation'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Toolbar
          DrawingToolbar(
            controller: _drawingController,
            onSave: () async {
              await showDialog(
                context: context,
                builder: (context) => SaveDrawingDialog(
                  controller: _drawingController,
                  canvasWidth: 800,
                  canvasHeight: 600,
                ),
              );
            },
            onExport: () async {
              await showDialog(
                context: context,
                builder: (context) => ExportDrawingDialog(
                  controller: _drawingController,
                  canvasWidth: 800,
                  canvasHeight: 600,
                ),
              );
            },
          ),

          // Main content
          Expanded(
            child: Row(
              children: [
                // Left sidebar - Tools
                Container(
                  width: 80,
                  color: Colors.white,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        DrawingToolsPalette(
                          controller: _drawingController,
                          direction: Axis.vertical,
                        ),
                      ],
                    ),
                  ),
                ),

                // Center - Canvas
                Expanded(
                  child: Container(
                    color: Colors.grey[200],
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: DrawingCanvas(
                        controller: _drawingController,
                        width: 800,
                        height: 600,
                        showGrid: _showGrid,
                        gridSize: _gridSize,
                      ),
                    ),
                  ),
                ),

                // Right sidebar - Properties
                Container(
                  width: 280,
                  color: Colors.white,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Color picker
                        if (_gameData != null)
                          ColorPickerWidget(
                            controller: _drawingController,
                            presetColors: _gameData!.colorPalette
                                .map((c) => c.color)
                                .toList(),
                          ),

                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Stroke width
                        StrokeWidthSlider(controller: _drawingController),

                        const SizedBox(height: 16),

                        // Opacity
                        OpacitySlider(controller: _drawingController),

                        const SizedBox(height: 16),

                        // Fill toggle
                        FillToggle(controller: _drawingController),

                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Grid toggle
                        GridToggle(
                          enabled: _showGrid,
                          onChanged: (value) => setState(() => _showGrid = value),
                          gridSize: _gridSize,
                          onGridSizeChanged: (value) => setState(() => _gridSize = value),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom bar - Layers and actions
          Container(
            height: 120,
            color: Colors.white,
            child: Column(
              children: [
                const Divider(height: 1),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: LayerThumbnailsView(
                            layerManager: _layerManager,
                            drawingController: _drawingController,
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text('Complete Design'),
                          onPressed: _completeDesign,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    final totalXP = (_gameData?.xpReward ?? 0) + _quizScore;

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
              Text('Congratulations!', style: AppTextStyles.h1),
              const SizedBox(height: AppSpacing.md),
              Text(
                'You\'ve successfully designed and protected your innovation!',
                style: AppTextStyles.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppDesignSystem.backgroundGrey,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: Column(
                  children: [
                    _buildResultRow('Design XP', '+${_gameData?.xpReward ?? 0} XP'),
                    const Divider(height: 24),
                    _buildResultRow('Quiz Score', '$_quizScore / $_quizTotalPoints'),
                    const Divider(height: 24),
                    _buildResultRow('Total XP Earned', '+$totalXP XP', highlight: true),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                text: 'Create Another',
                onPressed: _restartGame,
                fullWidth: true,
                icon: Icons.refresh,
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                child: const SizedBox(
                  width: double.infinity,
                  child: Text('Back to Games', textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium),
        Text(
          value,
          style: AppTextStyles.h3.copyWith(
            color: highlight ? Colors.teal : AppDesignSystem.textPrimary,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
