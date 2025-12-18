import 'package:flutter/material.dart';

/// Dialog to select export format (PDF, CSV, or Excel)
class ExportFormatDialog extends StatelessWidget {
  final String title;
  final VoidCallback onPdfExport;
  final VoidCallback onCsvExport;
  final VoidCallback onExcelExport;
  final bool showPdf;
  final bool showCsv;
  final bool showExcel;

  const ExportFormatDialog({
    super.key,
    required this.title,
    required this.onPdfExport,
    required this.onCsvExport,
    required this.onExcelExport,
    this.showPdf = true,
    this.showCsv = true,
    this.showExcel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.download, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Choose Export Format',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),

            // Export options
            if (showPdf) _buildExportOption(
              context,
              icon: Icons.picture_as_pdf,
              label: 'PDF Document',
              description: 'Professional formatted report',
              color: const Color(0xFFEF4444),
              onTap: () {
                Navigator.pop(context);
                onPdfExport();
              },
            ),
            if (showPdf && (showCsv || showExcel)) const SizedBox(height: 12),

            if (showCsv) _buildExportOption(
              context,
              icon: Icons.table_chart,
              label: 'CSV Spreadsheet',
              description: 'Compatible with Excel, Sheets',
              color: const Color(0xFF10B981),
              onTap: () {
                Navigator.pop(context);
                onCsvExport();
              },
            ),
            if (showCsv && showExcel) const SizedBox(height: 12),

            if (showExcel) _buildExportOption(
              context,
              icon: Icons.grid_on,
              label: 'Excel Workbook',
              description: 'Native .xlsx format',
              color: const Color(0xFF3B82F6),
              onTap: () {
                Navigator.pop(context);
                onExcelExport();
              },
            ),

            const SizedBox(height: 20),

            // Cancel button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}
