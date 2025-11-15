import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/content_service.dart';
import '../../core/models/realm_model.dart';
import '../../widgets/loading_skeleton.dart';
import 'realm_detail_screen.dart';

/// Learn Screen - All realms with modern UI and gradients
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final ContentService _contentService = ContentService();
  List<RealmModel> _realms = [];
  Map<String, dynamic> _userProgress = {};
  bool _isLoading = true;
  
  // Cached calculations to avoid recomputing in build
  int _cachedTotalXP = 0;
  int _cachedCompletedRealms = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load realms from ContentService (async)
      final realms = await _contentService.getAllRealms();
      
      setState(() {
        _realms = realms;
      });

      // Load user progress from Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          if (mounted) {
            setState(() {
              _userProgress = userDoc.data()?['progressSummary'] ?? {};
              _updateCachedStats();
            });
          }
        }
      }
    } catch (e) {
      // print('Error loading realms: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _updateCachedStats() {
    _cachedTotalXP = 0;
    _cachedCompletedRealms = 0;
    
    _userProgress.forEach((key, value) {
      if (value is Map) {
        if (value.containsKey('xpEarned')) {
          _cachedTotalXP += (value['xpEarned'] as num).toInt();
        }
        if (value['completed'] == true) {
          _cachedCompletedRealms++;
        }
      }
    });
  }

  Future<void> _refreshData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
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
    return _cachedTotalXP;
  }

  int _getCompletedRealms() {
    return _cachedCompletedRealms;
  }

  Widget _buildStatChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
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
      backgroundColor: AppDesignSystem.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Gradient App Bar
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6366F1), // Indigo
                    const Color(0xFF8B5CF6), // Purple
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  children: [
                    // Title - centered
                    Center(
                      child: Text(
                        'Learn IPR',
                        style: AppTextStyles.h2.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Stats chips - centered
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatChip(Icons.emoji_events, '$completedRealms/${_realms.length} Realms'),
                        const SizedBox(width: 12),
                        _buildStatChip(Icons.stars, '$totalXP XP'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshData,
                color: const Color(0xFF6366F1),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isLoading)
                        const GridSkeleton(itemCount: 6, crossAxisCount: 2)
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            
                            // Realms section
                            Text(
                              'All Realms',
                              style: AppTextStyles.sectionHeader.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            
                            // Realm cards
                            ..._realms.map((realm) {
                              final progress = _getRealmProgress(realm.id);
                              final isStarted = progress > 0;
                              final isCompleted = progress >= 1.0;
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(realm.color),
                                      Color(realm.color).withOpacity(0.8),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(realm.color).withOpacity(0.25),
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
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => RealmDetailScreen(realm: realm.toMap()),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          children: [
                                            // Larger icon
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.25),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Image.asset(
                                                realm.iconPath,
                                                width: 48,
                                                height: 48,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return const Icon(
                                                    Icons.school,
                                                    size: 48,
                                                    color: Colors.white,
                                                  );
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          realm.name,
                                                          style: const TextStyle(
                                                            fontSize: 17,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.white,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      if (isCompleted)
                                                        const Icon(
                                                          Icons.check_circle,
                                                          color: Colors.white,
                                                          size: 20,
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${realm.totalLevels} Levels',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.white.withOpacity(0.9),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  // Progress bar
                                                  if (isStarted) ...[
                                                    ClipRRect(
                                                      borderRadius: BorderRadius.circular(4),
                                                      child: LinearProgressIndicator(
                                                        value: progress,
                                                        backgroundColor: Colors.white.withOpacity(0.3),
                                                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                                        minHeight: 6,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '${(progress * 100).toInt()}% Complete',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ] else ...[
                                                    Text(
                                                      'Start your journey',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.white.withOpacity(0.85),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.arrow_forward_ios,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
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
