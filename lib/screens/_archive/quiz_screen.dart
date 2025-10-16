import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/clean_card.dart';
import '../../widgets/primary_button.dart';

/// Quiz Screen - Question and answer options
class QuizScreen extends StatefulWidget {
  const QuizScreen({Key? key}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestion = 0;
  int? _selectedOption;
  final int _totalQuestions = 5;
  final int _timeRemaining = 45;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quiz'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.timer,
                  size: 18,
                  color: AppColors.error,
                ),
                const SizedBox(width: 4),
                Text(
                  '$_timeRemaining',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question ${_currentQuestion + 1} of $_totalQuestions',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(
                      _totalQuestions,
                      (index) => Expanded(
                        child: Container(
                          height: 8,
                          margin: EdgeInsets.only(
                            right: index < _totalQuestions - 1 ? 4 : 0,
                          ),
                          decoration: BoxDecoration(
                            color: index <= _currentQuestion
                                ? AppColors.primary
                                : AppColors.backgroundGrey,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question card
                    CleanCard(
                      color: AppColors.primary.withOpacity(0.05),
                      child: Text(
                        'How long does copyright protection last in India?',
                        style: AppTextStyles.h3,
                      ),
                    ),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Options
                    _OptionCard(
                      option: 'A',
                      text: '50 years',
                      isSelected: _selectedOption == 0,
                      onTap: () => setState(() => _selectedOption = 0),
                    ),
                    
                    const SizedBox(height: AppSpacing.cardSpacing),
                    
                    _OptionCard(
                      option: 'B',
                      text: 'Lifetime + 60 years',
                      isSelected: _selectedOption == 1,
                      onTap: () => setState(() => _selectedOption = 1),
                    ),
                    
                    const SizedBox(height: AppSpacing.cardSpacing),
                    
                    _OptionCard(
                      option: 'C',
                      text: '100 years',
                      isSelected: _selectedOption == 2,
                      onTap: () => setState(() => _selectedOption = 2),
                    ),
                    
                    const SizedBox(height: AppSpacing.cardSpacing),
                    
                    _OptionCard(
                      option: 'D',
                      text: 'Forever',
                      isSelected: _selectedOption == 3,
                      onTap: () => setState(() => _selectedOption = 3),
                    ),
                    
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
            
            // Bottom button
            Container(
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: PrimaryButton(
                text: _currentQuestion < _totalQuestions - 1
                    ? 'Next Question'
                    : 'Submit Quiz',
                onPressed: _selectedOption != null
                    ? () {
                        if (_currentQuestion < _totalQuestions - 1) {
                          setState(() {
                            _currentQuestion++;
                            _selectedOption = null;
                          });
                        } else {
                          // Navigate to results
                          Navigator.pushReplacementNamed(
                            context,
                            '/quiz-results',
                          );
                        }
                      }
                    : () {},
                fullWidth: true,
                icon: Icons.arrow_forward,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Option card
class _OptionCard extends StatelessWidget {
  final String option;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _OptionCard({
    Key? key,
    required this.option,
    required this.text,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return CleanCard(
      color: isSelected
          ? AppColors.primary.withOpacity(0.1)
          : AppColors.background,
      border: Border.all(
        color: isSelected ? AppColors.primary : AppColors.border,
        width: isSelected ? 2 : 1,
      ),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.backgroundGrey,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                option,
                style: AppTextStyles.h4.copyWith(
                  color: isSelected
                      ? Colors.white
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyLarge.copyWith(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          if (isSelected)
            const Icon(
              Icons.check_circle,
              color: AppColors.primary,
              size: 24,
            ),
        ],
      ),
    );
  }
}
