import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static Future<void> initialize() async {
    try {
      if (kIsWeb) {
        // Web configuration
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: "YOUR_WEB_API_KEY",
            authDomain: "YOUR_PROJECT_ID.firebaseapp.com",
            projectId: "YOUR_PROJECT_ID",
            storageBucket: "YOUR_PROJECT_ID.appspot.com",
            messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
            appId: "YOUR_WEB_APP_ID",
          ),
        );
      } else {
        // Mobile will use google-services.json / GoogleService-Info.plist
        await Firebase.initializeApp();
      }
      
      if (kDebugMode) {
        print('Firebase initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Firebase initialization error: $e');
      }
      rethrow;
    }
  }
}

