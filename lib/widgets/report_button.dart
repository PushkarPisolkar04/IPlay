import 'package:flutter/material.dart';
import '../core/design/app_design_system.dart';
import '../screens/reports/report_content_screen.dart';

class ReportButton extends StatelessWidget {
  final String reportType;
  final String reportedItemId;

  const ReportButton({
    super.key,
    required this.reportType,
    required this.reportedItemId,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.flag_outlined, size: 20),
      color: AppDesignSystem.textSecondary,
      tooltip: 'Report',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportContentScreen(
              reportType: reportType,
              reportedItemId: reportedItemId,
            ),
          ),
        );
      },
    );
  }
}

