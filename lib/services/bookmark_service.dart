import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for managing content bookmarks
class BookmarkService {
  static final BookmarkService _instance = BookmarkService._internal();
  factory BookmarkService() => _instance;
  BookmarkService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Add a level to bookmarks
  Future<void> addBookmark({
    required String levelId,
    required String levelName,
    required String realmId,
    required String realmName,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .doc(levelId)
        .set({
      'levelId': levelId,
      'levelName': levelName,
      'realmId': realmId,
      'realmName': realmName,
      'bookmarkedAt': Timestamp.now(),
    });
  }

  /// Remove a level from bookmarks
  Future<void> removeBookmark(String levelId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .doc(levelId)
        .delete();
  }

  /// Check if a level is bookmarked
  Future<bool> isBookmarked(String levelId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .doc(levelId)
        .get();

    return doc.exists;
  }

  /// Get all bookmarks for current user
  Stream<QuerySnapshot> getBookmarksStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .orderBy('bookmarkedAt', descending: true)
        .snapshots();
  }

  /// Get bookmark count
  Future<int> getBookmarkCount() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return 0;

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// Toggle bookmark (add if not bookmarked, remove if bookmarked)
  Future<bool> toggleBookmark({
    required String levelId,
    required String levelName,
    required String realmId,
    required String realmName,
  }) async {
    final isCurrentlyBookmarked = await isBookmarked(levelId);

    if (isCurrentlyBookmarked) {
      await removeBookmark(levelId);
      return false;
    } else {
      await addBookmark(
        levelId: levelId,
        levelName: levelName,
        realmId: realmId,
        realmName: realmName,
      );
      return true;
    }
  }
}
