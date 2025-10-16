import 'package:cloud_firestore/cloud_firestore.dart';

/// Assignment model for teachers
/// Collection: /assignments
class AssignmentModel {
  final String id;
  final String classroomId;
  final String teacherId;
  final String teacherName;
  final String title;
  final String description;
  final DateTime dueDate;
  final int maxPoints;
  final List<String>? attachmentUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  AssignmentModel({
    required this.id,
    required this.classroomId,
    required this.teacherId,
    required this.teacherName,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.maxPoints,
    this.attachmentUrls,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'classroomId': classroomId,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'maxPoints': maxPoints,
      'attachmentUrls': attachmentUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  /// Create from Firestore document
  factory AssignmentModel.fromFirestore(Map<String, dynamic> data) {
    return AssignmentModel(
      id: data['id'] as String,
      classroomId: data['classroomId'] as String,
      teacherId: data['teacherId'] as String,
      teacherName: data['teacherName'] as String,
      title: data['title'] as String,
      description: data['description'] as String,
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      maxPoints: data['maxPoints'] as int,
      attachmentUrls: data['attachmentUrls'] != null 
          ? List<String>.from(data['attachmentUrls']) 
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  /// Create a copy with updated fields
  AssignmentModel copyWith({
    String? id,
    String? classroomId,
    String? teacherId,
    String? teacherName,
    String? title,
    String? description,
    DateTime? dueDate,
    int? maxPoints,
    List<String>? attachmentUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return AssignmentModel(
      id: id ?? this.id,
      classroomId: classroomId ?? this.classroomId,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      maxPoints: maxPoints ?? this.maxPoints,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Assignment submission model for students
/// Collection: /assignment_submissions
class AssignmentSubmissionModel {
  final String id;
  final String assignmentId;
  final String studentId;
  final String studentName;
  final String submissionText;
  final List<String>? attachmentUrls;
  final DateTime submittedAt;
  final int? score;
  final String? feedback;
  final DateTime? gradedAt;
  final String? gradedBy; // teacherId

  AssignmentSubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.studentName,
    required this.submissionText,
    this.attachmentUrls,
    required this.submittedAt,
    this.score,
    this.feedback,
    this.gradedAt,
    this.gradedBy,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'assignmentId': assignmentId,
      'studentId': studentId,
      'studentName': studentName,
      'submissionText': submissionText,
      'attachmentUrls': attachmentUrls,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'score': score,
      'feedback': feedback,
      'gradedAt': gradedAt != null ? Timestamp.fromDate(gradedAt!) : null,
      'gradedBy': gradedBy,
    };
  }

  /// Create from Firestore document
  factory AssignmentSubmissionModel.fromFirestore(Map<String, dynamic> data) {
    return AssignmentSubmissionModel(
      id: data['id'] as String,
      assignmentId: data['assignmentId'] as String,
      studentId: data['studentId'] as String,
      studentName: data['studentName'] as String,
      submissionText: data['submissionText'] as String,
      attachmentUrls: data['attachmentUrls'] != null 
          ? List<String>.from(data['attachmentUrls']) 
          : null,
      submittedAt: (data['submittedAt'] as Timestamp).toDate(),
      score: data['score'] as int?,
      feedback: data['feedback'] as String?,
      gradedAt: data['gradedAt'] != null 
          ? (data['gradedAt'] as Timestamp).toDate() 
          : null,
      gradedBy: data['gradedBy'] as String?,
    );
  }

  /// Create a copy with updated fields
  AssignmentSubmissionModel copyWith({
    String? id,
    String? assignmentId,
    String? studentId,
    String? studentName,
    String? submissionText,
    List<String>? attachmentUrls,
    DateTime? submittedAt,
    int? score,
    String? feedback,
    DateTime? gradedAt,
    String? gradedBy,
  }) {
    return AssignmentSubmissionModel(
      id: id ?? this.id,
      assignmentId: assignmentId ?? this.assignmentId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      submissionText: submissionText ?? this.submissionText,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      submittedAt: submittedAt ?? this.submittedAt,
      score: score ?? this.score,
      feedback: feedback ?? this.feedback,
      gradedAt: gradedAt ?? this.gradedAt,
      gradedBy: gradedBy ?? this.gradedBy,
    );
  }
}

