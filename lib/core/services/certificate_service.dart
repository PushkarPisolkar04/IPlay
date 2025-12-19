import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:typed_data';
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

      final data = doc.data()!;
      
      // Regenerate PDF from metadata
      return await _regenerateCertificatePdf(data);
    } catch (e) {
      throw Exception('Failed to get PDF: $e');
    }
  }

  /// Regenerate certificate PDF from stored metadata
  Future<Uint8List> _regenerateCertificatePdf(Map<String, dynamic> certData) async {
    final realmId = certData['realmId'] as String;
    final realmName = certData['realmName'] as String;
    final studentName = certData['studentName'] as String;
    final certificateNumber = certData['certificateNumber'] as String;
    final levelsCompleted = certData['levelsCompleted'] as int? ?? 0;
    final totalLevels = certData['totalLevels'] as int? ?? 10;
    final averageStars = (certData['averageStars'] as num?)?.toDouble() ?? 0.0;
    
    print('🎓 REGENERATING CERTIFICATE:');
    print('   Certificate Number: $certificateNumber');
    print('   Average Stars: $averageStars');
    print('   Student: $studentName');

    // Realm Config (same as in generateRealmCertificate)
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

    final config = realmConfig[realmId] ?? {
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
    final dancingScript = pw.Font.ttf(
      await rootBundle.load("assets/fonts/DancingScript-Bold.ttf"),
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

    // Build PDF
    final pdf = pw.Document();
    
    print('📄 Building enhanced certificate with:');
    print('   Stars: $averageStars');
    print('   Watermark: YES');
    print('   Signature: YES');
    
    try {
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
            studentName: studentName,
            certificateNumber: certificateNumber,
            levelsCompleted: levelsCompleted,
            totalLevels: totalLevels,
            averageStars: averageStars,
            qrImage: qrImage,
            poppins: poppins,
            poppinsBold: poppinsBold,
            poppinsItalic: poppinsItalic,
            dancingScript: dancingScript,
          ),
        ),
      );
      
      print('✅ PDF page added successfully');
      final bytes = await pdf.save();
      print('✅ PDF saved successfully, size: ${bytes.length} bytes');
      return bytes;
    } catch (e, stackTrace) {
      print('❌ Error building PDF: $e');
      print('Stack trace: $stackTrace');
      rethrow;
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

      // Use FileDownloadService for platform-safe sharing
      final fileDownloadService = FileDownloadService();
      await fileDownloadService.shareFile(
        bytes: pdfBytes,
        fileName: '$certificateNumber.pdf',
        shareText: 'My $realmName Certificate - $certificateNumber',
      );
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
      final dancingScript = pw.Font.ttf(
        await rootBundle.load("assets/fonts/DancingScript-Bold.ttf"),
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
      double averageStars = 0.0;
      if (progressDoc.exists) {
        levelsCompleted =
            (progressDoc.data()?['completedLevels'] as List?)?.length ?? 0;
        
        // Calculate average stars from levelStars map
        final levelStars = progressDoc.data()?['levelStars'] as Map<String, dynamic>?;
        if (levelStars != null && levelStars.isNotEmpty) {
          int totalStars = 0;
          int levelCount = 0;
          levelStars.forEach((key, value) {
            if (value is int) {
              totalStars += value;
              levelCount++;
            }
          });
          if (levelCount > 0) {
            averageStars = totalStars / levelCount;
          }
        }
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
            averageStars: averageStars,
            qrImage: qrImage,
            poppins: poppins,
            poppinsBold: poppinsBold,
            poppinsItalic: poppinsItalic,
            dancingScript: dancingScript,
          ),
        ),
      );

      // Generate PDF bytes for preview/validation but don't store
      final pdfBytes = await pdf.save();
      
      // Store only metadata - PDF will be regenerated on-demand
      final certificateData = {
        'id': certificateId,
        'userId': user.uid,
        'certificateType': 'realm',
        'realmId': realmId,
        'realmName': realmName,
        'studentName': userData['displayName'] ?? 'Outstanding Learner',
        'certificateNumber': certificateNumber,
        'levelsCompleted': levelsCompleted,
        'totalLevels': totalLevels,
        'averageStars': averageStars,
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

  /// Build Professional Certificate with Modern Design
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
  required double averageStars,
  required pw.Image qrImage,
  required pw.Font poppins,
  required pw.Font poppinsBold,
  required pw.Font poppinsItalic,
  required pw.Font dancingScript,
}) {
  print('🎨 Building certificate layout...');
  
  // Define elegant color palette
  final goldAccent = PdfColor.fromHex('#D4AF37'); // Gold
  final darkGrey = PdfColor.fromHex('#2C3E50');
  final lightGrey = PdfColor.fromHex('#95A5A6');
  
  return pw.Container(
    decoration: pw.BoxDecoration(
      color: PdfColors.white,
      border: pw.Border.all(
        color: goldAccent,
        width: 4,
      ),
    ),
    child: pw.Container(
      margin: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: realmColor,
          width: 2,
        ),
      ),
      child: pw.Container(
        margin: const pw.EdgeInsets.all(3),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(
            color: PdfColors.grey300,
            width: 1,
          ),
        ),
        padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 30),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Header with Logo and Verified Badge
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Container(
                  width: 55,
                  height: 55,
                  child: pw.Image(appLogoImage),
                ),
                // Verified Badge - Classic blue checkmark design
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#1E88E5'), // Blue
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      // Blue circle with white checkmark
                      pw.Container(
                        width: 16,
                        height: 16,
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#1976D2'), // Darker blue
                          shape: pw.BoxShape.circle,
                          border: pw.Border.all(color: PdfColors.white, width: 1.5),
                        ),
                        child: pw.Center(
                          child: pw.Container(
                            width: 8,
                            height: 8,
                            decoration: pw.BoxDecoration(
                              color: PdfColors.white,
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 6),
                      pw.Text(
                        'VERIFIED',
                        style: pw.TextStyle(
                          font: poppinsBold,
                          fontSize: 10,
                          color: PdfColors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            pw.SizedBox(height: 18),
            
            // Title with gradient-like effect
            pw.Text(
              'Certificate of Completion',
              style: pw.TextStyle(
                font: poppinsBold,
                fontSize: 42,
                color: darkGrey,
              ),
            ),
            
            pw.SizedBox(height: 8),
            
            // Decorative line with gold
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Container(width: 60, height: 2, color: goldAccent),
                pw.SizedBox(width: 10),
                pw.Container(
                  width: 8,
                  height: 8,
                  decoration: pw.BoxDecoration(
                    color: realmColor,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Container(width: 60, height: 2, color: goldAccent),
              ],
            ),
            
            pw.SizedBox(height: 20),
            
            // Subtitle
            pw.Text(
              'This is to certify that',
              style: pw.TextStyle(
                font: poppinsItalic,
                fontSize: 12,
                color: lightGrey,
              ),
            ),
            
            pw.SizedBox(height: 14),
            
            // Student Name - Bold with gold underline
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 8),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(
                    color: goldAccent,
                    width: 3,
                  ),
                ),
              ),
              child: pw.Text(
                studentName,
                style: pw.TextStyle(
                  font: poppinsBold,
                  fontSize: 38,
                  color: realmColor,
                ),
              ),
            ),
            
            pw.SizedBox(height: 18),
            
            // Achievement - More detailed with color
            pw.Container(
              width: 450,
              child: pw.RichText(
                textAlign: pw.TextAlign.center,
                text: pw.TextSpan(
                  style: pw.TextStyle(
                    font: poppins,
                    fontSize: 14,
                    color: darkGrey,
                    height: 1.5,
                  ),
                  children: [
                    pw.TextSpan(text: 'has successfully completed the '),
                    pw.TextSpan(
                      text: realmName,
                      style: pw.TextStyle(
                        font: poppinsBold,
                        color: realmColor,
                      ),
                    ),
                    pw.TextSpan(text: '\n\nThis achievement represents the completion of '),
                    pw.TextSpan(
                      text: '$totalLevels comprehensive levels',
                      style: pw.TextStyle(
                        font: poppinsBold,
                        color: goldAccent,
                      ),
                    ),
                    pw.TextSpan(text: ', demonstrating exceptional dedication and mastery of the subject matter.'),
                  ],
                ),
              ),
            ),
            
            pw.SizedBox(height: 22),
            
            // Performance Rating - Creative Progress Bar
            pw.Column(
              children: [
                pw.Text(
                  'PERFORMANCE RATING',
                  style: pw.TextStyle(
                    font: poppins,
                    fontSize: 9,
                    color: lightGrey,
                    letterSpacing: 1.2,
                  ),
                ),
                pw.SizedBox(height: 12),
                // Progress bar with segments
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    // 5 segments
                    for (int i = 0; i < 5; i++) ...[
                      pw.Container(
                        width: 35,
                        height: 8,
                        decoration: pw.BoxDecoration(
                          color: i < averageStars.round()
                              ? goldAccent
                              : PdfColors.grey300,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                      ),
                      if (i < 4) pw.SizedBox(width: 4),
                    ],
                  ],
                ),
                pw.SizedBox(height: 10),
                // Rating badge
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: realmColor,
                    borderRadius: pw.BorderRadius.circular(20),
                  ),
                  child: pw.Text(
                    '${averageStars.toStringAsFixed(1)} / 5.0',
                    style: pw.TextStyle(
                      font: poppinsBold,
                      fontSize: 14,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            pw.SizedBox(height: 24),
            
            // Decorative bottom border with gold
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Container(width: 40, height: 1, color: goldAccent),
                pw.SizedBox(width: 8),
                pw.Container(
                  width: 6,
                  height: 6,
                  decoration: pw.BoxDecoration(
                    color: realmColor,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Container(width: 40, height: 1, color: goldAccent),
              ],
            ),
            
            pw.SizedBox(height: 16),
            
            // Footer with signature
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'IPlay',
                      style: pw.TextStyle(
                        font: poppinsBold,
                        fontSize: 24,
                        color: realmColor,
                      ),
                    ),
                    pw.Container(
                      width: 110,
                      height: 2,
                      color: goldAccent,
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'IPlay Education',
                      style: pw.TextStyle(
                        font: poppins,
                        fontSize: 9,
                        color: darkGrey,
                      ),
                    ),
                    pw.Text(
                      _formatDate(DateTime.now()),
                      style: pw.TextStyle(
                        font: poppins,
                        fontSize: 8,
                        color: lightGrey,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 110,
                      height: 2,
                      color: goldAccent,
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      certificateNumber,
                      style: pw.TextStyle(
                        font: poppins,
                        fontSize: 8,
                        color: lightGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ),
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
          'CERTIFICATE OF COMPLETION',
          style: pw.TextStyle(
            font: bold,
            fontSize: 42,
            fontWeight: pw.FontWeight.bold,
            color: realm,
            letterSpacing: 2,
          ),
        ),
        pw.SizedBox(height: 12),
        // Decorative line with dots
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Container(
              width: 12,
              height: 12,
              decoration: pw.BoxDecoration(
                color: accent,
                shape: pw.BoxShape.circle,
              ),
            ),
            pw.SizedBox(width: 20),
            pw.Container(
              height: 2,
              width: 180,
              color: accent,
            ),
            pw.SizedBox(width: 20),
            pw.Container(
              width: 12,
              height: 12,
              decoration: pw.BoxDecoration(
                color: accent,
                shape: pw.BoxShape.circle,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'THIS CERTIFICATE IS PROUDLY PRESENTED TO',
          style: pw.TextStyle(
            font: bold,
            fontSize: 12,
            color: PdfColors.grey600,
            letterSpacing: 2,
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

  pw.Widget _buildStarRating(double averageStars, PdfColor accent, pw.Font font) {
    final fullStars = averageStars.floor();
    final hasHalfStar = (averageStars - fullStars) >= 0.5;
    
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.Text(
          'Performance: ',
          style: pw.TextStyle(
            font: font,
            fontSize: 16,
            color: PdfColors.grey700,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(width: 8),
        // Stars
        ...List.generate(5, (index) {
          if (index < fullStars) {
            // Full star
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 2),
              child: pw.Text(
                '★',
                style: pw.TextStyle(
                  fontSize: 24,
                  color: accent,
                ),
              ),
            );
          } else if (index == fullStars && hasHalfStar) {
            // Half star (using a lighter color to simulate half)
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 2),
              child: pw.Text(
                '★',
                style: pw.TextStyle(
                  fontSize: 24,
                  color: PdfColor(accent.red, accent.green, accent.blue, 0.5),
                ),
              ),
            );
          } else {
            // Empty star
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 2),
              child: pw.Text(
                '☆',
                style: pw.TextStyle(
                  fontSize: 24,
                  color: PdfColors.grey400,
                ),
              ),
            );
          }
        }),
        pw.SizedBox(width: 8),
        pw.Text(
          '${averageStars.toStringAsFixed(1)}/5.0',
          style: pw.TextStyle(
            font: font,
            fontSize: 16,
            color: PdfColors.grey700,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
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
            '$completed of $total Levels Completed',
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
    pw.Font dancingScript,
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
            // Handwritten Signature
            pw.Text(
              'IPlay',
              style: pw.TextStyle(
                font: dancingScript,
                fontSize: 52,
                color: realm,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Container(height: 2, width: 180, color: PdfColors.grey700),
            pw.SizedBox(height: 6),
            pw.Text(
              'Program Director',
              style: pw.TextStyle(
                font: regular,
                fontSize: 11,
                color: PdfColors.grey600,
                letterSpacing: 0.5,
              ),
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
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: pw.BoxDecoration(
        color: PdfColor(color.red, color.green, color.blue, 0.1),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: regular,
              fontSize: 10,
              color: PdfColors.grey600,
              letterSpacing: 0.5,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: bold,
              fontSize: 18,
              color: color,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // New helper for modern stat boxes
  pw.Widget _buildStatBox(String label, String value, PdfColor color, pw.Font regular, pw.Font bold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor(color.red, color.green, color.blue, 0.3), width: 2),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(
              font: regular,
              fontSize: 10,
              color: PdfColors.grey600,
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: bold,
              fontSize: 24,
              color: color,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build star rating display
  List<pw.Widget> _buildStars(double rating, PdfColor color) {
    final List<pw.Widget> stars = [];
    final fullStars = rating.floor();
    final decimal = rating - fullStars;
    final hasHalfStar = decimal >= 0.3 && decimal < 0.8; // Show half star for 0.3-0.7 range
    
    print('⭐ _buildStars called:');
    print('   Rating: $rating');
    print('   fullStars: $fullStars');
    print('   decimal: $decimal');
    print('   hasHalfStar: $hasHalfStar');
    
    // Add full stars (filled circles)
    for (int i = 0; i < fullStars; i++) {
      stars.add(
        pw.Container(
          width: 18,
          height: 18,
          margin: const pw.EdgeInsets.symmetric(horizontal: 2),
          decoration: pw.BoxDecoration(
            color: color,
            shape: pw.BoxShape.circle,
          ),
        ),
      );
    }
    
    // Add half star (semi-transparent circle)
    if (hasHalfStar && fullStars < 5) {
      print('   Adding half star!');
      stars.add(
        pw.Container(
          width: 18,
          height: 18,
          margin: const pw.EdgeInsets.symmetric(horizontal: 2),
          decoration: pw.BoxDecoration(
            color: PdfColor(color.red, color.green, color.blue, 0.25),
            shape: pw.BoxShape.circle,
          ),
        ),
      );
    }
    
    // Add empty stars (outlined circles)
    final emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);
    print('   emptyStars: $emptyStars');
    print('   Total stars: ${stars.length + emptyStars}');
    
    for (int i = 0; i < emptyStars; i++) {
      stars.add(
        pw.Container(
          width: 18,
          height: 18,
          margin: const pw.EdgeInsets.symmetric(horizontal: 2),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400, width: 1.5),
            shape: pw.BoxShape.circle,
          ),
        ),
      );
    }
    
    return stars;
  }

  pw.Widget _buildWatermark(pw.MemoryImage logo) {
    return pw.Center(
      child: pw.Opacity(
        opacity: 0.18,
        child: pw.Image(
          logo,
          width: 400,
          height: 400,
          fit: pw.BoxFit.contain,
        ),
      ),
    );
  }

  List<pw.Widget> _buildDecorativeCorners(PdfColor color) {
    // Removed star decorations to avoid font issues
    return [];
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
