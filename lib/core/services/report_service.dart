import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/report_model.dart';

/// Service for content reporting and moderation
class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ========== REPORT OPERATIONS ==========

  /// Submit a content report
  Future<ReportModel> submitReport({
    required String reportType,
    required String reportedItemId,
    required String reporterId,
    required String reporterName,
    required String reason,
    String? description,
    String? screenshotUrl,
  }) async {
    try {
      final report = ReportModel(
        id: _uuid.v4(),
        reportType: reportType,
        reportedItemId: reportedItemId,
        reporterId: reporterId,
        reporterName: reporterName,
        reason: reason,
        description: description,
        screenshotUrl: screenshotUrl,
        status: 'pending',
        reportedAt: DateTime.now(),
      );

      await _firestore
          .collection('reports')
          .doc(report.id)
          .set(report.toFirestore());

      return report;
    } catch (e) {
      throw Exception('Failed to submit report: $e');
    }
  }

  /// Get report by ID
  Future<ReportModel?> getReport(String reportId) async {
    try {
      final doc = await _firestore
          .collection('reports')
          .doc(reportId)
          .get();

      if (!doc.exists) return null;

      return ReportModel.fromFirestore(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get report: $e');
    }
  }

  /// Get pending reports
  Future<List<ReportModel>> getPendingReports({int limit = 50}) async {
    try {
      final query = await _firestore
          .collection('reports')
          .where('status', isEqualTo: 'pending')
          .orderBy('reportedAt', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => ReportModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get pending reports: $e');
    }
  }

  /// Get all reports by type
  Future<List<ReportModel>> getReportsByType(String reportType) async {
    try {
      final query = await _firestore
          .collection('reports')
          .where('reportType', isEqualTo: reportType)
          .orderBy('reportedAt', descending: true)
          .get();

      return query.docs
          .map((doc) => ReportModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get reports by type: $e');
    }
  }

  /// Get reports by reporter
  Future<List<ReportModel>> getReportsByReporter(String reporterId) async {
    try {
      final query = await _firestore
          .collection('reports')
          .where('reporterId', isEqualTo: reporterId)
          .orderBy('reportedAt', descending: true)
          .get();

      return query.docs
          .map((doc) => ReportModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get reports by reporter: $e');
    }
  }

  /// Update report status (review, resolve, dismiss)
  Future<void> updateReportStatus({
    required String reportId,
    required String status,
    required String reviewedBy,
    String? resolution,
  }) async {
    try {
      await _firestore
          .collection('reports')
          .doc(reportId)
          .update({
        'status': status,
        'reviewedAt': Timestamp.now(),
        'reviewedBy': reviewedBy,
        'resolution': resolution,
      });
    } catch (e) {
      throw Exception('Failed to update report status: $e');
    }
  }

  /// Get report statistics
  Future<Map<String, dynamic>> getReportStats() async {
    try {
      final allReports = await _firestore.collection('reports').get();
      
      final totalReports = allReports.docs.length;
      final pendingReports = allReports.docs.where((d) => d.data()['status'] == 'pending').length;
      final reviewedReports = allReports.docs.where((d) => d.data()['status'] == 'reviewed').length;
      final resolvedReports = allReports.docs.where((d) => d.data()['status'] == 'resolved').length;
      final dismissedReports = allReports.docs.where((d) => d.data()['status'] == 'dismissed').length;

      return {
        'totalReports': totalReports,
        'pendingReports': pendingReports,
        'reviewedReports': reviewedReports,
        'resolvedReports': resolvedReports,
        'dismissedReports': dismissedReports,
      };
    } catch (e) {
      throw Exception('Failed to get report stats: $e');
    }
  }

  // ========== FEEDBACK OPERATIONS ==========

  /// Submit user feedback
  Future<FeedbackModel> submitFeedback({
    required String userId,
    required String userName,
    required String category,
    required String title,
    required String message,
  }) async {
    try {
      final feedback = FeedbackModel(
        id: _uuid.v4(),
        userId: userId,
        userName: userName,
        category: category,
        title: title,
        message: message,
        status: 'pending',
        submittedAt: DateTime.now(),
      );

      await _firestore
          .collection('feedback')
          .doc(feedback.id)
          .set(feedback.toFirestore());

      return feedback;
    } catch (e) {
      throw Exception('Failed to submit feedback: $e');
    }
  }

  /// Get feedback by ID
  Future<FeedbackModel?> getFeedback(String feedbackId) async {
    try {
      final doc = await _firestore
          .collection('feedback')
          .doc(feedbackId)
          .get();

      if (!doc.exists) return null;

      return FeedbackModel.fromFirestore(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get feedback: $e');
    }
  }

  /// Get pending feedback
  Future<List<FeedbackModel>> getPendingFeedback({int limit = 50}) async {
    try {
      final query = await _firestore
          .collection('feedback')
          .where('status', isEqualTo: 'pending')
          .orderBy('submittedAt', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => FeedbackModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get pending feedback: $e');
    }
  }

  /// Get feedback by category
  Future<List<FeedbackModel>> getFeedbackByCategory(String category) async {
    try {
      final query = await _firestore
          .collection('feedback')
          .where('category', isEqualTo: category)
          .orderBy('submittedAt', descending: true)
          .get();

      return query.docs
          .map((doc) => FeedbackModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get feedback by category: $e');
    }
  }

  /// Get feedback by user
  Future<List<FeedbackModel>> getUserFeedback(String userId) async {
    try {
      final query = await _firestore
          .collection('feedback')
          .where('userId', isEqualTo: userId)
          .orderBy('submittedAt', descending: true)
          .get();

      return query.docs
          .map((doc) => FeedbackModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user feedback: $e');
    }
  }

  /// Update feedback status and add response
  Future<void> updateFeedbackStatus({
    required String feedbackId,
    required String status,
    String? response,
  }) async {
    try {
      await _firestore
          .collection('feedback')
          .doc(feedbackId)
          .update({
        'status': status,
        'reviewedAt': Timestamp.now(),
        'response': response,
      });
    } catch (e) {
      throw Exception('Failed to update feedback status: $e');
    }
  }

  /// Get feedback statistics
  Future<Map<String, dynamic>> getFeedbackStats() async {
    try {
      final allFeedback = await _firestore.collection('feedback').get();
      
      final totalFeedback = allFeedback.docs.length;
      final pendingFeedback = allFeedback.docs.where((d) => d.data()['status'] == 'pending').length;
      final reviewedFeedback = allFeedback.docs.where((d) => d.data()['status'] == 'reviewed').length;
      final implementedFeedback = allFeedback.docs.where((d) => d.data()['status'] == 'implemented').length;
      final rejectedFeedback = allFeedback.docs.where((d) => d.data()['status'] == 'rejected').length;

      // Count by category
      final bugReports = allFeedback.docs.where((d) => d.data()['category'] == 'bug').length;
      final featureRequests = allFeedback.docs.where((d) => d.data()['category'] == 'feature').length;
      final contentSuggestions = allFeedback.docs.where((d) => d.data()['category'] == 'content').length;
      final otherFeedback = allFeedback.docs.where((d) => d.data()['category'] == 'other').length;

      return {
        'totalFeedback': totalFeedback,
        'pendingFeedback': pendingFeedback,
        'reviewedFeedback': reviewedFeedback,
        'implementedFeedback': implementedFeedback,
        'rejectedFeedback': rejectedFeedback,
        'byCategory': {
          'bug': bugReports,
          'feature': featureRequests,
          'content': contentSuggestions,
          'other': otherFeedback,
        },
      };
    } catch (e) {
      throw Exception('Failed to get feedback stats: $e');
    }
  }
}

