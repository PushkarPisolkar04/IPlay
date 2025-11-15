import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/models/user_model.dart';
import '../../utils/haptic_feedback_util.dart';
import '../../services/sound_service.dart';
import '../../services/app_rating_service.dart';
import '../../services/app_tour_service.dart';
import '../../widgets/clean_card.dart';
import '../profile/edit_profile_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_screen.dart';
import 'data_security_screen.dart';

/// Settings Screen - App settings, privacy, terms, logout
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserModel? _user;
  bool _isLoading = true;

  // Notification settings
  bool _announcementsNotif = true;
  bool _joinRequestsNotif = true;
  bool _badgesNotif = true;
  
  // App settings
  bool _hapticFeedbackEnabled = true;
  bool _soundEffectsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadHapticSetting();
    _loadSoundSetting();
  }
  
  Future<void> _loadHapticSetting() async {
    setState(() {
      _hapticFeedbackEnabled = HapticFeedbackUtil.isEnabled;
    });
  }
  
  Future<void> _loadSoundSetting() async {
    setState(() {
      _soundEffectsEnabled = SoundService.isEnabled;
    });
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
          final userData = UserModel.fromMap(doc.data()!);
          setState(() {
            _user = userData;
            _announcementsNotif = userData.notificationSettings.announcements;
            _joinRequestsNotif = userData.notificationSettings.joinRequests;
            _badgesNotif = userData.notificationSettings.badges;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      // print('Error loading user data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateNotificationSetting(String setting, bool value) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({
          'notificationSettings.$setting': value,
          'updatedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      // print('Error updating notification setting: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update setting: ${e.toString()}'),
          backgroundColor: AppDesignSystem.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: CustomScrollView(
                slivers: [
                  // Header with gradient
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const Center(
                            child: Text(
                              'Settings',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('notifications')
                                  .where('toUserId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                                  .where('read', isEqualTo: false)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                final unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                                
                                return Stack(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.notifications_outlined,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/notifications');
                                      },
                                    ),
                                    if (unreadCount > 0)
                                      Positioned(
                                        right: 8,
                                        top: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 18,
                                            minHeight: 18,
                                          ),
                                          child: Center(
                                            child: Text(
                                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                                              style: const TextStyle(
                                                color: Color(0xFF3B82F6),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                  // Email Verification Banner
                  if (FirebaseAuth.instance.currentUser != null && 
                      !FirebaseAuth.instance.currentUser!.emailVerified) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppDesignSystem.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppDesignSystem.warning),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber, color: AppDesignSystem.warning),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Email Not Verified',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Please verify your email to access all features.',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _resendVerificationEmail(),
                              icon: const Icon(Icons.email, size: 18),
                              label: const Text('Resend Verification Email'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppDesignSystem.warning,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  
                  // Account Section
                  Text(
                    'Account',
                    style: AppTextStyles.sectionHeader,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  
                  CleanCard(
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.person,
                          title: _user?.displayName ?? 'User',
                          subtitle: _user?.email ?? '',
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () async {
                            // Navigate to edit profile
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfileScreen(),
                              ),
                            );
                            // Reload user data after editing
                            _loadUserData();
                          },
                        ),
                        const Divider(height: 1),
                        _SettingsTile(
                          icon: Icons.location_on,
                          title: 'State',
                          subtitle: _user?.state ?? '',
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () async {
                            // Change state via edit profile screen
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfileScreen(),
                              ),
                            );
                            // Reload user data after editing
                            _loadUserData();
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Notifications Section
                  Text(
                    'Notifications',
                    style: AppTextStyles.sectionHeader,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  
                  CleanCard(
                    child: Column(
                      children: [
                        _SettingsSwitchTile(
                          icon: Icons.announcement,
                          title: 'Announcements',
                          subtitle: 'Get notified about new announcements',
                          value: _announcementsNotif,
                          onChanged: (value) {
                            setState(() => _announcementsNotif = value);
                            _updateNotificationSetting('announcements', value);
                          },
                        ),
                        const Divider(height: 1),
                        _SettingsSwitchTile(
                          icon: Icons.group_add,
                          title: 'Join Requests',
                          subtitle: 'Get notified about classroom join requests',
                          value: _joinRequestsNotif,
                          onChanged: (value) {
                            setState(() => _joinRequestsNotif = value);
                            _updateNotificationSetting('joinRequests', value);
                          },
                        ),
                        const Divider(height: 1),
                        _SettingsSwitchTile(
                          icon: Icons.emoji_events,
                          title: 'Badges & Achievements',
                          subtitle: 'Get notified when you earn badges',
                          value: _badgesNotif,
                          onChanged: (value) {
                            setState(() => _badgesNotif = value);
                            _updateNotificationSetting('badges', value);
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // App Settings Section
                  Text(
                    'App Settings',
                    style: AppTextStyles.sectionHeader,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  
                  CleanCard(
                    child: Column(
                      children: [
                        _SettingsSwitchTile(
                          icon: Icons.vibration,
                          title: 'Haptic Feedback',
                          subtitle: 'Vibrate on button press and interactions',
                          value: _hapticFeedbackEnabled,
                          onChanged: (value) async {
                            setState(() => _hapticFeedbackEnabled = value);
                            await HapticFeedbackUtil.setEnabled(value);
                            // Give immediate feedback if enabling
                            if (value) {
                              HapticFeedbackUtil.mediumImpact();
                            }
                          },
                        ),
                        const Divider(height: 1),
                        _SettingsSwitchTile(
                          icon: Icons.volume_up,
                          title: 'Sound Effects',
                          subtitle: 'Play sounds for XP, badges, and interactions',
                          value: _soundEffectsEnabled,
                          onChanged: (value) async {
                            setState(() => _soundEffectsEnabled = value);
                            await SoundService.setEnabled(value);
                            // Give immediate feedback if enabling
                            if (value) {
                              await SoundService.playSuccess();
                            }
                          },
                        ),
                        const Divider(height: 1),
                        _SettingsTile(
                          icon: Icons.tour,
                          title: 'Reset App Tour',
                          subtitle: 'Show feature tooltips again',
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () async {
                            final appTourService = AppTourService();
                            await appTourService.resetAllTours();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('App tour reset successfully')),
                              );
                            }
                          },
                        ),
                        const Divider(height: 1),
                        _SettingsTile(
                          icon: Icons.download,
                          title: 'Export My Data',
                          subtitle: 'Download all your data as JSON',
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () => _exportUserData(),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Privacy & Legal Section
                  Text(
                    'Privacy & Legal',
                    style: AppTextStyles.sectionHeader,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  
                  CleanCard(
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.privacy_tip,
                          title: 'Privacy Policy',
                          subtitle: 'Read our privacy policy',
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PrivacyPolicyScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        _SettingsTile(
                          icon: Icons.description,
                          title: 'Terms & Conditions',
                          subtitle: 'Read our terms and conditions',
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TermsScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        _SettingsTile(
                          icon: Icons.shield,
                          title: 'Data & Security',
                          subtitle: 'How we protect your data',
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DataSecurityScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // About Section
                  Text(
                    'About',
                    style: AppTextStyles.sectionHeader,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  
                  CleanCard(
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.info,
                          title: 'About IPlay',
                          subtitle: 'Learn more about the app',
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () => _showAboutDialog(),
                        ),
                        const Divider(height: 1),
                        _SettingsTile(
                          icon: Icons.star,
                          title: 'Rate App',
                          subtitle: 'Enjoying IPlay? Rate us on the store',
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () => _rateApp(),
                        ),
                        const Divider(height: 1),
                        _SettingsTile(
                          icon: Icons.code,
                          title: 'Version',
                          subtitle: '1.0.0',
                          trailing: const SizedBox(),
                          onTap: null,
                        ),
                        const Divider(height: 1),
                        _SettingsTile(
                          icon: Icons.email,
                          title: 'Contact Support',
                          subtitle: 'pushkarppisolkar@gmail.com',
                          trailing: const Icon(Icons.open_in_new, size: 20),
                          onTap: () => _launchURL('mailto:pushkarppisolkar@gmail.com'),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Danger Zone
                  Text(
                    'Danger Zone',
                    style: AppTextStyles.sectionHeader.copyWith(
                      color: AppDesignSystem.error,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  
                  CleanCard(
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.delete_forever,
                          title: 'Delete Account',
                          subtitle: 'Permanently delete your account',
                          titleColor: AppDesignSystem.error,
                          trailing: const Icon(Icons.chevron_right, size: 20, color: AppDesignSystem.error),
                          onTap: () => _showDeleteAccountDialog(),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => _showLogoutDialog(),
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppDesignSystem.error,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  
                        const SizedBox(height: 40),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Resend Verification Email
  Future<void> _resendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification email sent! Please check your inbox.'),
              backgroundColor: AppDesignSystem.success,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppDesignSystem.error,
          ),
        );
      }
    }
  }

  // Export User Data
  Future<void> _exportUserData() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Collect all user data
      final Map<String, dynamic> exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'userId': user.uid,
        'email': user.email,
      };

      // Get user profile
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        exportData['profile'] = userDoc.data();
      }

      // Get progress data
      final progressDocs = await FirebaseFirestore.instance
          .collection('progress')
          .where('userId', isEqualTo: user.uid)
          .get();
      exportData['progress'] = progressDocs.docs.map((d) => d.data()).toList();

      // Get badges
      final badgesDocs = await FirebaseFirestore.instance
          .collection('user_badges')
          .where('userId', isEqualTo: user.uid)
          .get();
      exportData['badges'] = badgesDocs.docs.map((d) => d.data()).toList();

      // Get certificates
      final certsDocs = await FirebaseFirestore.instance
          .collection('certificates')
          .where('userId', isEqualTo: user.uid)
          .get();
      exportData['certificates'] = certsDocs.docs.map((d) => d.data()).toList();

      // Get XP history
      final xpDocs = await FirebaseFirestore.instance
          .collection('xp_history')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();
      exportData['xpHistory'] = xpDocs.docs.map((d) => d.data()).toList();

      // Convert to JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/iplay_data_export_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);

      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'IPlay Data Export',
        text: 'Your IPlay data export from ${DateTime.now().toString().split(' ')[0]}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data exported successfully!'),
            backgroundColor: AppDesignSystem.success,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting data: ${e.toString()}'),
          backgroundColor: AppDesignSystem.error,
        ),
      );
    }
  }

  // Launch URL
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open $url'),
            backgroundColor: AppDesignSystem.error,
          ),
        );
      }
    }
  }

  // Rate App
  Future<void> _rateApp() async {
    try {
      await AppRatingService.openAppStore();
      await AppRatingService.markAsRated();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for rating IPlay!'),
            backgroundColor: AppDesignSystem.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // print('Error opening app store: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open app store. Please try again later.'),
            backgroundColor: AppDesignSystem.error,
          ),
        );
      }
    }
  }

  // Show About Dialog
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Image.asset('assets/logos/logo.png', width: 40, height: 40),
              const SizedBox(width: 12),
              const Text('About IPlay'),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'IPlay - Learn Intellectual Property Rights',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  'IPlay is an educational app designed to teach students about Intellectual Property Rights (IPR) through interactive learning, quizzes, and games.',
                ),
                SizedBox(height: 12),
                Text(
                  'Version: 1.0.0',
                  style: TextStyle(fontSize: 12, color: AppDesignSystem.textSecondary),
                ),
                SizedBox(height: 4),
                Text(
                  'Made with ❤️ in India',
                  style: TextStyle(fontSize: 12, color: AppDesignSystem.textSecondary),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Show Logout Confirmation Dialog
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                await _performLogout();
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: AppDesignSystem.error),
              ),
            ),
          ],
        );
      },
    );
  }

  // Perform Logout
  Future<void> _performLogout() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
        },
      );

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Clear SharedPreferences cache
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      } catch (e) {
        // print('Error clearing SharedPreferences: $e');
        // Continue with logout even if cache clear fails
      }

      if (!mounted) return;
      
      // Close loading dialog
      Navigator.of(context).pop();

      // Navigate to auth screen and clear all previous routes
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/auth',
        (Route<dynamic> route) => false,
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully logged out'),
          backgroundColor: AppDesignSystem.success,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // print('Error during logout: $e');
      
      // Close loading dialog
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      if (!mounted) return;

      // Show error with retry option
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: AppDesignSystem.error,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _performLogout(),
          ),
        ),
      );
    }
  }

  // Show Delete Account Dialog
  void _showDeleteAccountDialog() {
    final TextEditingController confirmController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: AppDesignSystem.error),
              SizedBox(width: 8),
              Text('Delete Account'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This action is permanent and cannot be undone. All your progress, badges, and certificates will be lost.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Type "DELETE" to confirm:'),
              const SizedBox(height: 8),
              TextField(
                controller: confirmController,
                decoration: const InputDecoration(
                  hintText: 'DELETE',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                confirmController.dispose();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (confirmController.text.trim() == 'DELETE') {
                  confirmController.dispose();
                  Navigator.of(context).pop();
                  _performDeleteAccount();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please type DELETE to confirm'),
                      backgroundColor: AppDesignSystem.warning,
                    ),
                  );
                }
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: AppDesignSystem.error),
              ),
            ),
          ],
        );
      },
    );
  }

  // Perform Account Deletion
  Future<void> _performDeleteAccount() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Delete user data from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .delete();

      // Delete the user's authentication account
      await currentUser.delete();

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/auth',
        (Route<dynamic> route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account deleted successfully'),
          backgroundColor: AppDesignSystem.success,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // print('Error during account deletion: $e');
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading

      // If error is due to recent sign-in requirement
      if (e.toString().contains('requires-recent-login')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign out and sign in again before deleting your account'),
            backgroundColor: AppDesignSystem.error,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account deletion failed: ${e.toString()}'),
            backgroundColor: AppDesignSystem.error,
          ),
        );
      }
    }
  }
}

/// Settings tile widget
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(icon, color: titleColor ?? AppDesignSystem.textPrimary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.cardTitle.copyWith(
                        fontSize: 16,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// Settings switch tile widget
class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Function(bool) onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: AppDesignSystem.textPrimary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppDesignSystem.primaryIndigo,
          ),
        ],
      ),
    );
  }
}

