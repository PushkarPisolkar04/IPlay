import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/clean_card.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  final bool isSchoolWide;
  final String? classroomId;
  
  const CreateAnnouncementScreen({super.key, this.isSchoolWide = false, this.classroomId});

  @override
  State<CreateAnnouncementScreen> createState() => _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;
  String? _selectedClassroomId;
  List<Map<String, dynamic>> _classrooms = [];

  @override
  void initState() {
    super.initState();
    _selectedClassroomId = widget.classroomId;
    if (widget.classroomId == null && !widget.isSchoolWide) {
      _loadClassrooms();
    }
  }

  Future<void> _loadClassrooms() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final classroomsSnapshot = await FirebaseFirestore.instance
          .collection('classrooms')
          .where('teacherId', isEqualTo: user.uid)
          .get();

      setState(() {
        _classrooms = classroomsSnapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc.data()['name'] ?? 'Unnamed',
          };
        }).toList();
        
        if (_classrooms.isNotEmpty && _selectedClassroomId == null) {
          _selectedClassroomId = _classrooms[0]['id'];
        }
      });
    } catch (e) {
      print('Error loading classrooms: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _postAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Get user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) throw Exception('User not found');

      final userData = userDoc.data()!;
      final isPrincipal = userData['isPrincipal'] == true;
      
      // Create announcement
      final announcementData = {
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'authorId': user.uid,
        'authorName': userData['displayName'] ?? 'Unknown',
        'authorRole': isPrincipal ? 'principal' : 'teacher',
        'isSchoolWide': widget.isSchoolWide,
        'createdAt': Timestamp.now(),
      };

      if (widget.isSchoolWide && isPrincipal) {
        // School-wide announcement
        final schoolId = userData['principalOfSchool'];
        if (schoolId == null) throw Exception('Principal not associated with a school');
        
        announcementData['schoolId'] = schoolId;
        
        print('Creating announcement: $announcementData');
        
        final docRef = await FirebaseFirestore.instance
            .collection('announcements')
            .add(announcementData);
        
        print('Announcement created with ID: ${docRef.id}');
      } else {
        // Classroom announcement (for teachers)
        final classroomId = widget.classroomId ?? _selectedClassroomId;
        if (classroomId == null) throw Exception('No classroom specified');
        
        announcementData['classroomId'] = classroomId;
        
        print('Creating classroom announcement: $announcementData');
        
        final docRef = await FirebaseFirestore.instance
            .collection('announcements')
            .add(announcementData);
        
        print('Classroom announcement created with ID: ${docRef.id}');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isSchoolWide ? 'School Announcement' : 'Classroom Announcement'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CleanCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            widget.isSchoolWide ? Icons.school : Icons.class_,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.isSchoolWide ? 'Post to Entire School' : 'Post to Classroom',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.isSchoolWide
                            ? 'This announcement will be visible to all students and teachers in your school.'
                            : 'This announcement will be visible to all students in your classroom.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Classroom Selector for Teachers
              if (!widget.isSchoolWide && widget.classroomId == null && _classrooms.isNotEmpty)
                CleanCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Classroom',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedClassroomId,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: _classrooms.map((classroom) {
                            return DropdownMenuItem<String>(
                              value: classroom['id'],
                              child: Text(classroom['name']),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedClassroomId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a classroom';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              if (!widget.isSchoolWide && widget.classroomId == null && _classrooms.isNotEmpty)
                const SizedBox(height: 16),
              
              CleanCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Title',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'e.g., Important Update',
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Message',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Write your announcement here...',
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        maxLines: 8,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a message';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _postAnnouncement,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Post Announcement',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
