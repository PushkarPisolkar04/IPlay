import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/join_request_model.dart';

/// Service for classroom join request approval workflow
class JoinRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  /// Create a join request for a classroom
  Future<JoinRequestModel> createJoinRequest({
    required String classroomId,
    required String studentId,
    required String studentName,
  }) async {
    try {
      // Check if request already exists
      final existing = await _firestore
          .collection('join_requests')
          .where('classroomId', isEqualTo: classroomId)
          .where('studentId', isEqualTo: studentId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception('Join request already pending for this classroom');
      }

      final request = JoinRequestModel(
        id: _uuid.v4(),
        classroomId: classroomId,
        studentId: studentId,
        studentName: studentName,
        status: 'pending',
        requestedAt: DateTime.now(),
      );

      await _firestore
          .collection('join_requests')
          .doc(request.id)
          .set(request.toFirestore());

      return request;
    } catch (e) {
      throw Exception('Failed to create join request: $e');
    }
  }

  /// Get pending join requests for a classroom
  Future<List<JoinRequestModel>> getPendingRequests(String classroomId) async {
    try {
      final query = await _firestore
          .collection('join_requests')
          .where('classroomId', isEqualTo: classroomId)
          .where('status', isEqualTo: 'pending')
          .orderBy('requestedAt', descending: true)
          .get();

      return query.docs
          .map((doc) => JoinRequestModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get pending requests: $e');
    }
  }

  /// Get all join requests for a classroom (including resolved)
  Future<List<JoinRequestModel>> getAllRequests(String classroomId) async {
    try {
      final query = await _firestore
          .collection('join_requests')
          .where('classroomId', isEqualTo: classroomId)
          .orderBy('requestedAt', descending: true)
          .get();

      return query.docs
          .map((doc) => JoinRequestModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all requests: $e');
    }
  }

  /// Get join requests by student ID
  Future<List<JoinRequestModel>> getStudentRequests(String studentId) async {
    try {
      final query = await _firestore
          .collection('join_requests')
          .where('studentId', isEqualTo: studentId)
          .orderBy('requestedAt', descending: true)
          .get();

      return query.docs
          .map((doc) => JoinRequestModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get student requests: $e');
    }
  }

  /// Approve a join request
  Future<void> approveRequest({
    required String requestId,
    required String teacherId,
  }) async {
    try {
      // Get the request
      final requestDoc = await _firestore
          .collection('join_requests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        throw Exception('Join request not found');
      }

      final request = JoinRequestModel.fromFirestore(requestDoc.data()!);

      if (request.status != 'pending') {
        throw Exception('Request has already been resolved');
      }

      final batch = _firestore.batch();

      // Update join request status
      batch.update(
        _firestore.collection('join_requests').doc(requestId),
        {
          'status': 'approved',
          'resolvedAt': Timestamp.now(),
          'resolvedBy': teacherId,
        },
      );

      // Get classroom's schoolId and schoolTag
      final classroomDoc = await _firestore
          .collection('classrooms')
          .doc(request.classroomId)
          .get();
      final schoolId = classroomDoc.data()?['schoolId'];
      final schoolTag = classroomDoc.data()?['schoolTag'];

      // Add student to classroom and remove from pending
      batch.update(
        _firestore.collection('classrooms').doc(request.classroomId),
        {
          'studentIds': FieldValue.arrayUnion([request.studentId]),
          'pendingStudentIds': FieldValue.arrayRemove([request.studentId]),
          'updatedAt': Timestamp.now(),
        },
      );

      // Add classroom, schoolId, and schoolTag to user's profile
      final updateData = {
        'classroomIds': FieldValue.arrayUnion([request.classroomId]),
        'pendingClassroomRequests': FieldValue.arrayRemove([request.classroomId]),
        'updatedAt': Timestamp.now(),
      };
      if (schoolId != null) {
        updateData['schoolId'] = schoolId;
      }
      if (schoolTag != null) {
        updateData['schoolTag'] = schoolTag;
      }
      
      batch.update(
        _firestore.collection('users').doc(request.studentId),
        updateData,
      );

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to approve request: $e');
    }
  }

  /// Reject a join request
  Future<void> rejectRequest({
    required String requestId,
    required String teacherId,
    String? reason,
  }) async {
    try {
      // Get the request
      final requestDoc = await _firestore
          .collection('join_requests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        throw Exception('Join request not found');
      }

      final request = JoinRequestModel.fromFirestore(requestDoc.data()!);

      if (request.status != 'pending') {
        throw Exception('Request has already been resolved');
      }

      final batch = _firestore.batch();

      // Update join request status
      batch.update(
        _firestore.collection('join_requests').doc(requestId),
        {
          'status': 'rejected',
          'resolvedAt': Timestamp.now(),
          'resolvedBy': teacherId,
          'rejectReason': reason,
        },
      );

      // Remove from classroom's pending list and user's pending requests
      batch.update(
        _firestore.collection('classrooms').doc(request.classroomId),
        {
          'pendingStudentIds': FieldValue.arrayRemove([request.studentId]),
          'updatedAt': Timestamp.now(),
        },
      );
      
      batch.update(
        _firestore.collection('users').doc(request.studentId),
        {
          'pendingClassroomRequests': FieldValue.arrayRemove([request.classroomId]),
          'updatedAt': Timestamp.now(),
        },
      );

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to reject request: $e');
    }
  }

  /// Cancel a join request (by student)
  Future<void> cancelRequest(String requestId, String studentId) async {
    try {
      // Get the request
      final requestDoc = await _firestore
          .collection('join_requests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        throw Exception('Join request not found');
      }

      final request = JoinRequestModel.fromFirestore(requestDoc.data()!);

      if (request.studentId != studentId) {
        throw Exception('Unauthorized to cancel this request');
      }

      if (request.status != 'pending') {
        throw Exception('Request has already been resolved');
      }

      final batch = _firestore.batch();

      // Delete the join request
      batch.delete(_firestore.collection('join_requests').doc(requestId));

      // Remove from classroom's pending list and user's pending requests
      batch.update(
        _firestore.collection('classrooms').doc(request.classroomId),
        {
          'pendingStudentIds': FieldValue.arrayRemove([studentId]),
          'updatedAt': Timestamp.now(),
        },
      );
      
      batch.update(
        _firestore.collection('users').doc(studentId),
        {
          'pendingClassroomRequests': FieldValue.arrayRemove([request.classroomId]),
          'updatedAt': Timestamp.now(),
        },
      );

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to cancel request: $e');
    }
  }

  /// Get count of pending requests for a classroom
  Future<int> getPendingRequestCount(String classroomId) async {
    try {
      final query = await _firestore
          .collection('join_requests')
          .where('classroomId', isEqualTo: classroomId)
          .where('status', isEqualTo: 'pending')
          .count()
          .get();

      return query.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get pending request count: $e');
    }
  }

  /// Get count of pending requests for multiple classrooms (for teacher dashboard)
  Future<Map<String, int>> getPendingRequestCounts(List<String> classroomIds) async {
    try {
      final counts = <String, int>{};

      for (final classroomId in classroomIds) {
        final count = await getPendingRequestCount(classroomId);
        counts[classroomId] = count;
      }

      return counts;
    } catch (e) {
      throw Exception('Failed to get pending request counts: $e');
    }
  }
}

