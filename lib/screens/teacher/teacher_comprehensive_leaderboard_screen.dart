import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/clean_card.dart';
import '../../widgets/avatar_widget.dart';

class TeacherComprehensiveLeaderboardScreen extends StatefulWidget {
  final String schoolId;
  final List<String> classroomIds; // Teacher's classrooms
  
  const TeacherComprehensiveLeaderboardScreen({
    super.key, 
    required this.schoolId,
    required this.classroomIds,
  });

  @override
  State<TeacherComprehensiveLeaderboardScreen> createState() => _TeacherComprehensiveLeaderboardScreenState();
}

class _TeacherComprehensiveLeaderboardScreenState extends State<TeacherComprehensiveLeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  
  // School leaderboard
  List<Map<String, dynamic>> _schoolStudents = [];
  
  // Classroom leaderboard
  String? _selectedClassroomId;
  List<Map<String, dynamic>> _classroomStudents = [];
  Map<String, String> _classroomNames = {};
  
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
        await _loadClassroomData();
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

      _schoolStudents.sort((a, b) => (b['totalXP'] as int).compareTo(a['totalXP'] as int));
    } catch (e) {
      print('Error loading school leaderboard: $e');
    }
  }

  Future<void> _loadClassroomData() async {
    try {
      // Load classroom names
      for (var classroomId in widget.classroomIds) {
        final doc = await FirebaseFirestore.instance
            .collection('classrooms')
            .doc(classroomId)
            .get();
        
        if (doc.exists) {
          final data = doc.data()!;
          _classroomNames[classroomId] = '${data['name']} (${data['grade']} ${data['section']})';
        }
      }

      if (widget.classroomIds.isNotEmpty) {
        _selectedClassroomId = widget.classroomIds[0];
        await _loadClassroomStudents();
      }
    } catch (e) {
      print('Error loading classroom data: $e');
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
      final schoolDoc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .get();

      if (schoolDoc.exists) {
        _schoolState = schoolDoc.data()?['state'] ?? '';
        
        if (_schoolState.isNotEmpty) {
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
              'schoolName': '',
            };
          }).toList();

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
          'schoolName': '',
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
                          color: Color(0xFF10B981),
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
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header with green gradient
            Container(
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
                labelColor: const Color(0xFF10B981),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF10B981),
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
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSchoolTab(),
                        _buildClassroomTab(),
                        _buildStateTab(),
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
    if (widget.classroomIds.isEmpty) {
      return const Center(
        child: Text('No classrooms yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }

    return Column(
      children: [
        // Classroom selector
        if (widget.classroomIds.length > 1)
          Padding(
            padding: const EdgeInsets.all(16),
            child: CleanCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: DropdownButton<String>(
                  value: _selectedClassroomId,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: widget.classroomIds.map<DropdownMenuItem<String>>((classroomId) {
                    return DropdownMenuItem<String>(
                      value: classroomId,
                      child: Text(_classroomNames[classroomId] ?? 'Classroom'),
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
                  padding: EdgeInsets.only(
                    left: 16, 
                    right: 16, 
                    top: widget.classroomIds.length > 1 ? 0 : 16,
                    bottom: 16,
                  ),
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

