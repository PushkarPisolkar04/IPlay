import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/classroom_model.dart';
import '../core/models/realm_model.dart';
// Removed duplicate import - using LevelModel from core/models/realm_model.dart
import '../core/models/progress_model.dart';
import '../models/leaderboard_model.dart';
import '../core/constants/app_constants.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ========== Classroom Operations ==========

  // Generate unique class code - Format: CLS-XXXXX (5 random alphanumeric chars)
  String _generateClassCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    final code = List.generate(5, (index) => chars[random.nextInt(chars.length)]).join();
    return 'CLS-$code';
  }

  // Create classroom
  Future<ClassroomModel> createClassroom({
    required String teacherId,
    required String teacherName,
    required String name,
    required int grade,
    String? school,
  }) async {
    try {
      final joinCode = _generateClassCode();
      final classroom = ClassroomModel(
        id: _uuid.v4(),
        name: name,
        teacherId: teacherId,
        teacherName: teacherName,
        joinCode: joinCode,
        grade: grade,
        school: school,
        codeExpiresAt: DateTime.now().add(const Duration(days: 365)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.collectionClassrooms)
          .doc(classroom.id)
          .set(classroom.toMap());

      return classroom;
    } catch (e) {
      throw Exception('Failed to create classroom: $e');
    }
  }

  // Join classroom with code
  Future<ClassroomModel?> joinClassroom(String joinCode, String studentId) async {
    try {
      // Find classroom with code
      final querySnapshot = await _firestore
          .collection(AppConstants.collectionClassrooms)
          .where('joinCode', isEqualTo: joinCode.toUpperCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Invalid class code');
      }

      final classroomDoc = querySnapshot.docs.first;
      final classroom = ClassroomModel.fromMap(classroomDoc.data());

      // Check if code is expired
      if (classroom.codeExpiresAt.isBefore(DateTime.now())) {
        throw Exception('Class code has expired');
      }

      // Add student to pending or direct approval
      if (classroom.requiresApproval) {
        await _firestore
            .collection(AppConstants.collectionClassrooms)
            .doc(classroom.id)
            .update({
          'pendingStudentIds': FieldValue.arrayUnion([studentId]),
          'updatedAt': Timestamp.now(),
        });
      } else {
        await _firestore
            .collection(AppConstants.collectionClassrooms)
            .doc(classroom.id)
            .update({
          'studentIds': FieldValue.arrayUnion([studentId]),
          'updatedAt': Timestamp.now(),
        });

        // Add classroom to user
        await _firestore
            .collection(AppConstants.collectionUsers)
            .doc(studentId)
            .update({
          'classroomIds': FieldValue.arrayUnion([classroom.id]),
        });
      }

      return classroom;
    } catch (e) {
      throw Exception('Failed to join classroom: $e');
    }
  }

  // Approve student join request
  Future<void> approveStudent(String classroomId, String studentId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final classroomRef = _firestore
            .collection(AppConstants.collectionClassrooms)
            .doc(classroomId);
        final userRef = _firestore
            .collection(AppConstants.collectionUsers)
            .doc(studentId);

        transaction.update(classroomRef, {
          'studentIds': FieldValue.arrayUnion([studentId]),
          'pendingStudentIds': FieldValue.arrayRemove([studentId]),
          'updatedAt': Timestamp.now(),
        });

        transaction.update(userRef, {
          'classroomIds': FieldValue.arrayUnion([classroomId]),
        });
      });
    } catch (e) {
      throw Exception('Failed to approve student: $e');
    }
  }

  // Get classrooms for teacher
  Stream<List<ClassroomModel>> getTeacherClassrooms(String teacherId) {
    return _firestore
        .collection(AppConstants.collectionClassrooms)
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ClassroomModel.fromMap(doc.data()))
            .toList());
  }

  // Get classrooms for student
  Stream<List<ClassroomModel>> getStudentClassrooms(List<String> classroomIds) {
    if (classroomIds.isEmpty) {
      return Stream.value([]);
    }
    
    return _firestore
        .collection(AppConstants.collectionClassrooms)
        .where(FieldPath.documentId, whereIn: classroomIds)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ClassroomModel.fromMap(doc.data()))
            .toList());
  }

  // ========== Realm & Level Operations ==========

  // Get all active realms
  Stream<List<RealmModel>> getRealms() {
    return _firestore
        .collection(AppConstants.collectionRealms)
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RealmModel.fromMap(doc.data()))
            .toList());
  }

  // Get levels for realm
  Stream<List<LevelModel>> getLevelsForRealm(String realmId) {
    return _firestore
        .collection(AppConstants.collectionLevels)
        .where('realmId', isEqualTo: realmId)
        .where('isActive', isEqualTo: true)
        .orderBy('levelNumber')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LevelModel.fromMap(doc.data()))
            .toList());
  }

  // ========== Progress Operations ==========

  // Save/Update progress
  Future<void> saveProgress(ProgressModel progress) async {
    try {
      // Generate document ID from userId and realmId
      final docId = '${progress.userId}__${progress.realmId}';
      await _firestore
          .collection(AppConstants.collectionProgress)
          .doc(docId)
          .set(progress.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save progress: $e');
    }
  }

  // Get user progress for a level
  Future<ProgressModel?> getUserProgress(String userId, String levelId) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.collectionProgress)
          .where('userId', isEqualTo: userId)
          .where('levelId', isEqualTo: levelId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      return ProgressModel.fromMap(querySnapshot.docs.first.data());
    } catch (e) {
      throw Exception('Failed to get progress: $e');
    }
  }

  // Get all progress for user
  Stream<List<ProgressModel>> getUserAllProgress(String userId) {
    return _firestore
        .collection(AppConstants.collectionProgress)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProgressModel.fromMap(doc.data()))
            .toList());
  }

  // ========== Leaderboard Operations ==========

  // Get leaderboard entries
  Stream<List<LeaderboardEntry>> getLeaderboard({
    required String scope,
    String? scopeId,
    required String period,
    int limit = 100,
  }) {
    Query query = _firestore
        .collection(AppConstants.collectionLeaderboards)
        .where('scope', isEqualTo: scope)
        .where('period', isEqualTo: period);

    if (scopeId != null) {
      query = query.where('scopeId', isEqualTo: scopeId);
    }

    return query
        .orderBy('totalXP', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LeaderboardEntry.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Update leaderboard (called periodically via cloud function or app)
  Future<void> updateLeaderboard(String userId) async {
    try {
      // Get user data
      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(userId)
          .get();

      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final totalXP = userData['totalXP'] ?? 0;
      final displayName = userData['displayName'] ?? '';
      final avatarUrl = userData['avatarUrl'];
      final classroomIds = List<String>.from(userData['classroomIds'] ?? []);

      // Update national leaderboard
      await _updateLeaderboardEntry(
        userId: userId,
        displayName: displayName,
        avatarUrl: avatarUrl,
        totalXP: totalXP,
        scope: AppConstants.leaderboardNational,
        scopeId: null,
      );

      // Update class leaderboards
      for (final classroomId in classroomIds) {
        await _updateLeaderboardEntry(
          userId: userId,
          displayName: displayName,
          avatarUrl: avatarUrl,
          totalXP: totalXP,
          scope: AppConstants.leaderboardClass,
          scopeId: classroomId,
        );
      }
    } catch (e) {
      throw Exception('Failed to update leaderboard: $e');
    }
  }

  Future<void> _updateLeaderboardEntry({
    required String userId,
    required String displayName,
    String? avatarUrl,
    required int totalXP,
    required String scope,
    String? scopeId,
  }) async {
    final periods = ['weekly', 'monthly', 'allTime'];
    
    for (final period in periods) {
      final docId = '${userId}_${scope}_${scopeId ?? 'global'}_$period';
      
      await _firestore
          .collection(AppConstants.collectionLeaderboards)
          .doc(docId)
          .set({
        'userId': userId,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'totalXP': totalXP,
        'rank': 0, // Will be calculated by cloud function
        'scope': scope,
        'scopeId': scopeId,
        'period': period,
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));
    }
  }
}

