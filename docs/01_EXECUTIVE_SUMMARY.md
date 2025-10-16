# IPlay - Complete App Documentation
## Part 1: Executive Summary & Overview

**Version:** 1.0.0 (Production Ready)  
**Last Updated:** October 15, 2025  
**Tech Stack:** Flutter + Firebase  
**Target:** Students, Teachers, Principals in India  
**Objective:** Free, gamified Intellectual Property Rights (IPR) learning platform

---

## 1. Executive Summary

### 1.1 What is IPlay?

IPlay is a comprehensive educational platform designed to teach Intellectual Property Rights (IPR) concepts through gamification, structured learning paths, and social features. The app supports three user roles (Student, Teacher, Principal) with hierarchical classroom and school management.

**Core Features:**
- 📚 **6 Learning Realms** (Copyright, Trademark, Patent, Design, GI, Trade Secrets) with multiple levels each
- 🎮 **7 Mini Games** for interactive learning
- 🏆 **Multi-tier Leaderboards** (Classroom, School, State, National)
- 🎓 **School & Classroom Management** with unique join codes
- 📊 **Progress Tracking** with XP, badges, streaks, certificates
- 📱 **Offline Support** for low-bandwidth environments
- 🔒 **Privacy-First** design with child safety measures

### 1.2 Why This Architecture?

**Free-Tier Sustainability:**
- Firebase Spark plan (₹0/month) for 1000-5000 users
- Static content hosting (no database reads for content)
- Client-side caching and offline-first design
- Scheduled aggregation to minimize real-time queries

**No AI/ML (Student Project Constraint):**
- Rule-based gamification (XP formulas, badge logic)
- Pre-authored content (no AI generation)
- Simple matching algorithms for daily challenges

**Privacy & Child Safety:**
- No PII beyond email and name
- Optional display names for leaderboards
- Teacher-moderated classrooms only
- No student-to-student messaging
- Terms of Service with parental consent checkbox

**⚠️ UPDATED SIGNUP FLOW:**
- Role selection happens BEFORE account creation
- Students can join classrooms immediately via code
- Teachers can create schools or join existing ones during signup
- Solo learners supported (can join classrooms later, progress preserved)

---

## 2. Tech Stack (Final & Locked)

### 2.1 Frontend
- **Framework:** Flutter 3.24+ (Dart)
- **State Management:** Provider package
- **Navigation:** go_router
- **UI Components:** Material Design 3
- **Animations:** Lottie, custom animations package
- **Local Storage:** shared_preferences, sqflite (offline cache)
- **Image Handling:** cached_network_image, image_picker (with compression)

### 2.2 Backend (Firebase)
- **Authentication:** Firebase Auth (Email/Password, Google Sign-In)
- **Database:** Cloud Firestore (asia-south1 region)
- **Storage:** Firebase Storage (teacher uploads, certificates, avatars)
- **Functions:** Cloud Functions (Node.js 18) for:
  - Daily leaderboard aggregation
  - Classroom cleanup on deletion
  - User offboarding workflows
  - Certificate generation
  - Weekly backups
- **Hosting:** Firebase Hosting (static content - realms, levels, game assets)
- **Security:** App Check (protect against abuse)

### 2.3 Content Delivery
- **Static Content:** JSON files hosted on Firebase Hosting
- **Structure:**
  ```
  /content/
    /realms/
      realm_1_copyright.json
      realm_2_trademark.json
      ...
    /levels/
      realm_1_level_1.json
      realm_1_level_2.json
      ...
    /games/
      game_config.json
      game_assets/
  ```
- **Versioning:** Each JSON file includes `version` field
- **Caching:** Client downloads and caches in IndexedDB/sqflite

### 2.4 Development Tools
- **Version Control:** Git + GitHub
- **CI/CD:** GitHub Actions (optional, for automated deploys)
- **Testing:** Flutter integration tests, Firestore emulator
- **Analytics:** Firebase Analytics (free tier)
- **Monitoring:** Firebase Crashlytics (free tier)

---

## 3. User Roles & Capabilities

### 3.1 Student Role

**Primary Functions:**
- Browse and complete learning realms/levels
- Play mini games for additional XP
- Join classrooms using classroom codes
- View leaderboards (filtered by scope)
- Track personal progress (XP, streaks, badges)
- Download content for offline use
- Submit assignments (text + 1 image)
- View classroom announcements
- Generate and download certificates

**Restrictions:**
- Cannot create content
- Cannot message other students
- Cannot see other students' detailed progress (only leaderboard ranks)
- Cannot join more than 10 classrooms

**Data Owned:**
- Personal profile (name, email, avatar, display name)
- Progress records (XP, completed levels, game scores)
- Badges and certificates
- Classroom memberships

### 3.2 Teacher Role

**Primary Functions:**
- Create independent classrooms OR join a school first
- Generate unique classroom codes (7 chars: `CLS-XXXXX`)
- Approve/reject student join requests
- Post classroom announcements
- Create assignments (text, images, PDFs max 5MB)
- Upload teaching materials (PDFs max 5MB, images max 2MB)
- View classroom analytics (student progress, engagement)
- Export classroom data (CSV)
- Create schools (becomes Principal of that school)

**Restrictions:**
- Cannot access other teachers' classrooms (unless invited as co-teacher in Phase 2)
- Cannot ban users (only remove from their classrooms)
- Upload limits: 50MB total per teacher (Spark tier constraint)

**Data Owned:**
- Teacher profile
- Created classrooms (metadata, join codes)
- Announcements
- Assignments and teaching materials
- Student rosters (references to student IDs)

### 3.3 Principal Role

**⚠️ IMPORTANT:** Principal is NOT a separate role! It's a flag (`isPrincipal: true`)

**How It Works:**
- A Teacher becomes a Principal by creating a school
- This can happen:
  1. **During signup** - If teacher has no school code (first teacher in school)
  2. **After signup** - Via "Create School" button in Teacher Dashboard
- Principal is stored as metadata: `isPrincipal: true` in user document
- One teacher can be Principal of only ONE school at a time
- **Multiple teachers** can be in one school (they join via school code)
- Only the **FIRST teacher** (who created school) is the principal

**Additional Capabilities (beyond Teacher):**
- Create school with unique 8-char code (`SCH-XXXXX`)
- Generate school QR codes and shareable links
- Approve teachers joining the school
- View school-wide analytics (all classrooms from all teachers)
- Reassign classrooms to other teachers
- Transfer school ownership to another teacher (must be in same school)
- Delete school (requires emptying all classrooms first)

**Example Scenario:**
```
Delhi Public School (SCH-DPS01)
  ├─ Principal: Mr. Sharma (isPrincipal: true) - Created school
  ├─ Teacher: Mrs. Gupta (isPrincipal: false) - Joined via SCH-DPS01
  ├─ Teacher: Mr. Verma (isPrincipal: false) - Joined via SCH-DPS01
  └─ Teacher: Ms. Reddy (isPrincipal: false) - Joined via SCH-DPS01
```

**Data Owned:**
- School document (name, state, metadata)
- School-level analytics aggregations

### 3.4 Admin Role (Platform Level)

**Access:** Separate web dashboard (not in mobile app)

**Capabilities:**
- View platform-wide analytics:
  - Total users, schools, classrooms, teachers
  - Daily/Monthly active users (DAU/MAU)
  - Content engagement metrics
  - Storage and Firestore usage
- Content moderation:
  - Review reported content (teacher uploads)
  - Delete inappropriate content
  - Warn or ban users
- User management:
  - Force transfer school ownership (emergency)
  - Restore deleted accounts (from backups)
  - Manually approve/reject flagged signups
- System maintenance:
  - Trigger manual backups
  - Update platform content (realms, levels)
  - Manage content versions

**Data Owned:**
- Platform-wide aggregations
- Moderation logs
- System configuration

---

## 4. Data Privacy & Compliance

### 4.1 Data Collected

**Personal Identifiable Information (PII):**
- Email address (required for authentication)
- Full name (required, used for certificates)
- Optional: Display name/username (for leaderboards)
- Optional: Avatar image (user-uploaded or default)
- State/Union Territory (required for students, for state leaderboards)
- School name (optional metadata, free text)

**Non-PII Data:**
- Learning progress (realm/level completion, XP earned)
- Game scores and high scores
- Streak data (last active date)
- Classroom memberships (IDs only)
- Device info (for Analytics, anonymous)

**What We DON'T Collect:**
- ❌ Birthdate or age
- ❌ Physical address
- ❌ Phone number
- ❌ Payment information (app is 100% free)
- ❌ Behavioral tracking across websites
- ❌ Location data (beyond state selection)

### 4.2 Legal Compliance

**India's Digital Personal Data Protection Act (DPDP) 2023:**
- ✅ Parental consent: Terms checkbox during signup ("I confirm I have parental/guardian consent if under 18")
- ✅ Data minimization: Only essential data collected
- ✅ Right to deletion: Users can request account deletion (anonymization of data)
- ✅ Data localization: All data stored in `asia-south1` (Mumbai) region
- ✅ Transparent privacy policy: Accessible before signup

**Child Safety (for potential <13 users):**
- ✅ No public chat or messaging
- ✅ Teacher-moderated classrooms only
- ✅ Leaderboards use display names (optional)
- ✅ Content reporting mechanism
- ✅ No ads or third-party trackers

### 4.3 Data Retention

**Active Users:**
- Data retained as long as account is active
- Users can delete account anytime (see offboarding section)

**Inactive Users:**
- Accounts inactive for 2+ years: Email notification sent
- If no response in 30 days: Account marked for deletion
- Deletion: PII removed, progress anonymized (for analytics)

**Deleted Accounts:**
- Email, name, avatar: Immediately deleted
- Progress data: Anonymized (UID replaced with `deleted_user_<timestamp>`)
- Leaderboard entries: Removed in next aggregation cycle
- Classroom memberships: Removed immediately
- Certificates: Deleted from storage

**Backups:**
- Weekly Firestore exports retained for 90 days
- Backups are encrypted and access-controlled

---

## 5. Cost Breakdown (Firebase Spark - Free Tier)

### 5.1 Firestore Limits (Free)
- **Stored Data:** 1 GB
- **Document Reads:** 50,000/day
- **Document Writes:** 20,000/day
- **Deletes:** 20,000/day

**Our Usage Estimate (1000 active users):**
- User documents: ~1000 × 2KB = 2MB
- Classrooms: ~200 × 3KB = 600KB
- Schools: ~50 × 2KB = 100KB
- Progress records: ~1000 × 50KB = 50MB
- Join requests: ~500 × 1KB = 500KB
- Leaderboard cache: ~100 × 10KB = 1MB
- **Total: ~55MB** ✅ Well within 1GB

**Daily Operations:**
- Reads: ~5,000 (leaderboard fetches, profile loads) ✅
- Writes: ~2,000 (progress updates, streaks) ✅
- Deletes: ~100 (expired join requests) ✅

### 5.2 Authentication (Free)
- Unlimited email/password signups
- Unlimited Google Sign-In (using Firebase Auth, not Google Identity Platform)

### 5.3 Storage Limits (Free)
- **Total Storage:** 5 GB
- **Downloads:** 1 GB/day
- **Uploads:** 1 GB/day

**Our Usage Estimate:**
- Teacher uploads: 200 teachers × 50MB = 10GB ⚠️ **EXCEEDS FREE TIER**
- **Mitigation:**
  - Strict per-teacher limit: 25MB (not 50MB)
  - 200 teachers × 25MB = 5GB ✅
  - Enforce via client-side checks + Storage rules
  - Compress images client-side (max 2MB → ~500KB after compression)
  - PDFs max 5MB (no compression)
  - **No video uploads** (YouTube embeds only)

**Downloads:**
- Certificates: ~1000 users × 6 certs × 200KB = 1.2GB ⚠️
- **Mitigation:**
  - Generate certificates on-demand (not pre-generated)
  - Cache locally after first download
  - Use Cloud Functions for generation (stays within Storage)

### 5.4 Cloud Functions (Free)
- **Invocations:** 2 million/month
- **Compute Time:** 400,000 GB-seconds/month
- **Outbound Networking:** 5 GB/month

**Our Usage:**
- Daily leaderboard cron: 30 invocations/month × 10 seconds = negligible
- User operations (ban, cleanup): ~100/month × 2 seconds = negligible
- Certificate generation: ~500/month × 5 seconds = 2,500 seconds ✅

### 5.5 Hosting (Free)
- **Storage:** 10 GB
- **Transfer:** 360 MB/day

**Our Usage:**
- Static content (JSON, images): ~500MB ✅
- App bundle (web version): ~50MB ✅
- Daily downloads: ~50MB/day (cached aggressively) ✅

### 5.6 Total Cost
**₹0/month** for up to 1000-2000 active users with disciplined usage

**Monitoring:**
- Firebase Console usage dashboard (daily checks)
- Set alerts at 80% of limits
- If approaching limits: Optimize queries, increase cache TTL, or consider Blaze plan

---

## 6. Key Metrics & Analytics

### 6.1 User Engagement Metrics

**Daily Active Users (DAU):**
- Tracked via Firebase Analytics (automatic)
- Goal: 40%+ of registered users active daily

**Session Duration:**
- Average time per session (goal: 15+ minutes)
- Indicates content engagement quality

**Retention Rates:**
- Day 1: 60%+ (did user return next day?)
- Day 7: 40%+
- Day 30: 25%+

### 6.2 Learning Metrics

**Realm Completion Rate:**
- % of users who complete each realm
- Identifies difficult or boring content

**Level Drop-off Points:**
- Where do users abandon levels?
- Used to improve content

**Game Popularity:**
- Which mini games are played most?
- Informs future game development

**Average XP per User:**
- Goal: 1000 XP within first week
- Indicates proper onboarding

### 6.3 Social Metrics

**Classroom Join Rate:**
- % of students in at least 1 classroom
- Goal: 60%+ (remaining 40% are solo learners)

**Teacher Adoption:**
- % of teachers who create classrooms: 80%+
- % of teachers who post announcements: 60%+
- % of teachers who create assignments: 40%+

**School Formation:**
- Number of schools created per month
- Teacher-to-Principal conversion rate

### 6.4 Platform Health

**Content Reports:**
- Number of reports per 1000 users (goal: <5)
- Average resolution time: <48 hours

**Error Rate:**
- Crashes per 1000 sessions (goal: <1%)
- Failed syncs: <2%

**Storage Usage:**
- Firestore: <50% of limit
- Storage: <60% of limit (buffer for spikes)

---

## 7. Content Structure & Versioning

### 7.1 Learning Content Hierarchy

```
Platform
├── Realms (6 total)
│   ├── Realm 1: Copyright
│   ├── Realm 2: Trademark
│   ├── Realm 3: Patent
│   ├── Realm 4: Industrial Design
│   ├── Realm 5: Geographical Indication
│   └── Realm 6: Trade Secrets
│
└── Each Realm contains:
    ├── Levels (5-8 levels per realm, 35 total)
    │   ├── Content (text, images, examples)
    │   ├── Interactive elements (quizzes, drag-drop)
    │   └── XP reward (50-200 XP per level)
    │
    └── Realm Quiz (unlocked after all levels complete)
        └── XP reward: 300-500 XP
```

### 7.2 Static Content Format (JSON)

**Realm Metadata (`/content/realms/realm_1_copyright.json`):**
```json
{
  "id": "realm_1",
  "version": "1.0.0",
  "name": "Copyright Realm",
  "description": "Learn about copyright protection...",
  "icon": "assets/realms/copyright_icon.png",
  "color": "#FF6B6B",
  "prerequisite": null,
  "levels": ["realm_1_level_1", "realm_1_level_2", ...],
  "estimatedMinutes": 45,
  "totalXP": 800,
  "updatedAt": "2025-10-15T00:00:00Z"
}
```

**Level Content (`/content/levels/realm_1_level_1.json`):**
```json
{
  "id": "realm_1_level_1",
  "version": "1.0.0",
  "realmId": "realm_1",
  "name": "What is Copyright?",
  "content": [
    {
      "type": "text",
      "data": "Copyright is a legal right that grants..."
    },
    {
      "type": "image",
      "data": "assets/levels/copyright_intro.png",
      "caption": "Copyright symbol"
    },
    {
      "type": "video_embed",
      "data": "https://www.youtube.com/embed/..."
    },
    {
      "type": "interactive_quiz",
      "data": {
        "question": "What does copyright protect?",
        "options": ["Original works", "Ideas", "Facts", "Titles"],
        "correct": 0,
        "explanation": "Copyright protects original works..."
      }
    }
  ],
  "xpReward": 100,
  "estimatedMinutes": 8,
  "updatedAt": "2025-10-15T00:00:00Z"
}
```

### 7.3 Versioning Strategy

**Version Format:** `MAJOR.MINOR.PATCH` (Semantic Versioning)

**Major Version Change (2.0.0):**
- Content restructuring (level order changed)
- XP rewards significantly changed
- Questions completely rewritten
- **Impact:** Treated as NEW content
  - Users' old progress preserved (v1.0.0 completion = 100%)
  - New version shows as "Updated - Replay available"
  - Separate progress tracking

**Minor Version Change (1.1.0):**
- Added new interactive elements
- Improved explanations
- New images/videos
- **Impact:** Backward compatible
  - Users see "Updated content available"
  - Re-download suggested but not required
  - Progress carries over

**Patch Version (1.0.1):**
- Typo fixes
- Image optimization
- Bug fixes
- **Impact:** Silent update
  - Auto-downloaded on next sync
  - No user notification

**Client Handling:**
```dart
// Pseudocode
if (localVersion.major < serverVersion.major) {
  showDialog("New version available! Replay to earn XP again.");
  // Treat as separate content
} else if (localVersion.minor < serverVersion.minor) {
  showSnackbar("Content improved! Re-download recommended.");
  // Optional update
} else if (localVersion.patch < serverVersion.patch) {
  // Silent auto-update
  downloadContentInBackground();
}
```

---

## 8. Summary

This document provides the foundation for IPlay's architecture. The following documents will detail:

- **Part 2:** Database Schema (all Firestore collections)
- **Part 3:** User Flows (20+ detailed workflows)
- **Part 4:** UI/UX Specifications (every screen)
- **Part 5:** Gamification System
- **Part 6:** Security & Cloud Functions
- **Part 7:** Offline Strategy
- **Part 8:** Implementation Checklist

**Next:** See `02_DATABASE_SCHEMA.md`