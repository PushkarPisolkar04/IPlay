import 'package:flutter/material.dart';
import '../core/design/app_design_system.dart';
import '../core/constants/app_text_styles.dart';

/// Upload progress indicator widget
class UploadProgressIndicator extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String? fileName;
  final String? statusText;
  final VoidCallback? onCancel;

  const UploadProgressIndicator({
    super.key,
    required this.progress,
    this.fileName,
    this.statusText,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                color: AppDesignSystem.primaryIndigo,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText ?? 'Uploading...',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (fileName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        fileName!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppDesignSystem.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (onCancel != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onCancel,
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppDesignSystem.backgroundGrey,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppDesignSystem.primaryIndigo,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toInt()}%',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppDesignSystem.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact upload progress for inline display
class CompactUploadProgress extends StatelessWidget {
  final double progress;
  final String? label;

  const CompactUploadProgress({
    super.key,
    required this.progress,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppDesignSystem.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppDesignSystem.backgroundGrey,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppDesignSystem.primaryIndigo,
                  ),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(progress * 100).toInt()}%',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Circular upload progress
class CircularUploadProgress extends StatelessWidget {
  final double progress;
  final double size;
  final Color? color;

  const CircularUploadProgress({
    super.key,
    required this.progress,
    this.size = 40,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            backgroundColor: AppDesignSystem.backgroundGrey,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? AppDesignSystem.primaryIndigo,
            ),
            strokeWidth: 3,
          ),
          Text(
            '${(progress * 100).toInt()}%',
            style: TextStyle(
              fontSize: size * 0.25,
              fontWeight: FontWeight.bold,
              color: color ?? AppDesignSystem.primaryIndigo,
            ),
          ),
        ],
      ),
    );
  }
}
