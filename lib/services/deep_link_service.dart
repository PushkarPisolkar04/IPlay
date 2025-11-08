import 'package:flutter/material.dart';
import 'dart:async';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _linkController = StreamController<Uri>.broadcast();
  Stream<Uri> get linkStream => _linkController.stream;

  // Store pending deep link if app is not ready
  Uri? _pendingDeepLink;
  bool _isAppReady = false;

  void markAppReady() {
    _isAppReady = true;
  }

  void handleDeepLink(Uri uri, BuildContext context) {
    // If app is not ready, store the link for later
    if (!_isAppReady) {
      _pendingDeepLink = uri;
      return;
    }

    _processDeepLink(uri, context);
  }

  void processPendingDeepLink(BuildContext context) {
    if (_pendingDeepLink != null) {
      _processDeepLink(_pendingDeepLink!, context);
      _pendingDeepLink = null;
    }
  }

  void _processDeepLink(Uri uri, BuildContext context) {
    // Parse the URI - supports both iplay://realm/copyright and iplay://realm?id=copyright
    final host = uri.host;
    final pathSegments = uri.pathSegments;
    final queryParams = uri.queryParameters;

    // Determine the resource type and ID
    String? resourceType = host.isNotEmpty ? host : null;
    String? resourceId;

    // Try to get ID from path first, then from query params
    if (pathSegments.isNotEmpty) {
      resourceId = pathSegments.first;
    } else if (queryParams.containsKey('id')) {
      resourceId = queryParams['id'];
    }

    // Handle different resource types
    switch (resourceType) {
      case 'realm':
        if (resourceId != null) _navigateToRealm(context, resourceId);
        break;
      case 'game':
        if (resourceId != null) _navigateToGame(context, resourceId);
        break;
      case 'certificate':
        // Handle certificate verification: iplay://certificate/verify/CERT-123
        if (pathSegments.length >= 2 && pathSegments[0] == 'verify') {
          _navigateToCertificate(context, pathSegments[1]);
        } else if (queryParams.containsKey('verify')) {
          _navigateToCertificate(context, queryParams['verify']!);
        }
        break;
      case 'daily-challenge':
        _navigateToDailyChallenge(context);
        break;
      case 'chat':
        if (resourceId != null && queryParams.containsKey('userName')) {
          _navigateToChat(context, resourceId, queryParams['userName']!, queryParams['userAvatar']);
        }
        break;
      case 'classroom':
        if (pathSegments.isNotEmpty && pathSegments[0] == 'join') {
          // Handle both iplay://classroom/join/CODE and iplay://classroom/join?code=CODE
          final code = resourceId ?? queryParams['code'];
          final source = queryParams['source'] ?? 'link';
          if (code != null) {
            _navigateToJoinClassroom(context, code, source);
          }
        }
        break;
      case 'leaderboard':
        _navigateToLeaderboard(context);
        break;
      case 'badges':
        _navigateToBadges(context);
        break;
      case 'notifications':
        _navigateToNotifications(context);
        break;
    }
  }

  void _navigateToRealm(BuildContext context, String realmId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushNamed('/realm', arguments: {'realmId': realmId});
    });
  }

  void _navigateToGame(BuildContext context, String gameId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushNamed('/game', arguments: {'gameId': gameId});
    });
  }

  void _navigateToCertificate(BuildContext context, String certId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushNamed('/certificate/verify', arguments: {'certId': certId});
    });
  }

  void _navigateToDailyChallenge(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushNamed('/daily-challenge');
    });
  }

  void _navigateToChat(BuildContext context, String chatId, String userName, String? userAvatar) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushNamed('/chat', arguments: {
        'chatId': chatId,
        'otherUserName': userName,
        'otherUserAvatar': userAvatar,
      });
    });
  }

  void _navigateToJoinClassroom(BuildContext context, String classroomCode, String source) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushNamed('/join-classroom', arguments: {
        'code': classroomCode,
        'source': source,
      });
    });
  }

  void _navigateToLeaderboard(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushNamed('/main'); // Leaderboard is in main screen
    });
  }

  void _navigateToBadges(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushNamed('/badges');
    });
  }

  void _navigateToNotifications(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushNamed('/notifications');
    });
  }

  void dispose() {
    _linkController.close();
  }
}
