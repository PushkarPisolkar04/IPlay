import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../widgets/clean_card.dart';

class DataSecurityScreen extends StatelessWidget {
  const DataSecurityScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Data & Security'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CleanCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shield, color: AppColors.primary, size: 32),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'How We Protect Your Data',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    _buildSection(
                      'Data Encryption',
                      'All data transmitted between your device and our servers is encrypted using industry-standard SSL/TLS protocols.',
                      Icons.lock,
                      const Color(0xFF10B981),
                    ),
                    
                    _buildSection(
                      'Secure Storage',
                      'Your data is stored on Google Firebase servers with multiple layers of security and automatic backups.',
                      Icons.cloud_done,
                      const Color(0xFF3B82F6),
                    ),
                    
                    _buildSection(
                      'Authentication',
                      'We use Firebase Authentication to securely manage your login credentials with email verification and secure password storage.',
                      Icons.verified_user,
                      const Color(0xFF8B5CF6),
                    ),
                    
                    _buildSection(
                      'Access Control',
                      'Your personal data is only accessible to you and authorized school administrators. Teachers can only see data of students in their classrooms.',
                      Icons.admin_panel_settings,
                      const Color(0xFFF59E0B),
                    ),
                    
                    _buildSection(
                      'Data Minimization',
                      'We only collect the minimum data necessary to provide our educational services.',
                      Icons.minimize,
                      const Color(0xFF06B6D4),
                    ),
                    
                    _buildSection(
                      'Regular Audits',
                      'We regularly review and update our security practices to protect against new threats.',
                      Icons.security,
                      const Color(0xFFEC4899),
                    ),
                    
                    const SizedBox(height: 24),
                    const Text(
                      'What Data We Collect',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildDataItem('Account Information', 'Name, email, state'),
                    _buildDataItem('Profile Data', 'Display name, avatar, preferences'),
                    _buildDataItem('Progress Data', 'Scores, achievements, completed levels'),
                    _buildDataItem('School Data', 'School affiliation, classroom membership'),
                    _buildDataItem('Usage Data', 'App activity, last login date'),
                    
                    const SizedBox(height: 24),
                    const Text(
                      'Your Rights',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildRightItem('Access Your Data', 'View all data we have about you'),
                    _buildRightItem('Download Your Data', 'Export your progress and achievements'),
                    _buildRightItem('Update Your Data', 'Correct or update your information'),
                    _buildRightItem('Delete Your Data', 'Permanently remove your account'),
                    
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.primary),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'If you have any questions about data security, please contact us at support@iplay.example.com',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.arrow_right, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

