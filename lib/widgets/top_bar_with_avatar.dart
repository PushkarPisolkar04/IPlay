import 'package:flutter/material.dart';
import '../core/design/app_design_system.dart';
import 'avatar_widget.dart';
import 'notification_bell_icon.dart';

/// Top bar with avatar and notification bell
class TopBarWithAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String initials;
  final bool showOnlineBadge;
  final VoidCallback? onAvatarTap;
  final bool showNotificationBell;
  
  const TopBarWithAvatar({
    super.key,
    this.avatarUrl,
    required this.initials,
    this.showOnlineBadge = false,
    this.onAvatarTap,
    this.showNotificationBell = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16, right: 16, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (showNotificationBell) ...[
            const NotificationBellIcon(),
            const SizedBox(width: 8),
          ],
          AvatarWidget(
            imageUrl: avatarUrl,
            initials: initials,
            size: 40,
            showOnlineBadge: showOnlineBadge,
            backgroundColor: AppDesignSystem.primaryPink,
            onTap: onAvatarTap,
          ),
        ],
      ),
    );
  }
}

