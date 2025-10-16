import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../core/models/user_model.dart';
import '../home/home_screen.dart';
import '../learn/learn_screen.dart';
import '../games/play_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../profile/profile_screen.dart';
import '../teacher/teacher_dashboard_screen.dart';
import '../principal/principal_dashboard_screen.dart';
import '../announcements/announcements_screen.dart';

/// Main screen with bottom navigation - Role-based tabs
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        if (doc.exists && mounted) {
          setState(() {
            _user = UserModel.fromMap(doc.data()!);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Get screens based on user role
  List<Widget> get _screens {
    if (_user == null) {
      return const [
        HomeScreen(),
        LearnScreen(),
        PlayScreen(),
        LeaderboardScreen(),
        ProfileScreen(),
      ];
    }

    // STUDENT: Home, Learn, Play, Leaderboard, Profile
    if (_user!.role == 'student') {
      return const [
        HomeScreen(),
        LearnScreen(),
        PlayScreen(),
        LeaderboardScreen(),
        ProfileScreen(),
      ];
    }

    // TEACHER/PRINCIPAL: Use their own dashboard with built-in navigation
    // Return empty list - teacher dashboard handles its own UI
    return [];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If teacher/principal, show their dedicated dashboard
    if (_user != null && _user!.role != 'student') {
      // Show Principal Dashboard if user is a principal
      if (_user!.isPrincipal == true) {
        return const PrincipalDashboardScreen();
      }
      // Otherwise show regular Teacher Dashboard
      return const TeacherDashboardScreen();
    }

    // For students, show the normal tab navigation
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
