import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/design/app_design_system.dart';
import '../core/utils/cache_manager.dart';

/// LeaderboardTile - Displays user rank with medal icons for top 3
/// Highlights current user with different background
class LeaderboardTile extends StatelessWidget {
  final int rank;
  final String userName;
  final String? avatarUrl;
  final int xp;
  final bool isCurrentUser;
  final VoidCallback? onTap;

  const LeaderboardTile({
    super.key,
    required this.rank,
    required this.userName,
    this.avatarUrl,
    required this.xp,
    this.isCurrentUser = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDesignSystem.spacingMD,
            vertical: AppDesignSystem.spacingMD,
          ),
          decoration: BoxDecoration(
            color: isCurrentUser
                ? AppDesignSystem.primaryIndigo.withValues(alpha: 0.1)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: AppDesignSystem.backgroundGrey,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Rank or medal
              SizedBox(
                width: 40,
                child: _buildRankIndicator(),
              ),
              const SizedBox(width: AppDesignSystem.spacingMD),
              
              // Avatar with caching
              avatarUrl != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: avatarUrl!,
                        cacheManager: IPlayCacheManager.userDataCache,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => CircleAvatar(
                          radius: 20,
                          backgroundColor: AppDesignSystem.backgroundGrey,
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppDesignSystem.primaryIndigo,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => CircleAvatar(
                          radius: 20,
                          backgroundColor: AppDesignSystem.backgroundGrey,
                          child: Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                            style: AppDesignSystem.h6.copyWith(
                              color: AppDesignSystem.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    )
                  : CircleAvatar(
                      radius: 20,
                      backgroundColor: AppDesignSystem.backgroundGrey,
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                        style: AppDesignSystem.h6.copyWith(
                          color: AppDesignSystem.textSecondary,
                        ),
                      ),
                    ),
              const SizedBox(width: AppDesignSystem.spacingMD),
              
              // User name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: AppDesignSystem.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isCurrentUser
                            ? AppDesignSystem.primaryIndigo
                            : AppDesignSystem.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(height: 2),
                      Text(
                        'You',
                        style: AppDesignSystem.caption.copyWith(
                          color: AppDesignSystem.primaryIndigo,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // XP
              Row(
                children: [
                  Icon(
                    Icons.stars,
                    color: AppDesignSystem.primaryAmber,
                    size: 16,
                  ),
                  const SizedBox(width: AppDesignSystem.spacingXS),
                  Text(
                    _formatXP(xp),
                    style: AppDesignSystem.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppDesignSystem.textPrimary,
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

  Widget _buildRankIndicator() {
    // Top 3 get medals
    if (rank == 1) {
      return const Text(
        '🥇',
        style: TextStyle(fontSize: 28),
        textAlign: TextAlign.center,
      );
    } else if (rank == 2) {
      return const Text(
        '🥈',
        style: TextStyle(fontSize: 28),
        textAlign: TextAlign.center,
      );
    } else if (rank == 3) {
      return const Text(
        '🥉',
        style: TextStyle(fontSize: 28),
        textAlign: TextAlign.center,
      );
    }

    // Others get rank number
    return Text(
      '#$rank',
      style: AppDesignSystem.bodyMedium.copyWith(
        fontWeight: FontWeight.w600,
        color: AppDesignSystem.textSecondary,
      ),
      textAlign: TextAlign.center,
    );
  }

  String _formatXP(int xp) {
    if (xp >= 1000000) {
      return '${(xp / 1000000).toStringAsFixed(1)}M';
    } else if (xp >= 1000) {
      return '${(xp / 1000).toStringAsFixed(1)}K';
    }
    return xp.toString();
  }
}
