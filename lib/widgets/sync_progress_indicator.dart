import 'package:flutter/material.dart';
import '../core/design/app_design_system.dart';
import '../core/constants/app_text_styles.dart';

/// Sync progress indicator for offline data synchronization
class SyncProgressIndicator extends StatelessWidget {
  final int itemsSynced;
  final int totalItems;
  final String? statusText;
  final bool isComplete;

  const SyncProgressIndicator({
    super.key,
    required this.itemsSynced,
    required this.totalItems,
    this.statusText,
    this.isComplete = false,
  });

  double get progress => totalItems > 0 ? itemsSynced / totalItems : 0.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isComplete
            ? AppDesignSystem.success.withValues(alpha: 0.1)
            : AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isComplete
              ? AppDesignSystem.success
              : AppDesignSystem.primaryIndigo,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isComplete ? Icons.check_circle : Icons.sync,
                color: isComplete
                    ? AppDesignSystem.success
                    : AppDesignSystem.primaryIndigo,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  statusText ??
                      (isComplete
                          ? 'Sync Complete!'
                          : 'Syncing offline data...'),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isComplete
                        ? AppDesignSystem.success
                        : AppDesignSystem.primaryIndigo,
                  ),
                ),
              ),
            ],
          ),
          if (!isComplete) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppDesignSystem.backgroundGrey,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppDesignSystem.primaryIndigo,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$itemsSynced of $totalItems items synced',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppDesignSystem.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact sync indicator for app bar or status bar
class CompactSyncIndicator extends StatelessWidget {
  final bool isSyncing;
  final int? pendingCount;

  const CompactSyncIndicator({
    super.key,
    required this.isSyncing,
    this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    if (!isSyncing && (pendingCount == null || pendingCount == 0)) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSyncing
            ? AppDesignSystem.primaryIndigo.withValues(alpha: 0.1)
            : AppDesignSystem.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSyncing)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppDesignSystem.primaryIndigo,
                ),
              ),
            )
          else
            Icon(
              Icons.cloud_upload_outlined,
              size: 14,
              color: AppDesignSystem.warning,
            ),
          const SizedBox(width: 6),
          Text(
            isSyncing
                ? 'Syncing...'
                : '$pendingCount pending',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.bold,
              color: isSyncing
                  ? AppDesignSystem.primaryIndigo
                  : AppDesignSystem.warning,
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner for offline sync status
class SyncBanner extends StatelessWidget {
  final bool isSyncing;
  final int? pendingCount;
  final VoidCallback? onTap;

  const SyncBanner({
    super.key,
    required this.isSyncing,
    this.pendingCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!isSyncing && (pendingCount == null || pendingCount == 0)) {
      return const SizedBox.shrink();
    }

    return Material(
      color: isSyncing
          ? AppDesignSystem.primaryIndigo
          : AppDesignSystem.warning,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (isSyncing)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                const Icon(
                  Icons.cloud_upload_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isSyncing
                      ? 'Syncing offline progress...'
                      : '$pendingCount items waiting to sync',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
