class AppConstants {
  // App Info
  static const String appName = 'IPlay';
  static const String appVersion = '1.0.0';
  
  // User Roles
  static const String rolePrincipal = 'principal';
  static const String roleTeacher = 'teacher';
  static const String roleStudent = 'student';
  
  // XP & Gamification
  static const int xpLevelCompletion = 100;
  static const int xpQuizPerfect = 50;
  static const int xpDailyLogin = 10;
  static const int xpStreakBonus = 20;
  static const int dailyXpCap = 500;
  
  // Leaderboard Scopes
  static const String leaderboardClass = 'class';
  static const String leaderboardSchool = 'school';
  static const String leaderboardState = 'state';
  static const String leaderboardNational = 'national';
  
  // Certificate Types
  static const String certModule = 'module';
  static const String certRealm = 'realm';
  static const String certCourse = 'course';
  
  // Classroom Code Format
  static const int classCodeLength = 7;
  
  // Offline Settings
  static const int syncIntervalMinutes = 30;
  static const int maxOfflineQueueSize = 1000;
  
  // Content Pack Sizes (MB)
  static const int wifiDownloadThreshold = 50;
  
  // Grace Period for Streaks (hours)
  static const int streakGracePeriodHours = 24;
  
  // IPR Realms
  static const List<String> iprRealms = [
    'Patent Plains',
    'Trademark Tower',
    'Copyright Castle',
    'Design Domain',
    'GI Gardens',
  ];
  
  // Storage Paths
  static const String storageAvatars = 'avatars';
  static const String storageCertificates = 'certificates';
  static const String storageContent = 'content';
  
  // Collection Names
  static const String collectionUsers = 'users';
  static const String collectionClassrooms = 'classrooms';
  static const String collectionRealms = 'realms';
  static const String collectionLevels = 'levels';
  static const String collectionQuizzes = 'quizzes';
  static const String collectionProgress = 'progress';
  static const String collectionBadges = 'badges';
  static const String collectionCertificates = 'certificates';
  static const String collectionLeaderboards = 'leaderboards';
  static const String collectionAnnouncements = 'announcements';
  static const String collectionNews = 'news';
  
  // Default Values
  static const String defaultAvatarUrl = 'assets/icons/app_icon.png';
  static const String defaultState = 'Delhi'; // Default state for new users (will be updated during profile setup)
}

