import 'package:flutter/foundation.dart';

/// Service for content moderation and filtering
class ModerationService {
  static final ModerationService _instance = ModerationService._internal();
  factory ModerationService() => _instance;
  ModerationService._internal();

  /// List of inappropriate words to filter
  static const List<String> _bannedWords = [
    // Add banned words here as needed
    'spam',
    'inappropriate',
  ];

  /// Check if text contains inappropriate content
  bool containsInappropriateContent(String text) {
    if (text.isEmpty) return false;
    
    final lowerText = text.toLowerCase();
    return _bannedWords.any((word) => lowerText.contains(word.toLowerCase()));
  }

  /// Check if text contains profanity (alias for containsInappropriateContent)
  Future<bool> containsProfanity(String text) async {
    return containsInappropriateContent(text);
  }

  /// Filter inappropriate content from text
  String filterContent(String text) {
    if (text.isEmpty) return text;
    
    String filteredText = text;
    for (final word in _bannedWords) {
      final regex = RegExp(word, caseSensitive: false);
      filteredText = filteredText.replaceAll(regex, '*' * word.length);
    }
    
    return filteredText;
  }

  /// Validate content before posting
  Future<bool> validateContent(String content) async {
    try {
      // Basic validation
      if (content.trim().isEmpty) return false;
      if (content.length > 5000) return false; // Max length check
      
      // Check for inappropriate content
      if (containsInappropriateContent(content)) {
        if (kDebugMode) {
          print('Content rejected: Contains inappropriate content');
        }
        return false;
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error validating content: $e');
      }
      return false;
    }
  }

  /// Report content for review
  Future<void> reportContent({
    required String contentId,
    required String contentType,
    required String reason,
    String? additionalInfo,
  }) async {
    try {
      // In a real implementation, this would send the report to a backend service
      if (kDebugMode) {
        print('Content reported: $contentId ($contentType) - Reason: $reason');
        if (additionalInfo != null) {
          print('Additional info: $additionalInfo');
        }
      }
      
      // For now, just log the report
      // TODO: Implement actual reporting mechanism
    } catch (e) {
      if (kDebugMode) {
        print('Error reporting content: $e');
      }
      rethrow;
    }
  }

  /// Create a report (alias for reportContent)
  Future<void> createReport({
    required String contentId,
    required String contentType,
    required String reason,
    String? additionalInfo,
  }) async {
    return reportContent(
      contentId: contentId,
      contentType: contentType,
      reason: reason,
      additionalInfo: additionalInfo,
    );
  }

  /// Get content safety guidelines
  List<String> getContentGuidelines() {
    return [
      'Be respectful and kind to others',
      'No inappropriate language or content',
      'Stay on topic and relevant',
      'No spam or repetitive content',
      'Respect intellectual property rights',
      'Follow community standards',
    ];
  }

  /// Check if user can post content (rate limiting, etc.)
  Future<bool> canUserPost(String userId) async {
    try {
      // Basic rate limiting check
      // In a real implementation, this would check against a database
      // For now, always allow posting
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking user post permissions: $e');
      }
      return false;
    }
  }
}