import 'package:flutter/material.dart';
import '../core/design/app_design_system.dart';
import '../core/services/offline_sync_service.dart';
import '../core/services/offline_progress_manager.dart';

/// Widget to display sync status and trigger manual sync
class SyncStatusWidget extends StatefulWidget {
  const SyncStatusWidget({super.key});

  @override
  State<SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget> {
  final OfflineSyncService _syncService = OfflineSyncService.instance;
  final OfflineProgressManager _offlineManager = OfflineProgressManager.instance;
  
  bool _isSyncing = false;
  int _pendingCount = 0;
  int _unsavedXP = 0;

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
  }

  Future<void> _loadSyncStatus() async {
    try {
      final pendingCount = await _offlineManager.getPendingCount();
      final unsavedXP = await _offlineManager.getTotalUnsavedXP();
      
      if (mounted) {
        setState(() {
          _pendingCount = pendingCount;
          _unsavedXP = unsavedXP;
        });
      }
    } catch (e) {
      // print('Error loading sync status: $e');
    }
  }

  Future<void> _triggerSync() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      final result = await _syncService.syncOfflineProgress();
      
      if (mounted) {
        // Reload sync status
        await _loadSyncStatus();
        
        // Show result message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  result.success ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.success
                        ? 'Synced ${result.syncedCount} items • ${result.totalXP} XP'
                        : result.message,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: result.success ? AppDesignSystem.success : AppDesignSystem.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // print('Error during sync: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${e.toString()}'),
            backgroundColor: AppDesignSystem.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pendingCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppDesignSystem.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppDesignSystem.info.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sync,
                color: AppDesignSystem.info,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sync Pending',
                  style: TextStyle(
                    color: AppDesignSystem.info,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              if (_isSyncing)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$_pendingCount items waiting to sync • $_unsavedXP XP',
            style: TextStyle(
              color: AppDesignSystem.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSyncing ? null : _triggerSync,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppDesignSystem.info,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                _isSyncing ? 'Syncing...' : 'Sync Now',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
