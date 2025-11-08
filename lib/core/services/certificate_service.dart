import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart' show Color;
import 'dart:convert';
import 'dart:typed_data';
import '../models/certificate_model.dart';

/// Service for certificates with client-side PDF generation
class CertificateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get certificate by ID
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

  /// Get all certificates for a user
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

  /// Get certificates by realm
  Future<List<CertificateModel>> getRealmCertificates(String realmId) async {
    try {
      final query = await _firestore
          .collection('certificates')
          .where('realmId', isEqualTo: realmId)
          .orderBy('issuedAt', descending: true)
          .get();

      return query.docs
          .map((doc) => CertificateModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get realm certificates: $e');
    }
  }

  /// Check if user has certificate for a realm
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
      throw Exception('Failed to check user realm certificate: $e');
    }
  }

  /// Get certificate by certificate number (for verification)
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

  /// Get certificate statistics for a user
  Future<Map<String, dynamic>> getUserCertificateStats(String userId) async {
    try {
      final certificates = await getUserCertificates(userId);

      final totalCertificates = certificates.length;
      final realmCertificates = certificates.where((c) => c.certificateType == 'realm').length;
      final moduleCertificates = certificates.where((c) => c.certificateType == 'module').length;
      final courseCertificates = certificates.where((c) => c.certificateType == 'course').length;

      return {
        'totalCertificates': totalCertificates,
        'realmCertificates': realmCertificates,
        'moduleCertificates': moduleCertificates,
        'courseCertificates': courseCertificates,
      };
    } catch (e) {
      throw Exception('Failed to get certificate stats: $e');
    }
  }

  /// Generate certificate PDF on client-side when student completes realm
  Future<CertificateModel> generateRealmCertificate({
    required String realmId,
    required String realmName,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Get user data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      if (userData == null) {
        throw Exception('User data not found');
      }

      // Generate unique certificate number
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final certificateNumber = 'IPLAY-${realmId.toUpperCase().replaceAll('_', '')}-$timestamp';
      final certificateId = '${user.uid}_$realmId';

      // Generate QR code
      final qrPainter = QrPainter(
        data: 'https://iplay.app/verify/$certificateNumber',
        version: QrVersions.auto,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Color(0xFF000000),
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Color(0xFF000000),
        ),
      );
      final qrImageBytes = await qrPainter.toImageData(200);

      // Create PDF
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (context) => pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue800, width: 10),
            ),
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'Certificate of Achievement',
                  style: pw.TextStyle(
                    fontSize: 48,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 30),
                pw.Divider(color: PdfColors.blue800, thickness: 2),
                pw.SizedBox(height: 30),
                pw.Text(
                  'This is to certify that',
                  style: const pw.TextStyle(fontSize: 20),
                ),
                pw.SizedBox(height: 15),
                pw.Text(
                  userData['displayName'] ?? 'Student',
                  style: pw.TextStyle(
                    fontSize: 36,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 15),
                pw.Text(
                  'has successfully completed',
                  style: const pw.TextStyle(fontSize: 20),
                ),
                pw.SizedBox(height: 15),
                pw.Text(
                  realmName,
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 30),
                pw.Divider(color: PdfColors.blue800, thickness: 2),
                pw.SizedBox(height: 30),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Certificate Number:',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                        pw.Text(
                          certificateNumber,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          'Date Issued:',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                        pw.Text(
                          DateTime.now().toString().split(' ')[0],
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        if (qrImageBytes != null)
                          pw.Image(
                            pw.MemoryImage(qrImageBytes.buffer.asUint8List()),
                            width: 100,
                            height: 100,
                          ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Scan to verify',
                          style: const pw.TextStyle(fontSize: 10),
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

      // Save PDF bytes
      final pdfBytes = await pdf.save();
      final pdfBase64 = base64Encode(pdfBytes);

      // Save certificate to Firestore
      final certificateData = {
        'id': certificateId,
        'userId': user.uid,
        'certificateType': 'realm',
        'realmId': realmId,
        'realmName': realmName,
        'certificateNumber': certificateNumber,
        'pdfData': pdfBase64, // Store as base64 in Firestore
        'issuedAt': Timestamp.now(),
        'status': 'generated',
      };

      await _firestore
          .collection('certificates')
          .doc(certificateId)
          .set(certificateData);

      return CertificateModel.fromFirestore(certificateData);
    } catch (e) {
      throw Exception('Failed to generate certificate: $e');
    }
  }

  /// Get certificate PDF bytes for download/sharing
  Future<Uint8List?> getCertificatePdfBytes(String certificateId) async {
    try {
      final doc = await _firestore
          .collection('certificates')
          .doc(certificateId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null || data['pdfData'] == null) return null;

      return base64Decode(data['pdfData']);
    } catch (e) {
      throw Exception('Failed to get certificate PDF: $e');
    }
  }
  
  /// Get certificate download URL (for compatibility with old code)
  Future<String?> getCertificateDownloadUrl(String certificateId) async {
    try {
      final pdfBytes = await getCertificatePdfBytes(certificateId);
      if (pdfBytes == null) return null;
      
      // Return data URL for web or save to temp file for mobile
      return 'data:application/pdf;base64,${base64Encode(pdfBytes)}';
    } catch (e) {
      throw Exception('Failed to get certificate URL: $e');
    }
  }

  /// Listen to certificate updates for a user (for real-time notifications)
  Stream<List<CertificateModel>> watchUserCertificates(String userId) {
    return _firestore
        .collection('certificates')
        .where('userId', isEqualTo: userId)
        .orderBy('issuedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CertificateModel.fromFirestore(doc.data()))
            .toList());
  }
}

