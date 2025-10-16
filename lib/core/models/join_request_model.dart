import 'package:cloud_firestore/cloud_firestore.dart';

/// Join request model for classroom approval workflow
/// Collection: /join_requests
class JoinRequestModel {
  final String id;
  final String classroomId;
  final String studentId;
  final String studentName;
  final String status; // 'pending' | 'approved' | 'rejected'
  final DateTime requestedAt;
  final DateTime? resolvedAt;
  final String? resolvedBy; // teacherId who approved/rejected
  final String? rejectReason;

  JoinRequestModel({
    required this.id,
    required this.classroomId,
    required this.studentId,
    required this.studentName,
    required this.status,
    required this.requestedAt,
    this.resolvedAt,
    this.resolvedBy,
    this.rejectReason,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'classroomId': classroomId,
      'studentId': studentId,
      'studentName': studentName,
      'status': status,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolvedBy': resolvedBy,
      'rejectReason': rejectReason,
    };
  }

  /// Create from Firestore document
  factory JoinRequestModel.fromFirestore(Map<String, dynamic> data) {
    return JoinRequestModel(
      id: data['id'] as String,
      classroomId: data['classroomId'] as String,
      studentId: data['studentId'] as String,
      studentName: data['studentName'] as String,
      status: data['status'] as String,
      requestedAt: (data['requestedAt'] as Timestamp).toDate(),
      resolvedAt: data['resolvedAt'] != null 
          ? (data['resolvedAt'] as Timestamp).toDate() 
          : null,
      resolvedBy: data['resolvedBy'] as String?,
      rejectReason: data['rejectReason'] as String?,
    );
  }

  /// Create a copy with updated fields
  JoinRequestModel copyWith({
    String? id,
    String? classroomId,
    String? studentId,
    String? studentName,
    String? status,
    DateTime? requestedAt,
    DateTime? resolvedAt,
    String? resolvedBy,
    String? rejectReason,
  }) {
    return JoinRequestModel(
      id: id ?? this.id,
      classroomId: classroomId ?? this.classroomId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      rejectReason: rejectReason ?? this.rejectReason,
    );
  }
}

