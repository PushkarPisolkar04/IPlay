import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/certificate_model.dart';

/// Service for certificates (client-side part)
/// Note: Certificate generation (PDF creation) is handled by Cloud Functions
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

  /// Download certificate PDF (returns the URL)
  /// Note: This is a simple getter. The actual PDF generation is done by Cloud Functions
  Future<String?> getCertificateDownloadUrl(String certificateId) async {
    try {
      final certificate = await getCertificate(certificateId);
      return certificate?.certificateUrl;
    } catch (e) {
      throw Exception('Failed to get certificate download URL: $e');
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

