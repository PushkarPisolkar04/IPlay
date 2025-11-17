# Firebase App Check Setup Guide

App Check has been integrated into your app! Here's what you need to do next:

## ✅ What's Already Done
- Added `firebase_app_check` package to pubspec.yaml
- Configured App Check in `firebase_service.dart`
- Set up debug mode for development and Play Integrity/Device Check for production

## 🔧 Firebase Console Setup (Required for Production)

### 1. Enable App Check in Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to **Build** → **App Check**
4. Click **Get Started**

### 2. Register Your Android App
1. In App Check settings, find your Android app
2. Click **Register** next to Play Integrity
3. No additional configuration needed - Play Integrity works automatically

### 3. Register Your iOS App (if applicable)
1. In App Check settings, find your iOS app
2. Click **Register** next to App Attest or DeviceCheck
3. No additional configuration needed

### 4. Configure Enforcement (Important!)
For each Firebase service you use:
- **Firestore**: Go to App Check → Firestore → Set enforcement mode
- **Auth**: Go to App Check → Authentication → Set enforcement mode
- **Storage**: Go to App Check → Storage → Set enforcement mode

**Recommended Settings:**
- **Development**: Set to "Unenforced" (allows requests without App Check)
- **Production**: Set to "Enforced" (blocks requests without valid App Check token)

## 🧪 Testing in Development

### Debug Mode
Your app is configured to use debug tokens in development mode. This means:
- No warnings in debug builds
- App Check tokens are automatically generated
- No Firebase Console configuration needed for testing

### Getting Debug Token (if needed)
If you need to register a debug token:
1. Run your app in debug mode
2. Check the logs for: `App Check debug token: <TOKEN>`
3. Go to Firebase Console → App Check → Apps → Your App
4. Add the debug token under "Debug tokens"

## 🚀 Production Deployment

When deploying to production:
1. Build in release mode: `flutter build apk --release` or `flutter build appbundle --release`
2. The app will automatically use Play Integrity (Android) or Device Check (iOS)
3. Ensure enforcement is enabled in Firebase Console
4. Test thoroughly before releasing

## 📱 Platform-Specific Notes

### Android
- Uses **Play Integrity API** in production
- Requires app to be distributed through Google Play (or internal testing)
- Debug mode works on any device/emulator

### iOS
- Uses **DeviceCheck** in production
- Works on physical devices (iOS 11+)
- Debug mode works on simulators and devices

## ⚠️ Troubleshooting

**"App Check token error" in logs:**
- In debug mode: This is normal, debug tokens are used automatically
- In production: Ensure app is registered in Firebase Console

**Requests being blocked:**
- Check enforcement settings in Firebase Console
- Verify app is properly registered for App Check
- For debug builds, ensure debug provider is working

## 🔗 Resources
- [Firebase App Check Documentation](https://firebase.google.com/docs/app-check)
- [Play Integrity API](https://developer.android.com/google/play/integrity)
- [iOS DeviceCheck](https://developer.apple.com/documentation/devicecheck)
