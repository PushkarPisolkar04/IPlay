import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/design/app_design_system.dart';
import '../core/constants/app_text_styles.dart';
import '../core/utils/cache_manager.dart';

/// Avatar widget with optional online badge
class AvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String initials;
  final double size;
  final bool showOnlineBadge;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  
  const AvatarWidget({
    super.key,
    this.imageUrl,
    required this.initials,
    this.size = 40.0,
    this.showOnlineBadge = false,
    this.backgroundColor,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor ?? AppDesignSystem.backgroundGrey,
          border: Border.all(color: AppDesignSystem.backgroundGrey, width: 2),
        ),
        child: Stack(
          children: [
            // Avatar image or initials
            Center(
              child: imageUrl != null
                  ? ClipOval(
                      child: _buildAvatarImage(),
                    )
                  : _buildInitials(),
            ),
            // Online badge
            if (showOnlineBadge)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: size * 0.25,
                  height: size * 0.25,
                  decoration: BoxDecoration(
                    color: AppDesignSystem.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppDesignSystem.backgroundLight, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAvatarImage() {
    // Check if it's a local asset (starts with 'assets/') or network URL
    if (imageUrl!.startsWith('assets/')) {
      return Image.asset(
        imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildInitials(),
      );
    } else {
      // Network image (URL) with caching
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        cacheManager: IPlayCacheManager.userDataCache,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: AppDesignSystem.backgroundGrey,
          child: Center(
            child: SizedBox(
              width: size * 0.3,
              height: size * 0.3,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppDesignSystem.primaryIndigo),
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildInitials(),
      );
    }
  }
  
  Widget _buildInitials() {
    return Text(
      initials.toUpperCase(),
      style: AppTextStyles.h3.copyWith(
        color: AppDesignSystem.textPrimary,
        fontSize: size * 0.4,
      ),
    );
  }
}

