import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';

/// Avatar widget with optional online badge
class AvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String initials;
  final double size;
  final bool showOnlineBadge;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  
  const AvatarWidget({
    Key? key,
    this.imageUrl,
    required this.initials,
    this.size = 40.0,
    this.showOnlineBadge = false,
    this.backgroundColor,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor ?? AppColors.backgroundGrey,
          border: Border.all(color: AppColors.border, width: 2),
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
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 2),
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
      // Network image (URL)
      return Image.network(
        imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildInitials(),
      );
    }
  }
  
  Widget _buildInitials() {
    return Text(
      initials.toUpperCase(),
      style: AppTextStyles.h3.copyWith(
        color: AppColors.textPrimary,
        fontSize: size * 0.4,
      ),
    );
  }
}

