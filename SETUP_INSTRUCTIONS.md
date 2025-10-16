# IPlay - Setup Instructions

> **Important**: This repository does NOT include Firebase configuration files for security reasons.

## Required Files (Not in Git)

The following files must be configured manually:

### 1. `android/app/google-services.json`
- Download from Firebase Console → Project Settings → Your Android App
- Place in `android/app/` directory
- **Never commit this file**

### 2. `lib/firebase_options.dart`
- Generate using FlutterFire CLI:
  ```bash
  flutter pub global activate flutterfire_cli
  flutterfire configure
  ```
- Select your Firebase project
- Choose platforms (Android, iOS, Web)
- **Never commit this file**

### 3. `android/local.properties`
- Create or update with your local paths:
  ```properties
  sdk.dir=YOUR_ANDROID_SDK_PATH
  flutter.sdk=YOUR_FLUTTER_SDK_PATH
  flutter.buildMode=debug
  flutter.versionName=1.0.0
  flutter.versionCode=1
  ```
- Example Windows path: `sdk.dir=C:\\Users\\YourName\\AppData\\Local\\Android\\sdk`
- Example Mac/Linux path: `sdk.dir=/Users/YourName/Library/Android/sdk`

## Quick Setup Checklist

- [ ] Clone repository
- [ ] Run `flutter pub get`
- [ ] Create Firebase project
- [ ] Download `google-services.json` → `android/app/`
- [ ] Run `flutterfire configure`
- [ ] Update `android/local.properties`
- [ ] Run `flutter run`

## Firebase Console Setup

1. **Authentication**
   - Enable Email/Password provider
   - Enable Google Sign-In provider
   - Add authorized domains

2. **Firestore Database**
   - Create database in production mode
   - Deploy security rules: `firebase deploy --only firestore:rules`
   - Deploy indexes: `firebase deploy --only firestore:indexes`

3. **Storage**
   - Enable Firebase Storage
   - Deploy storage rules: `firebase deploy --only storage`

4. **Cloud Functions** (Optional)
   - Upgrade to Blaze plan for functions
   - Deploy: `firebase deploy --only functions`

## Troubleshooting

### "google-services.json not found"
- Download from Firebase Console
- Ensure it's in `android/app/` directory

### "Firebase not configured"
- Run `flutterfire configure`
- Ensure `lib/firebase_options.dart` exists

### "SDK location not found"
- Update `android/local.properties` with correct paths

## Security Notes

⚠️ **NEVER commit these files:**
- `android/app/google-services.json`
- `lib/firebase_options.dart`
- `android/local.properties`
- `.env` files
- `.keystore` files

These files contain API keys and local paths that should not be shared publicly.

