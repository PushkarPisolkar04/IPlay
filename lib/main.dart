import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/firebase_service.dart';
import 'core/services/service_initializer.dart';
import 'core/services/crash_recovery_service.dart';
import 'core/providers/user_provider.dart';
import 'core/providers/notification_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/auth/student_signup_screen.dart';
import 'screens/auth/teacher_signup_screen.dart';
import 'screens/auth/profile_setup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/main/main_screen.dart';
import 'screens/learn/realm_detail_screen.dart';
import 'screens/learn/level_detail_screen.dart';
import 'screens/games/games_screen.dart';
import 'screens/profile/badges_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/insights_screen.dart';
import 'screens/profile/bookmarks_screen.dart';
import 'screens/certificates/certificates_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/teacher/create_classroom_screen.dart';
import 'screens/classroom/join_classroom_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/chat/chat_list_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/daily_challenge/daily_challenge_screen.dart';
import 'screens/onboarding/student_tutorial_screen.dart';
import 'screens/onboarding/teacher_tutorial_screen.dart';
import 'core/models/realm_model.dart';
import 'utils/haptic_feedback_util.dart';
import 'services/sound_service.dart';
import 'services/deep_link_service.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // CRITICAL: Initialize Firebase first (required for auth)
  await FirebaseService.initialize();
  
  // Initialize crash recovery and Crashlytics
  await CrashRecoveryService.initialize();
  
  // Initialize haptic feedback settings
  await HapticFeedbackUtil.initialize();
  
  // Initialize sound service
  await SoundService.initialize();
  
  // Set preferred orientations (quick, non-blocking)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Show status bar with dark icons and transparent background
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Start the app immediately
  runApp(const MyApp());
  
  // LAZY LOAD: Initialize non-critical services after app starts
  // This improves perceived launch time significantly (target <3s to home screen)
  ServiceInitializer.initializeNonCriticalServices();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _deepLinkService = DeepLinkService();
  final _appLinks = AppLinks();
  StreamSubscription? _linkSubscription;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // Handle initial deep link (when app is opened from closed state)
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        // Store the link, it will be processed when app is ready
        _deepLinkService.handleDeepLink(initialLink, _navigatorKey.currentContext ?? context);
        
        // Wait for navigation to be ready, then process pending link
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_navigatorKey.currentContext != null) {
            _deepLinkService.markAppReady();
            _deepLinkService.processPendingDeepLink(_navigatorKey.currentContext!);
          }
        });
      } else {
        // No initial link, mark app as ready immediately
        _deepLinkService.markAppReady();
      }
    } catch (e) {
      // Handle error silently
      _deepLinkService.markAppReady();
    }

    // Listen for deep links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen((Uri uri) {
      if (_navigatorKey.currentContext != null) {
        _deepLinkService.handleDeepLink(uri, _navigatorKey.currentContext!);
      }
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()..initialize()),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'IPlay - IPR Learning',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        // Support text scaling with maximum limit to prevent layout breaks
        builder: (context, child) {
          final mediaQueryData = MediaQuery.of(context);
          final constrainedTextScaleFactor = mediaQueryData.textScaleFactor.clamp(1.0, 2.0);
          
          return MediaQuery(
            data: mediaQueryData.copyWith(
              textScaler: TextScaler.linear(constrainedTextScaleFactor),
            ),
            child: child!,
          );
        },
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(builder: (_) => const SplashScreen());
            case '/auth':
              return MaterialPageRoute(builder: (_) => const AuthScreen());
            case '/role-selection':
              return MaterialPageRoute(builder: (_) => const RoleSelectionScreen());
            case '/student-signup':
              return MaterialPageRoute(builder: (_) => const StudentSignupScreen());
            case '/teacher-signup':
              return MaterialPageRoute(builder: (_) => const TeacherSignupScreen());
            case '/profile-setup':
              return MaterialPageRoute(builder: (_) => const ProfileSetupScreen());
            case '/forgot-password':
              return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
            case '/email-verification':
              return MaterialPageRoute(builder: (_) => const EmailVerificationScreen());
            case '/main':
              return MaterialPageRoute(builder: (_) => const MainScreen());
            case '/realm-detail':
              final realm = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(builder: (_) => RealmDetailScreen(realm: realm ?? {}));
            case '/level-content':
              final args = settings.arguments as Map<String, dynamic>?;
              final level = args?['level'] as LevelModel?;
              if (level != null) {
                return MaterialPageRoute(builder: (_) => LevelDetailScreen(levelId: level.id));
              }
              return MaterialPageRoute(builder: (_) => const SplashScreen());
            case '/games':
              return MaterialPageRoute(builder: (_) => const GamesScreen());
            case '/badges':
              return MaterialPageRoute(builder: (_) => const BadgesScreen());
            case '/certificates':
              return MaterialPageRoute(builder: (_) => const CertificatesScreen());
            case '/bookmarks':
              return MaterialPageRoute(builder: (_) => const BookmarksScreen());
            case '/profile':
              return MaterialPageRoute(builder: (_) => const ProfileScreen());
            case '/insights':
              return MaterialPageRoute(builder: (_) => const InsightsScreen());
            case '/settings':
              return MaterialPageRoute(builder: (_) => const SettingsScreen());
            case '/create-classroom':
              return MaterialPageRoute(builder: (_) => const CreateClassroomScreen());
            case '/join-classroom':
              return MaterialPageRoute(builder: (_) => const JoinClassroomScreen());
            case '/edit-profile':
              return MaterialPageRoute(builder: (_) => const EditProfileScreen());
            case '/chat-list':
              return MaterialPageRoute(builder: (_) => const ChatListScreen());
            case '/chat':
              final args = settings.arguments as Map<String, dynamic>?;
              if (args != null && args['chatId'] != null && args['otherUserName'] != null) {
                return MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    chatId: args['chatId'] as String,
                    otherUserName: args['otherUserName'] as String,
                    otherUserAvatar: args['otherUserAvatar'] as String?,
                  ),
                );
              }
              return MaterialPageRoute(builder: (_) => const ChatListScreen());
            case '/notifications':
              return MaterialPageRoute(builder: (_) => const NotificationsScreen());
            case '/daily-challenge':
              return MaterialPageRoute(builder: (_) => const DailyChallengeScreen());
            case '/student-tutorial':
              return MaterialPageRoute(builder: (_) => const StudentTutorialScreen());
            case '/teacher-tutorial':
              return MaterialPageRoute(builder: (_) => const TeacherTutorialScreen());
            case '/realm':
              final args = settings.arguments as Map<String, dynamic>?;
              final realmId = args?['realmId'] as String?;
              if (realmId != null) {
                return MaterialPageRoute(builder: (_) => RealmDetailScreen(realm: {'id': realmId}));
              }
              return MaterialPageRoute(builder: (_) => const MainScreen());
            case '/level':
              final args = settings.arguments as Map<String, dynamic>?;
              final levelId = args?['levelId'] as String?;
              if (levelId != null) {
                return MaterialPageRoute(builder: (_) => LevelDetailScreen(levelId: levelId));
              }
              return MaterialPageRoute(builder: (_) => const MainScreen());
            case '/game':
              final args = settings.arguments as Map<String, dynamic>?;
              final gameId = args?['gameId'] as String?;
              if (gameId != null) {
                return MaterialPageRoute(builder: (_) => const GamesScreen());
              }
              return MaterialPageRoute(builder: (_) => const GamesScreen());
            case '/certificate/verify':
              // Navigate to profile/badges screen where certificates are shown
              return MaterialPageRoute(builder: (_) => const BadgesScreen());
            default:
              return MaterialPageRoute(builder: (_) => const SplashScreen());
          }
        },
      ),
    );
  }
}