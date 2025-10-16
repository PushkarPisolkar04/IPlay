import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/models/user_model.dart';
import '../../widgets/clean_card.dart';

/// Settings Screen - App settings, privacy, terms, logout
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

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
      print('Error loading user data: $e');
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
      print('Error updating notification setting: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update setting: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          onTap: () {
                            // Navigate to edit profile
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Edit profile coming soon!')),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        _SettingsTile(
                          icon: Icons.location_on,
                          title: 'State',
                          subtitle: _user?.state ?? '',
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () {
                            // Change state
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Change state coming soon!')),
                            );
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
                          trailing: const Icon(Icons.open_in_new, size: 20),
                          onTap: () => _launchURL('https://iplay.example.com/privacy'),
                        ),
                        const Divider(height: 1),
                        _SettingsTile(
                          icon: Icons.description,
                          title: 'Terms & Conditions',
                          subtitle: 'Read our terms and conditions',
                          trailing: const Icon(Icons.open_in_new, size: 20),
                          onTap: () => _launchURL('https://iplay.example.com/terms'),
                        ),
                        const Divider(height: 1),
                        _SettingsTile(
                          icon: Icons.shield,
                          title: 'Data & Security',
                          subtitle: 'How we protect your data',
                          trailing: const Icon(Icons.open_in_new, size: 20),
                          onTap: () => _launchURL('https://iplay.example.com/security'),
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
                          subtitle: 'support@iplay.example.com',
                          trailing: const Icon(Icons.open_in_new, size: 20),
                          onTap: () => _launchURL('mailto:support@iplay.example.com'),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Danger Zone
                  Text(
                    'Danger Zone',
                    style: AppTextStyles.sectionHeader.copyWith(
                      color: AppColors.error,
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
                          titleColor: AppColors.error,
                          trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.error),
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
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
    );
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
            backgroundColor: AppColors.error,
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
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                SizedBox(height: 4),
                Text(
                  'Made with ❤️ in India',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                style: TextStyle(color: AppColors.error),
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/auth',
        (Route<dynamic> route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully logged out'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error during logout: $e');
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // Show Delete Account Dialog
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: AppColors.error),
              SizedBox(width: 8),
              Text('Delete Account'),
            ],
          ),
          content: const Text(
            'This action is permanent and cannot be undone. All your progress, badges, and certificates will be lost.\n\nAre you absolutely sure?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account deletion coming soon. Please contact support.'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
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
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
    this.titleColor,
  }) : super(key: key);

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
              Icon(icon, color: titleColor ?? AppColors.textPrimary, size: 24),
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
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textPrimary, size: 24),
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
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

