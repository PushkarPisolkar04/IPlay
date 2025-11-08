import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import '../core/design/app_design_system.dart';
import '../core/services/offline_progress_manager.dart';

class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _isOffline = false;
  int _pendingCount = 0;
  int _unsavedXP = 0;
  final OfflineProgressManager _offlineManager = OfflineProgressManager.instance;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadSyncStatus();
    
    // Listen to connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        _isOffline = result.contains(ConnectivityResult.none);
      });
      _loadSyncStatus();
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = result.contains(ConnectivityResult.none);
    });
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

  @override
  Widget build(BuildContext context) {
    // Show banner if offline OR if there's pending sync
    if (!_isOffline && _pendingCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _isOffline ? AppDesignSystem.warning : AppDesignSystem.info,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isOffline ? Icons.cloud_off : Icons.sync,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isOffline
                  ? 'Offline Mode${_pendingCount > 0 ? ' • $_pendingCount items pending sync' : ''}'
                  : 'Sync pending: $_pendingCount items • $_unsavedXP XP',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (_pendingCount > 0 && !_isOffline)
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
    );
  }
}

