# IPlay - Complete App Documentation
## Part 7: Implementation Guide & Development Checklist

---

## 1. Development Phases Overview

**Total Estimated Time:** 8-12 weeks (1 developer, full-time)

| Phase | Duration | Deliverable |
|-------|----------|-------------|
| Phase 1: Setup & Auth | Week 1-2 | Firebase setup, authentication, basic navigation |
| Phase 2: Learning System | Week 3-4 | Realms, levels, content rendering, progress tracking |
| Phase 3: Gamification | Week 5-6 | XP, badges, streaks, leaderboards |
| Phase 4: Social Features | Week 7-8 | Classrooms, schools, announcements, assignments |
| Phase 5: Games & Challenges | Week 9 | 7 mini games, daily challenges |
| Phase 6: Polish & Testing | Week 10-11 | UI refinement, offline mode, bug fixes |
| Phase 7: Deployment | Week 12 | Production deployment, monitoring setup |

---

## 2. Phase 1: Setup & Authentication (Week 1-2)

### 2.1 Firebase Project Setup

**Tasks:**
1. ✅ Create Firebase project in Firebase Console
2. ✅ Add Android app (package name: `com.iplay.app`)
3. ✅ Add iOS app (optional, if targeting iOS)
4. ✅ Add Web app (optional, for testing)
5. ✅ Download `google-services.json` → `android/app/`
6. ✅ Download `GoogleService-Info.plist` → `ios/Runner/` (if iOS)
7. ✅ Enable Firebase Auth (Email/Password, Google Sign-In)
8. ✅ Enable Firestore Database (asia-south1 region)
9. ✅ Enable Firebase Storage
10. ✅ Enable Firebase Functions
11. ✅ Enable Firebase Hosting

**Commands:**
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize project
cd iplay
firebase init

# Select:
# - Firestore (rules, indexes)
# - Functions (JavaScript, Node.js 18)
# - Hosting
# - Storage (rules)

# Deploy initial rules
firebase deploy --only firestore:rules,storage:rules
```

### 2.2 Flutter Project Setup

**Tasks:**
1. ✅ Already done (existing Flutter project)
2. ✅ Update `pubspec.yaml` dependencies (already done)
3. ✅ Configure Android Gradle files (already done)
4. ✅ Create `lib/` folder structure:
   ```
   lib/
   ├── main.dart
   ├── core/
   │   ├── constants/
   │   ├── theme/
   │   └── utils/
   ├── models/
   ├── services/
   ├── providers/
   ├── screens/
   │   ├── splash/
   │   ├── welcome/
   │   ├── auth/
   │   ├── onboarding/
   │   ├── main/
   │   ├── home/
   │   ├── learn/
   │   ├── play/
   │   ├── leaderboard/
   │   ├── profile/
   │   └── teacher/
   └── widgets/
       ├── buttons/
       ├── cards/
       └── inputs/
   ```

### 2.3 Authentication Implementation

**Files to Create/Update:**

**`lib/services/auth_service.dart`:**
```dart
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  // Email signup
  Future<UserModel?> signUpWithEmail(String email, String password, String name) async {
    try {
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = credential.user;
      if (user == null) return null;
      
      // Create user document in Firestore
      final userModel = UserModel(
        uid: user.uid,
        email: email,
        displayName: name,
        role: '',  // Set later in role selection
        totalXP: 0,
        currentStreak: 0,
        createdAt: DateTime.now(),
      );
      
      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
      
      return userModel;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  // Email signin
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = credential.user;
      if (user == null) return null;
      
      final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
      if (!docSnapshot.exists) return null;
      
      return UserModel.fromMap(docSnapshot.data()!);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  // Google Sign-In (already implemented)
  Future<UserModel?> signInWithGoogle() async {
    // ... (existing code)
  }
  
  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
  
  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
```

**Testing Checklist:**
- [ ] Sign up with email/password
- [ ] Sign in with existing account
- [ ] Google Sign-In flow
- [ ] Sign out
- [ ] Forgot password
- [ ] Role selection after auth

---

## 3. Phase 2: Learning System (Week 3-4)

### 3.1 Static Content Setup

**Tasks:**
1. Create content JSON files in `public/content/` (Firebase Hosting)
2. Structure:
   ```
   public/content/
   ├── realms/
   │   ├── realm_1_copyright.json
   │   ├── realm_2_trademark.json
   │   └── ...
   ├── levels/
   │   ├── realm_1_level_1.json
   │   ├── realm_1_level_2.json
   │   └── ...
   └── games/
       └── game_config.json
   ```

**Example `realm_1_copyright.json`:**
```json
{
  "id": "realm_1",
  "version": "1.0.0",
  "name": "Copyright Realm",
  "description": "Learn about copyright protection for creative works",
  "icon": "assets/realms/copyright_icon.png",
  "color": "#FF6B6B",
  "prerequisite": null,
  "levels": [
    "realm_1_level_1",
    "realm_1_level_2",
    "realm_1_level_3",
    "realm_1_level_4",
    "realm_1_level_5",
    "realm_1_level_6"
  ],
  "estimatedMinutes": 45,
  "totalXP": 800,
  "updatedAt": "2025-10-15T00:00:00Z"
}
```

**Example `realm_1_level_1.json`:**
```json
{
  "id": "realm_1_level_1",
  "version": "1.0.0",
  "realmId": "realm_1",
  "name": "What is Copyright?",
  "content": [
    {
      "type": "text",
      "data": "Copyright is a legal right that grants the creator of original work exclusive rights to its use and distribution..."
    },
    {
      "type": "image",
      "data": "https://iplay.app/content/images/copyright_intro.png",
      "caption": "Copyright symbol ©"
    },
    {
      "type": "quiz",
      "data": {
        "question": "What does copyright protect?",
        "options": [
          "Original works of authorship",
          "Ideas and concepts",
          "Facts and data",
          "Titles and names"
        ],
        "correct": 0,
        "explanation": "Copyright protects original works of authorship, not the ideas behind them."
      }
    }
  ],
  "xpReward": 100,
  "estimatedMinutes": 8,
  "updatedAt": "2025-10-15T00:00:00Z"
}
```

**Deploy Content:**
```bash
firebase deploy --only hosting
```

### 3.2 Content Rendering

**Files to Create:**

**`lib/widgets/content_blocks/text_block.dart`:**
```dart
class TextBlock extends StatelessWidget {
  final String text;
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Text(
        text,
        style: AppTextStyles.bodyLarge,
      ),
    );
  }
}
```

**`lib/widgets/content_blocks/image_block.dart`:**
```dart
class ImageBlock extends StatelessWidget {
  final String imageUrl;
  final String? caption;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CachedNetworkImage(
          imageUrl: imageUrl,
          placeholder: (context, url) => CircularProgressIndicator(),
          errorWidget: (context, url, error) => Icon(Icons.error),
        ),
        if (caption != null)
          Text(caption!, style: AppTextStyles.caption),
      ],
    );
  }
}
```

**`lib/widgets/content_blocks/quiz_block.dart`:**
```dart
class QuizBlock extends StatefulWidget {
  final Map<String, dynamic> quizData;
  final Function(bool isCorrect) onAnswer;
  
  @override
  _QuizBlockState createState() => _QuizBlockState();
}

class _QuizBlockState extends State<QuizBlock> {
  int? selectedOption;
  bool? isCorrect;
  
  void _submitAnswer() {
    if (selectedOption == null) return;
    
    setState(() {
      isCorrect = selectedOption == widget.quizData['correct'];
    });
    
    widget.onAnswer(isCorrect!);
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Check!', style: AppTextStyles.h3),
            SizedBox(height: 8),
            Text(widget.quizData['question'], style: AppTextStyles.bodyLarge),
            SizedBox(height: 16),
            ...List.generate(
              (widget.quizData['options'] as List).length,
              (index) => RadioListTile<int>(
                title: Text(widget.quizData['options'][index]),
                value: index,
                groupValue: selectedOption,
                onChanged: isCorrect == null ? (val) {
                  setState(() => selectedOption = val);
                } : null,
              ),
            ),
            if (isCorrect != null) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                color: isCorrect! ? Colors.green[100] : Colors.red[100],
                child: Text(
                  isCorrect! ? '✓ Correct!' : '✗ Incorrect',
                  style: TextStyle(
                    color: isCorrect! ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(widget.quizData['explanation'], style: AppTextStyles.bodySmall),
            ] else
              PrimaryButton(
                text: 'Submit Answer',
                onPressed: _submitAnswer,
              ),
          ],
        ),
      ),
    );
  }
}
```

**Testing Checklist:**
- [ ] Fetch realm data from Hosting
- [ ] Display realm cards with progress
- [ ] Navigate to realm detail
- [ ] Display levels in correct order
- [ ] Locked/unlocked states work
- [ ] Level content renders (text, images, quizzes)
- [ ] Quiz answers are validated
- [ ] XP is awarded on completion

---

## 4. Phase 3: Gamification (Week 5-6)

### 4.1 XP System Implementation

**Files to Create:**

**`lib/services/xp_service.dart`:**
```dart
class XPService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<void> awardXP(String userId, String contentId, int xpAmount, String contentType) async {
    final batch = _firestore.batch();
    
    // Update progress document
    final progressRef = _firestore.collection('progress').doc('${userId}__$contentId');
    batch.set(progressRef, {
      'userId': userId,
      'contentId': contentId,
      'contentType': contentType,
      'xpEarned': FieldValue.increment(xpAmount),
      'completedAt': FieldValue.serverTimestamp(),
      'status': 'completed',
    }, SetOptions(merge: true));
    
    // Update user total XP
    final userRef = _firestore.collection('users').doc(userId);
    batch.update(userRef, {
      'totalXP': FieldValue.increment(xpAmount),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    await batch.commit();
    
    // Check for badge unlocks (client-side)
    await _checkBadgeUnlocks(userId);
  }
  
  Future<void> _checkBadgeUnlocks(String userId) async {
    // Fetch user data
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data()!;
    
    // Fetch all badges
    final badgesSnapshot = await _firestore.collection('badges').get();
    
    for (final badgeDoc in badgesSnapshot.docs) {
      final badge = badgeDoc.data();
      
      // Skip if already earned
      if ((userData['badges'] as List).contains(badgeDoc.id)) continue;
      
      // Check criteria
      bool shouldUnlock = false;
      
      switch (badge['criteria']['type']) {
        case 'xp_threshold':
          shouldUnlock = userData['totalXP'] >= badge['criteria']['value'];
          break;
        case 'levels_completed':
          shouldUnlock = userData['totalLevelsCompleted'] >= badge['criteria']['value'];
          break;
        // ... other criteria
      }
      
      if (shouldUnlock) {
        await _unlockBadge(userId, badgeDoc.id, badge['xpBonus'] ?? 0);
      }
    }
  }
  
  Future<void> _unlockBadge(String userId, String badgeId, int xpBonus) async {
    await _firestore.collection('users').doc(userId).update({
      'badges': FieldValue.arrayUnion([badgeId]),
      'totalXP': FieldValue.increment(xpBonus),
    });
    
    // Show badge popup (via event bus or provider)
    // eventBus.fire(BadgeUnlockedEvent(badgeId));
  }
}
```

**Testing Checklist:**
- [ ] XP awarded on level completion
- [ ] XP displayed in profile
- [ ] XP level calculation correct
- [ ] Badge unlock triggers
- [ ] Badge popup shows
- [ ] Badge appears in profile

### 4.2 Leaderboard Implementation

**Deploy Cloud Function:**
```bash
cd functions
npm install

# Deploy leaderboard function
firebase deploy --only functions:dailyLeaderboardUpdate

# Manually trigger for testing
firebase functions:shell
> dailyLeaderboardUpdate()
```

**Client-Side Leaderboard Fetch:**
```dart
class LeaderboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<List<LeaderboardEntry>> fetchLeaderboard({
    required String scope,
    String? region,
    String? learnerType,
  }) async {
    String scopeId = scope;
    if (learnerType != null) scopeId += '_$learnerType';
    if (region != null) scopeId += '_$region';
    
    final doc = await _firestore.collection('leaderboard_cache').doc(scopeId).get();
    
    if (!doc.exists) return [];
    
    final data = doc.data()!;
    final topUsers = data['topUsers'] as List;
    
    return topUsers.map((user) => LeaderboardEntry.fromMap(user)).toList();
  }
}
```

**Testing Checklist:**
- [ ] Leaderboard cache generated daily
- [ ] Client fetches correct scope
- [ ] Filters work (solo/classroom)
- [ ] User's rank highlighted
- [ ] Top 3 have special styling

---

## 5. Phase 4: Social Features (Week 7-8)

### 5.1 Classroom Creation

**Teacher Flow:**
```dart
Future<void> createClassroom({
  required String name,
  required String teacherId,
  String? schoolId,
  bool requiresApproval = true,
}) async {
  // Generate unique code
  String code = await generateClassroomCode();
  
  // Create classroom document
  await _firestore.collection('classrooms').add({
    'name': name,
    'teacherId': teacherId,
    'schoolId': schoolId,
    'classroomCode': code,
    'requiresApproval': requiresApproval,
    'studentIds': [],
    'createdAt': FieldValue.serverTimestamp(),
  });
}

Future<String> generateClassroomCode() async {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random.secure();
  
  String code;
  bool exists;
  
  do {
    code = 'CLS-' + List.generate(5, (_) => chars[random.nextInt(chars.length)]).join();
    
    final query = await _firestore.collection('classrooms')
      .where('classroomCode', '==', code)
      .limit(1)
      .get();
    
    exists = query.docs.isNotEmpty;
  } while (exists);
  
  return code;
}
```

**Testing Checklist:**
- [ ] Teacher can create classroom
- [ ] Code is unique
- [ ] QR code generated
- [ ] Classroom appears in teacher dashboard

### 5.2 Student Join Flow

**Join by Code:**
```dart
Future<void> joinClassroomByCode(String code, String studentId) async {
  // Find classroom
  final query = await _firestore.collection('classrooms')
    .where('classroomCode', '==', code)
    .limit(1)
    .get();
  
  if (query.docs.isEmpty) {
    throw Exception('Invalid classroom code');
  }
  
  final classroom = query.docs.first;
  final classroomData = classroom.data();
  
  if (classroomData['requiresApproval']) {
    // Create join request
    await _firestore.collection('join_requests').add({
      'classroomId': classroom.id,
      'classroomName': classroomData['name'],
      'studentId': studentId,
      'studentName': (await _firestore.collection('users').doc(studentId).get()).data()!['displayName'],
      'status': 'pending',
      'requestedAt': FieldValue.serverTimestamp(),
    });
    
    // Update user
    await _firestore.collection('users').doc(studentId).update({
      'pendingClassroomRequests': FieldValue.arrayUnion([classroom.id]),
    });
    
  } else {
    // Join immediately
    await _firestore.collection('classrooms').doc(classroom.id).update({
      'studentIds': FieldValue.arrayUnion([studentId]),
      'studentCount': FieldValue.increment(1),
    });
    
    await _firestore.collection('users').doc(studentId).update({
      'classroomIds': FieldValue.arrayUnion([classroom.id]),
    });
  }
}
```

**Testing Checklist:**
- [ ] Student can enter code
- [ ] Join request created (if approval required)
- [ ] Direct join works (if no approval)
- [ ] Teacher sees pending request
- [ ] Teacher can approve/reject
- [ ] Student added to classroom on approval

---

## 6. Phase 5: Games & Challenges (Week 9)

### 6.1 Mini Game Template

**Example: Match the IPR (Memory Card Game)**

```dart
class MatchTheIPRGame extends StatefulWidget {
  @override
  _MatchTheIPRGameState createState() => _MatchTheIPRGameState();
}

class _MatchTheIPRGameState extends State<MatchTheIPRGame> {
  List<GameCard> cards = [];
  int? firstSelectedIndex;
  int matchedPairs = 0;
  int score = 0;
  int timeLeft = 60;
  Timer? timer;
  
  @override
  void initState() {
    super.initState();
    _initializeGame();
    _startTimer();
  }
  
  void _initializeGame() {
    // Create pairs
    final pairs = [
      {'type': 'copyright', 'image': 'assets/games/copyright.png'},
      {'type': 'trademark', 'image': 'assets/games/trademark.png'},
      {'type': 'patent', 'image': 'assets/games/patent.png'},
      // ... 3 more pairs
    ];
    
    cards = [];
    for (var pair in pairs) {
      cards.add(GameCard(type: pair['type']!, image: pair['image']!));
      cards.add(GameCard(type: pair['type']!, image: pair['image']!));
    }
    
    cards.shuffle();
  }
  
  void _startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (timeLeft > 0) {
          timeLeft--;
        } else {
          _endGame();
        }
      });
    });
  }
  
  void _onCardTap(int index) {
    if (cards[index].isMatched || cards[index].isFaceUp) return;
    
    setState(() {
      cards[index].isFaceUp = true;
    });
    
    if (firstSelectedIndex == null) {
      firstSelectedIndex = index;
    } else {
      // Check for match
      if (cards[firstSelectedIndex!].type == cards[index].type) {
        // Match!
        cards[firstSelectedIndex!].isMatched = true;
        cards[index].isMatched = true;
        matchedPairs++;
        score += 10;
        
        if (matchedPairs == 6) {
          _endGame();
        }
      } else {
        // No match, flip back after delay
        Future.delayed(Duration(milliseconds: 800), () {
          setState(() {
            cards[firstSelectedIndex!].isFaceUp = false;
            cards[index].isFaceUp = false;
          });
        });
      }
      
      firstSelectedIndex = null;
    }
  }
  
  void _endGame() {
    timer?.cancel();
    
    // Calculate final score
    final timePenalty = (60 - timeLeft) ~/ 2;
    final finalScore = score - timePenalty;
    final xpEarned = finalScore ~/ 10;
    
    // Award XP
    XPService().awardXP(currentUserId, 'game_match_ipr', xpEarned, 'game');
    
    // Show result screen
    showDialog(
      context: context,
      builder: (context) => GameResultDialog(
        score: finalScore,
        xpEarned: xpEarned,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Match the IPR'),
        actions: [
          Center(child: Text('Score: $score', style: TextStyle(fontSize: 18))),
          SizedBox(width: 16),
          Center(child: Text('Time: $timeLeft', style: TextStyle(fontSize: 18))),
          SizedBox(width: 16),
        ],
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1,
        ),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _onCardTap(index),
            child: Card(
              color: cards[index].isFaceUp || cards[index].isMatched
                  ? Colors.white
                  : Colors.blue,
              child: cards[index].isFaceUp || cards[index].isMatched
                  ? Image.asset(cards[index].image)
                  : Icon(Icons.question_mark, size: 50),
            ),
          );
        },
      ),
    );
  }
  
  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}

class GameCard {
  final String type;
  final String image;
  bool isFaceUp = false;
  bool isMatched = false;
  
  GameCard({required this.type, required this.image});
}
```

**Testing Checklist:**
- [ ] Game logic works
- [ ] Timer counts down
- [ ] Score calculated correctly
- [ ] XP awarded on game end
- [ ] High score saved

**Repeat for all 7 games.**

---

## 7. Phase 6: Polish & Testing (Week 10-11)

### 7.1 Offline Mode Implementation

**Download Content:**
```dart
Future<void> downloadRealmForOffline(String realmId) async {
  // Fetch realm data
  final realmData = await http.get(Uri.parse('https://iplay.app/content/realms/$realmId.json'));
  
  // Fetch all levels
  final realm = json.decode(realmData.body);
  for (String levelId in realm['levels']) {
    final levelData = await http.get(Uri.parse('https://iplay.app/content/levels/$levelId.json'));
    
    // Save to local database
    await _localDB.insert('content', {
      'id': levelId,
      'data': levelData.body,
      'realmId': realmId,
    });
  }
  
  // Mark as downloaded
  await _localDB.insert('downloaded_realms', {
    'realmId': realmId,
    'downloadedAt': DateTime.now().toIso8601String(),
  });
}
```

**Offline XP Queueing:**
```dart
Future<void> awardXPOffline(String userId, String contentId, int xpAmount) async {
  // Save to local queue
  await _localDB.insert('pending_xp', {
    'userId': userId,
    'contentId': contentId,
    'xpAmount': xpAmount,
    'timestamp': DateTime.now().toIso8601String(),
  });
  
  // Update local user state
  final user = await _localDB.query('users', where: 'uid = ?', whereArgs: [userId]);
  final currentXP = user.first['totalXP'] as int;
  await _localDB.update('users', {'totalXP': currentXP + xpAmount}, where: 'uid = ?', whereArgs: [userId]);
}

Future<void> syncPendingXP() async {
  final pendingXP = await _localDB.query('pending_xp');
  
  for (var xp in pendingXP) {
    try {
      await XPService().awardXP(
        xp['userId'],
        xp['contentId'],
        xp['xpAmount'],
        'level',
      );
      
      // Remove from queue
      await _localDB.delete('pending_xp', where: 'id = ?', whereArgs: [xp['id']]);
    } catch (e) {
      // Keep in queue, try again later
      print('Sync failed for XP: $e');
    }
  }
}
```

**Testing Checklist:**
- [ ] Download realm works
- [ ] Offline content loads
- [ ] XP queues locally
- [ ] Sync works on reconnect
- [ ] Conflict resolution correct

---

## 8. Phase 7: Deployment (Week 12)

### 8.1 Pre-Deployment Checklist

**Code:**
- [ ] All linter warnings fixed
- [ ] No hardcoded secrets (API keys in environment variables)
- [ ] Error handling added to all async calls
- [ ] Loading states for all network requests
- [ ] User-friendly error messages

**Firebase:**
- [ ] Security rules deployed and tested
- [ ] Indexes created for all queries
- [ ] Cloud Functions deployed and tested
- [ ] Storage rules deployed
- [ ] Firestore and Storage backups configured

**Testing:**
- [ ] Unit tests for critical logic (XP calculation, badge unlocks)
- [ ] Integration tests for auth, classroom join, XP award
- [ ] Manual testing on Android (physical device)
- [ ] Manual testing on iOS (if applicable)
- [ ] Performance testing (app size, load time, memory usage)

**Content:**
- [ ] All 6 realms content written and reviewed
- [ ] All 35 levels content complete
- [ ] All 7 games functional
- [ ] Images optimized (<200 KB each)
- [ ] Static content deployed to Hosting

### 8.2 Production Deployment

**Android:**
```bash
# Build release APK
flutter build apk --release

# Or build App Bundle for Play Store
flutter build appbundle --release

# Sign APK (if not using Play App Signing)
jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 -keystore my-release-key.jks app-release.apk alias_name

# Output: build/app/outputs/bundle/release/app-release.aab
```

**iOS (if applicable):**
```bash
flutter build ios --release

# Open Xcode and upload to App Store Connect
open ios/Runner.xcworkspace
```

**Web (if applicable):**
```bash
flutter build web --release

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

### 8.3 Post-Deployment Monitoring

**Firebase Console:**
- Monitor Firestore usage (reads/writes/storage)
- Monitor Cloud Functions invocations
- Monitor Storage usage
- Set up budget alerts (80% of free tier limits)

**Crashlytics:**
```dart
// Add to main.dart
await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
```

**Analytics:**
```dart
await FirebaseAnalytics.instance.logEvent(
  name: 'level_completed',
  parameters: {'level_id': 'realm_1_level_1', 'xp_earned': 100},
);
```

---

## 9. Maintenance & Updates

### 9.1 Content Updates

**Adding a New Realm:**
1. Create `realm_7_newrealm.json`
2. Create level JSON files (`realm_7_level_1.json`, etc.)
3. Add realm to Firestore `/badges` (realm completion badge)
4. Deploy to Hosting: `firebase deploy --only hosting`
5. Increment app version (trigger client update prompt)

**Updating Existing Content:**
1. Increment `version` field in JSON (e.g., `1.0.0` → `1.1.0`)
2. Deploy to Hosting
3. Client checks version on launch, shows "Update available" prompt

### 9.2 Bug Fixes

**Process:**
1. User reports bug via Feedback form (stored in Firestore)
2. Admin reviews in admin dashboard
3. Fix code, test locally
4. Increment patch version (e.g., `1.0.1`)
5. Build and deploy new APK/AAB
6. Update release notes

### 9.3 Feature Additions

**Example: Adding Push Notifications (Phase 2)**
1. Enable Firebase Cloud Messaging (FCM) in console
2. Add `firebase_messaging` to `pubspec.yaml`
3. Implement notification service
4. Update Cloud Functions to send notifications (classroom announcements, join approvals)
5. Test thoroughly
6. Increment minor version (e.g., `1.1.0`)
7. Deploy

---

## 10. Summary

This implementation guide provides:

- ✅ **7-phase development plan** (12 weeks total)
- ✅ **Detailed task checklists** for each phase
- ✅ **Code examples** for critical features
- ✅ **Testing guidelines** (unit, integration, manual)
- ✅ **Deployment process** (Android, iOS, Web)
- ✅ **Post-launch monitoring** (Crashlytics, Analytics)
- ✅ **Maintenance plan** (content updates, bug fixes, features)

**All tasks are achievable within the free tier constraints.**

**Next:** See `README.md` for quick start guide and project overview.



