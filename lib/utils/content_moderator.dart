import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/services/notification_service.dart';

/// Content moderation utility for scanning user-generated content
/// Implements requirement 59: Content Moderation and Safety
class ContentModerator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final NotificationService _notificationService = NotificationService();

  /// List of inappropriate keywords to flag
  /// This should ideally be maintained server-side or in a remote config
  static const List<String> inappropriateKeywords = [
    // Profanity and offensive language
    'abuse', 'assault', 'attack', 'bully', 'harass', 'hate', 'threat', 'violence',
    
    // Spam indicators
    'click here', 'buy now', 'limited offer', 'act now', 'free money',
    
    // Personal information requests (phishing)
    'send password', 'share password', 'bank account', 'credit card',
    'social security', 'aadhar number', 'pan card',
    
    // Inappropriate content
    'cheat', 'hack', 'exploit', 'pirate', 'crack',
    
    // Note: This is a basic list. In production, use a comprehensive
    // moderation service or maintain this list remotely
  ];

  /// Scan content for inappropriate keywords
  /// Returns true if inappropriate content is detected
  static bool containsInappropriateContent(String text) {
    if (text.trim().isEmpty) return false;
    
    final lowerText = text.toLowerCase();
    
    // Check for inappropriate keywords
    for (final keyword in inappropriateKeywords) {
      if (lowerText.contains(keyword.toLowerCase())) {
        return true;
      }
    }
    
    // Additional checks
    // Check for excessive caps (spam indicator)
    if (_hasExcessiveCaps(text)) {
      return true;
    }
    
    // Check for repeated characters (spam indicator)
    if (_hasRepeatedCharacters(text)) {
      return true;
    }
    
    return false;
  }

  /// Check if text has excessive capital letters (>70% caps)
  static bool _hasExcessiveCaps(String text) {
    if (text.length < 10) return false; // Too short to judge
    
    final capsCount = text.split('').where((c) => c == c.toUpperCase() && c != c.toLowerCase()).length;
    final letterCount = text.split('').where((c) => c != c.toLowerCase()).length;
    
    if (letterCount == 0) return false;
    
    return (capsCount / letterCount) > 0.7;
  }

  /// Check if text has repeated characters (e.g., "hellooooo")
  static bool _hasRepeatedCharacters(String text) {
    final pattern = RegExp(r'(.)\1{4,}'); // Same character repeated 5+ times
    return pattern.hasMatch(text);
  }

  /// Moderate content and flag if inappropriate
  /// This is the main method to call when user posts content
  static Future<ModerationResult> moderateContent({
    required String contentId,
    required String contentType, // 'announcement', 'assignment', 'message', 'comment'
    required String content,
    required String creatorId,
    String? classroomId,
    String? schoolId,
  }) async {
    try {
      // Check for inappropriate content
      final isInappropriate = containsInappropriateContent(content);
      
      if (isInappropriate) {
        // Flag content for review
        await _flagContent(
          contentId: contentId,
          contentType: contentType,
          content: content,
          creatorId: creatorId,
          classroomId: classroomId,
          schoolId: schoolId,
        );
        
        // Notify content creator
        await _notifyCreator(
          creatorId: creatorId,
          contentType: contentType,
        );
        
        return ModerationResult(
          isApproved: false,
          isFlagged: true,
          reason: 'Content contains inappropriate keywords or patterns',
        );
      }
      
      return ModerationResult(
        isApproved: true,
        isFlagged: false,
        reason: null,
      );
    } catch (e) {
      // print('Error moderating content: $e');
      // In case of error, allow content but log the error
      return ModerationResult(
        isApproved: true,
        isFlagged: false,
        reason: 'Moderation check failed',
      );
    }
  }

  /// Flag content for review
  static Future<void> _flagContent({
    required String contentId,
    required String contentType,
    required String content,
    required String creatorId,
    String? classroomId,
    String? schoolId,
  }) async {
    await _firestore.collection('flagged_content').add({
      'contentId': contentId,
      'contentType': contentType,
      'content': content,
      'creatorId': creatorId,
      'classroomId': classroomId,
      'schoolId': schoolId,
      'reason': 'Automatic moderation: Inappropriate keywords detected',
      'status': 'pending', // pending, reviewed, approved, rejected
      'flaggedBy': 'system',
      'flaggedAt': Timestamp.now(),
      'reviewedBy': null,
      'reviewedAt': null,
      'reviewNotes': null,
    });
  }

  /// Notify content creator that their content was flagged
  static Future<void> _notifyCreator({
    required String creatorId,
    required String contentType,
  }) async {
    await _notificationService.sendToUser(
      userId: creatorId,
      title: 'Content Flagged for Review',
      body: 'Your $contentType has been flagged for review. Please ensure all content follows community guidelines.',
      data: {
        'type': 'content_flagged',
        'contentType': contentType,
      },
    );
  }

  /// Report content (user-initiated)
  /// Allows users to report inappropriate content they see
  static Future<void> reportContent({
    required String contentId,
    required String contentType,
    required String content,
    required String creatorId,
    required String reporterId,
    required String reason,
    String? classroomId,
    String? schoolId,
  }) async {
    try {
      // Check if already reported by this user
      final existingReport = await _firestore
          .collection('reports')
          .where('contentId', isEqualTo: contentId)
          .where('reporterId', isEqualTo: reporterId)
          .get();

      if (existingReport.docs.isNotEmpty) {
        throw Exception('You have already reported this content');
      }

      // Create report
      final reportRef = await _firestore.collection('reports').add({
        'contentId': contentId,
        'contentType': contentType,
        'content': content,
        'creatorId': creatorId,
        'reporterId': reporterId,
        'reason': reason,
        'classroomId': classroomId,
        'schoolId': schoolId,
        'status': 'pending', // pending, under_review, resolved, dismissed
        'reportedAt': Timestamp.now(),
        'reviewedBy': null,
        'reviewedAt': null,
        'resolution': null,
        'resolutionNotes': null,
      });

      // Check if content has been reported multiple times
      final allReports = await _firestore
          .collection('reports')
          .where('contentId', isEqualTo: contentId)
          .where('status', isEqualTo: 'pending')
          .get();

      // If reported 3+ times, auto-hide and escalate
      if (allReports.docs.length >= 3) {
        await _autoHideContent(contentId, contentType);
        await _escalateReport(
          contentId: contentId,
          contentType: contentType,
          reportCount: allReports.docs.length,
          schoolId: schoolId,
        );
      }

      // Notify appropriate reviewer based on content type and school structure
      await _notifyReviewer(
        reportId: reportRef.id,
        contentType: contentType,
        creatorId: creatorId,
        classroomId: classroomId,
        schoolId: schoolId,
      );
    } catch (e) {
      // print('Error reporting content: $e');
      rethrow;
    }
  }

  /// Auto-hide content that has been reported multiple times
  static Future<void> _autoHideContent(String contentId, String contentType) async {
    try {
      // Mark content as hidden in the appropriate collection
      String collection;
      switch (contentType) {
        case 'announcement':
          collection = 'announcements';
          break;
        case 'assignment':
          collection = 'assignments';
          break;
        case 'message':
          collection = 'messages';
          break;
        default:
          return;
      }

      await _firestore.collection(collection).doc(contentId).update({
        'hidden': true,
        'hiddenReason': 'Multiple reports received',
        'hiddenAt': Timestamp.now(),
      });
    } catch (e) {
      // print('Error auto-hiding content: $e');
    }
  }

  /// Escalate report to appropriate authority
  static Future<void> _escalateReport({
    required String contentId,
    required String contentType,
    required int reportCount,
    String? schoolId,
  }) async {
    // Notify school principal if available
    if (schoolId != null) {
      final principals = await _firestore
          .collection('users')
          .where('schoolId', isEqualTo: schoolId)
          .where('isPrincipal', isEqualTo: true)
          .get();

      for (var principal in principals.docs) {
        await _notificationService.sendToUser(
          userId: principal.id,
          title: 'Content Escalated for Review',
          body: 'A $contentType has been reported $reportCount times and requires immediate review.',
          data: {
            'type': 'escalated_report',
            'contentId': contentId,
            'contentType': contentType,
            'reportCount': reportCount,
          },
        );
      }
    }
  }

  /// Notify appropriate reviewer based on escalation hierarchy
  /// Student reports → Teacher → Principal → Admin
  static Future<void> _notifyReviewer({
    required String reportId,
    required String contentType,
    required String creatorId,
    String? classroomId,
    String? schoolId,
  }) async {
    try {
      // Get creator info to determine reviewer
      final creatorDoc = await _firestore.collection('users').doc(creatorId).get();
      final creatorRole = creatorDoc.data()?['role'] as String?;

      List<String> reviewerIds = [];

      // If creator is a student, notify their teacher
      if (creatorRole == 'student' && classroomId != null) {
        final classroom = await _firestore.collection('classrooms').doc(classroomId).get();
        final teacherId = classroom.data()?['teacherId'] as String?;
        if (teacherId != null) {
          reviewerIds.add(teacherId);
        }
      }

      // Also notify principal if school exists
      if (schoolId != null) {
        final principals = await _firestore
            .collection('users')
            .where('schoolId', isEqualTo: schoolId)
            .where('isPrincipal', isEqualTo: true)
            .get();

        for (var principal in principals.docs) {
          reviewerIds.add(principal.id);
        }
      }

      // Send notifications to reviewers
      for (var reviewerId in reviewerIds) {
        await _notificationService.sendToUser(
          userId: reviewerId,
          title: 'Content Reported',
          body: 'A $contentType has been reported and requires your review.',
          data: {
            'type': 'content_report',
            'reportId': reportId,
            'contentType': contentType,
          },
        );
      }
    } catch (e) {
      // print('Error notifying reviewer: $e');
    }
  }

  /// Get pending reports for review (for teachers/principals)
  static Stream<QuerySnapshot> getPendingReportsStream({
    String? schoolId,
    String? classroomId,
  }) {
    Query query = _firestore
        .collection('reports')
        .where('status', isEqualTo: 'pending')
        .orderBy('reportedAt', descending: true);

    if (schoolId != null) {
      query = query.where('schoolId', isEqualTo: schoolId);
    }

    if (classroomId != null) {
      query = query.where('classroomId', isEqualTo: classroomId);
    }

    return query.snapshots();
  }

  /// Get flagged content stream (for teachers/principals)
  static Stream<QuerySnapshot> getFlaggedContentStream({
    String? schoolId,
    String? classroomId,
  }) {
    Query query = _firestore
        .collection('flagged_content')
        .where('status', isEqualTo: 'pending')
        .orderBy('flaggedAt', descending: true);

    if (schoolId != null) {
      query = query.where('schoolId', isEqualTo: schoolId);
    }

    if (classroomId != null) {
      query = query.where('classroomId', isEqualTo: classroomId);
    }

    return query.snapshots();
  }
}

/// Result of content moderation
class ModerationResult {
  final bool isApproved;
  final bool isFlagged;
  final String? reason;

  ModerationResult({
    required this.isApproved,
    required this.isFlagged,
    this.reason,
  });
}
