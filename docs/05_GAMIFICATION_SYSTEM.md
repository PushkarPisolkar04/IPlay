# IPlay - Complete App Documentation
## Part 5: Gamification System

---

## 1. XP (Experience Points) System

### 1.1 XP Sources & Formulas

| Activity | XP Reward | Formula/Notes |
|----------|-----------|---------------|
| **Complete Level** | 50-200 XP | Based on level difficulty: Easy (50), Medium (100), Hard (150), Expert (200) |
| **Replay Level (Perfect)** | 25% of original | Encourages mastery; only if 100% quiz score |
| **Complete Realm** | 300 XP (bonus) | Awarded after final level of realm |
| **Daily Challenge** | 50 XP | Fixed reward if score ≥ 3/5 |
| **Game 1: IP Quiz Master** | 10 XP per correct | Max 100 XP (10 questions, 15 sec each) |
| **Game 2: Match the IPR** | Score ÷ 10 | Max ~20 XP (12 cards, 6 pairs, 60 sec) |
| **Game 3: Spot the Original** | 15 XP per correct | Max 75 XP (5 rounds, 4 images each) |
| **Game 4: IP Defender** | Score ÷ 50 | Max ~50 XP (tap-to-defend, 5 waves) |
| **Game 5: GI Mapper** | 10 XP per correct | Max 80 XP (drag 8 items to India map) |
| **Game 6: Patent Detective** | 20 XP per case | Max 60 XP (3 patent investigation cases) |
| **Game 7: Innovation Lab** | 100 XP | Fixed (draw invention + simulation) |
| **Badge Unlocked** | Variable | See badge table (section 2) |
| **Assignment Submission** | 20 XP | Fixed (optional teacher config) |
| **First Login of Day** | 10 XP | Encourages daily engagement |
| **7-Day Streak** | 100 XP (bonus) | One-time on streak milestone |

### 1.2 XP Caps & Anti-Abuse

**Daily XP Cap:** 1000 XP/day (prevents grinding)
- Implemented client-side (soft cap, shows warning)
- Server validates timestamps (Cloud Function)

**Replay Limits:**
- Each level can be replayed unlimited times
- But XP earned reduces: 100% → 25% → 10% → 0% (after 3rd replay)

**Quiz Attempts:**
- Failed quiz (< 3/5) can be retried once
- After 1 retry, must wait 24 hours to retry again (anti-spam)

### 1.3 XP to Level Mapping

**Level Formula:** `Level = floor(sqrt(totalXP / 100))`

| Level | XP Required | XP to Next Level |
|-------|-------------|------------------|
| 1     | 0           | 100              |
| 2     | 100         | 300              |
| 3     | 400         | 500              |
| 4     | 900         | 700              |
| 5     | 1,600       | 900              |
| 10    | 10,000      | 1,900            |
| 20    | 40,000      | 3,900            |
| 50    | 250,000     | 9,900            |

**Rationale:** Square root scaling prevents level-up from becoming too slow at high levels.

---

## 2. Badge System

### 2.1 Badge Categories

**1. Milestone Badges** (progress-based)
**2. Streak Badges** (consistency-based)
**3. Mastery Badges** (skill-based)
**4. Social Badges** (classroom-based)
**5. Special Badges** (rare, event-based)

### 2.2 Complete Badge List (35 Badges)

#### Milestone Badges (10)

| Badge ID | Name | Icon | Criteria | XP Bonus | Rarity |
|----------|------|------|----------|----------|--------|
| first_level | First Steps | 👣 | Complete 1 level | 50 | Common |
| first_realm | Realm Explorer | 🗺️ | Complete 1 realm | 100 | Common |
| three_realms | Tri-Master | 🏅 | Complete 3 realms | 200 | Rare |
| all_realms | IP Mastermind | 🧠 | Complete all 6 realms | 1000 | Legendary |
| xp_500 | Rising Star | ⭐ | Earn 500 XP | 50 | Common |
| xp_1000 | Skilled Learner | 🌟 | Earn 1,000 XP | 100 | Common |
| xp_5000 | Expert Scholar | 🏆 | Earn 5,000 XP | 300 | Rare |
| xp_10000 | Grand Master | 👑 | Earn 10,000 XP | 500 | Epic |
| level_10 | Level 10 Achiever | 🔟 | Reach Level 10 | 100 | Common |
| level_20 | Level 20 Legend | 🔥 | Reach Level 20 | 300 | Rare |

#### Streak Badges (6)

| Badge ID | Name | Icon | Criteria | XP Bonus | Rarity |
|----------|------|------|----------|----------|--------|
| streak_3 | 3-Day Streak | 📅 | 3-day streak | 30 | Common |
| streak_7 | Week Warrior | 🗓️ | 7-day streak | 100 | Common |
| streak_14 | Fortnight Fighter | 💪 | 14-day streak | 200 | Rare |
| streak_30 | Monthly Master | 🌙 | 30-day streak | 500 | Epic |
| streak_100 | Century Club | 💯 | 100-day streak | 1500 | Legendary |
| streak_365 | Year-Long Learner | 🎉 | 365-day streak | 5000 | Legendary |

#### Mastery Badges (7)

| Badge ID | Name | Icon | Criteria | XP Bonus | Rarity |
|----------|------|------|----------|----------|--------|
| perfect_quiz | Quiz Perfectionist | 💯 | Get 100% on any final quiz | 150 | Rare |
| perfect_three | Triple Perfect | ⭐⭐⭐ | Get 100% on 3 final quizzes | 300 | Epic |
| realm_copyright | Copyright Champion | ©️ | Complete Copyright Realm | 200 | Rare |
| realm_trademark | Trademark Titan | ™️ | Complete Trademark Realm | 200 | Rare |
| realm_patent | Patent Pro | 🔬 | Complete Patent Realm | 200 | Rare |
| realm_design | Design Maestro | 🎨 | Complete Design Realm | 200 | Rare |
| game_master | Game Master | 🎮 | Play all 7 games (≥1 attempt each) | 300 | Epic |

#### Social Badges (6)

| Badge ID | Name | Icon | Criteria | XP Bonus | Rarity |
|----------|------|------|----------|----------|--------|
| first_classroom | Classroom Joiner | 🎓 | Join 1 classroom | 50 | Common |
| three_classrooms | Multi-Class Learner | 🏫 | Join 3 classrooms | 150 | Rare |
| top_class | Class Champion | 🏆 | Rank #1 in classroom leaderboard (week) | 200 | Epic |
| top_school | School Star | ⭐ | Rank #1 in school leaderboard (week) | 300 | Epic |
| top_state | State Leader | 🌟 | Rank #1 in state leaderboard (week) | 500 | Legendary |
| assignment_ace | Assignment Ace | 📝 | Submit 10 assignments | 150 | Rare |

#### Special Badges (6)

| Badge ID | Name | Icon | Criteria | XP Bonus | Rarity |
|----------|------|------|----------|----------|--------|
| early_bird | Early Adopter | 🐦 | Signed up in first month of launch | 100 | Legendary |
| feedback_hero | Feedback Hero | 💬 | Submit 5 feedback reports | 100 | Rare |
| speedrun | Speedrunner | ⚡ | Complete a level in <5 minutes | 150 | Epic |
| night_owl | Night Owl | 🦉 | Complete a level between 10PM-6AM | 50 | Common |
| weekend_warrior | Weekend Warrior | 🎯 | Complete 5 levels on a weekend | 100 | Rare |
| daily_champ | Daily Challenge Champion | 🔥 | Complete 7 consecutive daily challenges | 200 | Epic |

### 2.3 Badge Unlock Logic (Client-Side)

```dart
// Pseudocode
Future<List<Badge>> checkBadgeUnlocks(User user, List<Badge> allBadges) async {
  List<Badge> newBadges = [];
  
  for (var badge in allBadges) {
    // Skip if already earned
    if (user.badges.contains(badge.id)) continue;
    
    bool shouldUnlock = false;
    
    switch (badge.criteria.type) {
      case 'levels_completed':
        shouldUnlock = user.totalLevelsCompleted >= badge.criteria.value;
        break;
      
      case 'realms_completed':
        shouldUnlock = user.totalRealmsCompleted >= badge.criteria.value;
        break;
      
      case 'xp_threshold':
        shouldUnlock = user.totalXP >= badge.criteria.value;
        break;
      
      case 'streak':
        shouldUnlock = user.currentStreak >= badge.criteria.value;
        break;
      
      case 'perfect_quiz':
        shouldUnlock = user.perfectQuizCount >= badge.criteria.value;
        break;
      
      case 'realm_complete':
        shouldUnlock = user.completedRealmIds.contains(badge.criteria.value);
        break;
      
      case 'games_played':
        shouldUnlock = user.gamesPlayed.length >= 7;
        break;
      
      case 'classrooms_joined':
        shouldUnlock = user.classroomIds.length >= badge.criteria.value;
        break;
      
      case 'leaderboard_rank':
        // Check leaderboard (server-side verification needed)
        shouldUnlock = await checkLeaderboardRank(user, badge.criteria);
        break;
      
      // ... other criteria types
    }
    
    if (shouldUnlock) {
      newBadges.add(badge);
      
      // Update Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'badges': FieldValue.arrayUnion([badge.id]),
        'totalXP': FieldValue.increment(badge.xpBonus ?? 0)
      });
    }
  }
  
  return newBadges;
}
```

### 2.4 Badge Display

**Profile Screen:**
- Grid layout (3 columns)
- Earned badges: Full color + bounce animation on tap
- Locked badges: Greyscale + lock icon overlay
- Tap badge → Modal with details:
  - Badge icon (large)
  - Name, description
  - Unlock date (if earned)
  - Unlock criteria (if locked)

**Badge Popup (on unlock):**
- Full-screen dimmed overlay
- Center modal with confetti animation
- Badge icon scales in (0 → 1.2 → 1)
- "+ XX XP" text bounces

---

## 3. Streak System

### 3.1 Streak Definition

**Activity Counts Toward Streak:**
- Complete a level (quiz passed)
- Play a game (any game, any score)
- Complete daily challenge
- Submit an assignment

**Does NOT Count:**
- Just opening the app
- Browsing content without completing
- Watching videos

### 3.2 Streak Calculation

```dart
void updateStreak(User user) {
  final now = DateTime.now();
  final lastActive = user.lastActiveDate;
  final hoursSinceActive = now.difference(lastActive).inHours;
  
  if (hoursSinceActive <= 48) {
    // Within grace period
    if (now.day != lastActive.day) {
      // New day → increment streak
      user.currentStreak += 1;
    }
    // Else: Same day, no change
  } else {
    // Streak broken (>48 hours)
    user.currentStreak = 1;
  }
  
  // Check for streak milestones (badges)
  if (user.currentStreak == 7 && !user.badges.contains('streak_7')) {
    // Award Week Warrior badge
  }
  
  user.lastActiveDate = now;
}
```

### 3.3 Streak Grace Period

**48-Hour Grace:**
- Allows for 1 day off without breaking streak
- Accounts for weekends, holidays, school breaks
- Example:
  - Monday 8 PM: Complete level (Day 1)
  - Tuesday: No activity (still OK)
  - Wednesday 6 PM: Complete level (Day 2, within 46 hours)

**Visual Indicator:**
- Streak icon 🔥 in profile
- Color changes:
  - 1-6 days: Orange
  - 7-29 days: Red
  - 30+ days: Gold (animated flame)

---

## 4. Leaderboard System

### 4.1 Leaderboard Types

**1. Classroom Leaderboard**
- Scope: Students in a specific classroom
- Ranking: Total XP (all-time)
- Updated: Real-time (client-side sorting)

**2. School Leaderboard**
- Scope: All students in a school (across all classrooms)
- Ranking: Total XP
- Updated: Daily (cached snapshot)

**3. State Leaderboard**
- Scope: All students in a state
- Ranking: Total XP
- Filters: Solo learners | Classroom learners | All
- Updated: Daily (cached snapshot)

**4. National Leaderboard**
- Scope: All students in India
- Ranking: Total XP
- Filters: Solo learners | Classroom learners | All
- Updated: Daily (cached snapshot)

### 4.2 Leaderboard Filtering

**Solo vs Classroom Learners:**
- **Solo:** `user.classroomIds.length == 0`
- **Classroom:** `user.classroomIds.length > 0`

**Rationale:** Prevents mixing independent learners with school-affiliated students (different contexts).

**Example Queries:**
```javascript
// State leaderboard - Solo learners only
db.collection('users')
  .where('state', '==', 'Delhi')
  .where('classroomIds', '==', [])  // Empty array = solo
  .orderBy('totalXP', 'desc')
  .limit(100)

// State leaderboard - Classroom learners only
db.collection('users')
  .where('state', '==', 'Delhi')
  .where('classroomIds', '!=', [])  // Non-empty array = classroom
  .orderBy('totalXP', 'desc')
  .limit(100)
```

### 4.3 Leaderboard Caching (Cloud Function)

**Daily Update (2 AM IST):**

```javascript
// Cloud Function
exports.dailyLeaderboardUpdate = functions.pubsub
  .schedule('0 2 * * *')  // Every day at 2 AM
  .timeZone('Asia/Kolkata')
  .onRun(async (context) => {
    
    // 1. National leaderboard (all users)
    await generateLeaderboard('national', null, null);
    
    // 2. National leaderboard (solo learners)
    await generateLeaderboard('national', 'solo', null);
    
    // 3. National leaderboard (classroom learners)
    await generateLeaderboard('national', 'classroom', null);
    
    // 4. State leaderboards (for each state)
    const states = ['Delhi', 'Maharashtra', 'Karnataka', ...];  // 36 states
    for (const state of states) {
      await generateLeaderboard('state', null, state);
      await generateLeaderboard('state', 'solo', state);
      await generateLeaderboard('state', 'classroom', state);
    }
    
    // 5. School leaderboards (for each school)
    const schools = await admin.firestore().collection('schools').get();
    for (const school of schools.docs) {
      await generateSchoolLeaderboard(school.id);
    }
    
    // 6. Classroom leaderboards (real-time, no cache needed)
    
    return null;
  });

async function generateLeaderboard(scope, learnerType, region) {
  let query = admin.firestore().collection('users')
    .where('isActive', '==', true);
  
  if (region) {
    query = query.where('state', '==', region);
  }
  
  if (learnerType === 'solo') {
    query = query.where('classroomIds', '==', []);
  } else if (learnerType === 'classroom') {
    query = query.where('classroomIds', '!=', []);
  }
  
  const users = await query
    .orderBy('totalXP', 'desc')
    .limit(100)
    .get();
  
  const topUsers = users.docs.map((doc, index) => ({
    userId: doc.id,
    displayName: doc.data().displayName,
    username: doc.data().username,
    avatarUrl: doc.data().avatarUrl,
    xp: doc.data().totalXP,
    rank: index + 1,
    schoolTag: doc.data().schoolTag,
    badges: doc.data().badges.length
  }));
  
  const scopeId = `${scope}${learnerType ? `_${learnerType}` : ''}${region ? `_${region}` : ''}`;
  
  await admin.firestore().collection('leaderboard_cache').doc(scopeId).set({
    scope,
    scopeName: region || 'National',
    period: 'all_time',
    learnerType,
    topUsers,
    totalUsers: users.size,
    lastUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    nextUpdateAt: getNextUpdateTime()  // Tomorrow 2 AM
  });
}
```

### 4.4 Leaderboard Rewards

**Weekly Top 3 (per scope):**
- #1: Special badge (e.g., "State Leader" if state leaderboard) + 500 XP bonus
- #2: 300 XP bonus
- #3: 200 XP bonus

**Awarded:** Every Monday at 2 AM (separate Cloud Function)

**Notification:** Email sent to winners (if email notifications enabled)

---

## 5. Certificate System

### 5.1 Certificate Types

**1. Realm Completion Certificates (6 total)**
- Awarded when all levels of a realm are completed
- Example: "Certificate of Completion: Copyright Realm"

**2. Master Certificate (1 total)**
- Awarded when all 6 realms are completed
- "IPlay IP Rights Master Certificate"

### 5.2 Certificate Generation (Cloud Function)

```javascript
exports.generateCertificate = functions.firestore
  .document('progress/{progressId}')
  .onUpdate(async (change, context) => {
    const after = change.after.data();
    const userId = after.userId;
    
    // Check if realm completed
    const user = await admin.firestore().collection('users').doc(userId).get();
    const realmId = extractRealmId(after.contentId);
    const realmProgress = user.data().progressSummary[realmId];
    
    if (realmProgress.levelsCompleted === realmProgress.totalLevels) {
      // Realm complete! Generate certificate
      
      // 1. Fetch realm details
      const realmData = await fetchRealmData(realmId);
      
      // 2. Generate PDF
      const pdfBytes = await createCertificatePDF({
        userName: user.data().displayName,
        realmName: realmData.name,
        completionDate: new Date(),
        certificateNumber: generateCertNumber()
      });
      
      // 3. Upload to Storage
      const bucket = admin.storage().bucket();
      const filePath = `certificates/${userId}/${realmId}_${Date.now()}.pdf`;
      const file = bucket.file(filePath);
      await file.save(pdfBytes);
      const downloadUrl = await file.getSignedUrl({ action: 'read', expires: '01-01-2100' });
      
      // 4. Create certificate document
      await admin.firestore().collection('certificates').add({
        userId,
        userName: user.data().displayName,
        certificateType: 'realm_completion',
        realmId,
        realmName: realmData.name,
        certificateUrl: downloadUrl[0],
        certificateNumber: generateCertNumber(),
        qrCodeData: `https://iplay.app/verify/${certNumber}`,
        isValid: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      // 5. Check for Master Certificate
      if (user.data().completedRealmIds.length === 6) {
        await generateMasterCertificate(userId, user.data());
      }
    }
  });

function generateCertNumber() {
  const year = new Date().getFullYear();
  const random = Math.random().toString(36).substring(2, 8).toUpperCase();
  return `CERT-${year}-${random}`;
}

async function createCertificatePDF(data) {
  const PDFDocument = require('pdf-lib').PDFDocument;
  const pdfDoc = await PDFDocument.create();
  const page = pdfDoc.addPage([595, 842]);  // A4 size
  
  // Add text, styling, QR code, etc.
  // (Full implementation in actual code)
  
  const pdfBytes = await pdfDoc.save();
  return pdfBytes;
}
```

### 5.3 Certificate Design (PDF Template)

**Layout:**
```
┌────────────────────────────────────────┐
│                                        │
│          [IPlay Logo]                  │
│                                        │
│    CERTIFICATE OF COMPLETION           │ ← Large, bold
│                                        │
│         This certifies that            │
│                                        │
│         [Student Name]                 │ ← Highlighted
│                                        │
│   has successfully completed the       │
│                                        │
│      [Realm Name] Realm                │ ← Colored, bold
│                                        │
│   demonstrating understanding of       │
│   [brief realm description]            │
│                                        │
│   Date: [DD Month YYYY]                │
│   Certificate No: CERT-2025-A4F9K2     │
│                                        │
│   [QR Code]          [Signature]       │ ← QR for verification
│   Verify at          Platform Admin    │
│   iplay.app/verify                     │
│                                        │
└────────────────────────────────────────┘
```

**Colors:**
- Border: Realm-specific color (e.g., red for Copyright)
- Background: Subtle watermark of realm icon
- Text: Professional black/grey

### 5.4 Certificate Verification (Public Page)

**URL:** `https://iplay.app/verify/{certificateNumber}`

**Page Content:**
- Certificate number, issue date
- Student name (if student hasn't hidden in settings)
- Realm name
- Status: Valid ✓ / Invalid ✗ (if revoked)

**Firestore Query:**
```javascript
const cert = await db.collection('certificates')
  .where('certificateNumber', '==', certNumber)
  .where('isValid', '==', true)
  .get();
```

---

## 6. Progress Tracking

### 6.1 Progress Data Structure

**User Document (`/users/{uid}`):**
```javascript
{
  // ... other fields
  totalXP: 1250,
  currentStreak: 7,
  lastActiveDate: Timestamp,
  
  progressSummary: {
    realm_1: {
      completed: false,
      levelsCompleted: 5,
      totalLevels: 6,
      xpEarned: 700,
      lastAccessedAt: Timestamp
    },
    realm_2: {
      completed: true,
      levelsCompleted: 6,
      totalLevels: 6,
      xpEarned: 800,
      lastAccessedAt: Timestamp
    },
    // ... other realms
  },
  
  gamesPlayed: ['game_match_ipr', 'game_copyright_defender'],
  perfectQuizCount: 3,
  completedRealmIds: ['realm_2'],
  totalLevelsCompleted: 11
}
```

**Progress Document (`/progress/{userId}__{contentId}`):**
```javascript
{
  userId: 'user123',
  contentId: 'realm_1_level_1',
  contentType: 'level',
  contentVersion: '1.0.0',
  status: 'completed',
  completionPercentage: 100,
  xpEarned: 100,
  attemptsCount: 1,
  highScore: null,
  accuracy: 80,  // % correct in quiz
  timeSpentSeconds: 480,
  startedAt: Timestamp,
  completedAt: Timestamp,
  lastAttemptAt: Timestamp
}
```

### 6.2 Progress Calculation

**Realm Progress:**
```dart
double calculateRealmProgress(String realmId, User user) {
  final summary = user.progressSummary[realmId];
  if (summary == null) return 0.0;
  return (summary.levelsCompleted / summary.totalLevels) * 100;
}
```

**Overall Progress:**
```dart
double calculateOverallProgress(User user) {
  int totalLevels = 35;  // 6 realms × ~6 levels average
  return (user.totalLevelsCompleted / totalLevels) * 100;
}
```

---

## 7. Gamification Analytics

### 7.1 Metrics to Track

**Engagement:**
- Daily Active Users (DAU)
- Average session duration
- Streak distribution (how many users have 7+ day streaks?)

**Learning:**
- Average XP per user
- Realm completion rate (% who finish each realm)
- Level drop-off points (where do users quit?)

**Social:**
- % of users in classrooms
- Classroom activity (announcements, assignments)
- Leaderboard engagement (how often users check leaderboard?)

**Gamification Effectiveness:**
- Badge unlock rate (which badges are most earned?)
- Certificate download rate
- XP sources breakdown (levels vs games vs challenges)

### 7.2 A/B Testing Ideas (Future)

- XP reward amounts (increase/decrease to find optimal engagement)
- Streak grace period (24h vs 48h)
- Badge rarity distribution
- Daily challenge difficulty

---

## 8. Summary

The gamification system provides:

- ✅ **Comprehensive XP system** with 15+ earning methods
- ✅ **35 badges** across 5 categories (milestone, streak, mastery, social, special)
- ✅ **Robust streak system** with 48-hour grace period
- ✅ **Multi-tier leaderboards** with caching and filtering
- ✅ **Professional certificates** (PDF generation, verification)
- ✅ **Detailed progress tracking** (user + content level)

All designed to be:
- **Motivating:** Clear goals, frequent rewards
- **Fair:** Anti-abuse measures, level playing field
- **Sustainable:** Free-tier friendly (cached leaderboards, minimal writes)

**Next:** See `06_SECURITY_CLOUD_FUNCTIONS.md` for Firebase security rules and Cloud Functions implementation.


