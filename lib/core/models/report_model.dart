import 'package:cloud_firestore/cloud_firestore.dart';

/// Report model for content moderation
/// Collection: /reports
class ReportModel {
  final String id;
  final String reportType; // 'announcement' | 'assignment' | 'user' | 'other'
  final String reportedItemId; // ID of the reported content
  final String reporterId;
  final String reporterName;
  final String reason;
  final String? description;
  final String? screenshotUrl;
  final String status; // 'pending' | 'reviewed' | 'resolved' | 'dismissed'
  final DateTime reportedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy; // Admin/principal ID who reviewed
  final String? resolution;
  final String? contentCreatorId; // For Firebase security rules - allows teachers to see reports about their content
  final String? schoolId; // For Firebase security rules - allows principals to filter by school

  ReportModel({
    required this.id,
    required this.reportType,
    required this.reportedItemId,
    required this.reporterId,
    required this.reporterName,
    required this.reason,
    this.description,
    this.screenshotUrl,
    required this.status,
    required this.reportedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.resolution,
    this.contentCreatorId,
    this.schoolId,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'reportType': reportType,
      'reportedItemId': reportedItemId,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reason': reason,
      'description': description,
      'screenshotUrl': screenshotUrl,
      'status': status,
      'reportedAt': Timestamp.fromDate(reportedAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
      'resolution': resolution,
      'contentCreatorId': contentCreatorId,
      'schoolId': schoolId,
    };
  }

  /// Create from Firestore document
  factory ReportModel.fromFirestore(Map<String, dynamic> data) {
    return ReportModel(
      id: data['id'] as String,
      reportType: data['reportType'] as String,
      reportedItemId: data['reportedItemId'] as String,
      reporterId: data['reporterId'] as String,
      reporterName: data['reporterName'] as String,
      reason: data['reason'] as String,
      description: data['description'] as String?,
      screenshotUrl: data['screenshotUrl'] as String?,
      status: data['status'] as String,
      reportedAt: (data['reportedAt'] as Timestamp).toDate(),
      reviewedAt: data['reviewedAt'] != null 
          ? (data['reviewedAt'] as Timestamp).toDate() 
          : null,
      reviewedBy: data['reviewedBy'] as String?,
      resolution: data['resolution'] as String?,
      contentCreatorId: data['contentCreatorId'] as String?,
      schoolId: data['schoolId'] as String?,
    );
  }

  /// Create a copy with updated fields
  ReportModel copyWith({
    String? id,
    String? reportType,
    String? reportedItemId,
    String? reporterId,
    String? reporterName,
    String? reason,
    String? description,
    String? screenshotUrl,
    String? status,
    DateTime? reportedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? resolution,
    String? contentCreatorId,
    String? schoolId,
  }) {
    return ReportModel(
      id: id ?? this.id,
      reportType: reportType ?? this.reportType,
      reportedItemId: reportedItemId ?? this.reportedItemId,
      reporterId: reporterId ?? this.reporterId,
      reporterName: reporterName ?? this.reporterName,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      screenshotUrl: screenshotUrl ?? this.screenshotUrl,
      status: status ?? this.status,
      reportedAt: reportedAt ?? this.reportedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      resolution: resolution ?? this.resolution,
      contentCreatorId: contentCreatorId ?? this.contentCreatorId,
      schoolId: schoolId ?? this.schoolId,
    );
  }
}

/// Feedback model for user suggestions
/// Collection: /feedback
class FeedbackModel {
  final String id;
  final String userId;
  final String userName;
  final String category; // 'bug' | 'feature' | 'content' | 'other'
  final String title;
  final String message;
  final String status; // 'pending' | 'reviewed' | 'implemented' | 'rejected'
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? response;

  FeedbackModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.category,
    required this.title,
    required this.message,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.response,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'category': category,
      'title': title,
      'message': message,
      'status': status,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'response': response,
    };
  }

  /// Create from Firestore document
  factory FeedbackModel.fromFirestore(Map<String, dynamic> data) {
    return FeedbackModel(
      id: data['id'] as String,
      userId: data['userId'] as String,
      userName: data['userName'] as String,
      category: data['category'] as String,
      title: data['title'] as String,
      message: data['message'] as String,
      status: data['status'] as String,
      submittedAt: (data['submittedAt'] as Timestamp).toDate(),
      reviewedAt: data['reviewedAt'] != null 
          ? (data['reviewedAt'] as Timestamp).toDate() 
          : null,
      response: data['response'] as String?,
    );
  }

  /// Create a copy with updated fields
  FeedbackModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? category,
    String? title,
    String? message,
    String? status,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? response,
  }) {
    return FeedbackModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      category: category ?? this.category,
      title: title ?? this.title,
      message: message ?? this.message,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      response: response ?? this.response,
    );
  }
}

