import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/providers/user_provider.dart';
import '../../widgets/primary_button.dart';

/// Profile Setup Screen - For Google Sign-In users or additional info collection
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({Key? key}) : super(key: key);

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  
  String? _selectedState;
  String? _selectedAvatar;
  String _schoolTag = '';

  final List<String> _indianStates = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand',
    'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur',
    'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Punjab',
    'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura',
    'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
    'Andaman and Nicobar Islands', 'Chandigarh', 'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi', 'Jammu and Kashmir', 'Ladakh', 'Lakshadweep', 'Puducherry',
  ];

  final List<String> _avatarOptions = [
    '👦', '👧', '👨', '👩', '🧒', '👶',
    '👨‍🎓', '👩‍🎓', '👨‍💻', '👩‍💻', '👨‍🏫', '👩‍🏫',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your state')),
      );
      return;
    }
    if (_selectedAvatar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an avatar')),
      );
      return;
    }

    final userProvider = context.read<UserProvider>();
    
    try {
      // Update profile with collected information
      await userProvider.updateProfile({
        'displayName': _nameController.text.trim(),
        'username': _usernameController.text.trim().isNotEmpty 
            ? _usernameController.text.trim() 
            : null,
        'state': _selectedState,
        'avatarUrl': _selectedAvatar,
        'schoolTag': _schoolTag.isNotEmpty ? _schoolTag : null,
      });

      if (!mounted) return;

      // Navigate to role-specific onboarding
      Navigator.pushReplacementNamed(context, '/role-selection');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/backgrounds/background1.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.white.withOpacity(0.6),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.md),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Complete Your Profile',
                        style: AppTextStyles.h1,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Tell us a bit about yourself',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar Selection
                          Text(
                            'Choose Your Avatar',
                            style: AppTextStyles.h3,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            height: 80,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _avatarOptions.length,
                              itemBuilder: (context, index) {
                                final avatar = _avatarOptions[index];
                                final isSelected = _selectedAvatar == avatar;
                                
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedAvatar = avatar;
                                    });
                                  },
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected 
                                          ? AppColors.primary.withOpacity(0.2)
                                          : Colors.white,
                                      border: Border.all(
                                        color: isSelected 
                                            ? AppColors.primary
                                            : AppColors.border,
                                        width: isSelected ? 3 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(35),
                                    ),
                                    child: Center(
                                      child: Text(
                                        avatar,
                                        style: const TextStyle(fontSize: 32),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          
                          const SizedBox(height: AppSpacing.xl),
                          
                          // Full Name
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name *',
                              hintText: 'Enter your full name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: AppSpacing.md),
                          
                          // Username (Display Name)
                          TextFormField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Display Name (Optional)',
                              hintText: 'How others see you on leaderboards',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            maxLength: 20,
                          ),
                          
                          const SizedBox(height: AppSpacing.md),
                          
                          // State Selection
                          DropdownButtonFormField<String>(
                            value: _selectedState,
                            decoration: const InputDecoration(
                              labelText: 'State/UT *',
                              hintText: 'Select your state',
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                            items: _indianStates.map((state) {
                              return DropdownMenuItem(
                                value: state,
                                child: Text(state),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedState = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select your state';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: AppSpacing.md),
                          
                          // School Tag (Optional)
                          TextFormField(
                            onChanged: (value) {
                              setState(() {
                                _schoolTag = value;
                              });
                            },
                            decoration: const InputDecoration(
                              labelText: 'School Name (Optional)',
                              hintText: 'Enter your school name',
                              prefixIcon: Icon(Icons.school_outlined),
                            ),
                          ),
                          
                          const SizedBox(height: AppSpacing.xl),
                          
                          // Save Button
                          Consumer<UserProvider>(
                            builder: (context, userProvider, _) {
                              return PrimaryButton(
                                text: userProvider.isLoading ? 'Saving...' : 'Continue',
                                onPressed: userProvider.isLoading ? () {} : _saveProfile,
                                fullWidth: true,
                              );
                            },
                          ),
                          
                          const SizedBox(height: AppSpacing.xl),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

