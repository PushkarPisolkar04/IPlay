# IPlay App - Complete Consolidated Design Document

**Status:** This document consolidates ALL design decisions from all spec documents
**Source Documents:**
- app-ui-consistency-and-cms/design.md
- app-stabilization-complete/MASTER_DOCUMENT.md (Appendix B)
- COMPREHENSIVE_APP_ISSUES_REPORT.md (technical details)

---

## TABLE OF CONTENTS

1. [Architecture Overview](#architecture-overview)
2. [Design System](#design-system)
3. [Component Library](#component-library)
4. [Data Models](#data-models)
5. [Service Layer](#service-layer)
6. [Firebase Structure](#firebase-structure)
7. [Security & Permissions](#security--permissions)
8. [Performance Optimization](#performance-optimization)
9. [Feature-Specific Designs](#feature-specific-designs)
10. [Admin Panel Design](#admin-panel-design)

---

## ARCHITECTURE OVERVIEW

### High-Level System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     IPlay Flutter App                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Student    │  │   Teacher    │  │  Principal   │      │
│  │  Dashboard   │  │  Dashboard   │  │  Dashboard   │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│         │                  │                  │              │
│         └──────────────────┴──────────────────┘              │
│                            │                                 │
│                   ┌────────▼────────┐                        │
│                   │  Shared Widgets │                        │
│                   │  (CleanCard,    │                        │
│                   │   StatCard,     │                        │
│                   │   etc.)         │                        │
│                   └────────┬────────┘                        │
│                            │                                 │
│         ┌──────────────────┴──────────────────┐             │
│         │                                      │             │
│  ┌──────▼──────┐                      ┌───────▼──────┐      │
│  │   Content   │                      │  Moderation  │      │
│  │   Service   │                      │   Service    │      │
│  └──────┬──────┘                      └───────┬──────┘      │
│         │                                      │             │
└─────────┼──────────────────────────────────────┼─────────────┘
          │                                      │
          │         Firebase Backend             │
          │                                      │
    ┌─────▼──────────────────────────────────────▼─────┐
    │                                                   │
    │  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
    │  │Firestore │  │ Storage  │  │   Auth   │       │
    │  │(Metadata)│  │(Content) │  │          │       │
    │  └──────────┘  └──────────┘  └──────────┘       │
    │                                                   │
    └───────────────────────┬───────────────────────────┘
                            │
                            │
                ┌───────────▼───────────┐
                │                       │
                │   Admin Panel (Web)   │
                │                       │
                │  ┌─────────────────┐  │
                │  │ Content Manager │  │
                │  ├─────────────────┤  │
                │  │ Config Manager  │  │
                │  ├─────────────────┤  │
                │  │   Analytics     │  │
                │  ├─────────────────┤  │
                │  │  Moderation     │  │
                │  └─────────────────┘  │
                │                       │
                └───────────────────────┘
```

### Layer Architecture

**Presentation Layer:**
- Screens (50+ screens organized by role and feature)
- Widgets (42 reusable components)
- State Management (Provider pattern)

**Business Logic Layer:**
- Services (15+ services for core functionality)
- Models (8 data models)
- Providers (State containers)

**Data Layer:**
- Firebase Firestore (User data, progress, classrooms only)
- Local JSON Files (All educational content - levels, quizzes, games)
- Local Assets (All images bundled with app)
- SharedPreferences (Content cache, local settings)
- SQLite (Offline user data cache)

---

## DESIGN SYSTEM

### Color Palette

**Primary Colors:**
```dart
class AppColors {
  // Primary
  static const primaryIndigo = Color(0xFF6366F1);
  static const primaryPink = Color(0xFFEC4899);
  static const primaryGreen = Color(0xFF10B981);
  static const primaryAmber = Color(0xFFF59E0B);
  
  // Secondary
  static const secondaryPurple = Color(0xFF8B5CF6);
  static const secondaryBlue = Color(0xFF3B82F6);
  static const secondaryRed = Color(0xFFEF4444);
  static const secondaryTeal = Color(0xFF14B8A6);
  
  // Gradients
  static const gradientPrimary = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  );
  static const gradientSuccess = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
  );
  
  // Neutrals
  static const background = Color(0xFFF5F7FA);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
  static const border = Color(0xFFE5E7EB);
}
```

### Typography

**Font Families:**
- **Headings:** Poppins (Bold, SemiBold)
- **Body:** Inter (Regular, Medium)
- **Monospace:** Fira Code (for code snippets)

**Text Styles:**
```dart
class AppTextStyles {
  // Headings
  static const h1 = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const h2 = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const h3 = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  // Body
  static const bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );
  
  static const bodyMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );
  
  static const bodySmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  
  // Special
  static const caption = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  
  static const button = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.surface,
  );
}
```

### Spacing System (8px Grid)

```dart
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  
  // Padding presets
  static const EdgeInsets paddingXS = EdgeInsets.all(xs);
  static const EdgeInsets paddingSM = EdgeInsets.all(sm);
  static const EdgeInsets paddingMD = EdgeInsets.all(md);
  static const EdgeInsets paddingLG = EdgeInsets.all(lg);
  static const EdgeInsets paddingXL = EdgeInsets.all(xl);
  
  // Horizontal/Vertical
  static const EdgeInsets horizontalMD = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets verticalMD = EdgeInsets.symmetric(vertical: md);
}
```

### Border Radius

```dart
class AppBorderRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 9999.0;
  
  static const BorderRadius radiusSM = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius radiusMD = BorderRadius.all(Radius.circular(md));
  static const BorderRadius radiusLG = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius radiusXL = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius radiusFull = BorderRadius.all(Radius.circular(full));
}
```

### Elevation & Shadows

```dart
class AppElevation {
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];
  
  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];
  
  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];
}
```

---

## COMPONENT LIBRARY

### Core Widgets

#### 1. CleanCard
**Purpose:** White card with shadow and border for content display
**Usage:** Dashboard stats, content containers, list items

```dart
class CleanCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? color;
  
  // Implementation details...
}
```

**Variants:**
- `CleanCard` - Standard white card
- `ColoredCard` - Card with custom background color
- `GradientCard` - Card with gradient background

#### 2. StatCard
**Purpose:** Display metrics with icon and value
**Usage:** Dashboard statistics, analytics displays

```dart
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  
  // Implementation details...
}
```

#### 3. PrimaryButton / SecondaryButton
**Purpose:** Consistent button styling across app
**Usage:** All action buttons

```dart
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;
  
  // Implementation details...
}
```

**Variants:**
- `PrimaryButton` - Filled button with primary color
- `SecondaryButton` - Outlined button
- `TextButton` - Text-only button
- `IconButton` - Icon-only button

#### 4. LevelCard
**Purpose:** Display level with lock/complete state
**Usage:** Learn page, realm detail page

```dart
class LevelCard extends StatelessWidget {
  final LevelModel level;
  final bool isLocked;
  final bool isCompleted;
  final VoidCallback onTap;
  
  // Implementation details...
}
```

#### 5. ProgressCard
**Purpose:** Display realm progress with visual bar
**Usage:** Dashboard, learn page

```dart
class ProgressCard extends StatelessWidget {
  final RealmModel realm;
  final double progress; // 0.0 to 1.0
  final int completedLevels;
  final int totalLevels;
  
  // Implementation details...
}
```

#### 6. GameCard
**Purpose:** Display game with metadata
**Usage:** Games page

```dart
class GameCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  
  // Implementation details...
}
```

#### 7. XPCounter
**Purpose:** Animated XP display
**Usage:** Dashboard, level completion

```dart
class XPCounter extends StatefulWidget {
  final int currentXP;
  final int? gainedXP;
  final bool animate;
  
  // Implementation details...
}
```

#### 8. StreakIndicator
**Purpose:** Display streak count with flame icon
**Usage:** Dashboard, profile

```dart
class StreakIndicator extends StatelessWidget {
  final int streakCount;
  final bool isActive;
  
  // Implementation details...
}
```

#### 9. LeaderboardTile
**Purpose:** Display user rank with medals
**Usage:** Leaderboard screens

```dart
class LeaderboardTile extends StatelessWidget {
  final int rank;
  final String userName;
  final String avatarUrl;
  final int xp;
  final bool isCurrentUser;
  
  // Implementation details...
}
```

#### 10. AchievementBadge
**Purpose:** Display badge with locked/unlocked state
**Usage:** Profile, achievements page

```dart
class AchievementBadge extends StatelessWidget {
  final BadgeModel badge;
  final bool isUnlocked;
  final VoidCallback? onTap;
  
  // Implementation details...
}
```

### Specialized Widgets

#### 11. OverlayBanner
**Purpose:** Non-intrusive status banner (offline/syncing)
**Usage:** App-wide for connectivity status

```dart
class OverlayBanner extends StatelessWidget {
  final String message;
  final BannerType type; // offline, syncing, error
  final bool isVisible;
  
  // Implementation details...
}
```

#### 12. LoadingSkeleton
**Purpose:** Shimmer loading effect
**Usage:** All list screens during data fetch

```dart
class LoadingSkeleton extends StatelessWidget {
  final int itemCount;
  final SkeletonType type; // card, list, grid
  
  // Implementation details...
}
```

#### 13. NotificationBellIcon
**Purpose:** Notification icon with badge count
**Usage:** App bars

```dart
class NotificationBellIcon extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;
  
  // Implementation details...
}
```

#### 14. BottomNavBar
**Purpose:** Consistent bottom navigation
**Usage:** Main app navigation

```dart
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final UserRole role;
  
  // Implementation details...
}
```

---

## DATA MODELS

### 1. UserModel

```dart
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final UserRole role; // student, teacher, principal
  final String? schoolId;
  final String? classroomId;
  
  // Gamification
  final int totalXP;
  final int currentLevel;
  final int streakCount;
  final DateTime? lastActivityDate;
  final List<String> unlockedBadges;
  final List<String> certificates;
  
  // Settings
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool hapticEnabled;
  
  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Methods
  Map<String, dynamic> toFirestore();
  factory UserModel.fromFirestore(DocumentSnapshot doc);
}
```

### 2. RealmModel

```dart
class RealmModel {
  final String id;
  final String title;
  final String description;
  final int order;
  final String iconPath;
  final Color color;
  final int totalLevels;
  final int xpReward;
  
  // Methods
  Map<String, dynamic> toJson();
  factory RealmModel.fromJson(Map<String, dynamic> json);
}
```

### 3. LevelModel

```dart
class LevelModel {
  final String id;
  final String realmId;
  final String title;
  final int levelNumber;
  final String difficulty; // Easy, Medium, Hard, Expert
  final int xpReward;
  final int estimatedMinutes;
  
  // Content
  final String? videoUrl;
  final int? videoDuration;
  final List<ContentBlock> contentBlocks;
  final List<String> keyTakeaways;
  
  // Quiz
  final List<QuizQuestion> quizQuestions;
  final int passingScore;
  
  // Metadata
  final String version;
  final DateTime updatedAt;
  
  // Methods
  Map<String, dynamic> toJson();
  factory LevelModel.fromJson(Map<String, dynamic> json);
}
```

### 4. ProgressModel

```dart
class ProgressModel {
  final String userId;
  final String realmId;
  final List<int> completedLevels;
  final int currentLevelNumber;
  final int xpEarned;
  final DateTime lastAccessedAt;
  
  // Methods
  Map<String, dynamic> toFirestore();
  factory ProgressModel.fromFirestore(DocumentSnapshot doc);
}
```

### 5. BadgeModel

```dart
class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final BadgeCategory category; // milestone, streak, mastery, social, special
  final BadgeRarity rarity; // common, rare, epic, legendary
  final String criteriaType; // xp_total, streak_days, realm_complete, etc.
  final int criteriaValue;
  final int xpBonus;
  
  // Methods
  Map<String, dynamic> toFirestore();
  factory BadgeModel.fromFirestore(DocumentSnapshot doc);
}
```

### 6. AssignmentModel

```dart
class AssignmentModel {
  final String id;
  final String title;
  final String description;
  final String teacherId;
  final String classroomId;
  final String schoolId; // Added for Firebase rules
  final String createdBy; // Added for Firebase rules
  final DateTime dueDate;
  final int maxPoints;
  final List<String>? attachmentUrls;
  final DateTime createdAt;
  
  // Methods
  Map<String, dynamic> toFirestore();
  factory AssignmentModel.fromFirestore(DocumentSnapshot doc);
}
```

### 7. ClassroomModel

```dart
class ClassroomModel {
  final String id;
  final String name;
  final String code; // 6-digit join code
  final String teacherId;
  final String schoolId;
  final List<String> studentIds;
  final DateTime createdAt;
  
  // Methods
  Map<String, dynamic> toFirestore();
  factory ClassroomModel.fromFirestore(DocumentSnapshot doc);
}
```

### 8. CertificateModel

```dart
class CertificateModel {
  final String id;
  final String userId;
  final String realmId;
  final String certificateNumber;
  final String pdfUrl;
  final String qrCodeData;
  final DateTime issuedAt;
  
  // Methods
  Map<String, dynamic> toFirestore();
  factory CertificateModel.fromFirestore(DocumentSnapshot doc);
}
```

---

*Document continues in next part...*

## SERVICE LAYER

### Core Services

#### 1. AuthService
**Location:** `lib/core/services/auth_service.dart`
**Purpose:** Handle authentication and user management

```dart
class AuthService {
  // Sign up with email/password
  Future<UserCredential> signUpWithEmail(String email, String password);
  
  // Sign in with email/password
  Future<UserCredential> signInWithEmail(String email, String password);
  
  // Sign in with Google
  Future<UserCredential> signInWithGoogle();
  
  // Sign out
  Future<void> signOut();
  
  // Password reset
  Future<void> sendPasswordResetEmail(String email);
  
  // Email verification
  Future<void> sendEmailVerification();
  
  // Get current user
  User? getCurrentUser();
}
```

**NOTE:** Duplicate exists at `lib/services/auth_service.dart` - needs consolidation

#### 2. ProgressService
**Location:** `lib/core/services/progress_service.dart`
**Purpose:** Track user progress through realms and levels

```dart
class ProgressService {
  // Complete a level
  Future<void> completeLevel(String userId, String realmId, int levelNumber, int xpEarned);
  
  // Get progress for a realm
  Future<ProgressModel?> getRealmProgress(String userId, String realmId);
  
  // Get all progress for user
  Future<List<ProgressModel>> getAllProgress(String userId);
  
  // Reset realm progress
  Future<void> resetRealmProgress(String userId, String realmId);
}
```

#### 3. XPService
**Location:** `lib/core/services/xp_service.dart`
**Purpose:** Manage XP rewards and daily caps

```dart
class XPService {
  // Award XP
  Future<void> awardXP(String userId, int amount, String source);
  
  // Check daily XP cap
  Future<bool> canEarnXP(String userId, int amount);
  
  // Get today's XP
  Future<int> getTodayXP(String userId);
  
  // Calculate replay XP reduction
  int calculateReplayXP(int baseXP, int attemptCount);
}
```

#### 4. StreakService
**Location:** `lib/services/streak_service.dart`
**Purpose:** Track daily login streaks

```dart
class StreakService {
  // Update streak on activity
  Future<void> updateStreakOnActivity(String userId);
  
  // Check if streak should reset
  bool shouldResetStreak(DateTime lastActivity);
  
  // Get current streak
  Future<int> getCurrentStreak(String userId);
  
  // Award streak milestone bonuses
  Future<void> checkStreakMilestones(String userId, int streakCount);
}
```

#### 5. BadgeService
**Location:** `lib/core/services/badge_service.dart`
**Purpose:** Manage badge unlocking and display

```dart
class BadgeService {
  // Check and unlock badges
  Future<List<BadgeModel>> checkBadgeUnlocks(String userId);
  
  // Get all badges
  Future<List<BadgeModel>> getAllBadges();
  
  // Get user's unlocked badges
  Future<List<BadgeModel>> getUserBadges(String userId);
  
  // Unlock specific badge
  Future<void> unlockBadge(String userId, String badgeId);
}
```

#### 6. ContentService
**Location:** `lib/core/services/content_service.dart`
**Purpose:** Load and cache learning content

```dart
class ContentService {
  // Load content from local JSON files
  Future<dynamic> loadLocalContent(String filePath);
  
  // Get content from cache (in-memory or SharedPreferences)
  Future<dynamic> getContent(String contentType, String id);
  
  // Cache content to SharedPreferences
  Future<void> cacheContent(String contentType, dynamic data);
  
  // Load realm data from local JSON
  Future<List<RealmModel>> getRealms();
  
  // Load level data from local JSON
  Future<List<LevelModel>> getLevels(String realmId);
  
  // Preload all content at app startup
  Future<void> preloadContent();
}
```

#### 7. CertificateService
**Location:** `lib/core/services/certificate_service.dart`
**Purpose:** Generate and manage certificates

```dart
class CertificateService {
  // Generate certificate PDF
  Future<String> generateCertificate(String userId, String realmId);
  
  // Get user certificates
  Future<List<CertificateModel>> getUserCertificates(String userId);
  
  // Download certificate
  Future<void> downloadCertificate(String certificateId);
  
  // Share certificate
  Future<void> shareCertificate(String certificateId);
}
```

**NOTE:** Currently uses in-app logic, needs to be moved to in-app generation

#### 8. NotificationService
**Location:** `lib/core/services/notification_service.dart`
**Purpose:** Handle push notifications and in-app notifications

```dart
class NotificationService {
  // Initialize FCM
  Future<void> initialize();
  
  // Request notification permissions
  Future<bool> requestPermissions();
  
  // Get FCM token
  Future<String?> getToken();
  
  // Handle foreground messages
  void handleForegroundMessage(RemoteMessage message);
  
  // Handle background messages
  static Future<void> handleBackgroundMessage(RemoteMessage message);
  
  // Send notification to user
  Future<void> sendNotification(String userId, String title, String body, Map<String, dynamic> data);
}
```

#### 9. SimplifiedChatService
**Location:** `lib/services/simplified_chat_service.dart`
**Purpose:** Handle teacher-student messaging

```dart
class SimplifiedChatService {
  // Send message
  Future<void> sendMessage(String chatId, String senderId, String message);
  
  // Get chat messages
  Stream<List<MessageModel>> getChatMessages(String chatId);
  
  // Create or get chat
  Future<String> getOrCreateChat(String teacherId, String studentId);
  
  // Mark messages as read
  Future<void> markAsRead(String chatId, String userId);
}
```

**NOTE:** Needs integration into navigation

#### 10. DailyChallengeService
**Location:** `lib/core/services/daily_challenge_service.dart`
**Purpose:** Generate and manage daily challenges

```dart
class DailyChallengeService {
  // Generate today's challenge
  Future<void> generateDailyChallenge();
  
  // Get today's challenge
  Future<DailyChallengeModel?> getTodaysChallenge();
  
  // Submit challenge attempt
  Future<void> submitAttempt(String userId, List<int> answers);
  
  // Check if user completed today
  Future<bool> hasCompletedToday(String userId);
}
```

**NOTE:** Needs to implement in-app generation (not in-app logic)

#### 11. OfflineProgressManager
**Location:** `lib/core/services/offline_progress_manager.dart`
**Purpose:** Manage offline content and progress

```dart
class OfflineProgressManager {
  // Content is always available offline (bundled locally)
  // This class only manages user progress offline
  
  // Save progress offline
  Future<void> saveProgressOffline(ProgressModel progress);
  
  // Get offline progress
  Future<List<ProgressModel>> getOfflineProgress(String userId);
  
  // Sync offline progress to Firebase when online
  Future<void> syncProgress();
  
  // Check if content is available (always true for local content)
  bool isContentAvailable(String realmId) => true;
}
```

**NOTE:** Needs integration

#### 12. OfflineSyncService
**Location:** `lib/core/services/offline_sync_service.dart`
**Purpose:** Sync offline data when online

```dart
class OfflineSyncService {
  // Sync all offline data
  Future<void> syncAll();
  
  // Sync progress
  Future<void> syncProgress();
  
  // Check sync status
  Future<SyncStatus> getSyncStatus();
  
  // Listen to connectivity changes
  Stream<bool> get connectivityStream;
}
```

**NOTE:** Needs integration

#### 13. ModerationService
**Location:** `lib/utils/content_moderator.dart`
**Purpose:** Content moderation and profanity filtering

```dart
class ModerationService {
  // Check text for profanity
  bool containsProfanity(String text);
  
  // Create moderation report
  Future<void> createReport(String contentId, String contentType, String reason);
  
  // Escalate report to admin
  Future<void> escalateReport(String reportId);
  
  // Get profanity word list from Firebase
  Future<List<String>> getProfanityList();
}
```

#### 14. LeaderboardService
**Location:** `lib/core/services/leaderboard_service.dart`
**Purpose:** Manage leaderboard caching and aggregation

```dart
class LeaderboardService {
  // Update leaderboard cache
  Future<void> updateLeaderboardCache(String scope, String scopeId);
  
  // Get leaderboard
  Future<List<LeaderboardEntry>> getLeaderboard(String scope, String scopeId);
  
  // Get user rank
  Future<int> getUserRank(String userId, String scope, String scopeId);
}
```

**NOTE:** Needs to implement in-app aggregation (not in-app logic)

#### 15. BookmarkService
**Location:** `lib/services/bookmark_service.dart`
**Purpose:** Manage content bookmarks

```dart
class BookmarkService {
  // Add bookmark
  Future<void> addBookmark(String userId, String contentType, String contentId);
  
  // Remove bookmark
  Future<void> removeBookmark(String userId, String bookmarkId);
  
  // Get user bookmarks
  Future<List<BookmarkModel>> getUserBookmarks(String userId);
  
  // Check if bookmarked
  Future<bool> isBookmarked(String userId, String contentType, String contentId);
}
```

---

## FIREBASE STRUCTURE

### Firestore Collections

#### 1. users
```
/users/{userId}
  - uid: string
  - email: string
  - displayName: string
  - avatarUrl: string (optional)
  - role: string (student, teacher, principal)
  - schoolId: string (optional)
  - classroomId: string (optional)
  - totalXP: number
  - currentLevel: number
  - streakCount: number
  - lastActivityDate: timestamp
  - unlockedBadges: array<string>
  - certificates: array<string>
  - notificationsEnabled: boolean
  - soundEnabled: boolean
  - hapticEnabled: boolean
  - createdAt: timestamp
  - updatedAt: timestamp
```

#### 2. schools
```
/schools/{schoolId}
  - name: string
  - code: string (6-digit)
  - principalId: string
  - address: string
  - city: string
  - state: string
  - createdAt: timestamp
```

#### 3. classrooms
```
/classrooms/{classroomId}
  - name: string
  - code: string (6-digit)
  - teacherId: string
  - schoolId: string
  - studentIds: array<string>
  - createdAt: timestamp
```

#### 4. progress
```
/progress/{userId__{realmId}}
  - userId: string
  - realmId: string
  - completedLevels: array<number>
  - currentLevelNumber: number
  - xpEarned: number
  - lastAccessedAt: timestamp
```

#### 5. badges
```
/badges/{badgeId}
  - name: string
  - description: string
  - iconPath: string
  - category: string
  - rarity: string
  - criteriaType: string
  - criteriaValue: number
  - xpBonus: number
```

#### 6. assignments
```
/assignments/{assignmentId}
  - title: string
  - description: string
  - teacherId: string
  - classroomId: string
  - schoolId: string
  - createdBy: string
  - dueDate: timestamp
  - maxPoints: number
  - attachmentUrls: array<string>
  - createdAt: timestamp
```

#### 7. assignment_submissions
```
/assignment_submissions/{submissionId}
  - assignmentId: string
  - studentId: string
  - submissionText: string
  - attachmentUrls: array<string>
  - grade: number (optional)
  - feedback: string (optional)
  - submittedAt: timestamp
  - gradedAt: timestamp (optional)
```

#### 8. announcements
```
/announcements/{announcementId}
  - title: string
  - content: string
  - teacherId: string
  - classroomId: string
  - schoolId: string
  - isSchoolWide: boolean
  - attachmentUrls: array<string>
  - createdAt: timestamp
```

#### 9. certificates
```
/certificates/{certificateId}
  - userId: string
  - realmId: string
  - certificateNumber: string
  - pdfUrl: string
  - qrCodeData: string
  - issuedAt: timestamp
```

#### 10. daily_challenges
```
/daily_challenges/{date}
  - date: string (YYYY-MM-DD)
  - questions: array<QuizQuestion>
  - xpReward: number
  - createdAt: timestamp
```

#### 11. daily_challenge_attempts
```
/daily_challenge_attempts/{userId__{date}}
  - userId: string
  - date: string
  - answers: array<number>
  - score: number
  - xpEarned: number
  - completedAt: timestamp
```

#### 12. leaderboard_cache
```
/leaderboard_cache/{scope__{scopeId}}
  - scope: string (classroom, school, state, national)
  - scopeId: string
  - entries: array<{userId, displayName, avatarUrl, xp, rank}>
  - updatedAt: timestamp
```

#### 13. join_requests
```
/join_requests/{requestId}
  - studentId: string
  - classroomId: string
  - status: string (pending, approved, denied)
  - createdAt: timestamp
  - reviewedAt: timestamp (optional)
```

#### 14. moderation_reports
```
/moderation_reports/{reportId}
  - contentId: string
  - contentType: string
  - contentText: string
  - reportedBy: string
  - reason: string
  - status: string (pending, escalated, resolved)
  - reviewedBy: string (optional)
  - action: string (optional)
  - createdAt: timestamp
  - reviewedAt: timestamp (optional)
  - escalatedAt: timestamp (optional)
```

#### 15. content_metadata
```
/content_metadata/{contentType}
  - contentType: string (realm, level, challenge, badge, game)
  - version: string
  - storageUrl: string
  - updatedAt: timestamp
  - isActive: boolean
```

#### 16. app_config
```
/app_config/current
  - xpRewards: map<string, number>
  - streakRules: map<string, any>
  - featureFlags: map<string, boolean>
  - version: string
  - updatedAt: timestamp
```

#### 17. profanity_words
```
/profanity_words/list
  - words: array<string>
  - updatedAt: timestamp
```

#### 18. admin_audit_log
```
/admin_audit_log/{logId}
  - adminId: string
  - action: string
  - resourceType: string
  - resourceId: string
  - changes: map
  - timestamp: timestamp
```

### Local Content Structure (NOT Firebase Storage)

**All educational content is bundled locally in the app:**

```
content/
  realms_v1.0.0.json
  badges.json
  certificates.json
  daily_challenges.json
  notifications.json
  app_config_v1.0.0.json
  levels/
    copyright_level_1.json
    copyright_level_2.json
    ... (60 total)
  quizzes/
    copyright_level_1.json
    trademark_level_1.json
    ... (60 total)
  games/
    quiz_master.json
    trademark_match.json
    ip_defender.json
    spot_the_original.json
    gi_mapper.json
    patent_detective.json
    innovation_lab.json

assets/
  badges/          # 50 badge images
  trademarks/      # 30 trademark logos
  games/           # 7 game icons
  logos/           # 6 realm logos
  backgrounds/
  icons/
  stu_avatars/
  tea_avatars/
  enemies/
  towers/
  projectiles/
  maps/
  gi/
  patents/
  products/
```

**Note:** Firebase Storage is NOT used to stay on free tier.
All content is version-controlled and bundled with the app.

---

## SECURITY & PERMISSIONS

### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isStudent() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'student';
    }
    
    function isTeacher() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'teacher';
    }
    
    function isPrincipal() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'principal';
    }
    
    function isAdmin() {
      return isAuthenticated() && request.auth.token.isAdmin == true;
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && request.auth.uid == userId;
      allow update: if isAuthenticated() && request.auth.uid == userId;
      allow delete: if isAdmin();
    }
    
    // Schools collection
    match /schools/{schoolId} {
      allow read: if isAuthenticated();
      allow create: if isPrincipal();
      allow update: if isPrincipal() && 
                     get(/databases/$(database)/documents/schools/$(schoolId)).data.principalId == request.auth.uid;
      allow delete: if isAdmin();
    }
    
    // Classrooms collection
    match /classrooms/{classroomId} {
      allow read: if isAuthenticated();
      allow create: if isTeacher();
      allow update: if isTeacher() && 
                     get(/databases/$(database)/documents/classrooms/$(classroomId)).data.teacherId == request.auth.uid;
      allow delete: if isTeacher() && 
                     get(/databases/$(database)/documents/classrooms/$(classroomId)).data.teacherId == request.auth.uid;
    }
    
    // Progress collection
    match /progress/{progressId} {
      allow read: if isAuthenticated() && 
                   progressId.split('__')[0] == request.auth.uid;
      allow write: if isAuthenticated() && 
                    progressId.split('__')[0] == request.auth.uid;
    }
    
    // Badges collection
    match /badges/{badgeId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
    
    // Assignments collection
    match /assignments/{assignmentId} {
      allow read: if isAuthenticated();
      allow create: if isTeacher();
      allow update: if isTeacher() && 
                     resource.data.createdBy == request.auth.uid;
      allow delete: if isTeacher() && 
                     resource.data.createdBy == request.auth.uid;
    }
    
    // Assignment submissions collection
    match /assignment_submissions/{submissionId} {
      allow read: if isAuthenticated();
      allow create: if isStudent();
      allow update: if (isStudent() && resource.data.studentId == request.auth.uid) ||
                     (isTeacher() && resource.data.grade == null);
    }
    
    // Announcements collection
    match /announcements/{announcementId} {
      allow read: if isAuthenticated();
      allow create: if isTeacher();
      allow update, delete: if isTeacher() && 
                             resource.data.teacherId == request.auth.uid;
    }
    
    // Certificates collection
    match /certificates/{certificateId} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }
    
    // Daily challenges collection
    match /daily_challenges/{date} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
    
    // Daily challenge attempts collection
    match /daily_challenge_attempts/{attemptId} {
      allow read: if isAuthenticated() && 
                   attemptId.split('__')[0] == request.auth.uid;
      allow write: if isAuthenticated() && 
                    attemptId.split('__')[0] == request.auth.uid;
    }
    
    // Leaderboard cache collection
    match /leaderboard_cache/{cacheId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
    
    // Join requests collection
    match /join_requests/{requestId} {
      allow read: if isAuthenticated();
      allow create: if isStudent();
      allow update: if isTeacher();
    }
    
    // Moderation reports collection
    match /moderation_reports/{reportId} {
      allow read: if isPrincipal() || isAdmin();
      allow create: if isAuthenticated();
      allow update: if isPrincipal() || isAdmin();
    }
    
    // Content metadata collection
    match /content_metadata/{contentType} {
      allow read: if true;
      allow write: if isAdmin();
    }
    
    // App config collection
    match /app_config/{doc} {
      allow read: if true;
      allow write: if isAdmin();
    }
    
    // Profanity words collection
    match /profanity_words/{doc} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
    
    // Admin audit log collection
    match /admin_audit_log/{logId} {
      allow read, write: if isAdmin();
    }
  }
}
```

### Firebase Storage Rules

**Firebase Storage is NOT used in this project.**

All educational content (levels, quizzes, games, badges) is bundled locally with the app.
This keeps the app on Firebase free tier and provides better offline support.

**Benefits of Local Content:**
- ✅ No Firebase Storage costs
- ✅ Faster loading (no network requests)
- ✅ Better offline support
- ✅ Simpler architecture
- ✅ Version-controlled content

---

*Document continues in COMPLETE_CONSOLIDATED_TASKS.md...*

**Document Version:** 1.0
**Last Updated:** 2025-11-10
**Source:** Consolidated from all spec documents in .kiro/specs/

