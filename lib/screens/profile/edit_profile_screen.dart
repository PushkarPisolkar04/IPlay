import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/design/app_design_system.dart';
import '../../widgets/clean_card.dart';

/// Edit Profile Screen - Edit user profile information
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

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
  bool _isPrincipal = false;

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
          _isPrincipal = userData['isPrincipal'] == true;
          
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
      // print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedAvatar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an avatar'),
          backgroundColor: AppDesignSystem.warning,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Only update displayName and avatarUrl (state is locked)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .update({
        'displayName': _nameController.text.trim(),
        'avatarUrl': _selectedAvatar,
        'updatedAt': Timestamp.now(),
      });

      if (!mounted) return;

      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppDesignSystem.success,
        ),
      );
    } catch (e) {
      // print('Error saving profile: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppDesignSystem.error,
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
      resizeToAvoidBottomInset: true,
      backgroundColor: AppDesignSystem.backgroundLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
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
                                'Edit Profile',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Content
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // Avatar Selection
                          const SizedBox(height: 8),
                          CleanCard(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: GridView.builder(
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
                                              ? AppDesignSystem.primaryIndigo 
                                              : Colors.grey.shade300,
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
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Display Name
                          CleanCard(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Display Name',
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
                          
                          const SizedBox(height: 20),
                          
                          // State Selection (Locked for everyone - set during signup)
                          CleanCard(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: TextFormField(
                                initialValue: _selectedState,
                                enabled: false,
                                decoration: InputDecoration(
                                  labelText: 'State',
                                  hintText: 'State (Cannot be changed)',
                                  prefixIcon: const Icon(Icons.location_on),
                                  border: const OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                  suffixIcon: const Icon(Icons.lock, color: Colors.grey),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Role Display (Read-only)
                          CleanCard(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: TextFormField(
                                initialValue: _isPrincipal ? 'Principal' : (_userRole ?? 'User'),
                                enabled: false,
                                decoration: InputDecoration(
                                  labelText: 'Role',
                                  hintText: 'Your role',
                                  prefixIcon: const Icon(Icons.badge),
                                  border: const OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                  suffixIcon: const Icon(Icons.lock, color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppDesignSystem.primaryIndigo,
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
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

