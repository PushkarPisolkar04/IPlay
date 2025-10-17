import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/content_service.dart';
import '../../core/models/realm_model.dart';
import '../../widgets/clean_card.dart';
import '../../widgets/progress_bar.dart';
import '../../widgets/primary_button.dart';
import 'realm_detail_screen.dart';

/// Learn Screen - All realms with modern UI and gradients
class LearnScreen extends StatefulWidget {
  const LearnScreen({Key? key}) : super(key: key);

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ContentService _contentService = ContentService();
  List<RealmModel> _realms = [];
  Map<String, dynamic> _userProgress = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Load realms from ContentService
      setState(() {
        _realms = _contentService.getAllRealms();
      });

      // Load user progress from Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          setState(() {
            _userProgress = userDoc.data()?['progressSummary'] ?? {};
          });
        }
      }
    } catch (e) {
      print('Error loading realms: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await _loadData();
  }

  double _getRealmProgress(String realmId) {
    if (_userProgress.containsKey(realmId)) {
      final realmProgress = _userProgress[realmId];
      if (realmProgress != null && realmProgress is Map) {
        final completed = realmProgress['levelsCompleted'] ?? 0;
        final total = realmProgress['totalLevels'] ?? 1;
        return completed / total;
      }
    }
    return 0.0;
  }

  int _getTotalXP() {
    int totalXP = 0;
    _userProgress.forEach((key, value) {
      if (value is Map && value.containsKey('xpEarned')) {
        totalXP += (value['xpEarned'] as num).toInt();
      }
    });
    return totalXP;
  }

  int _getCompletedRealms() {
    int count = 0;
    _userProgress.forEach((key, value) {
      if (value is Map && value['completed'] == true) {
        count++;
      }
    });
    return count;
  }

  Widget _buildStatChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalXP = _getTotalXP();
    final completedRealms = _getCompletedRealms();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFF3B82F6),
        child: CustomScrollView(
          slivers: [
            // Modern gradient app bar
            SliverAppBar(
              expandedHeight: 110,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF3B82F6),
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Learn IPR',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 50),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatChip(Icons.stars, '$totalXP XP'),
                            _buildStatChip(Icons.check_circle, '$completedRealms/${_realms.length} Done'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Content
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenHorizontal, AppSpacing.md, AppSpacing.screenHorizontal, AppSpacing.screenHorizontal),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_isLoading)
                    const Center(
                      heightFactor: 10,
                      child: CircularProgressIndicator(),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search bar with modern styling
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Search realms...',
                              prefixIcon: const Icon(Icons.search, color: Color(0xFF3B82F6)),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, color: Colors.grey),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: AppSpacing.lg),
                        
                        // Realms grid
                        Text(
                          'All Realms',
                          style: AppTextStyles.sectionHeader.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        
                        // Realm cards
                        ..._getFilteredRealms().map((realm) {
                          final progress = _getRealmProgress(realm.id);
                          final isStarted = progress > 0;
                          final isCompleted = progress >= 1.0;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(realm.color),
                                  Color(realm.color).withOpacity(0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(realm.color).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RealmDetailScreen(realm: realm.toMap()),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.3),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                realm.iconEmoji,
                                                style: const TextStyle(fontSize: 32),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    realm.name,
                                                    style: const TextStyle(
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${realm.totalLevels} Levels',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.white.withOpacity(0.9),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (isCompleted)
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.3),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.check_circle,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          realm.description,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white.withOpacity(0.95),
                                            height: 1.4,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 16),
                                        // Progress bar
                                        if (isStarted && !isCompleted) ...[
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: LinearProgressIndicator(
                                              value: progress,
                                              backgroundColor: Colors.white.withOpacity(0.3),
                                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                              minHeight: 8,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${(progress * 100).toInt()}% Complete',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                        // Start/Continue button
                                        const SizedBox(height: 12),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                isCompleted 
                                                    ? 'Review' 
                                                    : isStarted 
                                                        ? 'Continue' 
                                                        : 'Start Learning',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(Icons.arrow_forward, size: 20, color: Colors.white),
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
                        }).toList(),
                      ],
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<RealmModel> _getFilteredRealms() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      return _realms;
    }
    return _realms.where((realm) {
      return realm.name.toLowerCase().contains(query) ||
             realm.description.toLowerCase().contains(query);
    }).toList();
  }
}

