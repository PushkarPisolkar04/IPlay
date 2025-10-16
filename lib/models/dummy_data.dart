// UI-Only Dummy Data
// This file contains all mock data for the UI-only build
// Replace with real API calls in Phase 7

class DummyData {
  // Current User
  static final currentUser = {
    'uid': '1',
    'name': 'Alex Kumar',
    'displayName': 'Alex K.',
    'email': 'alex@example.com',
    'avatar': 'https://i.pravatar.cc/150?img=1',
    'role': 'student', // student, teacher
    'level': 5,
    'totalXP': 1250,
    'nextLevelXP': 1600,
    'currentStreak': 7,
    'longestStreak': 12,
    'grade': 8,
    'school': 'Delhi Public School',
    'state': 'Delhi',
    'badgeCount': 5,
    'certificateCount': 2,
    'classroomIds': ['1', '2'],
  };

  // Realms (6 IPR topics)
  static final realms = [
    {
      'id': '1',
      'name': 'Patent Realm',
      'icon': '💡',
      'emoji': '💡',
      'color': 0xFF3B82F6, // Blue
      'description': 'Discover the world of inventions and innovations',
      'progress': 0.8,
      'completedLevels': 5,
      'totalLevels': 6,
      'earnedXP': 700,
      'totalXP': 800,
      'isUnlocked': true,
      'completionPercentage': 83,
    },
    {
      'id': '2',
      'name': 'Trademark Realm',
      'icon': '🏷️',
      'emoji': '🏷️',
      'color': 0xFF8B5CF6, // Purple
      'description': 'Learn about brands, logos, and business identity',
      'progress': 0.5,
      'completedLevels': 3,
      'totalLevels': 6,
      'earnedXP': 400,
      'totalXP': 800,
      'isUnlocked': true,
      'completionPercentage': 50,
    },
    {
      'id': '3',
      'name': 'Copyright Realm',
      'icon': '©️',
      'emoji': '©️',
      'color': 0xFFEC4899, // Pink
      'description': 'Explore creative works protection',
      'progress': 0.33,
      'completedLevels': 2,
      'totalLevels': 6,
      'earnedXP': 250,
      'totalXP': 800,
      'isUnlocked': true,
      'completionPercentage': 33,
    },
    {
      'id': '4',
      'name': 'Design Realm',
      'icon': '🎨',
      'emoji': '🎨',
      'color': 0xFF10B981, // Green
      'description': 'Understand industrial design protection',
      'progress': 0.0,
      'completedLevels': 0,
      'totalLevels': 6,
      'earnedXP': 0,
      'totalXP': 800,
      'isUnlocked': true,
      'completionPercentage': 0,
    },
    {
      'id': '5',
      'name': 'GI Realm',
      'icon': '🌍',
      'emoji': '🌍',
      'color': 0xFFF59E0B, // Orange
      'description': 'Geographic Indications and regional products',
      'progress': 0.0,
      'completedLevels': 0,
      'totalLevels': 6,
      'earnedXP': 0,
      'totalXP': 800,
      'isUnlocked': false,
      'completionPercentage': 0,
    },
    {
      'id': '6',
      'name': 'Trade Secrets Realm',
      'icon': '🔒',
      'emoji': '🔒',
      'color': 0xFF6366F1, // Indigo
      'description': 'Learn about confidential business information',
      'progress': 0.0,
      'completedLevels': 0,
      'totalLevels': 6,
      'earnedXP': 0,
      'totalXP': 800,
      'isUnlocked': false,
      'completionPercentage': 0,
    },
  ];

  // Levels for each realm (sample for realm 1)
  static final levels = [
    {
      'id': '1',
      'realmId': '1',
      'title': 'What is a Patent?',
      'description': 'Learn the basics of patents',
      'order': 1,
      'isUnlocked': true,
      'isCompleted': true,
      'stars': 5,
      'xpEarned': 100,
      'xpTotal': 100,
    },
    {
      'id': '2',
      'realmId': '1',
      'title': 'Types of Patents',
      'description': 'Utility, Design, and Plant patents',
      'order': 2,
      'isUnlocked': true,
      'isCompleted': true,
      'stars': 4,
      'xpEarned': 100,
      'xpTotal': 100,
    },
    {
      'id': '3',
      'realmId': '1',
      'title': 'Patent Application Process',
      'description': 'How to file a patent',
      'order': 3,
      'isUnlocked': true,
      'isCompleted': true,
      'stars': 5,
      'xpEarned': 100,
      'xpTotal': 100,
    },
    {
      'id': '4',
      'realmId': '1',
      'title': 'Famous Indian Patents',
      'description': 'Learn about Indian inventors',
      'order': 4,
      'isUnlocked': true,
      'isCompleted': false,
      'stars': 0,
      'xpEarned': 0,
      'xpTotal': 100,
    },
    {
      'id': '5',
      'realmId': '1',
      'title': 'Patent Rights & Duration',
      'description': 'Understanding patent protection',
      'order': 5,
      'isUnlocked': false,
      'isCompleted': false,
      'stars': 0,
      'xpEarned': 0,
      'xpTotal': 100,
    },
    {
      'id': '6',
      'realmId': '1',
      'title': 'Patent Quiz Challenge',
      'description': 'Test your knowledge',
      'order': 6,
      'isUnlocked': false,
      'isCompleted': false,
      'stars': 0,
      'xpEarned': 0,
      'xpTotal': 100,
    },
  ];

  // Quiz Questions (sample)
  static final quizQuestions = [
    {
      'id': '1',
      'question': 'What is a patent?',
      'options': [
        'A type of trademark',
        'Legal protection for inventions',
        'A business license',
        'A copyright symbol'
      ],
      'correctAnswer': 1,
      'explanation': 'A patent is a legal right granted to inventors to protect their inventions.',
    },
    {
      'id': '2',
      'question': 'How long does a patent last in India?',
      'options': ['10 years', '15 years', '20 years', 'Forever'],
      'correctAnswer': 2,
      'explanation': 'In India, patents are valid for 20 years from the date of filing.',
    },
    {
      'id': '3',
      'question': 'Which of these can be patented?',
      'options': [
        'A new scientific theory',
        'A mathematical formula',
        'A new machine',
        'A natural phenomenon'
      ],
      'correctAnswer': 2,
      'explanation': 'Only practical inventions like machines can be patented, not abstract ideas.',
    },
  ];

  // Games
  static final games = [
    {
      'id': '1',
      'name': 'IPR Quiz Master',
      'icon': '🧠',
      'emoji': '🧠',
      'description': 'Test your IPR knowledge with quick quizzes',
      'bestScore': 850,
      'attempts': 12,
      'color': 0xFF3B82F6,
    },
    {
      'id': '2',
      'name': 'Patent Match',
      'icon': '🎯',
      'emoji': '🎯',
      'description': 'Match inventions with their inventors',
      'bestScore': 720,
      'attempts': 8,
      'color': 0xFF8B5CF6,
    },
    {
      'id': '3',
      'name': 'Trademark Designer',
      'icon': '✏️',
      'emoji': '✏️',
      'description': 'Create and evaluate trademark designs',
      'bestScore': 500,
      'attempts': 5,
      'color': 0xFFEC4899,
    },
    {
      'id': '4',
      'name': 'Copyright Detective',
      'icon': '🔍',
      'emoji': '🔍',
      'description': 'Find copyright violations in scenarios',
      'bestScore': 0,
      'attempts': 0,
      'color': 0xFF10B981,
    },
    {
      'id': '5',
      'name': 'IPR Word Quest',
      'icon': '📝',
      'emoji': '📝',
      'description': 'Word puzzles with IPR terminology',
      'bestScore': 0,
      'attempts': 0,
      'color': 0xFFF59E0B,
    },
    {
      'id': '6',
      'name': 'Innovation Timeline',
      'icon': '⏰',
      'emoji': '⏰',
      'description': 'Arrange inventions in chronological order',
      'bestScore': 0,
      'attempts': 0,
      'color': 0xFF6366F1,
    },
    {
      'id': '7',
      'name': 'IPR Trivia Challenge',
      'icon': '🎲',
      'emoji': '🎲',
      'description': 'Multiplayer trivia battles',
      'bestScore': 0,
      'attempts': 0,
      'color': 0xFFEF4444,
    },
  ];

  // Leaderboard (National)
  static final leaderboard = [
    {
      'rank': 1,
      'name': 'Priya Sharma',
      'displayName': 'Priya S.',
      'avatar': 'https://i.pravatar.cc/150?img=5',
      'xp': 3450,
      'badges': 12,
      'level': 8,
      'state': 'Maharashtra',
    },
    {
      'rank': 2,
      'name': 'Rahul Mehta',
      'displayName': 'Rahul M.',
      'avatar': 'https://i.pravatar.cc/150?img=12',
      'xp': 3200,
      'badges': 10,
      'level': 7,
      'state': 'Karnataka',
    },
    {
      'rank': 3,
      'name': 'Anita Kumar',
      'displayName': 'Anita K.',
      'avatar': 'https://i.pravatar.cc/150?img=9',
      'xp': 3100,
      'badges': 11,
      'level': 7,
      'state': 'Tamil Nadu',
    },
    {
      'rank': 4,
      'name': 'Vikram Singh',
      'displayName': 'Vikram S.',
      'avatar': 'https://i.pravatar.cc/150?img=15',
      'xp': 2950,
      'badges': 9,
      'level': 7,
      'state': 'Delhi',
    },
    {
      'rank': 5,
      'name': 'Neha Patel',
      'displayName': 'Neha P.',
      'avatar': 'https://i.pravatar.cc/150?img=20',
      'xp': 2800,
      'badges': 8,
      'level': 6,
      'state': 'Gujarat',
    },
    // Generate more entries...
    {
      'rank': 42,
      'name': 'You',
      'displayName': 'Alex K.',
      'avatar': 'https://i.pravatar.cc/150?img=1',
      'xp': 1250,
      'badges': 5,
      'level': 5,
      'state': 'Delhi',
      'isCurrentUser': true,
    },
  ];

  // Badges
  static final badges = [
    {
      'id': '1',
      'name': 'First Steps',
      'icon': '🏅',
      'emoji': '🏅',
      'description': 'Complete your first level',
      'category': 'milestone',
      'unlocked': true,
      'unlockedAt': '2025-10-10',
      'rarity': 'common',
    },
    {
      'id': '2',
      'name': 'Patent Pioneer',
      'icon': '💡',
      'emoji': '💡',
      'description': 'Complete Patent Realm',
      'category': 'realm',
      'unlocked': false,
      'unlockedAt': null,
      'rarity': 'rare',
    },
    {
      'id': '3',
      'name': 'Speed Demon',
      'icon': '⚡',
      'emoji': '⚡',
      'description': 'Complete a quiz in under 2 minutes',
      'category': 'achievement',
      'unlocked': true,
      'unlockedAt': '2025-10-12',
      'rarity': 'uncommon',
    },
    {
      'id': '4',
      'name': '7-Day Streak',
      'icon': '🔥',
      'emoji': '🔥',
      'description': 'Login for 7 consecutive days',
      'category': 'streak',
      'unlocked': true,
      'unlockedAt': '2025-10-14',
      'rarity': 'uncommon',
    },
    {
      'id': '5',
      'name': 'Quiz Master',
      'icon': '🎓',
      'emoji': '🎓',
      'description': 'Score 100% in 5 quizzes',
      'category': 'achievement',
      'unlocked': true,
      'unlockedAt': '2025-10-13',
      'rarity': 'rare',
    },
    {
      'id': '6',
      'name': 'Social Learner',
      'icon': '👥',
      'emoji': '👥',
      'description': 'Join a classroom',
      'category': 'social',
      'unlocked': true,
      'unlockedAt': '2025-10-11',
      'rarity': 'common',
    },
    // Add 19 more badges for total of 25
  ];

  // Classrooms (for students)
  static final classrooms = [
    {
      'id': '1',
      'name': 'Class 8A - IPR Basics',
      'teacherName': 'Ms. Priya Sharma',
      'teacherAvatar': 'https://i.pravatar.cc/150?img=25',
      'studentCount': 32,
      'code': 'IPR8A2025',
      'createdAt': '2025-09-01',
    },
    {
      'id': '2',
      'name': 'Advanced IPR Club',
      'teacherName': 'Mr. Rajesh Kumar',
      'teacherAvatar': 'https://i.pravatar.cc/150?img=33',
      'studentCount': 18,
      'code': 'IPRCLUB',
      'createdAt': '2025-09-15',
    },
  ];

  // Daily Challenge
  static final dailyChallenge = {
    'id': '1',
    'title': 'Patent Trivia',
    'description': 'Answer 5 patent-related questions',
    'xpReward': 50,
    'progress': 3,
    'total': 5,
    'expiresIn': '6h 23m',
  };

  // Recent Activity
  static final recentActivity = [
    {
      'type': 'level_complete',
      'title': 'Completed: Types of Patents',
      'xpGained': 100,
      'timestamp': '2 hours ago',
      'icon': '✅',
    },
    {
      'type': 'badge_unlock',
      'title': 'Unlocked: 7-Day Streak',
      'timestamp': '1 day ago',
      'icon': '🏆',
    },
    {
      'type': 'quiz_complete',
      'title': 'Patent Quiz - 5/5 stars',
      'xpGained': 150,
      'timestamp': '2 days ago',
      'icon': '⭐',
    },
  ];

  // Certificates
  static final certificates = [
    {
      'id': '1',
      'name': 'Patent Realm Master',
      'realmName': 'Patent Realm',
      'issuedDate': '2025-10-10',
      'certificateUrl': 'https://example.com/cert/1.pdf',
    },
    {
      'id': '2',
      'name': 'Trademark Expert',
      'realmName': 'Trademark Realm',
      'issuedDate': '2025-10-12',
      'certificateUrl': 'https://example.com/cert/2.pdf',
    },
  ];

  // Notifications
  static final notifications = [
    {
      'id': '1',
      'title': 'New badge unlocked!',
      'message': 'You earned the "7-Day Streak" badge',
      'type': 'badge',
      'isRead': false,
      'timestamp': '1 hour ago',
    },
    {
      'id': '2',
      'title': 'Classroom Update',
      'message': 'Ms. Sharma posted a new assignment',
      'type': 'classroom',
      'isRead': false,
      'timestamp': '3 hours ago',
    },
    {
      'id': '3',
      'title': 'Daily Challenge Available',
      'message': 'Complete today\'s challenge to earn 50 XP',
      'type': 'challenge',
      'isRead': true,
      'timestamp': '1 day ago',
    },
  ];

  // App Settings
  static final settings = {
    'notifications': {
      'pushEnabled': true,
      'emailEnabled': false,
      'dailyReminder': true,
      'achievementAlerts': true,
      'classroomUpdates': true,
    },
    'privacy': {
      'profileVisible': true,
      'showOnLeaderboard': true,
      'shareProgress': false,
    },
    'preferences': {
      'language': 'English',
      'theme': 'light',
      'soundEffects': true,
      'hapticFeedback': true,
    },
  };
}

