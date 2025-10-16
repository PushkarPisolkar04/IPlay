
## 1. Firestore Database Structure

### Overview
- **Region:** asia-south1 (Mumbai, India)
- **Mode:** Native mode (not Datastore mode)
- **Collections:** 15 primary collections
- **Indexing:** Composite indexes for complex queries
- **Security:** Row-level security via Firestore Rules

---

## 2. Collections Details

### 2.1 `/users/{userId}`

**Purpose:** Store all user data (students, teachers, principals, admins)

**Document Structure:**
```javascript
{
  // Authentication & Identity
  uid: string,                    // Firebase Auth UID (document ID)
  email: string,                  // Required, unique
  role: string,                   // 'student' | 'teacher' | 'admin' (NEVER 'principal')
  
  // Profile
  displayName: string,            // Full name (required)
  username: string | null,        // Optional display name for leaderboards
  avatarUrl: string | null,       // Storage path or default avatar ID
  state: string,                  // Required (for leaderboards)
  schoolTag: string | null,       // Optional free-text school name OR actual school.name
  
  // Role-specific metadata (Teachers only)
  isPrincipal: boolean,           // True if teacher created a school (first teacher)
  principalOfSchool: string | null, // School ID if isPrincipal = true
  
  // ⚠️ IMPORTANT: 
  // - 'principal' is NOT a role, it's a flag!
  // - Multiple teachers can be in one school
  // - Only the FIRST teacher (who created school) has isPrincipal: true
  // - Other teachers joining via school code have isPrincipal: false
  
  // Classroom memberships
  classroomIds: string[],         // Array of classroom IDs (max 10)
  pendingClassroomRequests: string[], // Join request IDs awaiting approval
  
  // Gamification
  totalXP: number,                // Total XP earned (sum of all progress)
  currentStreak: number,          // Days of consecutive activity
  lastActiveDate: Timestamp,      // Last time user completed any activity
  badges: string[],               // Array of badge IDs earned
  
  // Progress summary (for quick lookups)
  progressSummary: {
    realm_1: {
      completed: boolean,
      levelsCompleted: number,
      totalLevels: number,
      xpEarned: number
    },
    // ... repeat for each realm
  },
  
  // Settings
  hideFromPublicLeaderboard: boolean, // Privacy setting
  notificationSettings: {
    announcements: boolean,
    badges: boolean,
    joinRequests: boolean         // Teachers only
  },
  
  // Storage tracking (for teachers)
  storageUsedMB: number,          // Total storage used by uploads (max 25MB)
  
  // Metadata
  isActive: boolean,              // False if banned
  createdAt: Timestamp,
  updatedAt: Timestamp,
  lastSyncedAt: Timestamp | null  // For offline sync
}
```

**Indexes:**
- Composite: `(role, isActive, totalXP)` - For role-based leaderboards
- Composite: `(state, totalXP)` - For state leaderboards
- Single: `email` - For auth lookups
- Single: `totalXP` - For national leaderboard

**Security Rules:**
- Users can read/update their own document
- Only admins can update `isActive`, `role`
- XP can only be incremented (not decremented) by client

---

### 2.2 `/schools/{schoolId}`

**Purpose:** Store school metadata created by principals

**Document Structure:**
```javascript
{
  id: string,                     // Auto-generated Firestore ID
  name: string,                   // School name (e.g., "Delhi Public School")
  state: string,                  // Required (e.g., "Delhi")
  city: string | null,            // Optional
  
  // Access
  schoolCode: string,             // Unique 8-char code: SCH-XXXXX
  principalId: string,            // UID of FIRST teacher who created school
  teacherIds: string[],           // Array of ALL teachers (including principal)
  pendingTeacherIds: string[],    // Teachers awaiting approval
  
  // ⚠️ NOTE: 
  // - principalId = first teacher who created the school
  // - teacherIds = [principalId, teacher2, teacher3, ...]
  // - Multiple teachers can join via school code during signup
  
  // Metadata
  classroomIds: string[],         // All classrooms under this school
  studentCount: number,           // Aggregated count (updated via Cloud Function)
  
  // Settings
  isPublic: boolean,              // Show in public school search? (default: true)
  description: string | null,     // Optional description
  logoUrl: string | null,         // Optional school logo
  
  // Timestamps
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

**Indexes:**
- Composite: `(state, isPublic, name)` - For school search
- Single: `schoolCode` - For join-by-code

**Security Rules:**
- Read: Anyone (for school search)
- Write: Only principal (via `principalId` check)
- Admins can write (for moderation)

**Code Generation Logic:**
```dart
// Format: SCH-XXXXX (5 random alphanumeric)
// Example: SCH-A4F9K, SCH-M8P3X
// Collision check: Query Firestore before assigning
String generateSchoolCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random.secure();
  String code;
  do {
    code = 'SCH-' + List.generate(5, (_) => chars[random.nextInt(chars.length)]).join();
  } while (await schoolCodeExists(code)); // Check Firestore
  return code;
}
```

---

### 2.3 `/classrooms/{classroomId}`

**Purpose:** Store classroom data created by teachers

**Document Structure:**
```javascript
{
  id: string,                     // Auto-generated Firestore ID
  name: string,                   // Classroom name (e.g., "Class 8A - Mathematics")
  subject: string | null,         // Optional subject
  grade: string | null,           // Optional grade (e.g., "8", "9")
  
  // Ownership
  teacherId: string,              // UID of teacher who created classroom
  schoolId: string | null,        // Null if independent classroom
  
  // Access
  classroomCode: string,          // Unique 7-char code: CLS-XXXXX
  requiresApproval: boolean,      // If true, students must wait for approval
  isPublic: boolean,              // Show in public classroom search?
  
  // Members
  studentIds: string[],           // Approved students (max 100 for Spark tier)
  pendingStudentIds: string[],    // Students awaiting approval
  
  // Settings
  allowAnnouncements: boolean,    // Teacher can post announcements
  allowAssignments: boolean,      // Teacher can create assignments
  description: string | null,
  
  // Aggregated stats (updated via Cloud Function)
  studentCount: number,
  averageXP: number,
  averageCompletion: number,      // % of students who completed ≥1 realm
  
  // Timestamps
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

**Indexes:**
- Composite: `(schoolId, grade)` - For school's classroom listing
- Composite: `(teacherId, createdAt)` - For teacher's dashboard
- Single: `classroomCode` - For join-by-code

**Security Rules:**
- Read: Members (students + teacher) + school principal
- Write: Only teacher (via `teacherId` check)
- Students can add themselves to `pendingStudentIds` (if `requiresApproval` = true)

**Code Generation Logic:**
```dart
// Format: CLS-XXXXX (5 random alphanumeric)
String generateClassroomCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random.secure();
  String code;
  do {
    code = 'CLS-' + List.generate(5, (_) => chars[random.nextInt(chars.length)]).join();
  } while (await classroomCodeExists(code));
  return code;
}
```

---

### 2.4 `/join_requests/{requestId}`

**Purpose:** Track student requests to join classrooms (when approval required)

**Document Structure:**
```javascript
{
  id: string,                     // Auto-generated Firestore ID
  
  // Request details
  classroomId: string,
  classroomName: string,          // Denormalized for easy display
  studentId: string,
  studentName: string,            // Denormalized
  
  // Status
  status: string,                 // 'pending' | 'approved' | 'rejected'
  
  // Resolution
  reviewedBy: string | null,      // UID of teacher who approved/rejected
  reviewNote: string | null,      // Optional note from teacher
  
  // Timestamps
  requestedAt: Timestamp,
  resolvedAt: Timestamp | null
}
```

**Indexes:**
- Composite: `(classroomId, status, requestedAt)` - For teacher's pending queue
- Composite: `(studentId, status)` - For student's request history

**Security Rules:**
- Read: Student (own requests) + classroom teacher
- Write: Student can create (pending only), teacher can update status

**Cleanup:**
- Cloud Function: Delete approved/rejected requests older than 30 days

---

### 2.5 `/progress/{userId}__{contentId}`

**Purpose:** Track detailed user progress for each level/game

**Document Structure:**
```javascript
{
  id: string,                     // Composite: userId__realm_1_level_1
  userId: string,
  contentId: string,              // realm_1_level_1, game_copyright_match, etc.
  contentType: string,            // 'level' | 'game' | 'quiz'
  contentVersion: string,         // Version user completed (e.g., "1.0.0")
  
  // Progress
  status: string,                 // 'not_started' | 'in_progress' | 'completed'
  completionPercentage: number,   // 0-100
  
  // Performance
  xpEarned: number,
  attemptsCount: number,
  highScore: number | null,       // For games
  accuracy: number | null,        // % correct answers (for quizzes)
  timeSpentSeconds: number,
  
  // Timestamps
  startedAt: Timestamp,
  completedAt: Timestamp | null,
  lastAttemptAt: Timestamp
}
```

**Indexes:**
- Composite: `(userId, status)` - User's active progress
- Composite: `(userId, contentType, xpEarned)` - User's game high scores
- Composite: `(contentId, xpEarned)` - Global high scores per content

**Security Rules:**
- Read: User can read own progress + classroom teacher can read students' progress
- Write: Only user can write own progress
- XP can only increment

**Note:** For offline support, progress is stored locally first and synced when online.

---

### 2.6 `/badges/{badgeId}`

**Purpose:** Define available badges (platform-wide, admin-managed)

**Document Structure:**
```javascript
{
  id: string,                     // e.g., "first_level", "streak_7", "realm_master_copyright"
  name: string,
  description: string,
  icon: string,                   // Asset path or URL
  category: string,               // 'milestone' | 'streak' | 'mastery' | 'special'
  
  // Unlock criteria
  criteria: {
    type: string,                 // 'xp_threshold' | 'levels_completed' | 'streak' | 'realm_complete'
    value: number | string,       // e.g., 1000 (XP) or "realm_1" (realm ID)
  },
  
  // Rewards
  xpBonus: number | null,         // Optional XP awarded when badge earned
  
  // Metadata
  rarity: string,                 // 'common' | 'rare' | 'epic' | 'legendary'
  order: number,                  // Display order
  isActive: boolean,              // Admins can disable badges
  createdAt: Timestamp
}
```

**Predefined Badges (35 total):**

| Badge ID | Name | Criteria | XP Bonus |
|----------|------|----------|----------|
| first_level | First Steps | Complete 1 level | 50 |
| streak_7 | Week Warrior | 7-day streak | 100 |
| streak_30 | Monthly Master | 30-day streak | 500 |
| realm_copyright | Copyright Champion | Complete Copyright Realm | 200 |
| realm_trademark | Trademark Titan | Complete Trademark Realm | 200 |
| all_realms | IP Mastermind | Complete all 6 realms | 1000 |
| game_master | Game Master | Play all 7 games | 300 |
| high_scorer | High Scorer | Get 100% on any quiz | 150 |
| ... | ... | ... | ... |

**Security Rules:**
- Read: Anyone
- Write: Admins only

---

### 2.7 `/leaderboard_cache/{scopeId}`

**Purpose:** Pre-computed leaderboard snapshots (updated daily via Cloud Function)

**Document Structure:**
```javascript
{
  id: string,                     // Scope ID: 'national' | 'state_Delhi' | 'school_<id>' | 'classroom_<id>'
  scope: string,                  // 'national' | 'state' | 'school' | 'classroom'
  scopeName: string | null,       // Human-readable (e.g., "Delhi", "DPS School")
  
  // Filters
  period: string,                 // 'week' | 'month' | 'all_time'
  learnerType: string | null,     // 'solo' | 'classroom' | null (all)
  
  // Cached data (top 100 only)
  topUsers: [
    {
      userId: string,
      displayName: string,
      username: string | null,
      avatarUrl: string | null,
      xp: number,
      rank: number,
      schoolTag: string | null,
      badges: number               // Count of badges
    },
    // ... up to 100 entries
  ],
  
  // Metadata
  totalUsers: number,             // Total users in this scope
  lastUpdatedAt: Timestamp,
  nextUpdateAt: Timestamp
}
```

**Scope Examples:**
- `national` - All users in India
- `state_Delhi` - All users in Delhi
- `state_Delhi_solo` - Solo learners in Delhi
- `state_Delhi_classroom` - Classroom students in Delhi
- `school_<schoolId>` - All students in a school
- `classroom_<classroomId>` - Students in a classroom

**Security Rules:**
- Read: Anyone (public leaderboards)
- Write: Cloud Functions only

**Update Strategy:**
- Daily Cloud Function at 2 AM IST
- Queries users collection with filters
- Orders by XP (descending)
- Limits to top 100
- Writes to cache

---

### 2.8 `/announcements/{announcementId}`

**Purpose:** Teacher-posted announcements for classrooms

**Document Structure:**
```javascript
{
  id: string,
  classroomId: string,
  teacherId: string,
  teacherName: string,            // Denormalized
  
  // Content
  title: string,
  message: string,                // Max 500 characters
  attachmentUrl: string | null,   // Optional image/PDF
  
  // Visibility
  isPinned: boolean,              // Show at top
  expiresAt: Timestamp | null,    // Auto-hide after this date
  
  // Engagement
  viewedByStudents: string[],     // Student IDs who viewed (for analytics)
  
  // Timestamps
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

**Indexes:**
- Composite: `(classroomId, isPinned, createdAt)` - Fetch classroom announcements

**Security Rules:**
- Read: Classroom members (students + teacher)
- Write: Classroom teacher only

**Cleanup:**
- Cloud Function: Auto-delete announcements older than 90 days (unless pinned)

---

### 2.9 `/assignments/{assignmentId}`

**Purpose:** Teacher-created assignments for classrooms

**Document Structure:**
```javascript
{
  id: string,
  classroomId: string,
  teacherId: string,
  
  // Content
  title: string,
  description: string,
  attachmentUrls: string[],       // PDFs, images (max 3 files)
  
  // Scheduling
  assignedAt: Timestamp,
  dueDate: Timestamp | null,
  
  // Settings
  maxPoints: number,              // Optional grading points
  allowLateSubmission: boolean,
  
  // Aggregated stats
  totalStudents: number,          // Students in classroom at assignment time
  submittedCount: number,
  pendingCount: number,
  
  // Metadata
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

**Indexes:**
- Composite: `(classroomId, dueDate)` - Upcoming assignments
- Composite: `(teacherId, createdAt)` - Teacher's assignments

**Security Rules:**
- Read: Classroom members
- Write: Classroom teacher only

---

### 2.10 `/assignment_submissions/{submissionId}`

**Purpose:** Student submissions for assignments

**Document Structure:**
```javascript
{
  id: string,
  assignmentId: string,
  classroomId: string,
  studentId: string,
  studentName: string,
  
  // Submission
  submissionText: string | null,  // Text response
  attachmentUrl: string | null,   // Single image (max 1MB, compressed)
  submittedAt: Timestamp,
  isLate: boolean,                // True if after dueDate
  
  // Grading
  score: number | null,           // Out of maxPoints
  feedback: string | null,        // Teacher feedback
  gradedBy: string | null,        // Teacher UID
  gradedAt: Timestamp | null,
  
  // Metadata
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

**Indexes:**
- Composite: `(assignmentId, submittedAt)` - Assignment's submissions
- Composite: `(studentId, assignmentId)` - Student's submission (unique)

**Security Rules:**
- Read: Student (own), classroom teacher
- Write: Student (create/update own), teacher (grade)

---

### 2.11 `/reports/{reportId}`

**Purpose:** Content/user reports for moderation

**Document Structure:**
```javascript
{
  id: string,
  
  // Report details
  reportType: string,             // 'content' | 'user' | 'assignment'
  reportedItemId: string,         // Content ID, user ID, or assignment ID
  reportedItemType: string,       // 'teacher_upload' | 'announcement' | 'user_profile'
  reporterId: string,             // UID of reporter
  reporterRole: string,           // 'student' | 'teacher'
  
  // Content
  reason: string,                 // 'inappropriate' | 'spam' | 'harassment' | 'copyright' | 'other'
  details: string | null,         // Optional description
  screenshotUrl: string | null,   // Optional screenshot
  
  // Resolution
  status: string,                 // 'pending' | 'under_review' | 'resolved' | 'dismissed'
  reviewedBy: string | null,      // Admin or principal UID
  resolution: string | null,      // 'content_deleted' | 'user_warned' | 'user_banned' | 'no_action'
  resolutionNote: string | null,
  
  // Timestamps
  reportedAt: Timestamp,
  resolvedAt: Timestamp | null
}
```

**Indexes:**
- Composite: `(status, reportedAt)` - Pending reports queue
- Composite: `(reportedItemId, status)` - All reports for an item

**Security Rules:**
- Read: Admins + school principals (for their school's content)
- Write: Any authenticated user (create), admins/principals (update)

**Moderation Hierarchy:**
1. Report submitted → Status: `pending`
2. If reported item is in a school → Notify school principal
3. Principal reviews (7-day window)
4. If principal doesn't act OR report is escalated → Admin reviews
5. Admin takes action → Status: `resolved`

---

### 2.12 `/feedback/{feedbackId}`

**Purpose:** General user feedback (bugs, suggestions)

**Document Structure:**
```javascript
{
  id: string,
  userId: string,
  userName: string,
  userRole: string,
  
  // Feedback
  category: string,               // 'bug' | 'suggestion' | 'content_issue' | 'other'
  title: string,
  message: string,
  screenshotUrl: string | null,
  
  // Device info (for bug reports)
  deviceInfo: {
    platform: string,             // 'android' | 'ios' | 'web'
    version: string,              // App version
    os: string                    // OS version
  } | null,
  
  // Admin response
  status: string,                 // 'new' | 'acknowledged' | 'resolved' | 'closed'
  adminResponse: string | null,
  respondedBy: string | null,
  
  // Timestamps
  submittedAt: Timestamp,
  respondedAt: Timestamp | null
}
```

**Indexes:**
- Composite: `(status, submittedAt)` - New feedback queue
- Composite: `(category, status)` - Filter by category

**Security Rules:**
- Read: Own feedback (users), all feedback (admins)
- Write: Authenticated users (create), admins (update status/response)

---

### 2.13 `/certificates/{certificateId}`

**Purpose:** Track generated certificates for users

**Document Structure:**
```javascript
{
  id: string,
  userId: string,
  userName: string,               // Name on certificate
  
  // Certificate details
  certificateType: string,        // 'realm_completion' | 'master_certificate'
  realmId: string | null,         // Null for master certificate
  realmName: string | null,
  
  // Generation
  generatedAt: Timestamp,
  certificateUrl: string,         // Firebase Storage path
  certificateNumber: string,      // Unique cert number: CERT-<year>-<random>
  
  // Metadata
  qrCodeData: string,             // Verification URL
  isValid: boolean,               // Can be revoked by admin
  
  // Timestamps
  createdAt: Timestamp
}
```

**Certificate Number Format:** `CERT-2025-A4F9K2M8`

**Security Rules:**
- Read: User (own certificates), admins
- Write: Cloud Functions only (auto-generated on realm completion)

**Storage:**
- PDF stored in Firebase Storage: `/certificates/{userId}/{certificateId}.pdf`
- Generated via Cloud Function using `pdf` package

---

### 2.14 `/daily_challenges/{challengeId}`

**Purpose:** Auto-generated daily challenges for bonus XP

**Document Structure:**
```javascript
{
  id: string,                     // Format: challenge_YYYY-MM-DD
  date: Timestamp,                // Challenge date
  
  // Challenge content (5 random questions from completed realms)
  questions: [
    {
      questionId: string,         // Source level ID
      question: string,
      options: string[],
      correctIndex: number,
      realmId: string
    },
    // ... 5 questions total
  ],
  
  // Rewards
  xpReward: number,               // Fixed: 50 XP
  
  // Stats
  totalAttempts: number,
  successfulCompletions: number,
  
  // Metadata
  createdAt: Timestamp,
  expiresAt: Timestamp            // End of day
}
```

**Generation Logic:**
- Cloud Function runs daily at 12:01 AM IST
- Selects 5 random questions from all realms
- Ensures variety (at least 3 different realms)
- Same challenge for all users

**Security Rules:**
- Read: Authenticated users
- Write: Cloud Functions only

---

### 2.15 `/daily_challenge_attempts/{attemptId}`

**Purpose:** Track user attempts at daily challenges

**Document Structure:**
```javascript
{
  id: string,                     // userId__challengeId
  userId: string,
  challengeId: string,
  
  // Attempt
  score: number,                  // Out of 5
  xpEarned: number,               // 50 XP if score ≥ 3
  timeTakenSeconds: number,
  
  // Timestamps
  completedAt: Timestamp
}
```

**Indexes:**
- Composite: `(userId, completedAt)` - User's challenge history
- Composite: `(challengeId, score)` - Challenge leaderboard

**Security Rules:**
- Read: User (own attempts)
- Write: User (create once per challenge)

---

## 3. Firestore Indexes (Composite)

**Required Composite Indexes:**

```javascript
// Users collection
users: [
  { fields: ['role', 'isActive', 'totalXP'], order: 'desc' },
  { fields: ['state', 'totalXP'], order: 'desc' },
]

// Schools collection
schools: [
  { fields: ['state', 'isPublic', 'name'], order: 'asc' },
]

// Classrooms collection
classrooms: [
  { fields: ['schoolId', 'grade'], order: 'asc' },
  { fields: ['teacherId', 'createdAt'], order: 'desc' },
]

// Join requests
join_requests: [
  { fields: ['classroomId', 'status', 'requestedAt'], order: 'desc' },
  { fields: ['studentId', 'status'], order: 'desc' },
]

// Progress
progress: [
  { fields: ['userId', 'status'], order: 'asc' },
  { fields: ['userId', 'contentType', 'xpEarned'], order: 'desc' },
  { fields: ['contentId', 'xpEarned'], order: 'desc' },
]

// Announcements
announcements: [
  { fields: ['classroomId', 'isPinned', 'createdAt'], order: 'desc' },
]

// Assignments
assignments: [
  { fields: ['classroomId', 'dueDate'], order: 'asc' },
  { fields: ['teacherId', 'createdAt'], order: 'desc' },
]

// Assignment submissions
assignment_submissions: [
  { fields: ['assignmentId', 'submittedAt'], order: 'desc' },
]

// Reports
reports: [
  { fields: ['status', 'reportedAt'], order: 'desc' },
  { fields: ['reportedItemId', 'status'], order: 'desc' },
]

// Feedback
feedback: [
  { fields: ['status', 'submittedAt'], order: 'desc' },
  { fields: ['category', 'status'], order: 'desc' },
]

// Daily challenge attempts
daily_challenge_attempts: [
  { fields: ['userId', 'completedAt'], order: 'desc' },
  { fields: ['challengeId', 'score'], order: 'desc' },
]
```

**Deployment:**
- Automatically created when first query runs (Firestore auto-suggests)
- OR manually deploy via `firestore.indexes.json`

---

## 4. Security Rules Summary

**Key Principles:**
- **Least Privilege:** Users can only access what they need
- **No Direct Admin Access:** Admin operations via Cloud Functions
- **XP Integrity:** XP can only increment, never decrement (client-side)
- **Teacher Ownership:** Teachers can only modify their own classrooms
- **Student Privacy:** Students can't see each other's detailed progress

**Rule Examples (see full rules in `firestore.rules`):**

```javascript
// Users: Read own, write own (limited fields)
match /users/{userId} {
  allow read: if request.auth.uid == userId;
  allow update: if request.auth.uid == userId 
    && !request.resource.data.diff(resource.data).affectedKeys()
      .hasAny(['role', 'isActive', 'isPrincipal']);
}

// Classrooms: Read if member, write if teacher
match /classrooms/{classroomId} {
  allow read: if request.auth.uid in resource.data.studentIds
    || request.auth.uid == resource.data.teacherId;
  allow write: if request.auth.uid == resource.data.teacherId;
}

// Progress: Read own, write own (XP only increment)
match /progress/{progressId} {
  allow read: if progressId.split('__')[0] == request.auth.uid;
  allow create, update: if progressId.split('__')[0] == request.auth.uid
    && request.resource.data.xpEarned >= resource.data.xpEarned;
}
```

---

## 5. Data Migration & Seeding

**Initial Data (Admin-created):**

1. **Badges:** 35 predefined badges (see section 2.6)
2. **Content Metadata:** Realm/level references (stored as static JSON, not Firestore)
3. **Leaderboard Cache:** Empty (populated by first Cloud Function run)
4. **Daily Challenges:** Empty (generated daily)

**Seeding Script (for testing):**
```javascript
// firestore-seed.js
const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();

async function seedBadges() {
  const badges = [
    { id: 'first_level', name: 'First Steps', criteria: { type: 'levels_completed', value: 1 }, xpBonus: 50, ... },
    // ... 34 more badges
  ];
  
  for (const badge of badges) {
    await db.collection('badges').doc(badge.id).set(badge);
  }
  console.log('Badges seeded!');
}

seedBadges();
```

---

## 6. Backup & Recovery Strategy

### 6.1 Automated Backups (Cloud Function)

**Schedule:** Weekly (every Sunday at 3 AM IST)

**What's Backed Up:**
- All Firestore collections (exported to JSON)
- Storage manifest (list of all files, not the files themselves)

**Backup Location:**
- Firestore export: `gs://<project-id>-backups/firestore/<timestamp>/`
- Storage manifest: Firestore collection `/backups/{timestamp}`

**Cloud Function (pseudocode):**
```javascript
// Scheduled function
exports.weeklyBackup = functions.pubsub
  .schedule('0 3 * * 0')  // Every Sunday 3 AM
  .timeZone('Asia/Kolkata')
  .onRun(async (context) => {
    // Export Firestore
    const client = new FirestoreAdminClient();
    await client.exportDocuments({
      name: client.databasePath(projectId, '(default)'),
      outputUriPrefix: `gs://${bucketName}/firestore/${Date.now()}`,
      collectionIds: []  // Empty = all collections
    });
    
    // Create storage manifest
    const [files] = await storage.bucket().getFiles();
    await db.collection('backups').add({
      type: 'storage_manifest',
      files: files.map(f => ({ name: f.name, size: f.metadata.size })),
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });
  });
```

### 6.2 Manual Backup (for critical events)

**Before major updates:**
```bash
# Export Firestore
gcloud firestore export gs://iplay-backups/manual-$(date +%Y%m%d)

# Export Storage (if on Blaze plan)
gsutil -m cp -r gs://iplay-app.appspot.com gs://iplay-backups/storage-$(date +%Y%m%d)
```

### 6.3 Restore Procedure

**From Firestore export:**
```bash
gcloud firestore import gs://iplay-backups/firestore/<timestamp>
```

**Limitations on Spark tier:**
- Can't auto-copy Storage files (no Cloud Functions outbound networking)
- Manual restoration required (download + re-upload)

---

## 7. Summary

This database schema provides:
- ✅ **Scalability:** Up to 5000 users on free tier
- ✅ **Security:** Row-level access control
- ✅ **Performance:** Indexed for common queries
- ✅ **Flexibility:** Supports solo learners + classroom learners
- ✅ **Moderation:** Report system with hierarchical review
- ✅ **Backup:** Weekly automated exports

**Next:** See `03_USER_FLOWS.md` for detailed user journeys.


