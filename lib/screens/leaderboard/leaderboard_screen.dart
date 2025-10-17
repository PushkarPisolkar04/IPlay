import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/clean_card.dart';
import '../../widgets/avatar_widget.dart';

/// Modern Leaderboard Screen for Students
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _currentUserId;
  String? _userClassroomId;
  String? _userSchoolId;
  String? _userState;
  
  List<Map<String, dynamic>> _classStudents = [];
  List<Map<String, dynamic>> _schoolStudents = [];
  List<Map<String, dynamic>> _stateStudents = [];
  List<Map<String, dynamic>> _countryStudents = [];
  
  List<String> _availableTabs = [];
  Map<String, int> _tabIndexMap = {};

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final classroomIds = userData['classroomIds'] as List?;
        
        _userClassroomId = (classroomIds != null && classroomIds.isNotEmpty) 
            ? classroomIds.first 
            : null;
        
        // Get schoolId from classroom or user
        if (_userClassroomId != null) {
          final classroomDoc = await FirebaseFirestore.instance
              .collection('classrooms')
              .doc(_userClassroomId)
              .get();
          
          if (classroomDoc.exists) {
            _userSchoolId = classroomDoc.data()?['schoolId'];
          }
        }
        
        _userState = userData['state'];
        
        // Build available tabs based on user's enrollment
        _availableTabs = [];
        _tabIndexMap = {};
        int index = 0;
        
        if (_userClassroomId != null) {
          _availableTabs.add('Class');
          _tabIndexMap['Class'] = index++;
        }
        if (_userSchoolId != null) {
          _availableTabs.add('School');
          _tabIndexMap['School'] = index++;
        }
        _availableTabs.add('State');
        _tabIndexMap['State'] = index++;
        _availableTabs.add('Country');
        _tabIndexMap['Country'] = index++;
        
        // Initialize tab controller
        _tabController = TabController(length: _availableTabs.length, vsync: this);
        _tabController.addListener(() {
          if (_tabController.indexIsChanging) {
            _loadDataForTab(_tabController.index);
          }
        });
        
        // Load initial data
        _loadDataForTab(0);
      }
    } catch (e) {
      print('Error loading user info: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadDataForTab(int index) async {
    setState(() => _isLoading = true);
    
    final tabName = _availableTabs[index];
    
    switch (tabName) {
      case 'Class':
        await _loadClassLeaderboard();
        break;
      case 'School':
        await _loadSchoolLeaderboard();
        break;
      case 'State':
        await _loadStateLeaderboard();
        break;
      case 'Country':
        await _loadCountryLeaderboard();
        break;
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadClassLeaderboard() async {
    if (_userClassroomId == null) return;
    
    try {
      final classroomDoc = await FirebaseFirestore.instance
          .collection('classrooms')
          .doc(_userClassroomId)
          .get();
      
      if (classroomDoc.exists) {
        final studentIds = List<String>.from(classroomDoc.data()?['studentIds'] ?? []);
        
        _classStudents = [];
        for (String studentId in studentIds) {
          final studentDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(studentId)
              .get();
          
          if (studentDoc.exists) {
            final data = studentDoc.data()!;
            _classStudents.add({
              'id': studentId,
              'displayName': data['displayName'] ?? 'Unknown',
              'avatarUrl': data['avatarUrl'],
              'totalXP': data['totalXP'] ?? 0,
              'level': data['level'] ?? 1,
            });
          }
        }
        
        _classStudents.sort((a, b) => (b['totalXP'] as int).compareTo(a['totalXP'] as int));
      }
    } catch (e) {
      print('Error loading class leaderboard: $e');
    }
  }

  Future<void> _loadSchoolLeaderboard() async {
    if (_userSchoolId == null) return;
    
    try {
      final classroomsSnapshot = await FirebaseFirestore.instance
          .collection('classrooms')
          .where('schoolId', isEqualTo: _userSchoolId)
          .get();
      
      Set<String> studentIds = {};
      for (var classroomDoc in classroomsSnapshot.docs) {
        final studentList = List<String>.from(classroomDoc.data()['studentIds'] ?? []);
        studentIds.addAll(studentList);
      }
      
      _schoolStudents = [];
      for (String studentId in studentIds) {
        final studentDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(studentId)
            .get();
        
        if (studentDoc.exists) {
          final data = studentDoc.data()!;
          _schoolStudents.add({
            'id': studentId,
            'displayName': data['displayName'] ?? 'Unknown',
            'avatarUrl': data['avatarUrl'],
            'totalXP': data['totalXP'] ?? 0,
            'level': data['level'] ?? 1,
          });
        }
      }
      
      _schoolStudents.sort((a, b) => (b['totalXP'] as int).compareTo(a['totalXP'] as int));
    } catch (e) {
      print('Error loading school leaderboard: $e');
    }
  }

  Future<void> _loadStateLeaderboard() async {
    if (_userState == null) return;
    
    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('state', isEqualTo: _userState)
          .orderBy('totalXP', descending: true)
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
        };
      }).toList();
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
        };
      }).toList();
    } catch (e) {
      print('Error loading country leaderboard: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_availableTabs.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF34D399)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events, color: Colors.white, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'Leaderboard',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Compete with others and climb the ranks!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            
            // Tabs
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF10B981),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF10B981),
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                tabs: _availableTabs.map((tab) => Tab(text: tab)).toList(),
              ),
            ),
            
            // Tab content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: _availableTabs.map((tab) {
                        switch (tab) {
                          case 'Class':
                            return _buildLeaderboardTab(_classStudents);
                          case 'School':
                            return _buildLeaderboardTab(_schoolStudents);
                          case 'State':
                            return _buildLeaderboardTab(_stateStudents);
                          case 'Country':
                            return _buildLeaderboardTab(_countryStudents);
                          default:
                            return const SizedBox();
                        }
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardTab(List<Map<String, dynamic>> students) {
    if (students.isEmpty) {
      return const Center(
        child: Text('No students yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      itemBuilder: (context, index) {
        return _buildLeaderboardItem(students[index], index + 1);
      },
    );
  }

  Widget _buildLeaderboardItem(Map<String, dynamic> student, int rank) {
    final bool isCurrentUser = student['id'] == _currentUserId;
    
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: isCurrentUser
            ? const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF34D399)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isCurrentUser ? null : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isCurrentUser 
                ? const Color(0xFF10B981).withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Rank
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: rankColor ?? (isCurrentUser ? Colors.white.withOpacity(0.3) : Colors.grey[100]),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: medalIcon != null
                          ? Icon(medalIcon, color: Colors.white, size: 20)
                          : Text(
                              '$rank',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isCurrentUser ? Colors.white : Colors.black87,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Avatar
                  AvatarWidget(
                    imageUrl: student['avatarUrl'],
                    initials: _getInitials(student['displayName']),
                    size: 48,
                  ),
                  const SizedBox(width: 12),
                  // Name and Level
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                student['displayName'] ?? 'Unknown',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isCurrentUser ? Colors.white : Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCurrentUser) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'YOU',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Level ${student['level']} • ${student['totalXP']} XP',
                          style: TextStyle(
                            fontSize: 13,
                            color: isCurrentUser ? Colors.white.withOpacity(0.9) : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'U';
    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}

