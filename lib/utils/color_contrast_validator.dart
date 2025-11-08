import 'package:flutter/material.dart';
import '../core/design/app_design_system.dart';
import 'accessibility_helper.dart';

/// ColorContrastValidator - Validates color combinations meet WCAG standards
/// Provides tools for testing and reporting contrast ratios
class ColorContrastValidator {
  /// Validate all color combinations in the design system
  static Map<String, ContrastResult> validateDesignSystem() {
    final results = <String, ContrastResult>{};

    // Test text colors on white background
    results['textPrimary_on_white'] = _testContrast(
      'Primary Text on White',
      AppDesignSystem.textPrimary,
      AppDesignSystem.backgroundWhite,
    );

    results['textSecondary_on_white'] = _testContrast(
      'Secondary Text on White',
      AppDesignSystem.textSecondary,
      AppDesignSystem.backgroundWhite,
    );

    results['textTertiary_on_white'] = _testContrast(
      'Tertiary Text on White',
      AppDesignSystem.textTertiary,
      AppDesignSystem.backgroundWhite,
    );

    // Test text colors on light background
    results['textPrimary_on_light'] = _testContrast(
      'Primary Text on Light Background',
      AppDesignSystem.textPrimary,
      AppDesignSystem.backgroundLight,
    );

    results['textSecondary_on_light'] = _testContrast(
      'Secondary Text on Light Background',
      AppDesignSystem.textSecondary,
      AppDesignSystem.backgroundLight,
    );

    // Test white text on primary colors
    results['white_on_primaryIndigo'] = _testContrast(
      'White on Primary Indigo',
      AppDesignSystem.backgroundWhite,
      AppDesignSystem.primaryIndigo,
    );

    results['white_on_primaryPink'] = _testContrast(
      'White on Primary Pink',
      AppDesignSystem.backgroundWhite,
      AppDesignSystem.primaryPink,
    );

    results['white_on_primaryGreen'] = _testContrast(
      'White on Primary Green',
      AppDesignSystem.backgroundWhite,
      AppDesignSystem.primaryGreen,
    );

    results['white_on_primaryAmber'] = _testContrast(
      'White on Primary Amber',
      AppDesignSystem.backgroundWhite,
      AppDesignSystem.primaryAmber,
    );

    // Test white text on secondary colors
    results['white_on_secondaryPurple'] = _testContrast(
      'White on Secondary Purple',
      AppDesignSystem.backgroundWhite,
      AppDesignSystem.secondaryPurple,
    );

    results['white_on_secondaryBlue'] = _testContrast(
      'White on Secondary Blue',
      AppDesignSystem.backgroundWhite,
      AppDesignSystem.secondaryBlue,
    );

    results['white_on_secondaryRed'] = _testContrast(
      'White on Secondary Red',
      AppDesignSystem.backgroundWhite,
      AppDesignSystem.secondaryRed,
    );

    // Test semantic colors
    results['white_on_success'] = _testContrast(
      'White on Success',
      AppDesignSystem.backgroundWhite,
      AppDesignSystem.success,
    );

    results['white_on_warning'] = _testContrast(
      'White on Warning',
      AppDesignSystem.backgroundWhite,
      AppDesignSystem.warning,
    );

    results['white_on_error'] = _testContrast(
      'White on Error',
      AppDesignSystem.backgroundWhite,
      AppDesignSystem.error,
    );

    results['white_on_info'] = _testContrast(
      'White on Info',
      AppDesignSystem.backgroundWhite,
      AppDesignSystem.info,
    );

    return results;
  }

  /// Test a single color combination
  static ContrastResult _testContrast(
    String name,
    Color foreground,
    Color background,
  ) {
    final ratio = AccessibilityHelper.calculateContrastRatio(
      foreground,
      background,
    );

    return ContrastResult(
      name: name,
      foreground: foreground,
      background: background,
      ratio: ratio,
      meetsAA: ratio >= 4.5,
      meetsAAA: ratio >= 7.0,
      meetsAALargeText: ratio >= 3.0,
    );
  }

  /// Generate a report of all contrast issues
  static String generateReport() {
    final results = validateDesignSystem();
    final buffer = StringBuffer();

    buffer.writeln('=== Color Contrast Validation Report ===\n');
    buffer.writeln('WCAG 2.1 Standards:');
    buffer.writeln('  - AA Normal Text: 4.5:1');
    buffer.writeln('  - AA Large Text: 3.0:1');
    buffer.writeln('  - AAA Normal Text: 7.0:1\n');

    // Count results
    int totalTests = results.length;
    int passedAA = results.values.where((r) => r.meetsAA).length;
    int passedAAA = results.values.where((r) => r.meetsAAA).length;
    int failed = results.values.where((r) => !r.meetsAA).length;

    buffer.writeln('Summary:');
    buffer.writeln('  Total Tests: $totalTests');
    buffer.writeln('  Passed AA: $passedAA (${ (passedAA / totalTests * 100).toStringAsFixed(1)}%)');
    buffer.writeln('  Passed AAA: $passedAAA (${(passedAAA / totalTests * 100).toStringAsFixed(1)}%)');
    buffer.writeln('  Failed AA: $failed\n');

    // List all results
    buffer.writeln('Detailed Results:\n');
    
    // Group by status
    final passed = results.values.where((r) => r.meetsAA).toList();
    final failedList = results.values.where((r) => !r.meetsAA).toList();

    if (failedList.isNotEmpty) {
      buffer.writeln('❌ FAILED (Does not meet WCAG AA):');
      for (final result in failedList) {
        buffer.writeln('  ${result.name}');
        buffer.writeln('    Ratio: ${result.ratio.toStringAsFixed(2)}:1');
        buffer.writeln('    Foreground: ${_colorToHex(result.foreground)}');
        buffer.writeln('    Background: ${_colorToHex(result.background)}');
        buffer.writeln('    Recommendation: ${_getRecommendation(result)}');
        buffer.writeln();
      }
    }

    if (passed.isNotEmpty) {
      buffer.writeln('✅ PASSED (Meets WCAG AA):');
      for (final result in passed) {
        final aaaStatus = result.meetsAAA ? ' (AAA ✅)' : '';
        buffer.writeln('  ${result.name}: ${result.ratio.toStringAsFixed(2)}:1$aaaStatus');
      }
    }

    return buffer.toString();
  }

  /// Get recommendation for improving contrast
  static String _getRecommendation(ContrastResult result) {
    if (result.meetsAALargeText && !result.meetsAA) {
      return 'Use only for large text (18pt+ or 14pt+ bold)';
    }

    final targetRatio = 4.5;
    final currentRatio = result.ratio;
    final improvement = ((targetRatio / currentRatio - 1) * 100).toStringAsFixed(0);

    return 'Increase contrast by ~$improvement% or use alternative color';
  }

  /// Convert color to hex string
  static String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  /// Print report to console
  static void printReport() {
    // print(generateReport());
  }

  /// Get suggested text color for a background
  static Color getSuggestedTextColor(Color background) {
    return AccessibilityHelper.getAccessibleTextColor(background);
  }

  /// Adjust color to meet WCAG AA standards
  static Color adjustColorForWCAGAA(Color foreground, Color background) {
    return AccessibilityHelper.adjustColorForContrast(
      foreground,
      background,
    );
  }

  /// Check if a specific color combination is accessible
  static bool isAccessible(Color foreground, Color background) {
    return AccessibilityHelper.meetsWCAGAA(foreground, background);
  }

  /// Get all failing color combinations
  static List<ContrastResult> getFailingCombinations() {
    final results = validateDesignSystem();
    return results.values.where((r) => !r.meetsAA).toList();
  }

  /// Get all passing color combinations
  static List<ContrastResult> getPassingCombinations() {
    final results = validateDesignSystem();
    return results.values.where((r) => r.meetsAA).toList();
  }
}

/// Result of a contrast test
class ContrastResult {
  final String name;
  final Color foreground;
  final Color background;
  final double ratio;
  final bool meetsAA;
  final bool meetsAAA;
  final bool meetsAALargeText;

  ContrastResult({
    required this.name,
    required this.foreground,
    required this.background,
    required this.ratio,
    required this.meetsAA,
    required this.meetsAAA,
    required this.meetsAALargeText,
  });

  @override
  String toString() {
    return '$name: ${ratio.toStringAsFixed(2)}:1 '
        '(AA: ${meetsAA ? "✅" : "❌"}, '
        'AAA: ${meetsAAA ? "✅" : "❌"})';
  }
}

/// Widget to display contrast validation results (for debugging)
class ContrastValidationWidget extends StatelessWidget {
  const ContrastValidationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final results = ColorContrastValidator.validateDesignSystem();
    final failedResults = results.values.where((r) => !r.meetsAA).toList();
    final passedResults = results.values.where((r) => r.meetsAA).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Color Contrast Validation'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Summary',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('Total Tests: ${results.length}'),
                  Text('Passed AA: ${passedResults.length}'),
                  Text('Failed AA: ${failedResults.length}'),
                  Text(
                    'Compliance: ${(passedResults.length / results.length * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: failedResults.isEmpty ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Failed Results
          if (failedResults.isNotEmpty) ...[
            Text(
              '❌ Failed (${failedResults.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...failedResults.map((result) => _buildResultCard(context, result, false)),
            const SizedBox(height: 16),
          ],

          // Passed Results
          Text(
            '✅ Passed (${passedResults.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...passedResults.map((result) => _buildResultCard(context, result, true)),
        ],
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, ContrastResult result, bool passed) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    result.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${result.ratio.toStringAsFixed(2)}:1',
                  style: TextStyle(
                    color: passed ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildColorSwatch(result.foreground, 'FG'),
                const SizedBox(width: 8),
                const Text('on'),
                const SizedBox(width: 8),
                _buildColorSwatch(result.background, 'BG'),
              ],
            ),
            if (!passed) ...[
              const SizedBox(height: 8),
              Text(
                ColorContrastValidator._getRecommendation(result),
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.orange,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildColorSwatch(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
