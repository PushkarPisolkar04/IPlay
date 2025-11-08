import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../services/bookmark_service.dart';
import '../../widgets/clean_card.dart';
import '../learn/level_detail_screen.dart';

/// Bookmarks Screen - Display all bookmarked levels
class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final BookmarkService _bookmarkService = BookmarkService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(
        title: const Text('Bookmarks'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _bookmarkService.getBookmarksStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppDesignSystem.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading bookmarks',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            );
          }

          final bookmarks = snapshot.data?.docs ?? [];

          if (bookmarks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 80,
                    color: AppDesignSystem.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No bookmarks yet',
                    style: AppTextStyles.h5.copyWith(
                      color: AppDesignSystem.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bookmark levels to access them quickly',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppDesignSystem.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            itemCount: bookmarks.length,
            itemBuilder: (context, index) {
              final bookmark = bookmarks[index].data() as Map<String, dynamic>;
              final levelId = bookmark['levelId'] as String;
              final levelName = bookmark['levelName'] as String;
              final realmName = bookmark['realmName'] as String;
              final bookmarkedAt = bookmark['bookmarkedAt'] as Timestamp;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: CleanCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LevelDetailScreen(
                          levelId: levelId,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.bookmark,
                            color: AppDesignSystem.primaryIndigo,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                levelName,
                                style: AppTextStyles.cardTitle,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                realmName,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppDesignSystem.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(bookmarkedAt.toDate()),
                                style: AppTextStyles.caption.copyWith(
                                  color: AppDesignSystem.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            await _bookmarkService.removeBookmark(levelId);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Bookmark removed'),
                                backgroundColor: AppDesignSystem.success,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.bookmark_remove),
                          color: AppDesignSystem.error,
                          tooltip: 'Remove bookmark',
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
  }
}
