# IPlay - Complete App Documentation
## Part 3: User Flows & Workflows

---

## 1. Authentication & Onboarding Flows

### 1.1 New User Signup (Student/Teacher)

**⚠️ UPDATED FLOW - Role Selection FIRST**

**Flow:**
```
1. User opens app
   → Sees Splash Screen (3 seconds, app logo animation)
   
2. → Welcome Screen
   - "Welcome to IPlay"
   - "Learn IP Rights through Games"
   - Buttons: "Sign In" | "Sign Up"
   
3. User taps "Sign Up"
   → Role Selection Screen (FIRST!)
   - "Who are you?"
   - Cards: [Student] [Teacher]
   - Helper text to avoid confusion
   - User selects role
   
4. → Auth Screen (Role-Specific Fields)
   
   IF STUDENT:
   - Full Name (required)
   - Email (required)
   - Password (min 8 chars)
   - Confirm Password
   - Avatar selection
   - Classroom Code (Optional): CLS-XXXXX
     💡 "Have a code from your teacher? Enter it! Or skip to learn solo."
   
   IF classroom code entered:
     → Auto-fetch school & state from classroom
     → Join classroom (direct or approval-based)
   
   IF NO classroom code:
     → State (dropdown, required for leaderboards)
     → School Name (optional, free text)
   
   IF TEACHER:
   - Full Name (required)
   - Email (required)
   - Password (min 8 chars)
   - Confirm Password
   - Avatar selection
   - Question: "Do you have a school code?"
   
   Option A: Has school code
     → Enter: SCH-XXXXX
     → Join existing school as teacher
     → isPrincipal: false
   
   Option B: No school code (First teacher)
     → School Name (required)
     → State (dropdown, required)
     → City (optional)
     → Auto-generate school code
     → Create school
     → isPrincipal: true (becomes principal)
   
5. → Terms of Service Screen
   - "Terms of Service" (scrollable)
   - Checkbox: "I confirm I have parental/guardian consent (if under 18)"
   - Button: "Accept & Continue"
   
6. → Firestore: Create user document
    ```javascript
    // STUDENT
    /users/{uid} {
      role: 'student',
      email, displayName, state, schoolTag,
      classroomIds: [classroomId] or [],  // If code provided
      isPrincipal: false,
      totalXP: 0, currentStreak: 0,
      createdAt: now()
    }
    
    // TEACHER (with school code)
    /users/{uid} {
      role: 'teacher',
      email, displayName, state, schoolTag,
      isPrincipal: false,  // Joined existing school
      principalOfSchool: null,
      createdAt: now()
    }
    
    // TEACHER (creating school)
    /users/{uid} {
      role: 'teacher',
      email, displayName, state, schoolTag,
      isPrincipal: true,  // First teacher = principal
      principalOfSchool: schoolId,
      createdAt: now()
    }
    
    // Also create school document if teacher creates school
    /schools/{schoolId} {
      name, state, city,
      schoolCode: 'SCH-XXXXX',
      principalId: uid,
      teacherIds: [uid],
      classroomIds: [],
      studentCount: 0
    }
    ```
    
7. → Main Screen
    - Student: Home | Learn | Play | Rank | Profile
    - Teacher: Teacher Dashboard
```

**Error Handling:**
- Email already exists → Show error, suggest "Sign In"
- Weak password → Show password requirements
- Invalid classroom code → "Code not found, continue as solo learner?"
- Invalid school code → "Code not found, would you like to create a school?"
- Network error → Show retry button, cache data locally

**Key Changes:**
- ✅ Role selection BEFORE account creation
- ✅ Students can join classroom during signup via code
- ✅ Solo students must enter state manually (for leaderboards)
- ✅ Teachers can join existing schools via code
- ✅ First teacher in school becomes principal automatically
- ✅ Multiple teachers can be in one school

---

### 1.2 Google Sign-In Flow

**Flow:**
```
1. User taps "Continue with Google" (on Auth Screen)
   
2. → Google OAuth popup
   - User selects Google account
   - Grants permissions (email, profile)
   
3. Firebase Auth: Create user with Google credential
   
4. Check if user exists in Firestore:
   - If YES → Fetch user data → Go to Main Screen
   - If NO → Go to Step 6 (Role Selection)
   
5. (New user) → Same as Steps 6-11 above
   - Pre-fill name and avatar from Google profile
   
6. → Main Screen
```

**Edge Cases:**
- User cancels Google popup → Return to Auth Screen
- Google account has no email → Show error "Email required"
- Network error during Google auth → Show retry

---

### 1.3 Existing User Sign In

**Flow:**
```
1. Welcome Screen → User taps "Sign In"
   
2. → Auth Screen (Sign In tab)
   - Email field
   - Password field
   - "Forgot Password?" link
   - Button: "Sign In"
   - OR "Continue with Google"
   
3. Firebase Auth: signInWithEmailAndPassword()
   
4. Fetch user from Firestore (/users/{uid})
   
5. Check user.isActive:
   - If false → Show "Account suspended. Contact support."
   - If true → Proceed
   
6. Update user.lastActiveDate
   
7. Check streak:
   - If lastActiveDate < 48 hours ago → Maintain streak
   - Else → Reset streak to 0
   
8. → Main Screen (based on role fetched from database)
   - NO role selection for login!
   - If role = 'student' → Student Main Screen
   - If role = 'teacher' → Teacher Dashboard
```

**⚠️ IMPORTANT:** 
- Role is NEVER asked during login
- Role is fetched from user document in Firestore
- Navigation is automatic based on stored role

**Forgot Password Flow:**
```
1. Tap "Forgot Password?"
   → Forgot Password Screen
   
2. Enter email → Tap "Send Reset Link"
   
3. Firebase Auth: sendPasswordResetEmail()
   
4. Show success: "Check your email for reset link"
   
5. User clicks link in email → Opens browser
   
6. Firebase Auth page: Enter new password
   
7. → Redirect to app (deep link)
   
8. Show "Password updated! Please sign in."
```

---

## 2. Student Flows

### 2.1 Browse & Complete Learning Content

**Flow:**
```
1. Main Screen → Tap "Learn" tab
   
2. → Learn Screen (Realm Map)
   - Shows 6 realms as cards/map nodes
   - Each realm shows:
     * Name, icon, color
     * Progress: "0/6 levels" or "3/6 levels"
     * Status: Locked/Unlocked
     * XP reward: "800 XP"
   
3. Tap a realm (e.g., "Copyright Realm")
   
4. → Realm Detail Screen
   - Realm description
   - List of levels (vertical scroll):
     * Level 1: "What is Copyright?" [Start] (if not started)
     * Level 2: Locked (unlock after Level 1)
     * Level 3: Locked
     * ...
   - Download button: "Download for Offline" (downloads all levels as ZIP)
   
5. Tap "Start" on Level 1
   
6. → Level Screen
   - Content blocks (fetched from static JSON):
     * Text paragraphs
     * Images
     * Video embeds (YouTube)
     * Interactive quizzes (inline)
   - Scroll to read/watch
   - Answer quiz questions as you go
   
7. Reach end of level → Quiz (5 questions)
   - Multiple choice
   - Submit → See score (e.g., "4/5 correct")
   - If score ≥ 3 → Level complete
   - If score < 3 → Retry quiz
   
8. Level Complete!
   - Show animation (confetti, XP counter)
   - "You earned 100 XP!"
   - Check for badge unlocks (e.g., "First Steps" badge)
   - If badge earned → Show badge popup
   
9. Update Firestore:
   ```javascript
   /progress/{userId__realm_1_level_1} {
     status: 'completed',
     xpEarned: 100,
     completedAt: now()
   }
   
   /users/{userId} {
     totalXP: increment(100),
     progressSummary.realm_1.levelsCompleted: increment(1)
   }
   
   Check badge criteria → If met, add to users.badges[]
   ```
   
10. Return to Realm Detail Screen
    - Level 1: ✓ Completed (replay button)
    - Level 2: [Start] (now unlocked)
```

**Offline Mode:**
- If user tapped "Download for Offline":
  - ZIP file downloaded from Firebase Hosting
  - Extracted to local storage (sqflite)
  - Level content loaded from local JSON
  - XP earned is queued locally (synced when online)

---

### 2.2 Play Mini Games

**Flow:**
```
1. Main Screen → Tap "Play" tab
   
2. → Play Screen (Games List)
   - Shows 7 game cards:
     1. How Much Do You Know? (Quiz)
     2. Match the IPR (Memory game)
     3. Spot the Original (Image comparison)
     4. Copyright Defender (Tower defense style)
     5. Map the Mark (Trademark matching)
     6. Patent Detective (Case studies)
     7. Innovation Lab (Sandbox)
   
   - Each card shows:
     * Game icon, name
     * High score: "Best: 850"
     * XP earned: "120 XP total"
     * [Play] button
   
3. Tap "Play" on "Match the IPR"
   
4. → Game Screen
   - Game instructions (first time only)
   - Tap "Start"
   - Game logic (Flutter game widgets):
     * 12 cards (6 pairs)
     * Flip 2 cards
     * Match pairs
     * Timer: 60 seconds
   - Score calculation: Matches × 10 - Time penalty
   
5. Game Over
   - Show score: "Score: 85"
   - XP earned: score ÷ 10 = 8 XP (rounded)
   - Compare with high score:
     * If new high score → "New High Score!"
     * Else → "High Score: 120"
   
6. Buttons: [Replay] [Back to Games]
   
7. Update Firestore:
   ```javascript
   /progress/{userId__game_match_the_ipr} {
     attemptsCount: increment(1),
     highScore: max(currentHighScore, newScore),
     xpEarned: increment(8)
   }
   
   /users/{userId} {
     totalXP: increment(8)
   }
   ```
```

**Game-Specific Logic:**

| Game | Mechanics | XP Formula | Max XP/attempt |
|------|-----------|------------|----------------|
| How Much Do You Know? | 10 rapid-fire questions, 15 sec each | 10 XP per correct | 100 |
| Match the IPR | Memory card matching | Score ÷ 10 | 20 |
| Spot the Original | Compare 2 images, identify original | 15 XP per correct (5 rounds) | 75 |
| Copyright Defender | Defend IP from infringers (mini tower defense) | Score ÷ 50 | 50 |
| Map the Mark | Drag trademarks to correct categories | 10 XP per correct (8 items) | 80 |
| Patent Detective | Solve case studies (text-based) | 20 XP per case (3 cases) | 60 |
| Innovation Lab | Create and protect an invention (guided simulation) | Fixed 100 XP on completion | 100 |

---

### 2.3 Join Classroom

**Flow:**
```
1. Main Screen → Tap "Profile" tab
   
2. → Profile Screen
   - User avatar, name, XP, streak
   - Section: "My Classrooms" (shows 0 if none)
   - Button: "+ Join Classroom"
   
3. Tap "+ Join Classroom"
   
4. → Join Classroom Modal
   - Options:
     * "Enter Classroom Code"
     * "Scan QR Code"
     * "Browse Public Classrooms"
   
5a. Option 1: Enter Code
   - Input field: "CLS-XXXXX"
   - Tap "Join"
   - Firestore query: /classrooms where classroomCode == input
   - If not found → "Invalid code"
   - If found → Go to Step 6
   
5b. Option 2: Scan QR Code
   - Open camera
   - Scan QR code (contains classroom code)
   - Auto-fill code → Go to Step 5a
   
5c. Option 3: Browse
   - → Classroom Search Screen
   - Filters: State (default: user's state), Subject, Grade
   - List of public classrooms (Firestore query: isPublic = true)
   - Tap a classroom → Go to Step 6
   
6. → Classroom Preview
   - Classroom name, teacher name, school (if any)
   - Student count, description
   - Button: "Request to Join" (if requiresApproval = true)
   - OR "Join Now" (if requiresApproval = false)
   
7a. If requiresApproval = true:
   - Create join request:
     ```javascript
     /join_requests/{requestId} {
       classroomId, studentId, studentName,
       status: 'pending',
       requestedAt: now()
     }
     ```
   - Show: "Request sent! Wait for teacher approval."
   - Add requestId to user.pendingClassroomRequests[]
   
7b. If requiresApproval = false:
   - Directly add student to classroom:
     ```javascript
     /classrooms/{classroomId} {
       studentIds: arrayUnion(studentId)
     }
     /users/{studentId} {
       classroomIds: arrayUnion(classroomId)
     }
     ```
   - Show: "Joined successfully!"
   
8. → Profile Screen
   - "My Classrooms" now shows 1 classroom card
   - Tap to view classroom details
```

**Rate Limiting:**
- Max 5 join attempts per minute (client-side check)
- If exceeded → "Too many attempts. Try again later."

---

### 2.4 View Classroom Details (Student)

**Flow:**
```
1. Profile Screen → Tap classroom card
   
2. → Classroom Detail Screen
   - Header: Classroom name, teacher, code
   - Tabs: [Announcements] [Assignments] [Members] [Leaderboard]
   
3. Announcements Tab (default):
   - List of announcements (newest first)
   - Each shows: Title, message, timestamp
   - Pinned announcements at top
   - If attachment → Show thumbnail, tap to view/download
   - Mark as viewed (add studentId to announcement.viewedByStudents)
   
4. Assignments Tab:
   - List of assignments (due date order)
   - Each shows:
     * Title, due date
     * Status: "Pending" | "Submitted" | "Graded"
     * If graded: Score (e.g., "8/10")
   - Tap assignment:
     → Assignment Detail
     - Description, attachments
     - If not submitted:
       * Text input: "Your Response"
       * Image upload (optional, max 1MB)
       * Button: "Submit"
     - If submitted:
       * Show submission, timestamp
       * If graded: Show feedback
   
5. Members Tab:
   - Student count: "24 students"
   - List of students (avatars, names, XP)
   - Sorted by XP (classroom leaderboard preview)
   
6. Leaderboard Tab:
   - Full classroom leaderboard (same as Rank tab, but filtered)
   - Shows all students in classroom
   - User's rank highlighted
   
7. Button: "Leave Classroom" (bottom)
   - Tap → Confirmation dialog:
     "Are you sure? Your progress will be preserved."
   - If confirmed:
     ```javascript
     /classrooms/{classroomId} {
       studentIds: arrayRemove(studentId)
     }
     /users/{studentId} {
       classroomIds: arrayRemove(classroomId)
     }
     ```
   - → Back to Profile Screen
```

---

### 2.5 View Leaderboards

**Flow:**
```
1. Main Screen → Tap "Rank" tab
   
2. → Leaderboard Screen
   - Top section: User's rank card
     * "Your Rank: #42"
     * "Your XP: 1,250"
     * "Keep learning to climb!"
   
   - Filters (chips):
     * Scope: [Classroom] [School] [State] [National] (default: State)
     * Type: [All] [Solo Learners] [Classroom Learners] (default: All)
     * Period: [Week] [Month] [All Time] (default: All Time)
   
3. User selects filters (e.g., Scope: National, Type: Classroom Learners, Period: Month)
   
4. Fetch leaderboard:
   - Firestore query: /leaderboard_cache/{scope}_{type}_{period}
   - Example: /leaderboard_cache/national_classroom_month
   - If cache exists and < 24 hours old → Use cached data
   - Else → Show "Updating leaderboard..." (trigger Cloud Function manually or wait for next daily update)
   
5. Display leaderboard:
   - List of top 100 users
   - Each row: Rank | Avatar | Name | XP | Badges
   - Top 3 have special badges (gold/silver/bronze)
   - User's row highlighted (if in top 100)
   - If user not in top 100 → Show at bottom: "You: #142"
   
6. Pull to refresh → Re-fetch cache (if stale)
```

**Scope Logic:**
- **Classroom:** Only if user is in ≥1 classroom (shows dropdown to select which classroom)
- **School:** Only if user's classroom has a schoolId (shows school name)
- **State:** User's state from profile
- **National:** All India

**Type Logic:**
- **All:** Everyone
- **Solo Learners:** Users with classroomIds = []
- **Classroom Learners:** Users with classroomIds ≠ []

**Period Logic:**
- **Week:** XP earned in last 7 days (requires tracking `xpByDate` in user doc)
- **Month:** Last 30 days
- **All Time:** Total XP

**Note:** Week/Month filters require additional Firestore logic (track daily XP in sub-collection `/users/{uid}/xp_history/{date}` for granularity). For MVP, implement "All Time" only and add Week/Month in Phase 2.

---

### 2.6 Daily Challenge

**Flow:**
```
1. Main Screen → Home Tab
   
2. → Home Screen
   - Card: "Daily Challenge" (prominent)
   - Shows:
     * "5 quick questions"
     * "Earn 50 XP"
     * Status: "Not Started" | "Completed ✓"
   - Tap to play
   
3. → Daily Challenge Screen
   - Fetches today's challenge:
     ```javascript
     /daily_challenges/challenge_2025-10-15
     ```
   - Shows 5 questions (one at a time, vertical swipe)
   - Each question:
     * Question text
     * 4 options
     * Select one → Immediate feedback (green/red)
     * Correct answer explanation
     * [Next] button
   
4. After 5 questions:
   - Show score: "You got 4/5 correct!"
   - XP earned:
     * If score ≥ 3 → 50 XP
     * If score < 3 → 0 XP (but can retry once)
   
5. Update Firestore:
   ```javascript
   /daily_challenge_attempts/{userId__challengeId} {
     score: 4,
     xpEarned: 50,
     completedAt: now()
   }
   
   /users/{userId} {
     totalXP: increment(50),
     currentStreak: check and update
   }
   ```
   
6. Return to Home Screen
   - Daily Challenge card now shows: "Completed ✓"
   - Tomorrow, a new challenge will appear
```

**Streak Logic:**
```javascript
function updateStreak(user) {
  const now = new Date();
  const lastActive = user.lastActiveDate.toDate();
  const hoursDiff = (now - lastActive) / (1000 * 60 * 60);
  
  if (hoursDiff <= 48) {
    // Within grace period
    if (now.toDateString() !== lastActive.toDateString()) {
      // New day → increment streak
      user.currentStreak += 1;
    }
  } else {
    // Streak broken
    user.currentStreak = 1;
  }
  
  user.lastActiveDate = now;
  return user;
}
```

---

### 2.7 Earn Badge & Certificate

**Badge Flow:**
```
1. User completes an action (e.g., finishes Level 1)
   
2. Client checks badge criteria locally:
   ```dart
   // After XP update
   List<Badge> checkBadges(User user, List<Badge> allBadges) {
     List<Badge> newBadges = [];
     for (var badge in allBadges) {
       if (!user.badges.contains(badge.id)) {
         if (badge.criteria.type == 'levels_completed' && 
             user.totalLevelsCompleted >= badge.criteria.value) {
           newBadges.add(badge);
         }
         // ... other criteria checks
       }
     }
     return newBadges;
   }
   ```
   
3. If badge earned:
   - Update Firestore:
     ```javascript
     /users/{userId} {
       badges: arrayUnion(badgeId),
       totalXP: increment(badge.xpBonus)
     }
     ```
   - Show popup:
     * Badge icon (animated zoom-in)
     * "New Badge Unlocked!"
     * Badge name, description
     * "+" + xpBonus + " XP"
     * [Awesome!] button
   
4. User can view all badges:
   - Profile Screen → "My Badges" section
   - Grid of badge icons
   - Earned badges: Full color
   - Locked badges: Greyscale with lock icon
   - Tap badge → See details, unlock criteria
```

**Certificate Flow:**
```
1. User completes final level of a realm (e.g., Copyright Realm Level 6)
   
2. Client detects realm completion:
   ```dart
   if (user.progressSummary['realm_1'].levelsCompleted == 
       user.progressSummary['realm_1'].totalLevels) {
     // Realm complete!
     generateCertificate(userId, 'realm_1');
   }
   ```
   
3. Trigger Cloud Function: generateCertificate()
   ```javascript
   // Firebase Function
   exports.generateCertificate = functions.firestore
     .document('progress/{progressId}')
     .onUpdate(async (change, context) => {
       // Check if realm completed
       // Generate PDF using 'pdf' package
       const pdfBytes = await createCertificatePDF(user, realm);
       
       // Upload to Storage
       const bucket = admin.storage().bucket();
       const filePath = `certificates/${userId}/${realmId}_${timestamp}.pdf`;
       await bucket.file(filePath).save(pdfBytes);
       
       // Create certificate document
       await admin.firestore().collection('certificates').add({
         userId, realmId, certificateUrl: filePath,
         certificateNumber: generateCertNumber(),
         createdAt: admin.firestore.FieldValue.serverTimestamp()
       });
     });
   ```
   
4. Client listens for new certificate:
   ```dart
   // Real-time listener
   FirebaseFirestore.instance
     .collection('certificates')
     .where('userId', isEqualTo: currentUser.uid)
     .snapshots()
     .listen((snapshot) {
       if (snapshot.docs.isNotEmpty) {
         showCertificatePopup(snapshot.docs.last);
       }
     });
   ```
   
5. Show certificate popup:
   - "Congratulations!"
   - "You've mastered Copyright Realm!"
   - Certificate preview (PDF thumbnail)
   - Buttons: [Download] [Share]
   
6. Download:
   - Fetch PDF from Storage
   - Save to device
   - Show success: "Saved to Downloads"
   
7. Share:
   - Generate share link (deep link to certificate verification page)
   - Open share sheet (WhatsApp, Email, etc.)
```

---

## 3. Teacher Flows

### 3.1 Create School (Become Principal)

**⚠️ NOTE:** This can happen in TWO ways:
1. **During Signup** - First teacher creates school (see section 1.1)
2. **After Signup** - Teacher creates school via dashboard (below)

**Flow (Post-Signup School Creation):**
```
1. Teacher Dashboard → Tap "Create School" card
   
2. → Create School Screen
   - Input fields:
     * School Name (required)
     * State (dropdown, required)
     * City (optional)
     * Description (optional, 200 chars)
     * School Logo (optional, upload image max 2MB)
   - Button: "Create School"
   
3. Tap "Create School"
   
4. Validate:
   - Name not empty
   - State selected
   - Logo size ≤ 2MB (if provided)
   
5. Generate school code:
   ```dart
   String schoolCode = generateSchoolCode(); // SCH-XXXXX
   while (await schoolCodeExists(schoolCode)) {
     schoolCode = generateSchoolCode(); // Retry if collision
   }
   ```
   
6. Upload logo (if provided):
   - Compress image client-side (max 500KB)
   - Upload to Firebase Storage: /school_logos/{schoolId}.jpg
   
7. Create school document:
   ```javascript
   /schools/{schoolId} {
     name, state, city, description,
     schoolCode,
     principalId: currentUser.uid,
     teacherIds: [currentUser.uid],
     pendingTeacherIds: [],
     classroomIds: [],
     studentCount: 0,
     isPublic: true,
     logoUrl: storageUrl,
     createdAt: now()
   }
   ```
   
8. Update user document:
   ```javascript
   /users/{currentUser.uid} {
     isPrincipal: true,
     principalOfSchool: schoolId
   }
   ```
   
9. → School Created Screen
   - "School Created Successfully!"
   - School code: "SCH-A4F9K" (large, copyable)
   - QR code (contains school code)
   - Share buttons: [Copy Code] [Share QR] [Share Link]
   - Link format: iplay.app/join/school/SCH-A4F9K
   - Button: "Go to School Dashboard"
   
10. → School Dashboard (new section in Teacher Dashboard)
```

**Restrictions:**
- One teacher can create only ONE school
- If teacher already has `isPrincipal = true` → Show error:
  "You already manage <school name>. Transfer ownership to create another school."

---

### 3.2 Create Classroom

**Flow:**
```
1. Teacher Dashboard → Tap "Create Classroom"
   
2. → Create Classroom Screen
   - Input fields:
     * Classroom Name (required, e.g., "Class 8A - Mathematics")
     * Subject (optional)
     * Grade (optional, dropdown: 1-12, Other)
     * Description (optional)
   
   - School Affiliation:
     * Radio buttons:
       [ ] Independent Classroom (no school)
       [ ] Under My School: <school name> (if user.isPrincipal = true)
       [ ] Under Another School (enter school code)
   
   - Settings:
     * Toggle: Require Approval for Join Requests (default: ON)
     * Toggle: Public (show in classroom search, default: ON)
   
   - Button: "Create Classroom"
   
3. Validate:
   - Name not empty
   - If "Under Another School" selected → School code valid
   
4. Generate classroom code:
   ```dart
   String classroomCode = generateClassroomCode(); // CLS-XXXXX
   ```
   
5. Create classroom document:
   ```javascript
   /classrooms/{classroomId} {
     name, subject, grade, description,
     teacherId: currentUser.uid,
     schoolId: selectedSchoolId || null,
     classroomCode,
     requiresApproval: true/false,
     isPublic: true/false,
     studentIds: [],
     pendingStudentIds: [],
     studentCount: 0,
     createdAt: now()
   }
   ```
   
6. If schoolId provided:
   ```javascript
   /schools/{schoolId} {
     classroomIds: arrayUnion(classroomId),
     teacherIds: arrayUnion(currentUser.uid)  // Add teacher if not already
   }
   ```
   
7. Update user:
   ```javascript
   /users/{currentUser.uid} {
     classroomIds: arrayUnion(classroomId)  // Teacher is also "member"
   }
   ```
   
8. → Classroom Created Screen
   - Classroom code, QR code
   - Share options
   - Button: "Go to Classroom"
   
9. → Classroom Detail Screen (Teacher view)
```

---

### 3.3 Manage Join Requests

**Flow:**
```
1. Teacher Dashboard → "Pending Approvals" badge shows count (e.g., "5")
   
2. Tap "Pending Approvals"
   
3. → Join Requests Screen
   - List of pending requests (grouped by classroom)
   - Each request shows:
     * Student name, avatar
     * "Wants to join <classroom name>"
     * Timestamp: "2 hours ago"
     * Buttons: [Approve] [Reject]
   
4. Tap "Approve"
   
5. Update Firestore:
   ```javascript
   // Transaction to ensure atomicity
   await firestore.runTransaction(async (transaction) => {
     // Update classroom
     transaction.update(classroomRef, {
       studentIds: FieldValue.arrayUnion(studentId),
       pendingStudentIds: FieldValue.arrayRemove(studentId),
       studentCount: FieldValue.increment(1)
     });
     
     // Update student
     transaction.update(userRef, {
       classroomIds: FieldValue.arrayUnion(classroomId),
       pendingClassroomRequests: FieldValue.arrayRemove(requestId)
     });
     
     // Update request
     transaction.update(requestRef, {
       status: 'approved',
       reviewedBy: currentUser.uid,
       resolvedAt: FieldValue.serverTimestamp()
     });
   });
   ```
   
6. Show toast: "Student approved!"
   
7. (Optional) Send notification to student (email or push, if implemented)
   
8. If "Reject" tapped:
   ```javascript
   /join_requests/{requestId} {
     status: 'rejected',
     reviewedBy: currentUser.uid,
     reviewNote: "Optional reason",
     resolvedAt: now()
   }
   
   /users/{studentId} {
     pendingClassroomRequests: arrayRemove(requestId)
   }
   ```
   
9. Request removed from list
```

---

### 3.4 Post Announcement

**Flow:**
```
1. Classroom Detail Screen (Teacher view) → Tap "+" button
   
2. → Create Announcement Screen
   - Input fields:
     * Title (required, 100 chars)
     * Message (required, 500 chars)
     * Attachment (optional): [Upload Image] [Upload PDF]
     * Toggle: Pin to Top
     * Date picker: Expires On (optional)
   - Button: "Post"
   
3. Upload attachment (if provided):
   - Compress image (max 2MB → ~500KB)
   - Upload to Storage: /announcements/{classroomId}/{timestamp}_{filename}
   - Get download URL
   
4. Create announcement:
   ```javascript
   /announcements/{announcementId} {
     classroomId,
     teacherId: currentUser.uid,
     teacherName: currentUser.displayName,
     title, message,
     attachmentUrl: storageUrl || null,
     isPinned: true/false,
     expiresAt: selectedDate || null,
     viewedByStudents: [],
     createdAt: now()
   }
   ```
   
5. → Classroom Detail Screen
   - New announcement appears at top (if pinned) or chronologically
   
6. Students see announcement:
   - Real-time listener updates their view
   - Unread badge appears (if not in viewedByStudents[])
```

---

### 3.5 Create Assignment

**Flow:**
```
1. Classroom Detail Screen (Teacher) → Assignments tab → Tap "+"
   
2. → Create Assignment Screen
   - Input fields:
     * Title (required)
     * Description (required, rich text editor)
     * Attachments: [Upload PDF] [Upload Image] (max 3 files, 5MB each)
     * Due Date (date-time picker, optional)
     * Max Points (number, for grading, default: 10)
     * Toggle: Allow Late Submissions
   - Button: "Assign"
   
3. Upload attachments:
   - Each file compressed/validated
   - Upload to /assignments/{classroomId}/{assignmentId}/{filename}
   - Collect URLs
   
4. Create assignment:
   ```javascript
   /assignments/{assignmentId} {
     classroomId, teacherId,
     title, description,
     attachmentUrls: [url1, url2],
     dueDate, maxPoints, allowLateSubmission,
     totalStudents: classroom.studentCount,
     submittedCount: 0,
     pendingCount: classroom.studentCount,
     createdAt: now()
   }
   ```
   
5. (Optional) Notify students (email/push)
   
6. → Assignments Tab
   - New assignment appears in list
```

---

### 3.6 View & Grade Submissions

**Flow:**
```
1. Classroom Detail (Teacher) → Assignments tab → Tap assignment
   
2. → Assignment Detail Screen (Teacher view)
   - Assignment details (title, description, attachments)
   - Stats: "12/24 submitted, 12 pending"
   - Tabs: [Submissions] [Not Submitted]
   
3. Submissions Tab:
   - List of submissions (sorted by submission time)
   - Each shows:
     * Student name, avatar
     * Submission text (preview)
     * Attachment thumbnail
     * Submitted at: "2 hours ago" (with "Late" badge if late)
     * Status: "Pending" | "Graded (8/10)"
   - Tap submission:
   
4. → Submission Detail Screen
   - Student info
   - Full submission text
   - Attachment (tap to view full size)
   - Grading section:
     * Score input (0 to maxPoints)
     * Feedback textarea
     * Button: "Submit Grade"
   
5. Submit Grade:
   ```javascript
   /assignment_submissions/{submissionId} {
     score: enteredScore,
     feedback: feedbackText,
     gradedBy: currentUser.uid,
     gradedAt: now()
   }
   
   /assignments/{assignmentId} {
     // Optionally track graded count
   }
   ```
   
6. Show toast: "Graded!"
   
7. Return to Assignment Detail
   - Submission now shows "Graded (8/10)"
```

---

### 3.7 View Classroom Analytics

**Flow:**
```
1. Classroom Detail (Teacher) → Tap "Analytics" button
   
2. → Classroom Analytics Screen
   - Summary cards:
     * Total Students: 24
     * Average XP: 1,350
     * Average Realm Completion: 45%
     * Active Students (last 7 days): 18 (75%)
   
   - Chart: Student XP Distribution (bar chart)
   - Chart: Realm Progress (stacked bar: completed/in-progress/not-started)
   
   - Student List (sortable):
     * Name | XP | Realms Completed | Last Active
     * Tap student → Student Detail
   
3. → Student Detail (Teacher view)
   - Student profile (name, avatar, XP, streak)
   - Progress summary:
     * Realm 1: 5/6 levels ✓
     * Realm 2: 2/6 levels
     * ...
   - Game scores (list)
   - Assignment submissions (list with grades)
   - Button: "Export Student Report" (CSV)
   
4. Export:
   - Generate CSV with student data
   - Download to device
```

**Data Fetching:**
- Firestore queries:
  ```javascript
  // Get all students in classroom
  const students = await firestore.collection('users')
    .where('classroomIds', 'array-contains', classroomId)
    .get();
  
  // For each student, aggregate progress
  for (let student of students) {
    const progress = await firestore.collection('progress')
      .where('userId', '==', student.id)
      .get();
    // Calculate stats
  }
  ```

---

### 3.8 Transfer School Ownership (Principal)

**Flow:**
```
1. School Dashboard (Principal view) → Settings → "Transfer Ownership"
   
2. → Transfer Ownership Screen
   - Warning: "This action is irreversible. You will no longer be Principal."
   - Dropdown: Select New Principal (list of teachers in school)
   - Button: "Transfer"
   
3. Validate:
   - New principal must be a teacher in this school (teacherIds)
   - Confirmation dialog: "Are you sure?"
   
4. Trigger Cloud Function: transferSchoolOwnership()
   ```javascript
   exports.transferSchoolOwnership = functions.https.onCall(
     async (data, context) => {
       const { schoolId, newPrincipalId } = data;
       const currentUserId = context.auth.uid;
       
       // Verify current user is principal
       const school = await admin.firestore().collection('schools').doc(schoolId).get();
       if (school.data().principalId !== currentUserId) {
         throw new functions.https.HttpsError('permission-denied', 'Not principal');
       }
       
       // Verify new principal is in school
       if (!school.data().teacherIds.includes(newPrincipalId)) {
         throw new functions.https.HttpsError('invalid-argument', 'User not in school');
       }
       
       // Update school
       await admin.firestore().collection('schools').doc(schoolId).update({
         principalId: newPrincipalId
       });
       
       // Update old principal
       await admin.firestore().collection('users').doc(currentUserId).update({
         isPrincipal: false,
         principalOfSchool: null
       });
       
       // Update new principal
       await admin.firestore().collection('users').doc(newPrincipalId).update({
         isPrincipal: true,
         principalOfSchool: schoolId
       });
       
       return { success: true };
     }
   );
   ```
   
5. Show success: "Ownership transferred!"
   
6. → Teacher Dashboard (no longer shows School Dashboard section)
```

---

## 4. Principal Flows

### 4.1 Approve Teachers Joining School

**Flow:**
```
1. School Dashboard → "Pending Teachers" badge (count)
   
2. Tap → Pending Teachers Screen
   - List of teachers who entered school code
   - Each shows: Name, email, "Join requested X days ago"
   - Buttons: [Approve] [Reject]
   
3. Approve:
   ```javascript
   /schools/{schoolId} {
     teacherIds: arrayUnion(teacherId),
     pendingTeacherIds: arrayRemove(teacherId)
   }
   ```
   
4. Reject:
   ```javascript
   /schools/{schoolId} {
     pendingTeacherIds: arrayRemove(teacherId)
   }
   ```
   - (Optional) Send notification to teacher
```

---

### 4.2 View School Analytics

**Flow:**
```
1. School Dashboard → "Analytics" card
   
2. → School Analytics Screen
   - Summary:
     * Total Classrooms: 12
     * Total Students: 340
     * Total Teachers: 15
     * Average Student XP: 980
   
   - Classrooms List (sorted by student count):
     * Classroom Name | Teacher | Students | Avg XP
     * Tap → Classroom Detail (same as teacher view)
   
   - Top Students (school-wide leaderboard):
     * Top 10 students by XP
   
   - Export: [Export School Report] (CSV)
```

---

### 4.3 Delete School

**Flow:**
```
1. School Dashboard → Settings → "Delete School"
   
2. → Delete School Screen
   - Warning: "This will delete the school and remove all students from classrooms."
   - Checklist:
     * All classrooms have been deleted or reassigned: [ ]
     * I understand this is irreversible: [ ]
   - Button: "Delete School" (disabled until checkboxes checked)
   
3. Validate:
   - School has no classrooms (classroomIds = [])
   - If has classrooms → Show error: "Please delete or reassign all classrooms first."
   
4. Trigger Cloud Function: deleteSchool()
   ```javascript
   // Remove school document
   await admin.firestore().collection('schools').doc(schoolId).delete();
   
   // Update principal
   await admin.firestore().collection('users').doc(principalId).update({
     isPrincipal: false,
     principalOfSchool: null
   });
   
   // Remove all teachers from school
   for (let teacherId of school.teacherIds) {
     // Update teacher doc if needed
   }
   
   // Delete school logo from Storage
   if (school.logoUrl) {
     await admin.storage().bucket().file(school.logoUrl).delete();
   }
   ```
   
5. Show success: "School deleted."
   
6. → Teacher Dashboard
```

---

## 5. Admin Flows (Web Dashboard)

### 5.1 Review Content Reports

**Flow:**
```
1. Admin Dashboard (web) → "Reports" tab
   
2. → Reports Queue
   - Filters: Status (Pending/Resolved), Type (Content/User)
   - List of reports:
     * Reporter name, role
     * Reported item (content title/username)
     * Reason, timestamp
     * [View Details]
   
3. Click "View Details"
   
4. → Report Detail Page
   - Full report information
   - Reported content preview (if applicable)
   - Screenshot (if provided)
   - Actions:
     * [Delete Content]
     * [Warn User]
     * [Ban User]
     * [Dismiss Report]
     * Text field: Resolution Note
     * Button: "Take Action"
   
5. Select action (e.g., "Delete Content")
   
6. Trigger Cloud Function: moderateContent()
   ```javascript
   // If Delete Content:
   await admin.firestore().collection('announcements').doc(contentId).delete();
   await admin.storage().bucket().file(content.attachmentUrl).delete();
   
   // Update report
   await admin.firestore().collection('reports').doc(reportId).update({
     status: 'resolved',
     resolution: 'content_deleted',
     resolutionNote: noteText,
     reviewedBy: adminId,
     resolvedAt: admin.firestore.FieldValue.serverTimestamp()
   });
   ```
   
7. Show success notification
   
8. Report moves to "Resolved" tab
```

---

### 5.2 Ban User

**Flow:**
```
1. Reports Queue → Click "Ban User" on a report
   
2. → Ban User Confirmation Modal
   - User info, ban reason
   - Duration: [ Permanent ] [ Temporary (days) ]
   - Button: "Confirm Ban"
   
3. Trigger Cloud Function: banUser()
   ```javascript
   exports.banUser = functions.https.onCall(async (data, context) => {
     const { userId, reason, duration } = data;
     
     // Update user
     await admin.firestore().collection('users').doc(userId).update({
       isActive: false,
       banReason: reason,
       bannedAt: admin.firestore.FieldValue.serverTimestamp(),
       bannedUntil: duration ? calculateEndDate(duration) : null
     });
     
     // Remove user from all classrooms
     const user = await admin.firestore().collection('users').doc(userId).get();
     for (let classroomId of user.data().classroomIds) {
       await admin.firestore().collection('classrooms').doc(classroomId).update({
         studentIds: admin.firestore.FieldValue.arrayRemove(userId),
         studentCount: admin.firestore.FieldValue.increment(-1)
       });
     }
     
     // Clear user's classroom memberships
     await admin.firestore().collection('users').doc(userId).update({
       classroomIds: [],
       pendingClassroomRequests: []
     });
     
     // If teacher: handle content
     if (user.data().role === 'teacher') {
       // Flag all teacher's content for review
       const classrooms = await admin.firestore().collection('classrooms')
         .where('teacherId', '==', userId).get();
       for (let classroom of classrooms.docs) {
         await classroom.ref.update({ isActive: false });
       }
     }
     
     // If principal: alert admin for manual school transfer
     if (user.data().isPrincipal) {
       await admin.firestore().collection('admin_alerts').add({
         type: 'principal_banned',
         userId, schoolId: user.data().principalOfSchool,
         message: 'Banned principal needs school ownership transfer',
         createdAt: admin.firestore.FieldValue.serverTimestamp()
       });
     }
     
     return { success: true };
   });
   ```
   
4. Show success: "User banned."
   
5. (Optional) Send email to user with ban reason and appeal process
```

---

### 5.3 Platform Analytics

**Flow:**
```
1. Admin Dashboard → "Analytics" tab (default)
   
2. → Analytics Overview
   - Summary cards:
     * Total Users: 4,523
     * Active Users (7 days): 2,100 (46%)
     * Total Schools: 120
     * Total Classrooms: 450
     * Storage Used: 2.3 GB / 5 GB
     * Firestore Reads Today: 8,234 / 50,000
   
   - Charts:
     * User Growth (line chart, last 30 days)
     * XP Distribution (histogram)
     * Realm Popularity (bar chart: completion rates)
     * Game Popularity (bar chart: play counts)
   
   - Tables:
     * Top 10 Schools (by student count)
     * Top 10 Teachers (by classroom engagement)
     * Recent Signups (last 20 users)
   
3. Export buttons:
   * [Export All Users] → CSV
   * [Export Schools] → CSV
   * [Export Usage Report] → PDF
```

**Data Fetching:**
- Pre-aggregated data via Cloud Functions (daily)
- Stored in `/admin_analytics/{date}` collection
- Real-time Firebase quota usage via Admin SDK

---

## 6. Offline & Sync Flows

### 6.1 Download Content for Offline

**Flow:**
```
1. Learn Screen → Tap "Download" on a realm
   
2. → Download Confirmation
   - "Download Copyright Realm (15 MB)?"
   - Buttons: [Cancel] [Download]
   
3. Tap "Download"
   
4. Fetch content:
   - Download ZIP from Firebase Hosting:
     `/offline_content/realm_1.zip`
   - ZIP contains:
     * realm_1.json (metadata)
     * level_1.json, level_2.json, ... (content)
     * assets/ (images, minimal)
   
5. Extract ZIP:
   - Save JSON files to local storage (sqflite)
   - Save images to device cache
   
6. Update local state:
   ```dart
   await localDB.insert('downloaded_content', {
     'realmId': 'realm_1',
     'version': '1.0.0',
     'downloadedAt': DateTime.now().toIso8601String()
   });
   ```
   
7. Show success: "Downloaded! Available offline."
   
8. Realm card now shows "Downloaded ✓" badge
```

---

### 6.2 Play Offline

**Flow:**
```
1. User is offline (no internet)
   
2. Open app → Splash Screen
   
3. → Main Screen (loads from cache)
   - Show banner: "You're offline. Some features unavailable."
   
4. Tap "Learn" → Realm Map
   - Downloaded realms: Available (normal color)
   - Not downloaded: Disabled (greyed out, "Download to play offline")
   
5. Tap downloaded realm → Level list
   - Load content from local storage (sqflite)
   - Images loaded from cache
   
6. Complete level:
   - XP earned stored locally:
     ```dart
     await localDB.insert('pending_xp', {
       'userId': currentUser.uid,
       'contentId': 'realm_1_level_1',
       'xpEarned': 100,
       'timestamp': DateTime.now().toIso8601String()
     });
     ```
   - Progress stored locally
   - Badge checks performed locally (if criteria met, queued)
   
7. User sees:
   - "100 XP earned (will sync when online)"
   - XP counter updates locally
   - Sync icon appears in top bar
```

---

### 6.3 Sync When Back Online

**Flow:**
```
1. App detects internet connection (connectivity_plus package)
   
2. → Sync process starts automatically
   
3. Fetch pending operations from local DB:
   ```dart
   List<PendingXP> pendingXP = await localDB.query('pending_xp');
   List<PendingProgress> pendingProgress = await localDB.query('pending_progress');
   ```
   
4. For each pending XP:
   ```dart
   for (var pending in pendingXP) {
     try {
       // Update Firestore
       await FirebaseFirestore.instance
         .collection('progress')
         .doc('${pending.userId}__${pending.contentId}')
         .set({
           'xpEarned': FieldValue.increment(pending.xpEarned),
           'completedAt': Timestamp.fromDate(DateTime.parse(pending.timestamp)),
           // ... other fields
         }, SetOptions(merge: true));
       
       // Update user's total XP
       await FirebaseFirestore.instance
         .collection('users')
         .doc(pending.userId)
         .update({
           'totalXP': FieldValue.increment(pending.xpEarned)
         });
       
       // Mark as synced
       await localDB.delete('pending_xp', where: 'id = ?', whereArgs: [pending.id]);
       
     } catch (e) {
       // Sync failed, keep in queue
       print('Sync error: $e');
     }
   }
   ```
   
5. Show notification: "Sync complete! 300 XP added."
   
6. Check for badge unlocks (server-side or client re-check)
   
7. Update UI (refresh leaderboards, badges, etc.)
```

**Conflict Resolution:**
- XP: Always additive (use `FieldValue.increment()`)
- Progress: Merge strategy (if level completed offline and online, keep completed)
- Timestamp: Server timestamp wins for "completedAt"

---

## 7. Edge Cases & Error Handling

### 7.1 Classroom Code Collision

**Scenario:** Two classrooms generated same code (extremely rare with 5-char alphanumeric = 60M combinations)

**Handling:**
```dart
Future<String> generateUniqueClassroomCode() async {
  int attempts = 0;
  while (attempts < 10) {
    String code = generateClassroomCode();
    bool exists = await classroomCodeExists(code);
    if (!exists) return code;
    attempts++;
  }
  throw Exception('Failed to generate unique code after 10 attempts');
}
```

---

### 7.2 Student Joins Classroom, Then School is Deleted

**Scenario:**
1. Student joins Classroom A (part of School X)
2. Principal deletes School X
3. What happens to Classroom A?

**Handling:**
- School deletion requires all classrooms to be deleted/reassigned first
- If classroom is reassigned to another school → Student stays in classroom (new school association)
- If classroom is deleted → Cloud Function removes student from classroom but preserves progress

---

### 7.3 User Deletes Account

**Flow:**
```
1. Profile Screen → Settings → "Delete Account"
   
2. → Delete Account Confirmation
   - Warning: "This will permanently delete your account and all data."
   - Input field: "Type DELETE to confirm"
   - Button: "Delete My Account"
   
3. Trigger Cloud Function: deleteUserAccount()
   ```javascript
   exports.deleteUserAccount = functions.https.onCall(async (data, context) => {
     const userId = context.auth.uid;
     
     // 1. Remove from all classrooms
     const user = await admin.firestore().collection('users').doc(userId).get();
     for (let classroomId of user.data().classroomIds || []) {
       await admin.firestore().collection('classrooms').doc(classroomId).update({
         studentIds: admin.firestore.FieldValue.arrayRemove(userId)
       });
     }
     
     // 2. If teacher: reassign or delete classrooms
     const classrooms = await admin.firestore().collection('classrooms')
       .where('teacherId', '==', userId).get();
     for (let classroom of classrooms.docs) {
       await classroom.ref.delete(); // Or show prompt to reassign
     }
     
     // 3. If principal: prevent deletion (must transfer first)
     if (user.data().isPrincipal) {
       throw new functions.https.HttpsError(
         'failed-precondition',
         'Transfer school ownership before deleting account'
       );
     }
     
     // 4. Anonymize progress (keep for analytics)
     const progressDocs = await admin.firestore().collection('progress')
       .where('userId', '==', userId).get();
     for (let doc of progressDocs.docs) {
       await doc.ref.update({
         userId: `deleted_user_${Date.now()}`,
         userName: 'Deleted User'
       });
     }
     
     // 5. Delete user document
     await admin.firestore().collection('users').doc(userId).delete();
     
     // 6. Delete Firebase Auth user
     await admin.auth().deleteUser(userId);
     
     // 7. Delete user uploads from Storage
     await deleteUserStorageFiles(userId);
     
     return { success: true };
   });
   ```
   
4. → Sign out and redirect to Welcome Screen
```

---

## 8. Summary

This document covers **25+ detailed user flows** for all roles:
- **Students:** Learning, games, classrooms, leaderboards, offline mode
- **Teachers:** Classroom creation, announcements, assignments, analytics
- **Principals:** School management, teacher approval, ownership transfer
- **Admins:** Moderation, analytics, user management

All flows are designed for:
- ✅ **Simplicity:** Minimal steps, clear CTAs
- ✅ **Safety:** Confirmations for destructive actions
- ✅ **Performance:** Optimized Firestore queries, caching
- ✅ **Offline-first:** Local storage, sync when online

**Next:** See `04_UI_UX_SPECIFICATIONS.md` for screen designs and component details.


