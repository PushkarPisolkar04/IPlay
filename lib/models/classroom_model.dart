import 'package:cloud_firestore/cloud_firestore.dart';

class ClassroomModel {
  final String id;
  final String name;
  final String teacherId;
  final String teacherName;
  final String joinCode;
  final List<String> studentIds;
  final List<String> pendingStudentIds;
  final String? school;
  final int grade;
  final bool requiresApproval;
  final DateTime codeExpiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  ClassroomModel({
    required this.id,
    required this.name,
    required this.teacherId,
    required this.teacherName,
    required this.joinCode,
    this.studentIds = const [],
    this.pendingStudentIds = const [],
    this.school,
    required this.grade,
    this.requiresApproval = true,
    required this.codeExpiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'joinCode': joinCode,
      'studentIds': studentIds,
      'pendingStudentIds': pendingStudentIds,
      'school': school,
      'grade': grade,
      'requiresApproval': requiresApproval,
      'codeExpiresAt': Timestamp.fromDate(codeExpiresAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ClassroomModel.fromMap(Map<String, dynamic> map) {
    return ClassroomModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      teacherId: map['teacherId'] ?? '',
      teacherName: map['teacherName'] ?? '',
      joinCode: map['joinCode'] ?? map['classCode'] ?? '',  // Support both for backwards compatibility
      studentIds: List<String>.from(map['studentIds'] ?? []),
      pendingStudentIds: List<String>.from(map['pendingStudentIds'] ?? []),
      school: map['school'],
      grade: map['grade'] ?? 6,
      requiresApproval: map['requiresApproval'] ?? true,
      codeExpiresAt: (map['codeExpiresAt'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  ClassroomModel copyWith({
    String? id,
    String? name,
    String? teacherId,
    String? teacherName,
    String? joinCode,
    List<String>? studentIds,
    List<String>? pendingStudentIds,
    String? school,
    int? grade,
    bool? requiresApproval,
    DateTime? codeExpiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClassroomModel(
      id: id ?? this.id,
      name: name ?? this.name,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      joinCode: joinCode ?? this.joinCode,
      studentIds: studentIds ?? this.studentIds,
      pendingStudentIds: pendingStudentIds ?? this.pendingStudentIds,
      school: school ?? this.school,
      grade: grade ?? this.grade,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      codeExpiresAt: codeExpiresAt ?? this.codeExpiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

