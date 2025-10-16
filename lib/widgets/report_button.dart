import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../screens/reports/report_content_screen.dart';

class ReportButton extends StatelessWidget {
  final String reportType;
  final String reportedItemId;

  const ReportButton({
    Key? key,
    required this.reportType,
    required this.reportedItemId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.flag_outlined, size: 20),
      color: AppColors.textSecondary,
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

