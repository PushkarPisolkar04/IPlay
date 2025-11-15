import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import '../core/design/app_design_system.dart';
import '../core/services/offline_progress_manager.dart';
import '../core/services/offline_sync_service.dart';

/// An overlay banner that displays connectivity and sync status without affecting layout.
/// Uses Stack positioning to overlay on top of content without causing layout shifts.
class OverlayBanner extends StatefulWidget {
  final Widget child;

  const OverlayBanner({
    super.key,
    required this.child,
  });

  @override
  State<OverlayBanner> createState() => _OverlayBannerState();
}

class _OverlayBannerState extends State<OverlayBanner> with SingleTickerProviderStateMixin {
  bool _isOffline = false;
  bool _isSyncing = false;
  int _pendingCount = 0;
  int _unsavedXP = 0;
  Timer? _syncTimeoutTimer;
  Timer? _autoHideTimer;
  Timer? _syncCheckTimer;
  
  final OfflineProgressManager _offlineManager = OfflineProgressManager.instance;
  final OfflineSyncService _syncService = OfflineSyncService.instance;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _checkConnectivity();
    _loadSyncStatus();
    
    // Listen to connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      final wasOffline = _isOffline;
      final isNowOffline = result.contains(ConnectivityResult.none);
      
      setState(() {
        _isOffline = isNowOffline;
      });
      
      // If we just came back online and have pending items, start syncing
      if (wasOffline && !isNowOffline && _pendingCount > 0) {
        _startSyncWithTimeout();
      }
      
      _loadSyncStatus();
      _updateBannerVisibility();
    });
    
    // Periodically check sync status (every 5 seconds)
    _syncCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _loadSyncStatus();
        
        // Update syncing state from service
        final isSyncServiceActive = _syncService.isSyncing;
        if (_isSyncing != isSyncServiceActive) {
          setState(() {
            _isSyncing = isSyncServiceActive;
          });
          _updateBannerVisibility();
        }
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimeoutTimer?.cancel();
    _autoHideTimer?.cancel();
    _syncCheckTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = result.contains(ConnectivityResult.none);
    });
    _updateBannerVisibility();
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
        _updateBannerVisibility();
      }
    } catch (e) {
      debugPrint('Error loading sync status: $e');
    }
  }

  void _startSyncWithTimeout() async {
    setState(() {
      _isSyncing = true;
    });
    
    // Cancel any existing timers
    _syncTimeoutTimer?.cancel();
    _syncCheckTimer?.cancel();
    
    // Set 10-second timeout for sync operations
    _syncTimeoutTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _isSyncing) {
        debugPrint('Sync timeout reached after 10 seconds - auto-hiding banner');
        setState(() {
          _isSyncing = false;
        });
        _autoHideBanner();
      }
    });
    
    // Start the actual sync operation
    try {
      final result = await _syncService.syncOfflineProgress();
      
      if (mounted) {
        // Cancel timeout since sync completed
        _syncTimeoutTimer?.cancel();
        
        setState(() {
          _isSyncing = false;
        });
        
        // Reload sync status to update pending count
        await _loadSyncStatus();
        
        // Log sync result
        if (result.success) {
          debugPrint('Sync completed: ${result.syncedCount} items, ${result.totalXP} XP');
        } else {
          debugPrint('Sync failed: ${result.message}');
        }
        
        // Auto-hide banner after successful sync
        _autoHideBanner();
      }
    } catch (e) {
      debugPrint('Sync error: $e');
      
      if (mounted) {
        _syncTimeoutTimer?.cancel();
        setState(() {
          _isSyncing = false;
        });
        _autoHideBanner();
      }
    }
  }

  void _autoHideBanner() {
    // Auto-hide banner after 3 seconds
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _animationController.reverse();
      }
    });
  }

  void _updateBannerVisibility() {
    final shouldShow = _isOffline || _isSyncing || _pendingCount > 0;
    
    if (shouldShow) {
      _animationController.forward();
      // Cancel auto-hide if banner should be shown
      _autoHideTimer?.cancel();
    } else {
      _animationController.reverse();
    }
  }

  Color _getBannerColor() {
    if (_isOffline) {
      return AppDesignSystem.warning;
    } else if (_isSyncing) {
      return AppDesignSystem.info;
    } else if (_pendingCount > 0) {
      return AppDesignSystem.info;
    }
    return AppDesignSystem.info;
  }

  IconData _getBannerIcon() {
    if (_isOffline) {
      return Icons.cloud_off;
    } else if (_isSyncing) {
      return Icons.sync;
    } else if (_pendingCount > 0) {
      return Icons.cloud_upload_outlined;
    }
    return Icons.sync;
  }

  String _getBannerText() {
    if (_isOffline) {
      return _pendingCount > 0
          ? 'Offline Mode • $_pendingCount items pending sync'
          : 'Offline Mode';
    } else if (_isSyncing) {
      return 'Syncing $_pendingCount items...';
    } else if (_pendingCount > 0) {
      return 'Sync pending: $_pendingCount items • $_unsavedXP XP';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content
        widget.child,
        
        // Overlay banner positioned at the top
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SlideTransition(
            position: _slideAnimation,
            child: SafeArea(
              bottom: false,
              child: Material(
                elevation: 4,
                color: _getBannerColor(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSyncing)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else
                        Icon(
                          _getBannerIcon(),
                          color: Colors.white,
                          size: 16,
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getBannerText(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_pendingCount > 0 && !_isOffline && !_isSyncing)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$_unsavedXP XP',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
