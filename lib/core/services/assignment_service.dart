import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/assignment_model.dart';

/// Service for assignments and submissions
class AssignmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  /// Create a new assignment
  Future<AssignmentModel> createAssignment({
    required String classroomId,
    required String teacherId,
    required String teacherName,
    required String title,
    required String description,
    required DateTime dueDate,
    required int maxPoints,
    List<String>? attachmentUrls,
    String? schoolId, // Added for Firebase security rules
  }) async {
    try {
      final now = DateTime.now();

      final assignment = AssignmentModel(
        id: _uuid.v4(),
        classroomId: classroomId,
        teacherId: teacherId,
        teacherName: teacherName,
        title: title,
        description: description,
        dueDate: dueDate,
        maxPoints: maxPoints,
        attachmentUrls: attachmentUrls,
        createdAt: now,
        updatedAt: now,
        isActive: true,
        createdBy: teacherId, // Set for Firebase security rules
        schoolId: schoolId, // Set for principal access
      );

      await _firestore
          .collection('assignments')
          .doc(assignment.id)
          .set(assignment.toFirestore());

      return assignment;
    } catch (e) {
      throw Exception('Failed to create assignment: $e');
    }
  }

  /// Get assignment by ID
  Future<AssignmentModel?> getAssignment(String assignmentId) async {
    try {
      final doc = await _firestore
          .collection('assignments')
          .doc(assignmentId)
          .get();

      if (!doc.exists) return null;

      return AssignmentModel.fromFirestore(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get assignment: $e');
    }
  }

  /// Get assignment by ID (throws if not found)
  Future<AssignmentModel> getAssignmentById(String assignmentId) async {
    final assignment = await getAssignment(assignmentId);
    if (assignment == null) {
      throw Exception('Assignment not found');
    }
    return assignment;
  }

  /// Get all assignments for a classroom
  Future<List<AssignmentModel>> getClassroomAssignments(String classroomId) async {
    try {
      final query = await _firestore
          .collection('assignments')
          .where('classroomId', isEqualTo: classroomId)
          .where('isActive', isEqualTo: true)
          .orderBy('dueDate', descending: false)
          .get();

      return query.docs
          .map((doc) => AssignmentModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get classroom assignments: $e');
    }
  }

  /// Get assignments by teacher ID
  Future<List<AssignmentModel>> getTeacherAssignments(String teacherId) async {
    try {
      final query = await _firestore
          .collection('assignments')
          .where('teacherId', isEqualTo: teacherId)
          .where('isActive', isEqualTo: true)
          .orderBy('dueDate', descending: false)
          .get();

      return query.docs
          .map((doc) => AssignmentModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get teacher assignments: $e');
    }
  }

  /// Update assignment
  Future<void> updateAssignment(String assignmentId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.now();
      
      await _firestore
          .collection('assignments')
          .doc(assignmentId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update assignment: $e');
    }
  }

  /// Delete assignment (soft delete)
  Future<void> deleteAssignment(String assignmentId) async {
    try {
      await _firestore
          .collection('assignments')
          .doc(assignmentId)
          .update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to delete assignment: $e');
    }
  }

  // ========== SUBMISSION OPERATIONS ==========

  /// Submit an assignment
  Future<AssignmentSubmissionModel> submitAssignment({
    required String assignmentId,
    required String studentId,
    required String studentName,
    required String submissionText,
    List<String>? attachmentUrls,
  }) async {
    try {
      // Check if already submitted
      final existing = await _firestore
          .collection('assignment_submissions')
          .where('assignmentId', isEqualTo: assignmentId)
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception('Assignment already submitted. Use updateSubmission to edit.');
      }

      final submission = AssignmentSubmissionModel(
        id: _uuid.v4(),
        assignmentId: assignmentId,
        studentId: studentId,
        studentName: studentName,
        submissionText: submissionText,
        attachmentUrls: attachmentUrls,
        submittedAt: DateTime.now(),
      );

      await _firestore
          .collection('assignment_submissions')
          .doc(submission.id)
          .set(submission.toFirestore());

      return submission;
    } catch (e) {
      throw Exception('Failed to submit assignment: $e');
    }
  }

  /// Update a submission (before grading)
  Future<void> updateSubmission(String submissionId, {
    required String submissionText,
    List<String>? attachmentUrls,
  }) async {
    try {
      // Check if already graded
      final doc = await _firestore
          .collection('assignment_submissions')
          .doc(submissionId)
          .get();

      if (!doc.exists) {
        throw Exception('Submission not found');
      }

      final submission = AssignmentSubmissionModel.fromFirestore(doc.data()!);
      
      if (submission.gradedAt != null) {
        throw Exception('Cannot update submission after it has been graded');
      }

      await _firestore
          .collection('assignment_submissions')
          .doc(submissionId)
          .update({
        'submissionText': submissionText,
        'attachmentUrls': attachmentUrls,
        'submittedAt': Timestamp.now(), // Update submission timestamp
      });
    } catch (e) {
      throw Exception('Failed to update submission: $e');
    }
  }

  /// Get submission by ID
  Future<AssignmentSubmissionModel?> getSubmission(String submissionId) async {
    try {
      final doc = await _firestore
          .collection('assignment_submissions')
          .doc(submissionId)
          .get();

      if (!doc.exists) return null;

      return AssignmentSubmissionModel.fromFirestore(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get submission: $e');
    }
  }

  /// Get student's submission for an assignment
  Future<AssignmentSubmissionModel?> getStudentSubmission({
    required String assignmentId,
    required String studentId,
  }) async {
    try {
      final query = await _firestore
          .collection('assignment_submissions')
          .where('assignmentId', isEqualTo: assignmentId)
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      return AssignmentSubmissionModel.fromFirestore(query.docs.first.data());
    } catch (e) {
      throw Exception('Failed to get student submission: $e');
    }
  }

  /// Get all submissions for an assignment
  Future<List<AssignmentSubmissionModel>> getAssignmentSubmissions(String assignmentId) async {
    try {
      final query = await _firestore
          .collection('assignment_submissions')
          .where('assignmentId', isEqualTo: assignmentId)
          .orderBy('submittedAt', descending: true)
          .get();

      return query.docs
          .map((doc) => AssignmentSubmissionModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get assignment submissions: $e');
    }
  }

  /// Get all submissions by a student
  Future<List<AssignmentSubmissionModel>> getStudentSubmissions(String studentId) async {
    try {
      final query = await _firestore
          .collection('assignment_submissions')
          .where('studentId', isEqualTo: studentId)
          .orderBy('submittedAt', descending: true)
          .get();

      return query.docs
          .map((doc) => AssignmentSubmissionModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get student submissions: $e');
    }
  }

  /// Grade a submission
  Future<void> gradeSubmission({
    required String submissionId,
    required String teacherId,
    required int score,
    String? feedback,
  }) async {
    try {
      await _firestore
          .collection('assignment_submissions')
          .doc(submissionId)
          .update({
        'score': score,
        'feedback': feedback,
        'gradedAt': Timestamp.now(),
        'gradedBy': teacherId,
      });
    } catch (e) {
      throw Exception('Failed to grade submission: $e');
    }
  }

  /// Get assignment statistics
  Future<Map<String, dynamic>> getAssignmentStats(String assignmentId) async {
    try {
      final submissions = await getAssignmentSubmissions(assignmentId);
      
      final totalSubmissions = submissions.length;
      final gradedSubmissions = submissions.where((s) => s.score != null).length;
      final ungradedSubmissions = totalSubmissions - gradedSubmissions;
      
      double? averageScore;
      if (gradedSubmissions > 0) {
        final totalScore = submissions
            .where((s) => s.score != null)
            .fold<int>(0, (sum, s) => sum + s.score!);
        averageScore = totalScore / gradedSubmissions;
      }

      return {
        'totalSubmissions': totalSubmissions,
        'gradedSubmissions': gradedSubmissions,
        'ungradedSubmissions': ungradedSubmissions,
        'averageScore': averageScore,
      };
    } catch (e) {
      throw Exception('Failed to get assignment stats: $e');
    }
  }
}

