# 🔥 Complete Firebase Setup Guide for iPlay

## ✅ Current Status

**Firebase Project:** `iplay-246b9` (Active & Connected)
- ✅ Project ID: `iplay-246b9`
- ✅ Firebase Project Number: `14099012059`
- ✅ Android App configured
- ✅ Web App configured
- ✅ Firestore database exists
- ✅ Firebase Authentication enabled

---

## 🎯 Step-by-Step Fresh Setup

### Step 1: Clean Existing Data (⚠️ DESTRUCTIVE - Do this carefully!)

Since your current Firebase has test data from development, we'll clean it:

#### Option A: Delete All Collections (Recommended for Fresh Start)

```bash
# Navigate to project
cd D:\Learning\iplay

# Delete all documents in each collection
firebase firestore:delete --all-collections --project iplay-246b9
```

#### Option B: Manual Cleanup via Firebase Console

1. Go to https://console.firebase.google.com/project/iplay-246b9/firestore
2. Delete these collections ONE BY ONE:
   - `users` - All user data
   - `progress` - All progress tracking
   - `classrooms` - All classrooms
   - `assignments` - All assignments
   - `assignment_submissions` - All submissions
   - `announcements` - All announcements
   - `certificates` - All certificates
   - `badges` - Delete first, we'll repopulate
   - `daily_challenge_attempts` - All attempts
   - `join_requests` - All requests
   - `reports` - All reports
   - `feedback` - All feedback
   - `leaderboard_cache` - All cache
   - `notifications` - All notifications

**⚠️ WARNING:** This will delete ALL your data. Only proceed if you're sure!

---

### Step 2: Verify Firestore Security Rules (Spark Plan Compatible)

Your current rules are already Spark-compatible! ✅

Check: https://console.firebase.google.com/project/iplay-246b9/firestore/rules

The rules should match what's in: `D:\Learning\iplay\firestore.rules`

To deploy/update rules:
```bash
firebase deploy --only firestore:rules --project iplay-246b9
```

---

### Step 3: Verify Firebase Authentication Setup

1. Go to https://console.firebase.google.com/project/iplay-246b9/authentication
2. Make sure these are enabled:
   - ✅ Email/Password authentication
   - ✅ Google Sign-In (optional but recommended)

---

### Step 4: Populate Initial Data

#### A. Populate Badges (Required for Achievement System)

Run the populate script:

```bash
cd D:\Learning\iplay

# Run the badge population script
flutter run lib/core/utils/populate_badges.dart
```

This will create all achievement badges in Firestore.

#### B. Create Initial Content Structure

**IMPORTANT:** You need to create 38 JSON content files for:
- Copyright realm (8 levels)
- Trademark realm (8 levels)
- Patent realm (8 levels)
- Industrial Design realm (8 levels)
- GI realm (8 levels)
- Trade Secrets realm (8 levels)
- Plus 2 game files

**Content files location:** `D:\Learning\iplay\assets\content\`

**Missing files list:**
```
assets/content/copyright/
  - level_1.json through level_8.json

assets/content/trademark/
  - level_1.json through level_8.json

assets/content/patent/
  - level_1.json through level_8.json

assets/content/industrial_design/
  - level_1.json through level_8.json

assets/content/gi/
  - level_1.json through level_8.json

assets/content/trade_secrets/
  - level_1.json through level_8.json

assets/content/games/
  - ip_defender.json
  - innovation_lab.json
```

**Content JSON Structure:**

```json
{
  "levelId": "copyright_level_1",
  "realmId": "copyright",
  "levelNumber": 1,
  "title": "Introduction to Copyright",
  "description": "Learn the basics of copyright protection",
  "sections": [
    {
      "type": "text",
      "content": "Copyright is a legal right..."
    },
    {
      "type": "image",
      "url": "https://example.com/image.png",
      "caption": "Copyright symbol"
    },
    {
      "type": "video",
      "url": "https://youtube.com/watch?v=...",
      "title": "Copyright Explained"
    }
  ],
  "quiz": [
    {
      "question": "What does copyright protect?",
      "options": [
        "Original works of authorship",
        "Ideas",
        "Facts",
        "Methods"
      ],
      "correctAnswer": 0,
      "explanation": "Copyright protects original works..."
    }
  ],
  "xpReward": 50,
  "estimatedDuration": 15,
  "difficulty": "beginner"
}
```

---

### Step 5: Create Test User Accounts

#### Create Student Account:
1. Run your app: `flutter run`
2. Sign up with:
   - Email: `student@test.com`
   - Password: `Test@123`
   - Role: Student
   - School: Select or create a test school
   - Classroom: Join or create a test classroom

#### Create Teacher Account:
1. Sign up with:
   - Email: `teacher@test.com`
   - Password: `Test@123`
   - Role: Teacher
   - Create a classroom

#### Create Principal Account (Optional):
1. Go to Firebase Console → Firestore
2. Find the teacher user document
3. Add field: `isPrincipal: true`

---

### Step 6: Firestore Composite Indexes

Your indexes are already created! ✅

To verify or redeploy:
```bash
firebase deploy --only firestore:indexes --project iplay-246b9
```

View indexes: https://console.firebase.google.com/project/iplay-246b9/firestore/indexes

---

### Step 7: Firebase Storage (Optional - for avatars, certificates)

1. Go to https://console.firebase.google.com/project/iplay-246b9/storage
2. Click "Get Started"
3. Choose your region (same as Firestore ideally)
4. Security rules for Storage (`storage.rules`):

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // User avatars
    match /avatars/{userId}/{fileName} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Certificates (read-only after creation)
    match /certificates/{certificateId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Assignment submissions
    match /assignments/{assignmentId}/{studentId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == studentId;
    }
  }
}
```

Deploy storage rules:
```bash
firebase deploy --only storage --project iplay-246b9
```

---

## 🔥 Spark Plan Limitations (Free Tier)

✅ **What you CAN use (all included):**
- Firestore: 1 GB storage, 50K reads/day, 20K writes/day
- Authentication: Unlimited users
- Hosting: 10 GB storage, 360 MB/day transfer
- Cloud Storage: 5 GB storage, 1 GB/day download, 20K uploads/day
- Cloud Functions: **NOT available on Spark**
- FCM (Push Notifications): Unlimited ✅

❌ **What you CANNOT use:**
- Cloud Functions (requires Blaze plan)
- External API calls from Cloud Functions
- Scheduled functions

**Your app is already Spark-compatible!** ✅ No Cloud Functions are being used.

---

## 📊 Data Structure Overview

### Collections in Firestore:

1. **users** - User profiles
   ```
   {
     userId, email, displayName, role, schoolId, classroomIds,
     totalXP, currentStreak, badges, progressSummary, lastActiveDate
   }
   ```

2. **progress** - Per-realm progress (NEW SCHEMA ✅)
   ```
   Document ID: {userId}__{realmId}
   {
     userId, realmId, completedLevels: [1,2,3], 
     currentLevelNumber, xpEarned, lastAccessedAt
   }
   ```

3. **classrooms** - Teacher classrooms
   ```
   {
     name, teacherId, schoolId, studentIds, grade, section, createdAt
   }
   ```

4. **assignments** - Teacher assignments
   ```
   {
     title, description, classroomId, teacherId, dueDate, 
     realmId, maxScore, createdAt
   }
   ```

5. **badges** - Achievement badges
   ```
   {
     badgeId, name, description, iconUrl, category, 
     requirement, xpReward, displayOrder
   }
   ```

6. **certificates** - Generated certificates
   ```
   {
     userId, realmId, realmName, completedAt, issuedAt, certificateUrl
   }
   ```

7. **notifications** - User notifications
   ```
   {
     toUserId, fromUserId, title, body, read, sentAt, data
   }
   ```

---

## 🧪 Testing Checklist

After setup, test these features:

- [ ] User signup (Student, Teacher)
- [ ] User login
- [ ] View realms
- [ ] Complete a level (with populated content)
- [ ] Earn XP
- [ ] Create classroom (Teacher)
- [ ] Join classroom (Student)
- [ ] Create assignment (Teacher)
- [ ] Submit assignment (Student)
- [ ] View leaderboard
- [ ] Earn badge
- [ ] Generate certificate
- [ ] Send notification
- [ ] Offline mode (complete level offline, sync when online)

---

## 🚀 Deployment Commands

```bash
# Deploy everything
firebase deploy --project iplay-246b9

# Deploy specific services
firebase deploy --only firestore:rules --project iplay-246b9
firebase deploy --only firestore:indexes --project iplay-246b9
firebase deploy --only storage --project iplay-246b9
firebase deploy --only hosting --project iplay-246b9
```

---

## 🔐 Security Best Practices

1. **Never commit secrets:**
   - `google-services.json` → Already in `.gitignore`
   - `firebase_options.dart` → Contains API keys (public but limit usage)

2. **Set up API key restrictions:**
   - Go to: https://console.cloud.google.com/apis/credentials?project=iplay-246b9
   - Click on API keys
   - Add application restrictions (Android package name, iOS bundle ID)

3. **Monitor usage:**
   - https://console.firebase.google.com/project/iplay-246b9/usage

4. **Enable App Check (Recommended):**
   - https://console.firebase.google.com/project/iplay-246b9/appcheck
   - Prevents API abuse

---

## 📞 Need Help?

- Firebase Console: https://console.firebase.google.com/project/iplay-246b9
- Firebase Docs: https://firebase.google.com/docs
- Status: https://status.firebase.google.com

---

**Last Updated:** 2025-11-09  
**Firebase Project:** iplay-246b9  
**Status:** ✅ Ready for Fresh Setup
