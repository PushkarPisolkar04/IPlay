import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/certificate_service.dart';
import '../../core/models/certificate_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_skeleton.dart';
import 'package:intl/intl.dart';

class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  final CertificateService _certificateService = CertificateService();
  
  List<CertificateModel> _certificates = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  Future<void> _loadCertificates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = Provider.of<AuthProvider>(context, listen: false).currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final certificates = await _certificateService.getUserCertificates(userId);
      
      setState(() {
        _certificates = certificates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadCertificate(CertificateModel certificate) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Downloading certificate...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Get PDF bytes from Firestore
      final pdfBytes = await _certificateService.getCertificatePdfBytes(certificate.id);
      
      if (pdfBytes == null) {
        throw Exception('Certificate PDF not found');
      }

      // Get downloads directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage');
      }

      // Create file path
      final fileName = 'IPlay_Certificate_${certificate.certificateNumber}.pdf';
      final filePath = '${directory.path}/$fileName';

      // Write PDF to file
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Certificate saved to: $filePath'),
            backgroundColor: AppDesignSystem.success,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Share',
              textColor: Colors.white,
              onPressed: () => _shareCertificate(certificate),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: ${e.toString()}'),
            backgroundColor: AppDesignSystem.error,
          ),
        );
      }
    }
  }

  Future<void> _shareCertificate(CertificateModel certificate) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Preparing to share...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Get PDF bytes from Firestore
      final pdfBytes = await _certificateService.getCertificatePdfBytes(certificate.id);
      
      if (pdfBytes == null) {
        throw Exception('Certificate PDF not found');
      }

      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final fileName = 'IPlay_Certificate_${certificate.certificateNumber}.pdf';
      final filePath = '${directory.path}/$fileName';

      // Write PDF to temporary file
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      // Share the file with text
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'I completed the ${certificate.realmName} realm on IPlay! 🎉\n\n'
            'Certificate #${certificate.certificateNumber}\n'
            'Verify at: https://iplay.app/verify/${certificate.certificateNumber}\n\n'
            'Download IPlay to learn IPR the fun way!',
        subject: 'IPlay Certificate - ${certificate.realmName}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Share failed: ${e.toString()}'),
            backgroundColor: AppDesignSystem.error,
          ),
        );
      }
    }
  }

  Future<void> _viewCertificate(CertificateModel certificate) async {
    try {
      final url = await _certificateService.getCertificateDownloadUrl(certificate.id);
      
      // Show certificate details dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(certificate.realmName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Certificate Number: ${certificate.certificateNumber}'),
              const SizedBox(height: 8),
              Text('Issued: ${DateFormat('MMM dd, yyyy').format(certificate.issuedAt)}'),
              const SizedBox(height: 8),
              Text('Type: ${certificate.certificateType.toUpperCase()}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _downloadCertificate(certificate);
              },
              child: const Text('Download'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Certificates'),
        backgroundColor: AppDesignSystem.primaryIndigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const GridSkeleton(itemCount: 6, crossAxisCount: 1)
          : _error != null
              ? _buildErrorState()
              : _certificates.isEmpty
                  ? _buildEmptyState()
                  : _buildCertificatesList(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppDesignSystem.textSecondary),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadCertificates,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.workspace_premium_outlined,
              size: 80,
              color: AppDesignSystem.textSecondary,
            ),
            const SizedBox(height: 24),
            Text(
              'No Certificates Yet',
              style: AppTextStyles.h1,
            ),
            const SizedBox(height: 16),
            Text(
              'Complete realms to earn certificates!\nEach completed realm awards you a certificate of achievement.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppDesignSystem.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificatesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _certificates.length,
      itemBuilder: (context, index) {
        final certificate = _certificates[index];
        return _CertificateCard(
          certificate: certificate,
          onTap: () => _viewCertificate(certificate),
          onDownload: () => _downloadCertificate(certificate),
          onShare: () => _shareCertificate(certificate),
        );
      },
    );
  }
}

class _CertificateCard extends StatelessWidget {
  final CertificateModel certificate;
  final VoidCallback onTap;
  final VoidCallback onDownload;
  final VoidCallback onShare;

  const _CertificateCard({
    required this.certificate,
    required this.onTap,
    required this.onDownload,
    required this.onShare,
  });

  String _getRealmEmoji(String realmId) {
    switch (realmId) {
      case 'realm_copyright':
        return '©️';
      case 'realm_trademark':
        return '™️';
      case 'realm_patent':
        return '💡';
      case 'realm_design':
        return '🎨';
      case 'realm_gi':
        return '🌍';
      case 'realm_secrets':
        return '🔒';
      default:
        return '🏆';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Emoji icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppDesignSystem.primaryIndigo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        _getRealmEmoji(certificate.realmId),
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Certificate info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          certificate.realmName,
                          style: AppTextStyles.h3,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Certificate #${certificate.certificateNumber}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppDesignSystem.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Issued: ${DateFormat('MMM dd, yyyy').format(certificate.issuedAt)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppDesignSystem.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppDesignSystem.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      certificate.certificateType.toUpperCase(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppDesignSystem.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDownload,
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Download'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppDesignSystem.primaryIndigo,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onShare,
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('Share'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppDesignSystem.primaryIndigo,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

