import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/clean_card.dart';
import '../../widgets/avatar_widget.dart';

class SchoolLeaderboardScreen extends StatefulWidget {
  final String schoolId;
  
  const SchoolLeaderboardScreen({super.key, required this.schoolId});

  @override
  State<SchoolLeaderboardScreen> createState() => _SchoolLeaderboardScreenState();
}

class _SchoolLeaderboardScreenState extends State<SchoolLeaderboardScreen> {
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  String _schoolName = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Get school info
      final schoolDoc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .get();
      
      if (schoolDoc.exists) {
        _schoolName = schoolDoc.data()?['name'] ?? 'School';
        
        // Get all classrooms in school
        final classroomsSnapshot = await FirebaseFirestore.instance
            .collection('classrooms')
            .where('schoolId', isEqualTo: widget.schoolId)
            .get();
        
        // Collect all student IDs from all classrooms
        final studentIds = <String>{};
        for (var classroom in classroomsSnapshot.docs) {
          final ids = (classroom.data()['studentIds'] as List?)?.cast<String>() ?? [];
          studentIds.addAll(ids);
        }
        
        // Fetch all students
        final students = <Map<String, dynamic>>[];
        if (studentIds.isNotEmpty) {
          // Firestore has a limit of 10 items for 'whereIn', so batch them
          final batches = <List<String>>[];
          final idsList = studentIds.toList();
          for (int i = 0; i < idsList.length; i += 10) {
            batches.add(idsList.sublist(i, (i + 10 < idsList.length) ? i + 10 : idsList.length));
          }
          
          for (var batch in batches) {
            final snapshot = await FirebaseFirestore.instance
                .collection('users')
                .where(FieldPath.documentId, whereIn: batch)
                .get();
            
            for (var doc in snapshot.docs) {
              final data = doc.data();
              if (data['role'] == 'student') {
                students.add({
                  'uid': doc.id,
                  'displayName': data['displayName'] ?? 'Unknown',
                  'avatarUrl': data['avatarUrl'],
                  'totalXP': data['totalXP'] ?? 0,
                });
              }
            }
          }
        }
        
        // Sort by XP
        students.sort((a, b) => (b['totalXP'] as int).compareTo(a['totalXP'] as int));
        
        setState(() {
          _students = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading leaderboard: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_schoolName.isEmpty ? 'School Leaderboard' : '$_schoolName Leaderboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? const Center(
                  child: Text(
                    'No students yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    final rank = index + 1;
                    
                    // Special styling for top 3
                    Color? rankColor;
                    IconData? medalIcon;
                    if (rank == 1) {
                      rankColor = const Color(0xFFFFD700); // Gold
                      medalIcon = Icons.emoji_events;
                    } else if (rank == 2) {
                      rankColor = const Color(0xFFC0C0C0); // Silver
                      medalIcon = Icons.emoji_events;
                    } else if (rank == 3) {
                      rankColor = const Color(0xFFCD7F32); // Bronze
                      medalIcon = Icons.emoji_events;
                    }
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CleanCard(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Rank
                              SizedBox(
                                width: 40,
                                child: rank <= 3 && medalIcon != null
                                    ? Icon(medalIcon, color: rankColor, size: 28)
                                    : Text(
                                        '#$rank',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              // Avatar
                              AvatarWidget(
                                imageUrl: student['avatarUrl'],
                                initials: (student['displayName'] as String).substring(0, 1).toUpperCase(),
                                size: 40,
                              ),
                              const SizedBox(width: 12),
                              // Name
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student['displayName'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Level ${((student['totalXP'] as int) / 200).floor() + 1}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // XP
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${student['totalXP']} XP',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

