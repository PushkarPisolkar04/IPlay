import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import 'avatar_widget.dart';

/// Top bar with avatar only (like reference design)
class TopBarWithAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String initials;
  final bool showOnlineBadge;
  final VoidCallback? onAvatarTap;
  
  const TopBarWithAvatar({
    Key? key,
    this.avatarUrl,
    required this.initials,
    this.showOnlineBadge = false,
    this.onAvatarTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16, right: 16, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AvatarWidget(
            imageUrl: avatarUrl,
            initials: initials,
            size: 40,
            showOnlineBadge: showOnlineBadge,
            backgroundColor: AppColors.secondary,
            onTap: onAvatarTap,
          ),
        ],
      ),
    );
  }
}

