import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/design/app_design_system.dart';
import '../../widgets/clean_card.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/loading_skeleton.dart';
import '../teacher/student_detail_screen.dart';

/// All Students Screen for Principal
/// Displays all students across all classrooms in the school
/// with filtering and sorting options
class AllStudentsScreen extends StatefulWidget {
  final String schoolId;

  const AllStudentsScreen({
    super.key,
    required this.schoolId,
  });

  @override
  State<AllStudentsScreen> createState() => _AllStudentsScreenState();
}

class _AllStudentsScreenState extends State<AllStudentsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  bool _isLoading = true;
  
  // Filter and sort options
  String _searchQuery = '';
  String _sortBy = 'name'; // name, xp, streak, classroom
  bool _sortAscending = true;
  String? _filterClassroom;
  List<Map<String, dynamic>> _classrooms = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load all classrooms in the school
      final classroomsSnapshot = await _firestore
          .collection('classrooms')
          .where('schoolId', isEqualTo: widget.schoolId)
          .get();
      
      _classrooms = classroomsSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc.data()['name'] ?? 'Unnamed Classroom',
        };
      }).toList();
      
      // Collect all unique student IDs from all classrooms
      Set<String> studentIds = {};
      Map<String, String> studentClassrooms = {}; // studentId -> classroomName
      
      for (var classroomDoc in classroomsSnapshot.docs) {
        final data = classroomDoc.data();
        final classroomName = data['name'] ?? 'Unnamed Classroom';
        final ids = List<String>.from(data['studentIds'] ?? []);
        
        for (var id in ids) {
          studentIds.add(id);
          // Store first classroom (students might be in multiple)
          if (!studentClassrooms.containsKey(id)) {
            studentClassrooms[id] = classroomName;
          }
        }
      }
      
      // Load student data
      _students = [];
      for (var studentId in studentIds) {
        final studentDoc = await _firestore
            .collection('users')
            .doc(studentId)
            .get();
        
        if (studentDoc.exists) {
          final userData = studentDoc.data()!;
          _students.add({
            'id': studentId,
            'name': userData['displayName'] ?? 'Unknown',
            'avatarUrl': userData['avatarUrl'],
            'totalXP': userData['totalXP'] ?? 0,
            'currentStreak': userData['currentStreak'] ?? 0,
            'badges': (userData['badges'] as List?)?.length ?? 0,
            'classroom': studentClassrooms[studentId] ?? 'No Classroom',
            'progressSummary': userData['progressSummary'] ?? {},
            'lastActiveDate': (userData['lastActiveDate'] as Timestamp?)?.toDate(),
          });
        }
      }
      
      _applyFiltersAndSort();
    } catch (e) {
      // print('Error loading students: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading students: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFiltersAndSort() {
    // Apply filters
    _filteredStudents = _students.where((student) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final name = student['name'].toString().toLowerCase();
        if (!name.contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }
      
      // Classroom filter
      if (_filterClassroom != null && _filterClassroom!.isNotEmpty) {
        if (student['classroom'] != _filterClassroom) {
          return false;
        }
      }
      
      return true;
    }).toList();
    
    // Apply sorting
    _filteredStudents.sort((a, b) {
      int comparison = 0;
      
      switch (_sortBy) {
        case 'name':
          comparison = a['name'].toString().compareTo(b['name'].toString());
          break;
        case 'xp':
          comparison = (a['totalXP'] as int).compareTo(b['totalXP'] as int);
          break;
        case 'streak':
          comparison = (a['currentStreak'] as int).compareTo(b['currentStreak'] as int);
          break;
        case 'classroom':
          comparison = a['classroom'].toString().compareTo(b['classroom'].toString());
          break;
      }
      
      return _sortAscending ? comparison : -comparison;
    });
    
    setState(() {});
  }

  int _calculateProgress(Map<String, dynamic> progressSummary) {
    if (progressSummary.isEmpty) return 0;
    
    int totalLevels = 0;
    int completedLevels = 0;
    
    for (var entry in progressSummary.values) {
      if (entry is Map<String, dynamic>) {
        totalLevels += (entry['totalLevels'] as int?) ?? 0;
        completedLevels += (entry['levelsCompleted'] as int?) ?? 0;
      }
    }
    
    if (totalLevels == 0) return 0;
    return ((completedLevels / totalLevels) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('All Students'),
        backgroundColor: const Color(0xFF6B46C1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6B46C1), Color(0xFF9333EA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    _applyFiltersAndSort();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search students...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Filter and Sort Row
                Row(
                  children: [
                    // Classroom Filter
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _filterClassroom,
                            hint: const Text('All Classrooms'),
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('All Classrooms'),
                              ),
                              ..._classrooms.map((classroom) {
                                return DropdownMenuItem<String?>(
                                  value: classroom['name'],
                                  child: Text(classroom['name']),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() => _filterClassroom = value);
                              _applyFiltersAndSort();
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Sort Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.sort),
                        onSelected: (value) {
                          setState(() {
                            if (_sortBy == value) {
                              _sortAscending = !_sortAscending;
                            } else {
                              _sortBy = value;
                              _sortAscending = false; // Default to descending for XP/streak
                            }
                          });
                          _applyFiltersAndSort();
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'name',
                            child: Row(
                              children: [
                                Icon(
                                  _sortBy == 'name' ? Icons.check : Icons.person,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text('Name'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'xp',
                            child: Row(
                              children: [
                                Icon(
                                  _sortBy == 'xp' ? Icons.check : Icons.stars,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text('XP'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'streak',
                            child: Row(
                              children: [
                                Icon(
                                  _sortBy == 'streak' ? Icons.check : Icons.local_fire_department,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text('Streak'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'classroom',
                            child: Row(
                              children: [
                                Icon(
                                  _sortBy == 'classroom' ? Icons.check : Icons.class_,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text('Classroom'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Student Count
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredStudents.length} student${_filteredStudents.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                if (_sortBy != 'name')
                  Text(
                    'Sorted by ${_sortBy.toUpperCase()} ${_sortAscending ? '↑' : '↓'}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
              ],
            ),
          ),
          
          // Students List
          Expanded(
            child: _isLoading
                ? const ListSkeleton(itemCount: 8)
                : _filteredStudents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty || _filterClassroom != null
                                  ? 'No students found'
                                  : 'No students in school',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = _filteredStudents[index];
                            return _buildStudentCard(student);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final progress = _calculateProgress(student['progressSummary']);
    final initials = student['name']
        .toString()
        .split(' ')
        .map((n) => n.isNotEmpty ? n[0] : '')
        .take(2)
        .join()
        .toUpperCase();
    
    final lastActive = student['lastActiveDate'] as DateTime?;
    final daysInactive = lastActive != null
        ? DateTime.now().difference(lastActive).inDays
        : null;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CleanCard(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentDetailScreen(
                studentId: student['id'],
                studentName: student['name'],
              ),
            ),
          );
        },
        child: Row(
          children: [
            // Avatar
            AvatarWidget(
              initials: initials,
              size: 56,
              backgroundColor: AppDesignSystem.primaryIndigo,
              imageUrl: student['avatarUrl'],
            ),
            const SizedBox(width: 16),
            
            // Student Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          student['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (daysInactive != null && daysInactive > 7)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Inactive ${daysInactive}d',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    student['classroom'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Stats Row
                  Row(
                    children: [
                      _buildStatChip(
                        Icons.stars,
                        '${student['totalXP']} XP',
                        const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        Icons.local_fire_department,
                        '${student['currentStreak']}',
                        const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        Icons.emoji_events,
                        '${student['badges']}',
                        const Color(0xFF8B5CF6),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Progress Bar
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF10B981),
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$progress%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
