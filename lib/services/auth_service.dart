import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/models/user_model.dart';
import '../core/constants/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    required String role,
    required String state,
    String? schoolTag,
  }) async {
    try {
      // Create user in Firebase Auth
      final UserCredential userCredential = 
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user == null) return null;

      // Create user document in Firestore
      final userModel = UserModel(
        uid: user.uid,
        email: email,
        role: role,
        displayName: displayName,
        state: state,
        schoolTag: schoolTag,
        totalXP: 0,
        currentStreak: 0,
        lastActiveDate: DateTime.now(),
        notificationSettings: const NotificationSettings(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(user.uid)
          .set(userModel.toFirestore());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = 
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user == null) return null;

      // Get user document from Firestore
      final docSnapshot = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(user.uid)
          .get();

      if (!docSnapshot.exists) {
        throw Exception('User data not found');
      }

      return UserModel.fromMap(docSnapshot.data()!);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Get user data
  Future<UserModel?> getUserData(String uid) async {
    try {
      final docSnapshot = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(uid)
          .get();

      if (!docSnapshot.exists) return null;

      return UserModel.fromMap(docSnapshot.data()!);
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Update user data
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = Timestamp.now();
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(uid)
          .update(data);
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }

  // Sign in with Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = 
          await _auth.signInWithCredential(credential);

      final User? user = userCredential.user;
      if (user == null) return null;

      // Check if user document exists
      final docSnapshot = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(user.uid)
          .get();

      if (!docSnapshot.exists) {
        // New user - create document with minimal info
        // Role and state will be selected later in profile setup
        final userModel = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          role: '', // Empty role - will be set later
          displayName: user.displayName ?? googleUser.displayName ?? 'User',
          avatarUrl: user.photoURL,
          state: AppConstants.defaultState,
          totalXP: 0,
          currentStreak: 0,
          lastActiveDate: DateTime.now(),
          notificationSettings: const NotificationSettings(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection(AppConstants.collectionUsers)
            .doc(user.uid)
            .set(userModel.toFirestore());

        return userModel;
      }

      return UserModel.fromMap(docSnapshot.data()!);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }

  // Sign out (including Google)
  Future<void> signOutCompletely() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      default:
        return 'Authentication error: ${e.message}';
    }
  }

  // Update streak and last active date
  Future<void> updateUserActivity(String uid) async {
    try {
      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(uid)
          .get();

      if (!userDoc.exists) return;

      final userData = UserModel.fromMap(userDoc.data()!);
      final now = DateTime.now();
      final lastActive = userData.lastActiveDate;

      int newStreak = userData.currentStreak;

      final difference = now.difference(lastActive);
      
      // If within grace period, maintain streak
      if (difference.inHours <= AppConstants.streakGracePeriodHours + 24) {
        // If it's a new day, increment streak
        if (difference.inHours >= 24) {
          newStreak += 1;
        }
      } else {
        // Streak broken
        newStreak = 1;
      }
    
      await updateUserData(uid, {
        'currentStreak': newStreak,
        'lastActiveDate': Timestamp.fromDate(now),
      });
    } catch (e) {
      throw Exception('Failed to update user activity: $e');
    }
  }
}

