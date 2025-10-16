import 'package:cloud_firestore/cloud_firestore.dart';

/// School model matching Firestore schema
/// Collection: /schools
class SchoolModel {
  final String id;
  final String name;
  final String state;
  final String? city;
  final String schoolCode; // Format: SCH-XXXXX
  final String principalId;
  final List<String> teacherIds;
  final List<String> classroomIds;
  final String? logoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  SchoolModel({
    required this.id,
    required this.name,
    required this.state,
    this.city,
    required this.schoolCode,
    required this.principalId,
    this.teacherIds = const [],
    this.classroomIds = const [],
    this.logoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'state': state,
      'city': city,
      'schoolCode': schoolCode,
      'principalId': principalId,
      'teacherIds': teacherIds,
      'classroomIds': classroomIds,
      'logoUrl': logoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  /// Create from Firestore document
  factory SchoolModel.fromFirestore(Map<String, dynamic> data) {
    return SchoolModel(
      id: data['id'] as String,
      name: data['name'] as String,
      state: data['state'] as String,
      city: data['city'] as String?,
      schoolCode: data['schoolCode'] as String,
      principalId: data['principalId'] as String,
      teacherIds: List<String>.from(data['teacherIds'] ?? []),
      classroomIds: List<String>.from(data['classroomIds'] ?? []),
      logoUrl: data['logoUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  /// Create a copy with updated fields
  SchoolModel copyWith({
    String? id,
    String? name,
    String? state,
    String? city,
    String? schoolCode,
    String? principalId,
    List<String>? teacherIds,
    List<String>? classroomIds,
    String? logoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return SchoolModel(
      id: id ?? this.id,
      name: name ?? this.name,
      state: state ?? this.state,
      city: city ?? this.city,
      schoolCode: schoolCode ?? this.schoolCode,
      principalId: principalId ?? this.principalId,
      teacherIds: teacherIds ?? this.teacherIds,
      classroomIds: classroomIds ?? this.classroomIds,
      logoUrl: logoUrl ?? this.logoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

