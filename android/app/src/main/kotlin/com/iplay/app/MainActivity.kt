package com.iplay.app

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import com.google.firebase.FirebaseApp

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Initialize Firebase BEFORE calling super.onCreate()
        // This ensures Firebase is ready when Flutter tries to use it
        FirebaseApp.initializeApp(this)
        super.onCreate(savedInstanceState)
    }
}