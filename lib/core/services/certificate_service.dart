import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import '../models/certificate_model.dart';
import 'file_download_service.dart';

/// Enhanced Certificate Service with Premium PDF Generation
/// Features: Gradient backgrounds, decorative elements, badge-like styling
class CertificateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Public API Methods remain the same
  Future<CertificateModel?> getCertificate(String certificateId) async {
    try {
      final doc = await _firestore
          .collection('certificates')
          .doc(certificateId)
          .get();
      if (!doc.exists) return null;
      return CertificateModel.fromFirestore(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get certificate: $e');
    }
  }

  Future<List<CertificateModel>> getUserCertificates(String userId) async {
    try {
      final query = await _firestore
          .collection('certificates')
          .where('userId', isEqualTo: userId)
          .orderBy('issuedAt', descending: true)
          .get();

      return query.docs
          .map((doc) => CertificateModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user certificates: $e');
    }
  }

  Future<CertificateModel?> getUserRealmCertificate({
    required String userId,
    required String realmId,
  }) async {
    try {
      final query = await _firestore
          .collection('certificates')
          .where('userId', isEqualTo: userId)
          .where('realmId', isEqualTo: realmId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;
      return CertificateModel.fromFirestore(query.docs.first.data());
    } catch (e) {
      throw Exception('Failed to check realm certificate: $e');
    }
  }

  Future<CertificateModel?> verifyCertificate(String certificateNumber) async {
    try {
      final query = await _firestore
          .collection('certificates')
          .where('certificateNumber', isEqualTo: certificateNumber)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;
      return CertificateModel.fromFirestore(query.docs.first.data());
    } catch (e) {
      throw Exception('Failed to verify certificate: $e');
    }
  }

  Future<Uint8List?> getCertificatePdfBytes(String certificateId) async {
    try {
      final doc = await _firestore
          .collection('certificates')
          .doc(certificateId)
          .get();
      if (!doc.exists) return null;

      final localPath = doc.data()?['localPath'] as String?;
      if (localPath == null) return null;

      final file = File(localPath);
      if (!await file.exists()) return null;

      return await file.readAsBytes();
    } catch (e) {
      throw Exception('Failed to get PDF: $e');
    }
  }

  Future<String?> getCertificateDownloadUrl(String certificateId) async {
    try {
      final pdfBytes = await getCertificatePdfBytes(certificateId);
      if (pdfBytes == null) return null;
      return 'data:application/pdf;base64,${base64Encode(pdfBytes)}';
    } catch (e) {
      throw Exception('Failed to get certificate URL: $e');
    }
  }

  Future<String?> downloadCertificate(String certificateId) async {
    try {
      final pdfBytes = await getCertificatePdfBytes(certificateId);
      if (pdfBytes == null) throw Exception('Certificate PDF not found');

      final doc = await _firestore
          .collection('certificates')
          .doc(certificateId)
          .get();
      final certificateNumber =
          doc.data()?['certificateNumber'] ?? 'certificate';

      // Use FileDownloadService for user-selected location
      final fileDownloadService = FileDownloadService();
      final savedPath = await fileDownloadService.saveFile(
        bytes: pdfBytes,
        suggestedName: '$certificateNumber.pdf',
        mimeType: 'application/pdf',
      );

      return savedPath;
    } catch (e) {
      throw Exception('Failed to download certificate: $e');
    }
  }

  Future<void> shareCertificate(String certificateId) async {
    try {
      final pdfBytes = await getCertificatePdfBytes(certificateId);
      if (pdfBytes == null) throw Exception('Certificate PDF not found');

      final doc = await _firestore
          .collection('certificates')
          .doc(certificateId)
          .get();
      final certificateNumber =
          doc.data()?['certificateNumber'] ?? 'certificate';
      final realmName = doc.data()?['realmName'] ?? 'Realm';

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$certificateNumber.pdf');
      await tempFile.writeAsBytes(pdfBytes);

      await Share.shareXFiles([
        XFile(tempFile.path),
      ], text: 'My $realmName Certificate - $certificateNumber');
    } catch (e) {
      throw Exception('Failed to share certificate: $e');
    }
  }

  Stream<List<CertificateModel>> watchUserCertificates(String userId) {
    return _firestore
        .collection('certificates')
        .where('userId', isEqualTo: userId)
        .orderBy('issuedAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => CertificateModel.fromFirestore(d.data()))
              .toList(),
        );
  }

  /// ENHANCED: Generate Premium Certificate with Gradients & Decorative Elements
  Future<CertificateModel> generateRealmCertificate({
    required String realmId,
    required String realmName,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      if (userData == null) throw Exception('User data not found');

      // Realm Config
      final realmConfig = {
        'realm_copyright': {
          'color': PdfColor.fromHex('#EC4899'),
          'accent': PdfColor.fromHex('#FFD700'),
          'logo': 'assets/logos/copyright_logo.png',
        },
        'realm_trademark': {
          'color': PdfColor.fromHex('#10B981'),
          'accent': PdfColor.fromHex('#FFD700'),
          'logo': 'assets/logos/trademark_logo.png',
        },
        'realm_patent': {
          'color': PdfColor.fromHex('#6366F1'),
          'accent': PdfColor.fromHex('#FFD700'),
          'logo': 'assets/logos/patent_logo.png',
        },
        'realm_industrial_design': {
          'color': PdfColor.fromHex('#F59E0B'),
          'accent': PdfColor.fromHex('#FFD700'),
          'logo': 'assets/logos/design_logo.png',
        },
        'realm_geographical_indications': {
          'color': PdfColor.fromHex('#14B8A6'),
          'accent': PdfColor.fromHex('#8B4513'),
          'logo': 'assets/logos/gi_logo.png',
        },
        'realm_trade_secrets': {
          'color': PdfColor.fromHex('#8B5CF6'),
          'accent': PdfColor.fromHex('#FFD700'),
          'logo': 'assets/logos/trade_secrets_logo.png',
        },
      };

      final config = realmConfig[realmId] ??
          {
            'color': PdfColors.indigo800,
            'accent': PdfColors.amber,
            'logo': 'assets/logos/logo.png',
          };

      final realmColor = config['color'] as PdfColor;
      final accentColor = config['accent'] as PdfColor;
      final realmLogoPath = config['logo'] as String;

      // Load Fonts
      final poppinsBold = pw.Font.ttf(
        await rootBundle.load("assets/fonts/Poppins-Bold.ttf"),
      );
      final poppins = pw.Font.ttf(
        await rootBundle.load("assets/fonts/Poppins-Regular.ttf"),
      );
      final poppinsItalic = pw.Font.ttf(
        await rootBundle.load("assets/fonts/Poppins-Italic.ttf"),
      );

      // Load Images
      final appLogoImage = pw.MemoryImage(
        (await rootBundle.load('assets/logos/logo.png')).buffer.asUint8List(),
      );

      pw.MemoryImage? realmLogoImage;
      try {
        final bytes = await rootBundle.load(realmLogoPath);
        realmLogoImage = pw.MemoryImage(bytes.buffer.asUint8List());
      } catch (e) {
        // Logo load failed
      }

      // Certificate Number
      final year = DateTime.now().year;
      final counterRef = _firestore.collection('counters').doc('certificates');
      int counter = 1;
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(counterRef);
        counter = (snap.data()?['count'] ?? 0) + 1;
        tx.set(counterRef, {'count': counter}, SetOptions(merge: true));
      });

      final certificateNumber =
          'IPLAY-$year-${realmId.split('_').last.toUpperCase()}-$counter';
      final certificateId = '${user.uid}_$realmId';

      // QR Code
      final qrPainter = QrPainter(
        data: 'https://iplay.app/verify/$certificateNumber',
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Color(0xFF000000),
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Color(0xFF000000),
        ),
      );
      final qrImageData = await qrPainter.toImageData(220);
      final qrImage = pw.Image(
        pw.MemoryImage(qrImageData!.buffer.asUint8List()),
        width: 90,
        height: 90,
      );

      // Progress
      final progressDoc = await _firestore
          .collection('progress')
          .doc('${user.uid}__$realmId')
          .get();
      int levelsCompleted = 0;
      int totalLevels = 10;
      if (progressDoc.exists) {
        levelsCompleted =
            (progressDoc.data()?['completedLevels'] as List?)?.length ?? 0;
      }

      // ENHANCED PDF with Premium Design
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: pw.EdgeInsets.zero,
          build: (context) => _buildEnhancedCertificate(
            realmColor: realmColor,
            accentColor: accentColor,
            appLogoImage: appLogoImage,
            realmLogoImage: realmLogoImage,
            realmName: realmName,
            studentName: userData['displayName'] ?? 'Outstanding Learner',
            certificateNumber: certificateNumber,
            levelsCompleted: levelsCompleted,
            totalLevels: totalLevels,
            qrImage: qrImage,
            poppins: poppins,
            poppinsBold: poppinsBold,
            poppinsItalic: poppinsItalic,
          ),
        ),
      );

      // Save PDF
      final pdfBytes = await pdf.save();
      final directory = await getApplicationDocumentsDirectory();
      final certificatesDir = Directory('${directory.path}/certificates');
      if (!await certificatesDir.exists()) {
        await certificatesDir.create(recursive: true);
      }

      final pdfFile = File('${certificatesDir.path}/$certificateNumber.pdf');
      await pdfFile.writeAsBytes(pdfBytes);

      // Store metadata
      final certificateData = {
        'id': certificateId,
        'userId': user.uid,
        'certificateType': 'realm',
        'realmId': realmId,
        'realmName': realmName,
        'certificateNumber': certificateNumber,
        'localPath': pdfFile.path,
        'issuedAt': Timestamp.now(),
        'status': 'generated',
      };

      await _firestore
          .collection('certificates')
          .doc(certificateId)
          .set(certificateData);

      await _notify(user.uid, realmName, certificateId);
      await _logActivity(userData, realmName, certificateId, realmId);

      return CertificateModel.fromFirestore(certificateData);
    } catch (e) {
      throw Exception('Failed to generate certificate: $e');
    }
  }

  /// Build Enhanced Certificate with Premium Design
  pw.Widget _buildEnhancedCertificate({
    required PdfColor realmColor,
    required PdfColor accentColor,
    required pw.MemoryImage appLogoImage,
    pw.MemoryImage? realmLogoImage,
    required String realmName,
    required String studentName,
    required String certificateNumber,
    required int levelsCompleted,
    required int totalLevels,
    required pw.Image qrImage,
    required pw.Font poppins,
    required pw.Font poppinsBold,
    required pw.Font poppinsItalic,
  }) {
    return pw.Stack(
      children: [
        // Premium Gradient Background
        pw.Container(
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [
                PdfColor.fromHex('#FFFBF0'),
                PdfColors.white,
                PdfColor.fromHex('#F0F9FF'),
              ],
              begin: pw.Alignment.topLeft,
              end: pw.Alignment.bottomRight,
            ),
          ),
        ),

        // Double Border with Shadow Effect
        pw.Container(
          margin: const pw.EdgeInsets.all(25),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: accentColor, width: 8),
            borderRadius: pw.BorderRadius.circular(24),
          ),
          child: pw.Container(
            margin: const pw.EdgeInsets.all(5),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(20),
              border: pw.Border.all(color: realmColor, width: 4),
            ),
            padding: const pw.EdgeInsets.all(45),
            child: pw.Column(
              children: [
                // Enhanced Header
                _buildHeader(appLogoImage, accentColor, realmColor, poppinsBold),
                pw.SizedBox(height: 28),

                // Title with Divider
                _buildTitle(realmColor, accentColor, poppinsBold, poppinsItalic),
                pw.SizedBox(height: 35),

                // Student Name
                _buildStudentName(studentName, accentColor, poppinsBold),
                pw.SizedBox(height: 32),

                // Realm Badge
                _buildRealmBadge(realmName, realmColor, realmLogoImage, poppinsBold),
                pw.SizedBox(height: 18),

                // Completion Stats
                _buildCompletionStats(levelsCompleted, totalLevels, realmColor, poppins, poppinsBold),
                pw.SizedBox(height: 35),

                // Footer
                _buildFooter(certificateNumber, accentColor, realmColor, appLogoImage, qrImage, poppins, poppinsBold, poppinsItalic),
              ],
            ),
          ),
        ),

        // Watermark
        _buildWatermark(realmColor, poppinsBold),

        // Decorative Corners
        ..._buildDecorativeCorners(accentColor),
      ],
    );
  }

  pw.Widget _buildHeader(pw.MemoryImage logo, PdfColor accent, PdfColor realm, pw.Font font) {
    return pw.Stack(
      alignment: pw.Alignment.center,
      children: [
        pw.Container(
          height: 75,
          decoration: pw.BoxDecoration(
            color: realm,
            borderRadius: pw.BorderRadius.circular(38),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 45, vertical: 14),
          decoration: pw.BoxDecoration(
            color: accent,
            borderRadius: pw.BorderRadius.circular(32),
          ),
          child: pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Image(logo, width: 42, height: 42),
              pw.SizedBox(width: 14),
              pw.Text(
                'IPlay',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 30,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTitle(PdfColor realm, PdfColor accent, pw.Font bold, pw.Font italic) {
    return pw.Column(
      children: [
        pw.Text(
          'CERTIFICATE OF MASTERY',
          style: pw.TextStyle(
            font: bold,
            fontSize: 50,
            fontWeight: pw.FontWeight.bold,
            color: realm,
            letterSpacing: 3,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          height: 3,
          width: 250,
          color: accent,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          '★  Intellectual Property Realm Completion  ★',
          style: pw.TextStyle(
            font: italic,
            fontSize: 19,
            color: PdfColors.grey700,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildStudentName(String name, PdfColor accent, pw.Font font) {
    return pw.Column(
      children: [
        pw.Text(
          'Proudly Awarded To',
          style: pw.TextStyle(
            font: font,
            fontSize: 24,
            color: PdfColors.grey800,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        pw.SizedBox(height: 14),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 55, vertical: 18),
          decoration: pw.BoxDecoration(
            color: accent,
            borderRadius: pw.BorderRadius.circular(18),
          ),
          child: pw.Text(
            name,
            style: pw.TextStyle(
              font: font,
              fontSize: 42,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              letterSpacing: 1.5,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildRealmBadge(String name, PdfColor color, pw.MemoryImage? logo, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(22),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(22),
        border: pw.Border.all(color: color, width: 4),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          if (logo != null) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(12),
                border: pw.Border.all(color: color, width: 2),
              ),
              child: pw.Image(logo, width: 52, height: 52),
            ),
            pw.SizedBox(width: 18),
          ],
          pw.Text(
            name,
            style: pw.TextStyle(
              font: font,
              fontSize: 36,
              fontWeight: pw.FontWeight.bold,
              color: color,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCompletionStats(int completed, int total, PdfColor color, pw.Font regular, pw.Font bold) {
    return pw.Column(
      children: [
        pw.Text(
          'Has conquered all challenges and mastered the realm',
          style: pw.TextStyle(
            font: regular,
            fontSize: 19,
            color: PdfColors.grey700,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(16),
            border: pw.Border.all(color: color, width: 2),
          ),
          child: pw.Text(
            '★  $completed of $total Levels Completed  ★',
            style: pw.TextStyle(
              font: bold,
              fontSize: 17,
              color: color,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildFooter(
    String certNum,
    PdfColor accent,
    PdfColor realm,
    pw.MemoryImage logo,
    pw.Image qr,
    pw.Font regular,
    pw.Font bold,
    pw.Font italic,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _infoBox('Certificate ID', certNum, regular, bold, realm),
            pw.SizedBox(height: 14),
            _infoBox('Issued On', _formatDate(DateTime.now()), regular, bold, realm),
          ],
        ),
        pw.Column(
          children: [
            pw.Container(height: 2, width: 190, color: PdfColors.grey700),
            pw.SizedBox(height: 8),
            pw.Text(
              'Authorized by IPlay',
              style: pw.TextStyle(
                font: italic,
                fontSize: 12,
                color: PdfColors.grey700,
                fontStyle: pw.FontStyle.italic,
                letterSpacing: 0.8,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: accent, width: 2),
              ),
              child: pw.Image(logo, width: 32, height: 32),
            ),
          ],
        ),
        pw.Column(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(14),
                border: pw.Border.all(color: realm, width: 3),
              ),
              child: qr,
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Scan to Verify',
              style: pw.TextStyle(
                font: bold,
                fontSize: 11,
                color: realm,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _infoBox(String label, String value, pw.Font regular, pw.Font bold, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color, width: 1),
      ),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label\n',
              style: pw.TextStyle(
                font: regular,
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
            pw.TextSpan(
              text: value,
              style: pw.TextStyle(
                font: bold,
                fontSize: 12,
                color: color,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildWatermark(PdfColor color, pw.Font font) {
    return pw.Center(
      child: pw.Transform.rotate(
        angle: -0.3,
        child: pw.Opacity(
          opacity: 0.04,
          child: pw.Text(
            'IPlay CERTIFIED',
            style: pw.TextStyle(
              font: font,
              fontSize: 150,
              fontWeight: pw.FontWeight.bold,
              color: color,
              letterSpacing: 8,
            ),
          ),
        ),
      ),
    );
  }

  List<pw.Widget> _buildDecorativeCorners(PdfColor color) {
    return [
      pw.Positioned(
        top: 40,
        left: 40,
        child: pw.Text('★', style: pw.TextStyle(fontSize: 32, color: color)),
      ),
      pw.Positioned(
        top: 40,
        right: 40,
        child: pw.Text('★', style: pw.TextStyle(fontSize: 32, color: color)),
      ),
      pw.Positioned(
        bottom: 40,
        left: 40,
        child: pw.Text('★', style: pw.TextStyle(fontSize: 32, color: color)),
      ),
      pw.Positioned(
        bottom: 40,
        right: 40,
        child: pw.Text('★', style: pw.TextStyle(fontSize: 32, color: color)),
      ),
    ];
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _notify(String userId, String realm, String certId) async {
    await _firestore.collection('notifications').add({
      'toUserId': userId,
      'title': 'Certificate Unlocked!',
      'body': 'You are now a certified $realm Master!',
      'data': {'type': 'certificate', 'certificateId': certId},
      'read': false,
      'sentAt': Timestamp.now(),
    });
  }

  Future<void> _logActivity(
    Map userData,
    String realm,
    String certId,
    String realmId,
  ) async {
    await _firestore.collection('recent_activities').add({
      'userId': userData['uid'],
      'userName': userData['displayName'],
      'activityType': 'certificate_earned',
      'title': 'Realm Master!',
      'description': 'Completed $realm',
      'metadata': {'certificateId': certId, 'realmId': realmId},
      'timestamp': Timestamp.now(),
    });
  }
}
