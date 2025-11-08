import 'package:flutter/material.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_spacing.dart';
import '../../widgets/clean_card.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
                    const Text(
                      'Privacy Policy for IPlay',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppDesignSystem.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Last updated: ${DateTime.now().year}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppDesignSystem.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    _buildSection(
                      'Introduction',
                      'IPlay ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.',
                    ),
                    
                    _buildSection(
                      'Information We Collect',
                      'We collect information that you provide directly to us, including:\n\n'
                      '• Account information (name, email address, state)\n'
                      '• Profile information (display name, avatar)\n'
                      '• Educational data (progress, scores, achievements)\n'
                      '• School/classroom information\n'
                      '• Usage data and preferences',
                    ),
                    
                    _buildSection(
                      'How We Use Your Information',
                      'We use the information we collect to:\n\n'
                      '• Provide and maintain our services\n'
                      '• Personalize your learning experience\n'
                      '• Track your educational progress\n'
                      '• Enable classroom and school features\n'
                      '• Communicate with you about the app\n'
                      '• Improve our services',
                    ),
                    
                    _buildSection(
                      'Data Security',
                      'We implement appropriate security measures to protect your personal information. Your data is stored securely using Firebase services with industry-standard encryption.',
                    ),
                    
                    _buildSection(
                      'Children\'s Privacy',
                      'Our service is designed for educational use by students. We comply with applicable children\'s privacy laws and do not knowingly collect personal information from children without proper consent.',
                    ),
                    
                    _buildSection(
                      'Data Sharing',
                      'We do not sell your personal information. We may share your information with:\n\n'
                      '• Your teachers and school administrators (for educational purposes)\n'
                      '• Service providers who assist in operating our app\n'
                      '• As required by law or legal process',
                    ),
                    
                    _buildSection(
                      'Your Rights',
                      'You have the right to:\n\n'
                      '• Access your personal information\n'
                      '• Update or correct your information\n'
                      '• Delete your account and data\n'
                      '• Control notification settings\n'
                      '• Opt-out of data collection',
                    ),
                    
                    _buildSection(
                      'Data Retention',
                      'We retain your information for as long as your account is active or as needed to provide services. When you delete your account, we will delete your personal information within 30 days.',
                    ),
                    
                    _buildSection(
                      'Changes to This Policy',
                      'We may update this Privacy Policy from time to time. We will notify you of any changes by updating the "Last updated" date at the top of this policy.',
                    ),
                    
                    _buildSection(
                      'Contact Us',
                      'If you have questions about this Privacy Policy, please contact us at:\n\n'
                      'Email: support@iplay.example.com\n'
                      'Address: [Your Organization Address]',
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

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppDesignSystem.primaryIndigo,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppDesignSystem.textPrimary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

