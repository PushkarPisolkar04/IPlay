import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../../core/design/app_design_system.dart';
import '../../core/models/certificate_model.dart';
import '../../core/services/certificate_service.dart';
import 'package:intl/intl.dart';

class CertificateViewerScreen extends StatefulWidget {
  final CertificateModel certificate;

  const CertificateViewerScreen({
    super.key,
    required this.certificate,
  });

  @override
  State<CertificateViewerScreen> createState() => _CertificateViewerScreenState();
}

class _CertificateViewerScreenState extends State<CertificateViewerScreen> {
  final CertificateService _certificateService = CertificateService();
  bool _isLoading = true;
  String? _error;
  Uint8List? _pdfBytes;

  @override
  void initState() {
    super.initState();
    _loadCertificate();
  }

  Future<void> _loadCertificate() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final bytes = await _certificateService.getCertificatePdfBytes(
        widget.certificate.id,
      );

      if (bytes == null) {
        throw Exception('Certificate not found');
      }

      setState(() {
        _pdfBytes = Uint8List.fromList(bytes);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadCertificate() async {
    try {
      if (_pdfBytes == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading certificate...')),
      );

      await _certificateService.downloadCertificate(widget.certificate.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Certificate saved to Downloads!'),
            backgroundColor: AppDesignSystem.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: AppDesignSystem.error,
          ),
        );
      }
    }
  }

  Future<void> _shareCertificate() async {
    try {
      if (_pdfBytes == null) return;

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/IPlay_Certificate_${widget.certificate.certificateNumber}.pdf',
      );
      await tempFile.writeAsBytes(_pdfBytes!);

      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: 'I completed the ${widget.certificate.realmName} realm on IPlay! 🎉\\n'
            'Certificate #${widget.certificate.certificateNumber}',
        subject: 'IPlay Certificate - ${widget.certificate.realmName}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Share failed: $e'),
            backgroundColor: AppDesignSystem.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          widget.certificate.realmName,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppDesignSystem.primaryIndigo,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _pdfBytes != null ? _shareCertificate : null,
            tooltip: 'Share',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _pdfBytes != null ? _downloadCertificate : null,
            tooltip: 'Download',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppDesignSystem.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load certificate',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadCertificate,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Certificate info card
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppDesignSystem.primaryIndigo.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.workspace_premium,
                              size: 32,
                              color: AppDesignSystem.primaryIndigo,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.certificate.certificateNumber,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Issued: ${DateFormat('MMMM dd, yyyy').format(widget.certificate.issuedAt)}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // PDF Preview
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: PdfPreview(
                            build: (format) => _pdfBytes!,
                            allowSharing: false,
                            allowPrinting: false,
                            canChangePageFormat: false,
                            canChangeOrientation: false,
                            canDebug: false,
                            pdfFileName: 'IPlay_Certificate_${widget.certificate.certificateNumber}.pdf',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
    );
  }
}
