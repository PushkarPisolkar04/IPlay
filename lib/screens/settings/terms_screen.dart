import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../widgets/clean_card.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
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
                      'Terms and Conditions',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Last updated: ${DateTime.now().year}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    _buildSection(
                      'Acceptance of Terms',
                      'By accessing and using IPlay, you accept and agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use the app.',
                    ),
                    
                    _buildSection(
                      'Use License',
                      'Permission is granted to use IPlay for educational purposes. This license shall automatically terminate if you violate any of these restrictions.',
                    ),
                    
                    _buildSection(
                      'User Accounts',
                      'When you create an account with us, you must:\n\n'
                      '• Provide accurate and complete information\n'
                      '• Maintain the security of your password\n'
                      '• Be responsible for all activities under your account\n'
                      '• Notify us immediately of any unauthorized access',
                    ),
                    
                    _buildSection(
                      'User Conduct',
                      'You agree not to:\n\n'
                      '• Use the app for any unlawful purpose\n'
                      '• Harass, abuse, or harm other users\n'
                      '• Upload malicious code or viruses\n'
                      '• Attempt to gain unauthorized access\n'
                      '• Impersonate others\n'
                      '• Share inappropriate content',
                    ),
                    
                    _buildSection(
                      'Educational Content',
                      'All learning content provided in IPlay is for educational purposes. While we strive for accuracy, we do not guarantee that all information is complete or error-free.',
                    ),
                    
                    _buildSection(
                      'Intellectual Property',
                      'The app and its original content, features, and functionality are owned by IPlay and are protected by international copyright, trademark, and other intellectual property laws.',
                    ),
                    
                    _buildSection(
                      'User-Generated Content',
                      'By posting content in the app, you grant us the right to use, modify, and display such content for the purpose of providing and improving our services.',
                    ),
                    
                    _buildSection(
                      'Termination',
                      'We may terminate or suspend your account immediately, without prior notice, if you breach these Terms and Conditions.',
                    ),
                    
                    _buildSection(
                      'Limitation of Liability',
                      'IPlay shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use or inability to use the service.',
                    ),
                    
                    _buildSection(
                      'Disclaimer',
                      'The service is provided "AS IS" and "AS AVAILABLE" without warranties of any kind, either express or implied.',
                    ),
                    
                    _buildSection(
                      'Changes to Terms',
                      'We reserve the right to modify these terms at any time. We will notify users of any material changes.',
                    ),
                    
                    _buildSection(
                      'Governing Law',
                      'These terms shall be governed by and construed in accordance with the laws of India, without regard to its conflict of law provisions.',
                    ),
                    
                    _buildSection(
                      'Contact Information',
                      'For questions about these Terms and Conditions, please contact:\n\n'
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
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

