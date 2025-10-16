import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/clean_card.dart';
import '../../widgets/avatar_widget.dart';

class TeacherLeaderboardScreen extends StatefulWidget {
  final String classroomId;
  
  const TeacherLeaderboardScreen({super.key, required this.classroomId});

  @override
  State<TeacherLeaderboardScreen> createState() => _TeacherLeaderboardScreenState();
}

class _TeacherLeaderboardScreenState extends State<TeacherLeaderboardScreen> {
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  String _classroomName = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Get classroom info
      final classroomDoc = await FirebaseFirestore.instance
          .collection('classrooms')
          .doc(widget.classroomId)
          .get();
      
      if (classroomDoc.exists) {
        final data = classroomDoc.data()!;
        _classroomName = data['name'] ?? 'Classroom';
        
        // Get student IDs
        final studentIds = (data['studentIds'] as List?)?.cast<String>() ?? [];
        
        // Fetch students
        final students = <Map<String, dynamic>>[];
        if (studentIds.isNotEmpty) {
          // Batch requests
          final batches = <List<String>>[];
          for (int i = 0; i < studentIds.length; i += 10) {
            batches.add(studentIds.sublist(i, (i + 10 < studentIds.length) ? i + 10 : studentIds.length));
          }
          
          for (var batch in batches) {
            final snapshot = await FirebaseFirestore.instance
                .collection('users')
                .where(FieldPath.documentId, whereIn: batch)
                .get();
            
            for (var doc in snapshot.docs) {
              final data = doc.data();
              students.add({
                'uid': doc.id,
                'displayName': data['displayName'] ?? 'Unknown',
                'avatarUrl': data['avatarUrl'],
                'totalXP': data['totalXP'] ?? 0,
                'level': data['level'] ?? 1,
              });
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
      backgroundColor: const Color(0xFFF5F7FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: CustomScrollView(
                slivers: [
                  // Header with green gradient
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const Spacer(),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              _classroomName.isEmpty ? 'Classroom Leaderboard' : _classroomName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content
                  if (_students.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'No students yet',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final student = _students[index];
                            final rank = index + 1;
                            
                            // Special styling for top 3
                            Color? rankColor;
                            IconData? medalIcon;
                            if (rank == 1) {
                              rankColor = const Color(0xFFFFD700);
                              medalIcon = Icons.emoji_events;
                            } else if (rank == 2) {
                              rankColor = const Color(0xFFC0C0C0);
                              medalIcon = Icons.emoji_events;
                            } else if (rank == 3) {
                              rankColor = const Color(0xFFCD7F32);
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
                                              'Level ${student['level']}',
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
                                          color: const Color(0xFF10B981).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '${student['totalXP']} XP',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF10B981),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: _students.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

