import 'package:flutter/material.dart';
import '../core/design/app_design_system.dart';
import '../core/constants/app_text_styles.dart';

/// Download progress dialog for offline content
class DownloadProgressDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double progress; // 0.0 to 1.0
  final int? currentItem;
  final int? totalItems;
  final VoidCallback? onCancel;

  const DownloadProgressDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.progress,
    this.currentItem,
    this.totalItems,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.download_outlined,
                color: AppDesignSystem.primaryIndigo,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              title,
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),

            // Subtitle
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppDesignSystem.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 24),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppDesignSystem.backgroundGrey,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppDesignSystem.primaryIndigo,
                ),
                minHeight: 12,
              ),
            ),

            const SizedBox(height: 12),

            // Progress text
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (currentItem != null && totalItems != null)
                  Text(
                    'Item $currentItem of $totalItems',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppDesignSystem.textSecondary,
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppDesignSystem.primaryIndigo,
                  ),
                ),
              ],
            ),

            // Cancel button
            if (onCancel != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onCancel,
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppDesignSystem.error,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Show download progress dialog
Future<void> showDownloadProgress({
  required BuildContext context,
  required String title,
  String? subtitle,
  required Stream<double> progressStream,
  Stream<int>? currentItemStream,
  int? totalItems,
  VoidCallback? onCancel,
}) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StreamBuilder<double>(
        stream: progressStream,
        initialData: 0.0,
        builder: (context, progressSnapshot) {
          return StreamBuilder<int>(
            stream: currentItemStream,
            builder: (context, itemSnapshot) {
              return DownloadProgressDialog(
                title: title,
                subtitle: subtitle,
                progress: progressSnapshot.data ?? 0.0,
                currentItem: itemSnapshot.data,
                totalItems: totalItems,
                onCancel: onCancel,
              );
            },
          );
        },
      );
    },
  );
}

/// Compact download indicator
class CompactDownloadIndicator extends StatelessWidget {
  final double progress;
  final String? label;
  final VoidCallback? onCancel;

  const CompactDownloadIndicator({
    super.key,
    required this.progress,
    this.label,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              backgroundColor: AppDesignSystem.backgroundGrey,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppDesignSystem.primaryIndigo,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label ?? 'Downloading...',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: AppTextStyles.caption.copyWith(
                    color: AppDesignSystem.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (onCancel != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onCancel,
              iconSize: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
