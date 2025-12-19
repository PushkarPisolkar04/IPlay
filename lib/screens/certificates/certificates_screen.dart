import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/design/app_design_system.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/certificate_service.dart';
import '../../core/models/certificate_model.dart';
import '../../widgets/loading_skeleton.dart';
import 'package:intl/intl.dart';
import 'certificate_viewer_screen.dart';

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
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final certificates = await _certificateService.getUserCertificates(
        userId,
      );

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

      // Use certificate service download which uses FileDownloadService
      final savedPath = await _certificateService.downloadCertificate(
        certificate.id,
      );

      // Show success message
      if (mounted && savedPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Certificate saved to Downloads folder!'),
            backgroundColor: AppDesignSystem.success,
            duration: const Duration(seconds: 3),
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

  Future<void> _regenerateCertificate(CertificateModel certificate) async {
    try {
      // Show confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Regenerate Certificate?'),
          content: const Text(
            'This will regenerate your certificate with the latest design and data. '
            'Your certificate number will remain the same.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppDesignSystem.primaryIndigo,
              ),
              child: const Text('Regenerate'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Show loading
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
              Text('Regenerating certificate...'),
            ],
          ),
          duration: Duration(seconds: 3),
        ),
      );

      // Regenerate by generating a new certificate for the same realm
      await _certificateService.generateRealmCertificate(
        realmId: certificate.realmId,
        realmName: certificate.realmName,
      );

      // Reload certificates
      await _loadCertificates();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Certificate regenerated successfully!'),
            backgroundColor: AppDesignSystem.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Regeneration failed: ${e.toString()}'),
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
      final pdfBytes = await _certificateService.getCertificatePdfBytes(
        certificate.id,
      );

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
        text:
            'I completed the ${certificate.realmName} realm on IPlay! 🎉\n\n'
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
    // Navigate to certificate viewer screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CertificateViewerScreen(
          certificate: certificate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Certificates',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppDesignSystem.primaryIndigo,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
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
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppDesignSystem.textSecondary,
            ),
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
            Text('No Certificates Yet', style: AppTextStyles.h1),
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
          onRegenerate: () => _regenerateCertificate(certificate),
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
  final VoidCallback onRegenerate;

  const _CertificateCard({
    required this.certificate,
    required this.onTap,
    required this.onDownload,
    required this.onShare,
    required this.onRegenerate,
  });

  String _getRealmLogo(String realmId) {
    switch (realmId) {
      case 'realm_copyright':
        return 'assets/logos/copyright_logo.png';
      case 'realm_trademark':
        return 'assets/logos/trademark_logo.png';
      case 'realm_patent':
        return 'assets/logos/patent_logo.png';
      case 'realm_design':
        return 'assets/logos/design_logo.png';
      case 'realm_gi':
        return 'assets/logos/gi_logo.png';
      case 'realm_trade_secrets':
        return 'assets/logos/trade_secrets_logo.png';
      default:
        return 'assets/logos/logo.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Realm logo
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppDesignSystem.primaryIndigo.withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Image.asset(
                        _getRealmLogo(certificate.realmId),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.workspace_premium,
                          size: 28,
                          color: AppDesignSystem.primaryIndigo,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Certificate info - Expanded to prevent overflow
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          certificate.realmName,
                          style: AppTextStyles.h3.copyWith(fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Cert #${certificate.certificateNumber}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppDesignSystem.textSecondary,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('MMM dd, yyyy').format(certificate.issuedAt),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppDesignSystem.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppDesignSystem.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      certificate.certificateType.toUpperCase(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppDesignSystem.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Action buttons - 3 buttons in a row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDownload,
                      icon: const Icon(Icons.download, size: 14),
                      label: const Text(
                        'Download',
                        style: TextStyle(fontSize: 11),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppDesignSystem.primaryIndigo,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onShare,
                      icon: const Icon(Icons.share, size: 14),
                      label: const Text(
                        'Share',
                        style: TextStyle(fontSize: 11),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppDesignSystem.primaryIndigo,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onRegenerate,
                      icon: const Icon(Icons.refresh, size: 14),
                      label: const Text(
                        'Regen',
                        style: TextStyle(fontSize: 11),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppDesignSystem.primaryPink,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        minimumSize: const Size(0, 32),
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
