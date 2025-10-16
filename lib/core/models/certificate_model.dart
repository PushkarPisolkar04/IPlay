import 'package:cloud_firestore/cloud_firestore.dart';

/// Certificate model for realm completions
/// Collection: /certificates
class CertificateModel {
  final String id;
  final String userId;
  final String certificateType; // 'realm' | 'module' | 'course'
  final String realmId;
  final String realmName;
  final String certificateUrl; // PDF URL in Firebase Storage
  final String certificateNumber; // Unique certificate number
  final DateTime issuedAt;

  CertificateModel({
    required this.id,
    required this.userId,
    required this.certificateType,
    required this.realmId,
    required this.realmName,
    required this.certificateUrl,
    required this.certificateNumber,
    required this.issuedAt,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'certificateType': certificateType,
      'realmId': realmId,
      'realmName': realmName,
      'certificateUrl': certificateUrl,
      'certificateNumber': certificateNumber,
      'issuedAt': Timestamp.fromDate(issuedAt),
    };
  }

  /// Create from Firestore document
  factory CertificateModel.fromFirestore(Map<String, dynamic> data) {
    return CertificateModel(
      id: data['id'] as String,
      userId: data['userId'] as String,
      certificateType: data['certificateType'] as String,
      realmId: data['realmId'] as String,
      realmName: data['realmName'] as String,
      certificateUrl: data['certificateUrl'] as String,
      certificateNumber: data['certificateNumber'] as String,
      issuedAt: (data['issuedAt'] as Timestamp).toDate(),
    );
  }

  /// Create a copy with updated fields
  CertificateModel copyWith({
    String? id,
    String? userId,
    String? certificateType,
    String? realmId,
    String? realmName,
    String? certificateUrl,
    String? certificateNumber,
    DateTime? issuedAt,
  }) {
    return CertificateModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      certificateType: certificateType ?? this.certificateType,
      realmId: realmId ?? this.realmId,
      realmName: realmName ?? this.realmName,
      certificateUrl: certificateUrl ?? this.certificateUrl,
      certificateNumber: certificateNumber ?? this.certificateNumber,
      issuedAt: issuedAt ?? this.issuedAt,
    );
  }
}

