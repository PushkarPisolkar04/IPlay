import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/firebase_service.dart';
import 'core/providers/user_provider.dart';
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
import 'screens/games/games_screen.dart';
import 'screens/profile/badges_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/teacher/create_classroom_screen.dart';
import 'screens/classroom/join_classroom_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await FirebaseService.initialize();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
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
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'IPlay - IPR Learning',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
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
            case '/games':
              return MaterialPageRoute(builder: (_) => const GamesScreen());
            case '/badges':
              return MaterialPageRoute(builder: (_) => const BadgesScreen());
            case '/profile':
              return MaterialPageRoute(builder: (_) => const ProfileScreen());
            case '/settings':
              return MaterialPageRoute(builder: (_) => const SettingsScreen());
            case '/create-classroom':
              return MaterialPageRoute(builder: (_) => const CreateClassroomScreen());
            case '/join-classroom':
              return MaterialPageRoute(builder: (_) => const JoinClassroomScreen());
            default:
              return MaterialPageRoute(builder: (_) => const SplashScreen());
          }
        },
      ),
    );
  }
}