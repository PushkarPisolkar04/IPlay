import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/clean_card.dart';
import 'qr_scanner_screen.dart';

/// Join Classroom Screen - For students to join classrooms using codes
class JoinClassroomScreen extends StatefulWidget {
  const JoinClassroomScreen({super.key});

  @override
  State<JoinClassroomScreen> createState() => _JoinClassroomScreenState();
}

class _JoinClassroomScreenState extends State<JoinClassroomScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _foundClassroom;
  String _inviteSource = 'manual'; // manual, link, code, qr

  @override
  void initState() {
    super.initState();
    // Check if we received a code from deep link
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['code'] != null) {
        _codeController.text = args['code'];
        _inviteSource = args['source'] ?? 'link';
        _searchClassroom();
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _searchClassroom() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final code = _codeController.text.trim().toUpperCase();
      
      final query = await FirebaseFirestore.instance
          .collection('classrooms')
          .where('joinCode', isEqualTo: code)
          .limit(1)
          .get();
      
      if (query.docs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid classroom code'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      
      setState(() {
        _foundClassroom = query.docs.first.data();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _joinClassroom() async {
    if (_foundClassroom == null) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // print('Student joining classroom - User ID: ${user.uid}');

      // Get student's name
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (!userDoc.exists) throw Exception('User not found');
      
      final studentName = userDoc.data()?['displayName'] ?? 'Student';
      final classroomId = _foundClassroom!['id'];
      final requiresApproval = _foundClassroom!['requiresApproval'] ?? false;

      // print('Student name: $studentName, role: $studentRole');
      // print('Classroom ID: $classroomId, requiresApproval: $requiresApproval');

      if (requiresApproval) {
        // print('Creating join request (requires approval)...');
        
        // Create join request
        await FirebaseFirestore.instance
            .collection('join_requests')
            .add({
          'classroomId': classroomId,
          'classroomName': _foundClassroom!['name'],
          'studentId': user.uid,
          'studentName': studentName,
          'status': 'pending',
          'resolvedBy': null,
          'rejectReason': null,
          'requestedAt': Timestamp.now(),
          'resolvedAt': null,
          'inviteSource': _inviteSource,
        });

        // print('Join request created, adding to pendingStudentIds and pendingClassroomRequests...');
        
        // Add student to pending list in classroom
        await FirebaseFirestore.instance
            .collection('classrooms')
            .doc(classroomId)
            .update({
          'pendingStudentIds': FieldValue.arrayUnion([user.uid]),
          'updatedAt': Timestamp.now(),
        });

        // Add classroom to student's pending requests
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'pendingClassroomRequests': FieldValue.arrayUnion([classroomId]),
          'updatedAt': Timestamp.now(),
        });

        // print('Successfully added to pending list!');

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Join request sent! Wait for teacher approval.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      } else {
        // print('Direct join (no approval needed)...');
        
        // Get classroom's schoolId and schoolTag to update student profile
        final schoolId = _foundClassroom!['schoolId'];
        final schoolTag = _foundClassroom!['schoolTag'];
        
        // Direct join (no approval needed)
        await FirebaseFirestore.instance
            .collection('classrooms')
            .doc(classroomId)
            .update({
          'studentIds': FieldValue.arrayUnion([user.uid]),
          'updatedAt': Timestamp.now(),
        });

        // print('Added to studentIds, updating user profile...');

        // Update student's profile with classroom, school, and schoolTag
        final updateData = {
          'classroomIds': FieldValue.arrayUnion([classroomId]),
          'updatedAt': Timestamp.now(),
        };
        
        if (schoolId != null) {
          updateData['schoolId'] = schoolId;
        }
        
        if (schoolTag != null) {
          updateData['schoolTag'] = schoolTag;
        }
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update(updateData);

        // Track invite source in classroom analytics
        await FirebaseFirestore.instance
            .collection('classrooms')
            .doc(classroomId)
            .collection('analytics')
            .doc('invite_sources')
            .set({
          _inviteSource: FieldValue.increment(1),
        }, SetOptions(merge: true));

        // print('Successfully joined classroom with schoolId: $schoolId!');

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully joined classroom!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppDesignSystem.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Custom gradient app bar
            Container(
              decoration: BoxDecoration(
                gradient: AppDesignSystem.gradientPrimary,
                boxShadow: [
                  BoxShadow(
                    color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Join Classroom',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
            // Body content
            Expanded(
              child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
                      AppDesignSystem.primaryPink.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.group_add,
                        color: AppDesignSystem.primaryIndigo,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Enter the join code provided by your teacher',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppDesignSystem.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              TextFormField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Classroom Code',
                  hintText: 'CLS-XXXXX',
                  prefixIcon: Icon(Icons.vpn_key),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a classroom code';
                  }
                  if (!RegExp(r'^CLS-[A-Z0-9]{5}$').hasMatch(value.toUpperCase())) {
                    return 'Invalid code format (CLS-XXXXX)';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() => _foundClassroom = null);
                },
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              if (_foundClassroom == null) ...[
                PrimaryButton(
                  text: _isLoading ? 'Searching...' : 'Search Classroom',
                  onPressed: _isLoading ? () {} : _searchClassroom,
                  fullWidth: true,
                ),
                
                const SizedBox(height: AppSpacing.md),
                
                // QR Scanner Button
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : () async {
                    final scannedCode = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QRScannerScreen(),
                      ),
                    );
                    
                    if (scannedCode != null && mounted) {
                      _codeController.text = scannedCode;
                      _inviteSource = 'qr';
                      _searchClassroom();
                    }
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan QR Code'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    side: const BorderSide(color: AppDesignSystem.primaryIndigo),
                    foregroundColor: AppDesignSystem.primaryIndigo,
                  ),
                ),
              ],
              
              const SizedBox(height: AppSpacing.xl),
              
              // Found classroom
              if (_foundClassroom != null) ...[
                Text(
                  'Classroom Found',
                  style: AppTextStyles.sectionHeader,
                ),
                const SizedBox(height: AppSpacing.sm),
                
                CleanCard(
                  color: AppDesignSystem.success.withValues(alpha: 0.1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppDesignSystem.primaryIndigo,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.school,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _foundClassroom!['name'],
                                  style: AppTextStyles.cardTitle,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Teacher: ${_foundClassroom!['teacherName']}',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      if (_foundClassroom!['schoolTag'] != null) ...[
                        const Divider(),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_city,
                              size: 16,
                              color: AppDesignSystem.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _foundClassroom!['schoolTag'],
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ],
                      
                      const Divider(),
                      
                      Row(
                        children: [
                          Icon(
                            _foundClassroom!['requiresApproval'] 
                                ? Icons.lock 
                                : Icons.lock_open,
                            size: 16,
                            color: AppDesignSystem.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _foundClassroom!['requiresApproval']
                                ? 'Requires teacher approval'
                                : 'Join instantly',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                PrimaryButton(
                  text: _isLoading ? 'Joining...' : 'Join Classroom',
                  onPressed: _isLoading ? () {} : _joinClassroom,
                  fullWidth: true,
                ),
              ],
              
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

