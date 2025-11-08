import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/design/app_design_system.dart';
import '../../core/services/xp_service.dart';
import '../../core/services/badge_service.dart';

class StudentTutorialScreen extends StatefulWidget {
  const StudentTutorialScreen({super.key});

  @override
  State<StudentTutorialScreen> createState() => _StudentTutorialScreenState();
}

class _StudentTutorialScreenState extends State<StudentTutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 5;

  final List<_TutorialPage> _pages = [
    _TutorialPage(
      icon: Icons.explore,
      title: 'Welcome to IPlay!',
      description: 'Your journey to master Intellectual Property Rights starts here. Learn through interactive lessons and fun games!',
      gradient: [AppDesignSystem.primaryIndigo, AppDesignSystem.secondaryPurple],
      imageAsset: 'assets/backgrounds/background1.png',
    ),
    _TutorialPage(
      icon: Icons.school,
      title: 'Explore 6 Realms',
      description: 'Dive into Copyright, Trademark, Patent, Industrial Design, Geographical Indication, and Trade Secrets.',
      gradient: [AppDesignSystem.primaryPink, AppDesignSystem.primaryAmber],
      imageAsset: 'assets/backgrounds/background1.png',
    ),
    _TutorialPage(
      icon: Icons.games,
      title: 'Play & Learn',
      description: 'Challenge yourself with 7 exciting games! Spot the Original, GI Mapper, IP Defender, and more.',
      gradient: [AppDesignSystem.primaryGreen, AppDesignSystem.primaryTeal],
      imageAsset: 'assets/backgrounds/background1.png',
    ),
    _TutorialPage(
      icon: Icons.stars,
      title: 'Earn XP & Badges',
      description: 'Complete levels, ace quizzes, and unlock achievements. Every lesson earns you XP and cool badges!',
      gradient: [AppDesignSystem.primaryAmber, AppDesignSystem.primaryOrange],
      imageAsset: 'assets/backgrounds/background1.png',
    ),
    _TutorialPage(
      icon: Icons.leaderboard,
      title: 'Compete & Win',
      description: 'Climb leaderboards at classroom, school, state, and national levels. Show everyone your IPR expertise!',
      gradient: [AppDesignSystem.secondaryPurple, AppDesignSystem.primaryIndigo],
      imageAsset: 'assets/backgrounds/background1.png',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_completed', true);

    final xpService = XPService();
    final badgeService = BadgeService();
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      await xpService.awardXPAndCheckRank(
        userId: userId,
        xpAmount: 50,
      );

      if (mounted) {
        await badgeService.checkAndAwardBadges(
          userId,
          context: context,
        );
      }
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  void _skipTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_completed', true);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _pages[_currentPage].gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _skipTutorial,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: _totalPages,
                    itemBuilder: (context, index) {
                      return _buildPage(_pages[index]);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: SmoothPageIndicator(
                    controller: _pageController,
                    count: _totalPages,
                    effect: WormEffect(
                      dotColor: Colors.white.withValues(alpha: 0.4),
                      activeDotColor: Colors.white,
                      dotHeight: 12,
                      dotWidth: 12,
                      spacing: 16,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentPage > 0)
                        TextButton.icon(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          label: const Text(
                            'Back',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        )
                      else
                        const SizedBox(width: 80),
                      ElevatedButton(
                        onPressed: () {
                          if (_currentPage < _totalPages - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _completeTutorial();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _pages[_currentPage].gradient[0],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 5,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentPage < _totalPages - 1 ? 'Next' : 'Get Started',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _currentPage < _totalPages - 1
                                  ? Icons.arrow_forward
                                  : Icons.check_circle,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(_TutorialPage page) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      page.icon,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 48),
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            page.description,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TutorialPage {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradient;
  final String imageAsset;

  _TutorialPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
    required this.imageAsset,
  });
}
