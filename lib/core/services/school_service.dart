import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import '../models/school_model.dart';

/// Service for school CRUD operations
class SchoolService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  /// Generate unique school code - Format: SCH-XXXXX (5 random alphanumeric chars)
  String _generateSchoolCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    final code = List.generate(5, (index) => chars[random.nextInt(chars.length)]).join();
    return 'SCH-$code';
  }

  /// Create a new school
  Future<SchoolModel> createSchool({
    required String name,
    required String state,
    required String principalId,
    String? city,
    String? logoUrl,
  }) async {
    try {
      final schoolCode = _generateSchoolCode();
      final now = DateTime.now();

      final school = SchoolModel(
        id: _uuid.v4(),
        name: name,
        state: state,
        city: city,
        schoolCode: schoolCode,
        principalId: principalId,
        teacherIds: [],
        classroomIds: [],
        logoUrl: logoUrl,
        createdAt: now,
        updatedAt: now,
        isActive: true,
      );

      await _firestore
          .collection('schools')
          .doc(school.id)
          .set(school.toFirestore());

      // Update user document to mark as principal of this school
      await _firestore
          .collection('users')
          .doc(principalId)
          .update({
        'isPrincipal': true,
        'principalOfSchool': school.id,
      });

      return school;
    } catch (e) {
      throw Exception('Failed to create school: $e');
    }
  }

  /// Get school by ID
  Future<SchoolModel?> getSchool(String schoolId) async {
    try {
      final doc = await _firestore
          .collection('schools')
          .doc(schoolId)
          .get();

      if (!doc.exists) return null;

      return SchoolModel.fromFirestore(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get school: $e');
    }
  }

  /// Get school by code
  Future<SchoolModel?> getSchoolByCode(String schoolCode) async {
    try {
      final query = await _firestore
          .collection('schools')
          .where('schoolCode', isEqualTo: schoolCode.toUpperCase())
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      return SchoolModel.fromFirestore(query.docs.first.data());
    } catch (e) {
      throw Exception('Failed to get school by code: $e');
    }
  }

  /// Get school by principal ID
  Future<SchoolModel?> getSchoolByPrincipal(String principalId) async {
    try {
      final query = await _firestore
          .collection('schools')
          .where('principalId', isEqualTo: principalId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      return SchoolModel.fromFirestore(query.docs.first.data());
    } catch (e) {
      throw Exception('Failed to get school by principal: $e');
    }
  }

  /// Get schools by state
  Future<List<SchoolModel>> getSchoolsByState(String state) async {
    try {
      final query = await _firestore
          .collection('schools')
          .where('state', isEqualTo: state)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return query.docs
          .map((doc) => SchoolModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get schools by state: $e');
    }
  }

  /// Update school details
  Future<void> updateSchool(String schoolId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.now();
      
      await _firestore
          .collection('schools')
          .doc(schoolId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update school: $e');
    }
  }

  /// Add teacher to school
  Future<void> addTeacher(String schoolId, String teacherId) async {
    try {
      await _firestore
          .collection('schools')
          .doc(schoolId)
          .update({
        'teacherIds': FieldValue.arrayUnion([teacherId]),
        'updatedAt': Timestamp.now(),
      });

      // Update teacher's user document
      await _firestore
          .collection('users')
          .doc(teacherId)
          .update({
        'schoolTag': schoolId,
      });
    } catch (e) {
      throw Exception('Failed to add teacher to school: $e');
    }
  }

  /// Remove teacher from school
  Future<void> removeTeacher(String schoolId, String teacherId) async {
    try {
      await _firestore
          .collection('schools')
          .doc(schoolId)
          .update({
        'teacherIds': FieldValue.arrayRemove([teacherId]),
        'updatedAt': Timestamp.now(),
      });

      // Update teacher's user document
      await _firestore
          .collection('users')
          .doc(teacherId)
          .update({
        'schoolTag': FieldValue.delete(),
      });
    } catch (e) {
      throw Exception('Failed to remove teacher from school: $e');
    }
  }

  /// Add classroom to school
  Future<void> addClassroom(String schoolId, String classroomId) async {
    try {
      await _firestore
          .collection('schools')
          .doc(schoolId)
          .update({
        'classroomIds': FieldValue.arrayUnion([classroomId]),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to add classroom to school: $e');
    }
  }

  /// Remove classroom from school
  Future<void> removeClassroom(String schoolId, String classroomId) async {
    try {
      await _firestore
          .collection('schools')
          .doc(schoolId)
          .update({
        'classroomIds': FieldValue.arrayRemove([classroomId]),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to remove classroom from school: $e');
    }
  }

  /// Deactivate school (soft delete)
  Future<void> deactivateSchool(String schoolId) async {
    try {
      await _firestore
          .collection('schools')
          .doc(schoolId)
          .update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to deactivate school: $e');
    }
  }

  /// Transfer school ownership to new principal
  Future<void> transferOwnership({
    required String schoolId,
    required String oldPrincipalId,
    required String newPrincipalId,
  }) async {
    try {
      final batch = _firestore.batch();

      // Update school document
      batch.update(
        _firestore.collection('schools').doc(schoolId),
        {
          'principalId': newPrincipalId,
          'updatedAt': Timestamp.now(),
        },
      );

      // Update old principal's user document
      batch.update(
        _firestore.collection('users').doc(oldPrincipalId),
        {
          'isPrincipal': false,
          'principalOfSchool': FieldValue.delete(),
        },
      );

      // Update new principal's user document
      batch.update(
        _firestore.collection('users').doc(newPrincipalId),
        {
          'isPrincipal': true,
          'principalOfSchool': schoolId,
        },
      );

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to transfer school ownership: $e');
    }
  }

  /// Get school analytics
  Future<Map<String, dynamic>> getSchoolAnalytics(String schoolId) async {
    try {
      final school = await getSchool(schoolId);
      if (school == null) {
        throw Exception('School not found');
      }

      // Get total students across all classrooms
      int totalStudents = 0;
      for (final classroomId in school.classroomIds) {
        final classroom = await _firestore
            .collection('classrooms')
            .doc(classroomId)
            .get();
        
        if (classroom.exists) {
          final studentIds = classroom.data()?['studentIds'] as List?;
          totalStudents += studentIds?.length ?? 0;
        }
      }

      return {
        'totalTeachers': school.teacherIds.length,
        'totalClassrooms': school.classroomIds.length,
        'totalStudents': totalStudents,
        'schoolName': school.name,
        'schoolCode': school.schoolCode,
      };
    } catch (e) {
      throw Exception('Failed to get school analytics: $e');
    }
  }
}

