import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/clean_card.dart';
import '../../widgets/avatar_widget.dart';

class ComprehensiveLeaderboardScreen extends StatefulWidget {
  final String schoolId;
  
  const ComprehensiveLeaderboardScreen({super.key, required this.schoolId});

  @override
  State<ComprehensiveLeaderboardScreen> createState() => _ComprehensiveLeaderboardScreenState();
}

class _ComprehensiveLeaderboardScreenState extends State<ComprehensiveLeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  
  // School leaderboard
  List<Map<String, dynamic>> _schoolStudents = [];
  
  // Classroom leaderboard
  List<Map<String, dynamic>> _classrooms = [];
  String? _selectedClassroomId;
  List<Map<String, dynamic>> _classroomStudents = [];
  
  // State leaderboard
  String _schoolState = '';
  List<Map<String, dynamic>> _stateStudents = [];
  
  // Country leaderboard
  List<Map<String, dynamic>> _countryStudents = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _loadDataForTab(_tabController.index);
      }
    });
    _loadDataForTab(0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDataForTab(int index) async {
    setState(() => _isLoading = true);
    
    switch (index) {
      case 0:
        await _loadSchoolLeaderboard();
        break;
      case 1:
        await _loadClassrooms();
        break;
      case 2:
        await _loadStateLeaderboard();
        break;
      case 3:
        await _loadCountryLeaderboard();
        break;
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadSchoolLeaderboard() async {
    try {
      // Get all students from this school
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('schoolId', isEqualTo: widget.schoolId)
          .get();

      _schoolStudents = studentsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'displayName': data['displayName'] ?? 'Unknown',
          'avatarUrl': data['avatarUrl'],
          'totalXP': data['totalXP'] ?? 0,
          'level': data['level'] ?? 1,
        };
      }).toList();

      // Sort by totalXP
      _schoolStudents.sort((a, b) => (b['totalXP'] as int).compareTo(a['totalXP'] as int));
    } catch (e) {
      print('Error loading school leaderboard: $e');
    }
  }

  Future<void> _loadClassrooms() async {
    try {
      final classroomsSnapshot = await FirebaseFirestore.instance
          .collection('classrooms')
          .where('schoolId', isEqualTo: widget.schoolId)
          .get();

      _classrooms = classroomsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'grade': data['grade'] ?? '',
          'section': data['section'] ?? '',
        };
      }).toList();

      if (_classrooms.isNotEmpty && _selectedClassroomId == null) {
        _selectedClassroomId = _classrooms[0]['id'];
        await _loadClassroomStudents();
      }
    } catch (e) {
      print('Error loading classrooms: $e');
    }
  }

  Future<void> _loadClassroomStudents() async {
    if (_selectedClassroomId == null) return;
    
    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('classroomId', isEqualTo: _selectedClassroomId)
          .get();

      _classroomStudents = studentsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'displayName': data['displayName'] ?? 'Unknown',
          'avatarUrl': data['avatarUrl'],
          'totalXP': data['totalXP'] ?? 0,
          'level': data['level'] ?? 1,
        };
      }).toList();

      _classroomStudents.sort((a, b) => (b['totalXP'] as int).compareTo(a['totalXP'] as int));
      
      if (mounted) setState(() {});
    } catch (e) {
      print('Error loading classroom students: $e');
    }
  }

  Future<void> _loadStateLeaderboard() async {
    try {
      // Get school's state
      final schoolDoc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .get();

      if (schoolDoc.exists) {
        _schoolState = schoolDoc.data()?['state'] ?? '';
        
        if (_schoolState.isNotEmpty) {
          // Get all students from the same state
          final studentsSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'student')
              .where('state', isEqualTo: _schoolState)
              .limit(100)
              .get();

          _stateStudents = studentsSnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'displayName': data['displayName'] ?? 'Unknown',
              'avatarUrl': data['avatarUrl'],
              'totalXP': data['totalXP'] ?? 0,
              'level': data['level'] ?? 1,
              'schoolName': '', // Will be fetched
            };
          }).toList();

          // Sort by totalXP
          _stateStudents.sort((a, b) => (b['totalXP'] as int).compareTo(a['totalXP'] as int));
          
          // Get school names
          for (var student in _stateStudents) {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(student['id'])
                .get();
            
            if (userDoc.exists) {
              final schoolId = userDoc.data()?['schoolId'];
              if (schoolId != null) {
                final schoolDoc = await FirebaseFirestore.instance
                    .collection('schools')
                    .doc(schoolId)
                    .get();
                student['schoolName'] = schoolDoc.data()?['name'] ?? 'Unknown School';
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error loading state leaderboard: $e');
    }
  }

  Future<void> _loadCountryLeaderboard() async {
    try {
      // Get top students from entire country (limit to 100)
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .orderBy('totalXP', descending: true)
          .limit(100)
          .get();

      _countryStudents = studentsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'displayName': data['displayName'] ?? 'Unknown',
          'avatarUrl': data['avatarUrl'],
          'totalXP': data['totalXP'] ?? 0,
          'level': data['level'] ?? 1,
          'state': data['state'] ?? 'Unknown',
          'schoolName': '', // Will be fetched
        };
      }).toList();

      // Get school names
      for (var student in _countryStudents) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(student['id'])
            .get();
        
        if (userDoc.exists) {
          final schoolId = userDoc.data()?['schoolId'];
          if (schoolId != null) {
            final schoolDoc = await FirebaseFirestore.instance
                .collection('schools')
                .doc(schoolId)
                .get();
            student['schoolName'] = schoolDoc.data()?['name'] ?? 'Unknown School';
          }
        }
      }
    } catch (e) {
      print('Error loading country leaderboard: $e');
    }
  }

  Widget _buildLeaderboardItem(Map<String, dynamic> student, int rank, {String? subtitle}) {
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
                child: Center(
                  child: medalIcon != null
                      ? Icon(medalIcon, color: rankColor, size: 28)
                      : Text(
                          '$rank',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
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
              // Info
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
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // XP
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.stars, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${student['totalXP']} XP',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Level ${student['level']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6B46C1), Color(0xFF9333EA)],
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
                      'Leaderboards',
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
            
            // Tabs (outside gradient)
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                tabs: const [
                  Tab(text: 'School'),
                  Tab(text: 'Class'),
                  Tab(text: 'State'),
                  Tab(text: 'Country'),
                ],
              ),
            ),
            
            // Tab content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        // School Tab
                        _buildSchoolTab(),
                        // Classroom Tab
                        _buildClassroomTab(),
                        // State Tab
                        _buildStateTab(),
                        // Country Tab
                        _buildCountryTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolTab() {
    if (_schoolStudents.isEmpty) {
      return const Center(
        child: Text('No students yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _schoolStudents.length,
      itemBuilder: (context, index) {
        return _buildLeaderboardItem(_schoolStudents[index], index + 1);
      },
    );
  }

  Widget _buildClassroomTab() {
    if (_classrooms.isEmpty) {
      return const Center(
        child: Text('No classrooms yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }

    return Column(
      children: [
        // Classroom selector
        Padding(
          padding: const EdgeInsets.all(16),
          child: CleanCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DropdownButton<String>(
                value: _selectedClassroomId,
                isExpanded: true,
                underline: const SizedBox(),
                items: _classrooms.map<DropdownMenuItem<String>>((classroom) {
                  return DropdownMenuItem<String>(
                    value: classroom['id'] as String,
                    child: Text('${classroom['name']} (Grade ${classroom['grade']} ${classroom['section']})'),
                  );
                }).toList(),
                onChanged: (value) async {
                  setState(() {
                    _selectedClassroomId = value;
                    _isLoading = true;
                  });
                  await _loadClassroomStudents();
                  setState(() => _isLoading = false);
                },
              ),
            ),
          ),
        ),
        // Students list
        Expanded(
          child: _classroomStudents.isEmpty
              ? const Center(
                  child: Text('No students in this classroom', style: TextStyle(fontSize: 16, color: Colors.grey)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _classroomStudents.length,
                  itemBuilder: (context, index) {
                    return _buildLeaderboardItem(_classroomStudents[index], index + 1);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStateTab() {
    if (_stateStudents.isEmpty) {
      return Center(
        child: Text(
          _schoolState.isEmpty ? 'School state not set' : 'No students in $_schoolState',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Top Students in $_schoolState',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _stateStudents.length,
            itemBuilder: (context, index) {
              final student = _stateStudents[index];
              return _buildLeaderboardItem(
                student,
                index + 1,
                subtitle: student['schoolName'],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCountryTab() {
    if (_countryStudents.isEmpty) {
      return const Center(
        child: Text('No students yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Top 100 Students in India',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _countryStudents.length,
            itemBuilder: (context, index) {
              final student = _countryStudents[index];
              return _buildLeaderboardItem(
                student,
                index + 1,
                subtitle: '${student['schoolName']} • ${student['state']}',
              );
            },
          ),
        ),
      ],
    );
  }
}

