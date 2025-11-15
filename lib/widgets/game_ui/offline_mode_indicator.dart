import 'package:flutter/material.dart';

/// Widget for displaying offline mode indicator
class OfflineModeIndicator extends StatelessWidget {
  final bool isOffline;
  final VoidCallback? onTap;

  const OfflineModeIndicator({
    super.key,
    required this.isOffline,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange[300]!, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: 16,
              color: Colors.orange[800],
            ),
            const SizedBox(width: 6),
            Text(
              'Offline Mode',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.orange[900],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner for displaying offline mode at the top of screens
class OfflineModeBanner extends StatelessWidget {
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const OfflineModeBanner({
    super.key,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange[100],
        border: Border(
          bottom: BorderSide(
            color: Colors.orange[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off,
            color: Colors.orange[800],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Playing in Offline Mode',
                  style: TextStyle(
                    color: Colors.orange[900],
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Using cached content',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  color: Colors.orange[900],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          if (onDismiss != null) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: onDismiss,
              icon: Icon(
                Icons.close,
                color: Colors.orange[800],
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget for displaying cache status
class CacheStatusWidget extends StatelessWidget {
  final Map<String, bool> cacheStatus;
  final VoidCallback? onClearCache;

  const CacheStatusWidget({
    super.key,
    required this.cacheStatus,
    this.onClearCache,
  });

  @override
  Widget build(BuildContext context) {
    final cachedCount = cacheStatus.values.where((cached) => cached).length;
    final totalCount = cacheStatus.length;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Offline Cache Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onClearCache != null && cachedCount > 0)
                  TextButton.icon(
                    onPressed: onClearCache,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Clear'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$cachedCount of $totalCount games cached for offline play',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ...cacheStatus.entries.map((entry) {
              final gameName = _formatGameName(entry.key);
              final isCached = entry.value;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      isCached ? Icons.check_circle : Icons.cancel,
                      size: 20,
                      color: isCached ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        gameName,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      isCached ? 'Cached' : 'Not cached',
                      style: TextStyle(
                        fontSize: 12,
                        color: isCached ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  String _formatGameName(String gameId) {
    return gameId
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

/// Compact cache indicator for game cards
class GameCacheIndicator extends StatelessWidget {
  final bool isCached;

  const GameCacheIndicator({
    super.key,
    required this.isCached,
  });

  @override
  Widget build(BuildContext context) {
    if (!isCached) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.offline_pin,
            size: 14,
            color: Colors.green[700],
          ),
          const SizedBox(width: 4),
          Text(
            'Offline',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }
}
