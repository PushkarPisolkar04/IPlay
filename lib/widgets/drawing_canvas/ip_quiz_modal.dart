import 'package:flutter/material.dart';
import '../../models/innovation_lab_model.dart';

/// IP Filing Quiz Modal
class IPQuizModal extends StatefulWidget {
  final List<IPQuestion> questions;
  final Function(int score, int totalPoints) onComplete;

  const IPQuizModal({
    super.key,
    required this.questions,
    required this.onComplete,
  });

  @override
  State<IPQuizModal> createState() => _IPQuizModalState();
}

class _IPQuizModalState extends State<IPQuizModal> {
  int _currentQuestionIndex = 0;
  final Map<String, int> _answers = {};
  final Map<String, bool> _correctAnswers = {};
  int _score = 0;
  int _totalPoints = 0;
  bool _showingResult = false;

  IPQuestion get _currentQuestion => widget.questions[_currentQuestionIndex];
  bool get _isLastQuestion => _currentQuestionIndex == widget.questions.length - 1;
  bool get _hasAnswered => _answers.containsKey(_currentQuestion.id);

  @override
  void initState() {
    super.initState();
    _totalPoints = widget.questions.fold(0, (sum, q) => sum + q.points);
  }

  void _selectAnswer(int index) {
    if (_hasAnswered) return;

    setState(() {
      _answers[_currentQuestion.id] = index;
      final isCorrect = index == _currentQuestion.correctIndex;
      _correctAnswers[_currentQuestion.id] = isCorrect;

      if (isCorrect) {
        _score += _currentQuestion.points;
      }
    });
  }

  void _nextQuestion() {
    if (!_hasAnswered) return;

    if (_isLastQuestion) {
      setState(() {
        _showingResult = true;
      });
    } else {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _complete() {
    widget.onComplete(_score, _totalPoints);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: _showingResult ? _buildResultView() : _buildQuizView(),
      ),
    );
  }

  Widget _buildQuizView() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.teal,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.quiz, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'IP Filing Quiz',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress indicator
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (_currentQuestionIndex + 1) / widget.questions.length,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_currentQuestionIndex + 1}/${widget.questions.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Question content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question text
                Text(
                  _currentQuestion.question,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 12),

                // Context
                if (_currentQuestion.context.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, size: 20, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _currentQuestion.context,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Answer options
                ...List.generate(_currentQuestion.options.length, (index) {
                  return _buildAnswerOption(index);
                }),

                // Explanation (shown after answering)
                if (_hasAnswered) ...[
                  const SizedBox(height: 24),
                  _buildExplanation(),
                ],

                // Educational content (shown after answering)
                if (_hasAnswered) ...[
                  const SizedBox(height: 16),
                  _buildEducationalContent(),
                ],
              ],
            ),
          ),
        ),

        // Navigation buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(
              top: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Row(
            children: [
              if (_currentQuestionIndex > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _previousQuestion,
                    child: const Text('Previous'),
                  ),
                ),
              if (_currentQuestionIndex > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _hasAnswered ? _nextQuestion : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(_isLastQuestion ? 'Finish Quiz' : 'Next Question'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerOption(int index) {
    final option = _currentQuestion.options[index];
    final isSelected = _answers[_currentQuestion.id] == index;
    final isCorrect = index == _currentQuestion.correctIndex;
    final hasAnswered = _hasAnswered;

    Color? backgroundColor;
    Color? borderColor;
    IconData? icon;

    if (hasAnswered) {
      if (isSelected) {
        if (isCorrect) {
          backgroundColor = Colors.green.withValues(alpha: 0.1);
          borderColor = Colors.green;
          icon = Icons.check_circle;
        } else {
          backgroundColor = Colors.red.withValues(alpha: 0.1);
          borderColor = Colors.red;
          icon = Icons.cancel;
        }
      } else if (isCorrect) {
        backgroundColor = Colors.green.withValues(alpha: 0.05);
        borderColor = Colors.green;
        icon = Icons.check_circle_outline;
      }
    } else if (isSelected) {
      backgroundColor = Colors.teal.withValues(alpha: 0.1);
      borderColor = Colors.teal;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: hasAnswered ? null : () => _selectAnswer(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor ?? Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: borderColor?.withValues(alpha: 0.2) ?? Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + index), // A, B, C, D
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: borderColor ?? Colors.grey[700],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 15,
                    color: borderColor ?? Colors.black,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 8),
                Icon(icon, color: borderColor, size: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExplanation() {
    final isCorrect = _correctAnswers[_currentQuestion.id] ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect ? Colors.green : Colors.orange,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.info,
                color: isCorrect ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? 'Correct!' : 'Explanation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isCorrect ? Colors.green : Colors.orange,
                ),
              ),
              const Spacer(),
              Text(
                '+${_currentQuestion.points} XP',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isCorrect ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _currentQuestion.explanation,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationalContent() {
    final content = _currentQuestion.educationalContent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                content.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content.content,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          if (content.examples != null && content.examples!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Examples:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            ...content.examples!.map((example) => Padding(
                  padding: const EdgeInsets.only(left: 12, top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 13)),
                      Expanded(
                        child: Text(
                          example,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildResultView() {
    final percentage = (_score / _totalPoints * 100).round();
    final passed = percentage >= 60;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: passed ? Colors.green : Colors.orange,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              Icon(
                passed ? Icons.emoji_events : Icons.info,
                size: 64,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                passed ? 'Great Job!' : 'Keep Learning!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Results
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Score card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$_score / $_totalPoints',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: passed ? Colors.green : Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$percentage% Correct',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Stats
                _buildStatRow(
                  'Questions Answered',
                  '${widget.questions.length}',
                  Icons.quiz,
                ),
                const SizedBox(height: 12),
                _buildStatRow(
                  'Correct Answers',
                  '${_correctAnswers.values.where((v) => v).length}',
                  Icons.check_circle,
                ),
                const SizedBox(height: 12),
                _buildStatRow(
                  'XP Earned',
                  '+$_score XP',
                  Icons.star,
                ),

                const SizedBox(height: 24),

                // Message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    passed
                        ? 'You have a good understanding of IP filing! Your design is ready for protection.'
                        : 'Review the educational content to improve your understanding of IP filing.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Complete button
        Container(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _complete,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Complete',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
        ],
      ),
    );
  }
}
