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

/// Enhanced Certificate Service with Stunning, Professional & Fun PDF Generation
class CertificateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ======================
  // Public API Methods
  // ======================

  Future<CertificateModel?> getCertificate(String certificateId) async {
    try {
      final doc = await _firestore.collection('certificates').doc(certificateId).get();
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

      return query.docs.map((doc) => CertificateModel.fromFirestore(doc.data())).toList();
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
      // Read PDF from local storage
      final doc = await _firestore.collection('certificates').doc(certificateId).get();
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

  /// Download certificate to user-selected location
  Future<String?> downloadCertificate(String certificateId) async {
    try {
      final pdfBytes = await getCertificatePdfBytes(certificateId);
      if (pdfBytes == null) throw Exception('Certificate PDF not found');
      
      final doc = await _firestore.collection('certificates').doc(certificateId).get();
      final certificateNumber = doc.data()?['certificateNumber'] ?? 'certificate';
      
      // Get downloads directory
      final directory = await getExternalStorageDirectory();
      final downloadsPath = '${directory?.path}/Download';
      final downloadsDir = Directory(downloadsPath);
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      
      // Save to downloads
      final downloadFile = File('$downloadsPath/$certificateNumber.pdf');
      await downloadFile.writeAsBytes(pdfBytes);
      
      return downloadFile.path;
    } catch (e) {
      throw Exception('Failed to download certificate: $e');
    }
  }

  /// Share certificate via share sheet
  Future<void> shareCertificate(String certificateId) async {
    try {
      final pdfBytes = await getCertificatePdfBytes(certificateId);
      if (pdfBytes == null) throw Exception('Certificate PDF not found');
      
      final doc = await _firestore.collection('certificates').doc(certificateId).get();
      final certificateNumber = doc.data()?['certificateNumber'] ?? 'certificate';
      final realmName = doc.data()?['realmName'] ?? 'Realm';
      
      // Create temp file for sharing
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$certificateNumber.pdf');
      await tempFile.writeAsBytes(pdfBytes);
      
      // Share the file
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: 'My $realmName Certificate - $certificateNumber',
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
        .map((s) => s.docs.map((d) => CertificateModel.fromFirestore(d.data())).toList());
  }

  // ======================
  // Core: Generate Realm Certificate
  // ======================

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

      // === Realm Config ===
      final realmConfig = {
        'realm_copyright': {
          'color': PdfColor.fromHex('#FF6B35'),
          'accent': PdfColor.fromHex('#FFD700'),
          'logo': 'assets/logos/copyright_logo.png',
        },
        'realm_trademark': {
          'color': PdfColor.fromHex('#2196F3'),
          'accent': PdfColor.fromHex('#FFD700'),
          'logo': 'assets/logos/trademark_logo.png',
        },
        'realm_patent': {
          'color': PdfColor.fromHex('#4CAF50'),
          'accent': PdfColor.fromHex('#FFD700'),
          'logo': 'assets/logos/patent_logo.png',
        },
        'realm_design': {
          'color': PdfColor.fromHex('#E91E63'),
          'accent': PdfColor.fromHex('#FFD700'),
          'logo': 'assets/logos/design_logo.png',
        },
        'realm_gi': {
          'color': PdfColor.fromHex('#FFC107'),
          'accent': PdfColor.fromHex('#8B4513'),
          'logo': 'assets/logos/gi_logo.png',
        },
        'realm_trade_secrets': {
          'color': PdfColor.fromHex('#9C27B0'),
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

      // === Load Fonts ===
      final poppinsBold = pw.Font.ttf(await rootBundle.load("assets/fonts/Poppins-Bold.ttf"));
      final poppins = pw.Font.ttf(await rootBundle.load("assets/fonts/Poppins-Regular.ttf"));
      final poppinsItalic = pw.Font.ttf(await rootBundle.load("assets/fonts/Poppins-Italic.ttf"));

      // === Load Images ===
      final appLogoImage = pw.MemoryImage((await rootBundle.load('assets/logos/logo.png')).buffer.asUint8List());

      pw.MemoryImage? realmLogoImage;
      try {
        final bytes = await rootBundle.load(realmLogoPath);
        realmLogoImage = pw.MemoryImage(bytes.buffer.asUint8List());
      } catch (e) {
        // Logo load failed, will continue without realm logo
      }

      // === Serial Number with Counter ===
      final year = DateTime.now().year;
      final counterRef = _firestore.collection('counters').doc('certificates');
      int counter = 1;
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(counterRef);
        counter = (snap.data()?['count'] ?? 0) + 1;
        tx.set(counterRef, {'count': counter}, SetOptions(merge: true));
      });

      final certificateNumber = 'IPLAY-$year-${realmId.split('_').last.toUpperCase()}-$counter';
      final certificateId = '${user.uid}_$realmId';

      // === QR Code ===
      final qrPainter = QrPainter(
        data: 'https://iplay.app/verify/$certificateNumber',
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF000000)),
        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF000000)),
      );
      final qrImageData = await qrPainter.toImageData(220);
      final qrImage = pw.Image(pw.MemoryImage(qrImageData!.buffer.asUint8List()), width: 90, height: 90);

      // === Progress ===
      final progressDoc = await _firestore.collection('progress').doc('${user.uid}__$realmId').get();
      int levelsCompleted = 0;
      int totalLevels = 8;
      if (progressDoc.exists) {
        levelsCompleted = (progressDoc.data()?['completedLevels'] as List?)?.length ?? 0;
      }

      // === PDF Document ===
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: pw.EdgeInsets.zero,
          build: (context) => pw.Stack(
              children: [
                // Background
                pw.Container(
                  decoration: pw.BoxDecoration(
                    gradient: pw.LinearGradient(
                      colors: [PdfColors.grey50, PdfColors.white, PdfColors.grey50],
                      begin: pw.Alignment.topLeft,
                      end: pw.Alignment.bottomRight,
                    ),
                  ),
                ),

                // Outer Golden Border
                pw.Container(
                  margin: const pw.EdgeInsets.all(25),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: accentColor, width: 6),
                    borderRadius: pw.BorderRadius.circular(20),
                  ),
                  child: pw.Container(
                    margin: const pw.EdgeInsets.all(4),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(16),
                      border: pw.Border.all(color: realmColor, width: 3),
                    ),
                    padding: const pw.EdgeInsets.all(50),
                    child: pw.Column(
                      children: [
                        // Header Ribbon
                        pw.Stack(
                          alignment: pw.Alignment.center,
                          children: [
                            pw.Container(height: 70, decoration: pw.BoxDecoration(color: realmColor, borderRadius: pw.BorderRadius.circular(35))),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                              decoration: pw.BoxDecoration(color: accentColor, borderRadius: pw.BorderRadius.circular(30)),
                              child: pw.Row(
                                mainAxisSize: pw.MainAxisSize.min,
                                children: [
                                  pw.Image(appLogoImage, width: 40, height: 40),
                                  pw.SizedBox(width: 12),
                                  pw.Text('IPlay', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 30),

                        // Title
                        pw.Text('CERTIFICATE OF MASTERY', style: pw.TextStyle(fontSize: 48, fontWeight: pw.FontWeight.bold, color: realmColor, letterSpacing: 2)),
                        pw.SizedBox(height: 8),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            _star(accentColor),
                            pw.SizedBox(width: 8),
                            pw.Text('Intellectual Property Realm Completion', style: pw.TextStyle(fontSize: 18, color: PdfColors.grey700, fontStyle: pw.FontStyle.italic)),
                            pw.SizedBox(width: 8),
                            _star(accentColor),
                          ],
                        ),
                        pw.SizedBox(height: 40),

                        // Awarded To
                        pw.Text('Proudly Awarded To', style: pw.TextStyle(fontSize: 22, color: PdfColors.grey800, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 12),

                        // Student Name Badge
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                          decoration: pw.BoxDecoration(
                            color: accentColor, 
                            borderRadius: pw.BorderRadius.circular(15),
                          ),
                          child: pw.Text(
                            userData['displayName'] ?? 'Outstanding Learner',
                            style: pw.TextStyle(fontSize: 40, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.SizedBox(height: 35),

                        // Realm Badge
                        pw.Container(
                          padding: const pw.EdgeInsets.all(20),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey100, 
                            borderRadius: pw.BorderRadius.circular(20), 
                            border: pw.Border.all(color: realmColor, width: 3)
                          ),
                          child: pw.Row(
                            mainAxisSize: pw.MainAxisSize.min,
                            children: [
                              if (realmLogoImage != null) pw.Image(realmLogoImage, width: 50, height: 50),
                              if (realmLogoImage != null) pw.SizedBox(width: 15),
                              pw.Text(realmName, style: pw.TextStyle(fontSize: 34, fontWeight: pw.FontWeight.bold, color: realmColor)),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 20),

                        // Completion Text
                        pw.Text('Has conquered all challenges and mastered the realm', style: pw.TextStyle(fontSize: 18, color: PdfColors.grey700), textAlign: pw.TextAlign.center),
                        pw.SizedBox(height: 8),
                        pw.Text('$levelsCompleted of $totalLevels Levels Completed', style: pw.TextStyle(fontSize: 16, color: realmColor, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 40),

                        // Footer
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                              _info('Certificate ID', certificateNumber, poppins, poppinsBold),
                              pw.SizedBox(height: 12),
                              _info('Issued On', _formatDate(DateTime.now()), poppins, poppinsBold),
                            ]),
                            pw.Column(children: [
                              pw.Container(width: 180, height: 1, color: PdfColors.grey700),
                              pw.SizedBox(height: 6),
                              pw.Text('Authorized by IPlay', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                              pw.SizedBox(height: 4),
                              pw.Image(appLogoImage, width: 30, height: 30),
                            ]),
                            pw.Column(children: [
                              pw.Container(padding: const pw.EdgeInsets.all(6), decoration: pw.BoxDecoration(border: pw.Border.all(color: realmColor, width: 2), borderRadius: pw.BorderRadius.circular(12)), child: qrImage),
                              pw.SizedBox(height: 6),
                              pw.Text('Scan to Verify', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                            ]),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Watermark
                pw.Center(
                  child: pw.Transform.rotate(
                    angle: -0.3,
                    child: pw.Opacity(
                      opacity: 0.06,
                      child: pw.Text('IPlay CERTIFIED', style: pw.TextStyle(fontSize: 140, fontWeight: pw.FontWeight.bold, color: realmColor)),
                    ),
                  ),
                ),
              ],
            ),
        ),
      );

      // === Save PDF Locally ===
      final pdfBytes = await pdf.save();
      
      // Save PDF to device storage
      final directory = await getApplicationDocumentsDirectory();
      final certificatesDir = Directory('${directory.path}/certificates');
      if (!await certificatesDir.exists()) {
        await certificatesDir.create(recursive: true);
      }
      
      final pdfFile = File('${certificatesDir.path}/$certificateNumber.pdf');
      await pdfFile.writeAsBytes(pdfBytes);
      
      // Store metadata in Firestore (not the PDF itself)
      final certificateData = {
        'id': certificateId,
        'userId': user.uid,
        'certificateType': 'realm',
        'realmId': realmId,
        'realmName': realmName,
        'certificateNumber': certificateNumber,
        'localPath': pdfFile.path, // Store local file path
        'issuedAt': Timestamp.now(),
        'status': 'generated',
      };

      await _firestore.collection('certificates').doc(certificateId).set(certificateData);

      // Notification & Activity
      await _notify(user.uid, realmName, certificateId);
      await _logActivity(userData, realmName, certificateId, realmId);

      return CertificateModel.fromFirestore(certificateData);
    } catch (e) {
      throw Exception('Failed to generate certificate: $e');
    }
  }

  // ======================
  // Helpers
  // ======================

  pw.Widget _star(PdfColor color) => pw.Text('star', style: pw.TextStyle(fontSize: 22, color: color));

  pw.Widget _info(String label, String value, pw.Font regular, pw.Font bold) {
    return pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(text: '$label: ', style: pw.TextStyle(font: bold, fontSize: 11, color: PdfColors.grey700)),
          pw.TextSpan(text: value, style: pw.TextStyle(font: regular, fontSize: 11, color: PdfColors.grey900)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
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

  Future<void> _logActivity(Map userData, String realm, String certId, String realmId) async {
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