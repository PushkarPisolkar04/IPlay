import 'package:flutter/material.dart';
import '../../core/design/app_design_system.dart';
import '../../models/badge_model.dart';
import '../../core/services/badge_service.dart';
import '../../widgets/loading_skeleton.dart';

/// Search screen for finding realms, levels, games, and badges
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final BadgeService _badgeService = BadgeService();
  
  List<SearchResult> _results = [];
  bool _isSearching = false;
  String _query = '';

  // Static data for realms, levels, and games
  final List<Map<String, dynamic>> _realms = [
    {
      'id': 'copyright',
      'name': 'Copyright Realm',
      'icon': '©️',
      'description': 'Learn about copyright protection for creative works',
      'levels': 8,
    },
    {
      'id': 'trademark',
      'name': 'Trademark Realm',
      'icon': '™️',
      'description': 'Master trademark law and brand protection',
      'levels': 8,
    },
    {
      'id': 'patent',
      'name': 'Patent Realm',
      'icon': '💡',
      'description': 'Discover patent protection for inventions',
      'levels': 9,
    },
    {
      'id': 'industrial_design',
      'name': 'Industrial Design Realm',
      'icon': '🎨',
      'description': 'Explore design protection and aesthetics',
      'levels': 7,
    },
    {
      'id': 'gi',
      'name': 'Geographical Indication Realm',
      'icon': '🌍',
      'description': 'Learn about GI protection for regional products',
      'levels': 6,
    },
    {
      'id': 'trade_secrets',
      'name': 'Trade Secrets Realm',
      'icon': '🔒',
      'description': 'Understand confidential business information',
      'levels': 6,
    },
  ];

  final List<Map<String, dynamic>> _games = [
    {
      'id': 'quiz_master',
      'name': 'Quiz Master',
      'icon': '❓',
      'description': 'Test your IPR knowledge with quick quizzes',
    },
    {
      'id': 'spot_the_original',
      'name': 'Spot the Original',
      'icon': '🔍',
      'description': 'Identify original works from copies',
    },
    {
      'id': 'gi_mapper',
      'name': 'GI Mapper',
      'icon': '🗺️',
      'description': 'Match GI products to their regions',
    },
    {
      'id': 'ip_defender',
      'name': 'IP Defender',
      'icon': '🛡️',
      'description': 'Protect your IP assets from infringers',
    },
    {
      'id': 'patent_detective',
      'name': 'Patent Detective',
      'icon': '🕵️',
      'description': 'Investigate patent cases and make decisions',
    },
    {
      'id': 'innovation_lab',
      'name': 'Innovation Lab',
      'icon': '🔬',
      'description': 'Create inventions and learn about protection',
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query != _query) {
      setState(() {
        _query = query;
      });
      _performSearch(query);
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final results = <SearchResult>[];
    final lowerQuery = query.toLowerCase();

    // Search realms
    for (final realm in _realms) {
      if (realm['name'].toString().toLowerCase().contains(lowerQuery) ||
          realm['description'].toString().toLowerCase().contains(lowerQuery)) {
        results.add(SearchResult(
          type: SearchResultType.realm,
          id: realm['id'],
          title: realm['name'],
          subtitle: realm['description'],
          icon: realm['icon'],
          data: realm,
        ));
      }
    }

    // Search games
    for (final game in _games) {
      if (game['name'].toString().toLowerCase().contains(lowerQuery) ||
          game['description'].toString().toLowerCase().contains(lowerQuery)) {
        results.add(SearchResult(
          type: SearchResultType.game,
          id: game['id'],
          title: game['name'],
          subtitle: game['description'],
          icon: game['icon'],
          data: game,
        ));
      }
    }

    // Search badges
    try {
      final badges = await _badgeService.getAllBadges();
      for (final badge in badges) {
        if (badge.name.toLowerCase().contains(lowerQuery) ||
            badge.description.toLowerCase().contains(lowerQuery)) {
          results.add(SearchResult(
            type: SearchResultType.badge,
            id: badge.id,
            title: badge.name,
            subtitle: badge.description,
            icon: badge.icon,
            data: badge,
          ));
        }
      }
    } catch (e) {
      // print('Error searching badges: $e');
    }

    setState(() {
      _results = results;
      _isSearching = false;
    });
  }

  void _onResultTap(SearchResult result) {
    // Navigate to appropriate screen based on result type
    switch (result.type) {
      case SearchResultType.realm:
        Navigator.pushNamed(
          context,
          '/realm-detail',
          arguments: result.id,
        );
        break;
      case SearchResultType.level:
        Navigator.pushNamed(
          context,
          '/level-detail',
          arguments: result.id,
        );
        break;
      case SearchResultType.game:
        Navigator.pushNamed(
          context,
          '/game',
          arguments: result.id,
        );
        break;
      case SearchResultType.badge:
        // Show badge detail dialog
        _showBadgeDetail(result.data as BadgeModel);
        break;
    }
  }

  void _showBadgeDetail(BadgeModel badge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(badge.icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                badge.name,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(badge.description),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: AppDesignSystem.primaryIndigo),
                  const SizedBox(width: 8),
                  Text(
                    '+${badge.xpBonus} XP',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppDesignSystem.primaryIndigo,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _highlightMatch(String text, String query) {
    // Simple highlighting - in production, use a package like flutter_highlight
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search realms, games, badges...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey.shade400),
          ),
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return const ListSkeleton(itemCount: 5);
    }

    if (_query.isEmpty) {
      return _buildEmptyState();
    }

    if (_results.isEmpty) {
      return _buildNoResults();
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        return _buildResultTile(_results[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Search for anything',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Realms, levels, games, or badges',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultTile(SearchResult result) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _getTypeColor(result.type).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            result.icon,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
      title: Text(
        result.title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        result.subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Chip(
        label: Text(
          _getTypeLabel(result.type),
          style: const TextStyle(fontSize: 12),
        ),
        backgroundColor: _getTypeColor(result.type).withValues(alpha: 0.1),
        labelStyle: TextStyle(
          color: _getTypeColor(result.type),
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () => _onResultTap(result),
    );
  }

  Color _getTypeColor(SearchResultType type) {
    switch (type) {
      case SearchResultType.realm:
        return AppDesignSystem.primaryIndigo;
      case SearchResultType.level:
        return AppDesignSystem.primaryPink;
      case SearchResultType.game:
        return AppDesignSystem.primaryGreen;
      case SearchResultType.badge:
        return AppDesignSystem.primaryAmber;
    }
  }

  String _getTypeLabel(SearchResultType type) {
    switch (type) {
      case SearchResultType.realm:
        return 'Realm';
      case SearchResultType.level:
        return 'Level';
      case SearchResultType.game:
        return 'Game';
      case SearchResultType.badge:
        return 'Badge';
    }
  }
}

enum SearchResultType {
  realm,
  level,
  game,
  badge,
}

class SearchResult {
  final SearchResultType type;
  final String id;
  final String title;
  final String subtitle;
  final String icon;
  final dynamic data;

  SearchResult({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.data,
  });
}
