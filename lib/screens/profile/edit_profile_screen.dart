import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/models/user_model.dart';
import '../../widgets/clean_card.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/primary_button.dart';

/// Edit Profile Screen - Edit user profile information
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  String? _selectedState;
  String? _selectedAvatar;
  String? _currentUserId;
  String? _userRole;
  
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

  List<String> _avatarOptions = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        _currentUserId = currentUser.uid;
        
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        
        if (doc.exists) {
          final userData = doc.data()!;
          _userRole = userData['role'];
          
          // Set avatar options based on role
          if (_userRole == 'student') {
            _avatarOptions = List.generate(16, (i) => 'assets/stu_avatars/avatar${i + 1}.png');
          } else {
            _avatarOptions = List.generate(16, (i) => 'assets/tea_avatars/avatar${i + 1}.png');
          }
          
          setState(() {
            _nameController.text = userData['displayName'] ?? '';
            _selectedState = userData['state'];
            _selectedAvatar = userData['avatarUrl'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your state'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    
    if (_selectedAvatar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an avatar'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .update({
        'displayName': _nameController.text.trim(),
        'state': _selectedState,
        'avatarUrl': _selectedAvatar,
        'updatedAt': Timestamp.now(),
      });

      if (!mounted) return;

      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      print('Error saving profile: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar Selection
                    Text(
                      'Select Avatar',
                      style: AppTextStyles.sectionHeader,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CleanCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Current Avatar Preview
                            if (_selectedAvatar != null)
                              Center(
                                child: AvatarWidget(
                                  imageUrl: _selectedAvatar,
                                  initials: _nameController.text.isNotEmpty 
                                      ? _nameController.text.substring(0, 1).toUpperCase() 
                                      : 'U',
                                  size: 80,
                                ),
                              ),
                            const SizedBox(height: 16),
                            
                            // Avatar Grid
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: _avatarOptions.length,
                              itemBuilder: (context, index) {
                                final avatar = _avatarOptions[index];
                                final isSelected = _selectedAvatar == avatar;
                                
                                return GestureDetector(
                                  onTap: () {
                                    setState(() => _selectedAvatar = avatar);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected 
                                            ? AppColors.primary 
                                            : AppColors.border,
                                        width: isSelected ? 3 : 2,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        avatar,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.person),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Display Name
                    Text(
                      'Display Name',
                      style: AppTextStyles.sectionHeader,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CleanCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            hintText: 'Enter your display name',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your display name';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    // State Selection
                    Text(
                      'State',
                      style: AppTextStyles.sectionHeader,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CleanCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: DropdownButtonFormField<String>(
                          value: _selectedState,
                          decoration: const InputDecoration(
                            hintText: 'Select your state',
                            prefixIcon: Icon(Icons.location_on),
                            border: OutlineInputBorder(),
                          ),
                          items: _indianStates.map((state) {
                            return DropdownMenuItem(
                              value: state,
                              child: Text(state),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedState = value);
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select your state';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: AppSpacing.xl),
                    
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
    );
  }
}

