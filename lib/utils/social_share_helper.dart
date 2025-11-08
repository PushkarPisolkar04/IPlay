import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/badge_model.dart';
import '../core/design/app_design_system.dart';

/// Helper class for social sharing functionality
class SocialShareHelper {
  /// Share certificate with verification URL
  static Future<void> shareCertificate({
    required String certificateId,
    required String realmName,
    required String userName,
    String? filePath,
  }) async {
    final verificationUrl = 'https://iplay.app/verify/$certificateId';
    
    final text = '''
🎓 Certificate Achievement!

I've successfully completed the $realmName in IPlay and earned my certificate!

Verify this certificate: $verificationUrl

Download IPlay and start your IPR learning journey:
📱 Play Store: [Link]
🍎 App Store: [Link]

#IPlay #IPR #Learning #Certificate
''';

    if (filePath != null && File(filePath).existsSync()) {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: text,
        subject: 'IPlay Certificate - $realmName',
      );
    } else {
      await Share.share(
        text,
        subject: 'IPlay Certificate - $realmName',
      );
    }
  }

  /// Share badge unlock
  static Future<void> shareBadge({
    required BadgeModel badge,
    required String userName,
  }) async {
    final text = '''
🎉 Badge Unlocked!

I just earned the "${badge.name}" badge in IPlay!

${badge.description}

+${badge.xpBonus} XP earned!

Join me in learning about Intellectual Property Rights:
📱 Download IPlay: [App Link]

#IPlay #IPR #Badge #Achievement
''';

    await Share.share(
      text,
      subject: 'IPlay Badge - ${badge.name}',
    );
  }

  /// Generate and share badge image
  static Future<void> shareBadgeWithImage({
    required BadgeModel badge,
    required String userName,
    required BuildContext context,
  }) async {
    try {
      // Create badge image
      final imageFile = await _generateBadgeImage(badge, userName);
      
      final text = '''
🎉 I just unlocked the "${badge.name}" badge in IPlay!

${badge.description}

Download IPlay: [App Link]

#IPlay #IPR #Badge
''';

      await Share.shareXFiles(
        [XFile(imageFile.path)],
        text: text,
        subject: 'IPlay Badge - ${badge.name}',
      );
    } catch (e) {
      // print('Error sharing badge with image: $e');
      // Fallback to text-only share
      await shareBadge(badge: badge, userName: userName);
    }
  }

  /// Generate badge image for sharing
  static Future<File> _generateBadgeImage(
    BadgeModel badge,
    String userName,
  ) async {
    // Create a custom painter for the badge image
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(800, 800);

    // Background gradient
    final gradient = ui.Gradient.linear(
      const Offset(0, 0),
      const Offset(800, 800),
      [
        AppDesignSystem.primaryIndigo,
        AppDesignSystem.primaryPink,
      ],
    );

    final paint = Paint()..shader = gradient;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // White circle background
    final circlePaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      300,
      circlePaint,
    );

    // Badge icon (would need proper text rendering)
    final textPainter = TextPainter(
      text: TextSpan(
        text: badge.icon,
        style: const TextStyle(
          fontSize: 200,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2 - 100,
      ),
    );

    // Badge name
    final namePainter = TextPainter(
      text: TextSpan(
        text: badge.name,
        style: const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    namePainter.layout(maxWidth: 700);
    namePainter.paint(
      canvas,
      Offset(
        (size.width - namePainter.width) / 2,
        size.height / 2 + 150,
      ),
    );

    // User name
    final userPainter = TextPainter(
      text: TextSpan(
        text: 'Earned by $userName',
        style: const TextStyle(
          fontSize: 32,
          color: Colors.black87,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    userPainter.layout();
    userPainter.paint(
      canvas,
      Offset(
        (size.width - userPainter.width) / 2,
        size.height / 2 + 220,
      ),
    );

    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    // Save to temp file
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/badge_${badge.id}.png');
    await file.writeAsBytes(bytes);

    return file;
  }

  /// Share achievement/milestone
  static Future<void> shareAchievement({
    required String achievementTitle,
    required String achievementDescription,
    required String userName,
  }) async {
    final text = '''
🎯 Achievement Unlocked!

$achievementTitle

$achievementDescription

Join me on IPlay and start your IPR learning journey:
📱 Download: [App Link]

#IPlay #IPR #Achievement
''';

    await Share.share(
      text,
      subject: 'IPlay Achievement - $achievementTitle',
    );
  }

  /// Share realm completion
  static Future<void> shareRealmCompletion({
    required String realmName,
    required int levelsCompleted,
    required int xpEarned,
    required String userName,
  }) async {
    final text = '''
🎉 Realm Completed!

I just completed the $realmName in IPlay!

✅ $levelsCompleted levels completed
⭐ $xpEarned XP earned

Master Intellectual Property Rights with IPlay:
📱 Download: [App Link]

#IPlay #IPR #Learning
''';

    await Share.share(
      text,
      subject: 'IPlay - $realmName Completed',
    );
  }

  /// Share leaderboard rank
  static Future<void> shareLeaderboardRank({
    required int rank,
    required String scope,
    required int totalXP,
    required String userName,
  }) async {
    final scopeText = scope == 'classroom'
        ? 'classroom'
        : scope == 'school'
            ? 'school'
            : scope == 'state'
                ? 'state'
                : 'national';

    final text = '''
🏆 Leaderboard Achievement!

I'm ranked #$rank on the $scopeText leaderboard in IPlay!

Total XP: $totalXP

Think you can beat me? Download IPlay and start learning:
📱 [App Link]

#IPlay #IPR #Leaderboard
''';

    await Share.share(
      text,
      subject: 'IPlay Leaderboard - Rank #$rank',
    );
  }

  /// Share app invitation
  static Future<void> shareAppInvitation({
    required String userName,
  }) async {
    final text = '''
🎓 Join me on IPlay!

I'm learning about Intellectual Property Rights through fun games and interactive lessons.

Download IPlay and start your learning journey:
📱 Play Store: [Link]
🍎 App Store: [Link]

Let's learn together!

#IPlay #IPR #Learning
''';

    await Share.share(
      text,
      subject: 'Join me on IPlay!',
    );
  }

  /// Capture widget as image and share
  static Future<void> shareWidgetAsImage({
    required GlobalKey widgetKey,
    required String text,
    required String subject,
  }) async {
    try {
      // Find the render object
      final RenderRepaintBoundary boundary =
          widgetKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      // Capture the image
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/share_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);

      // Share
      await Share.shareXFiles(
        [XFile(file.path)],
        text: text,
        subject: subject,
      );
    } catch (e) {
      // print('Error sharing widget as image: $e');
      // Fallback to text-only share
      await Share.share(text, subject: subject);
    }
  }
}
