import 'package:flutter/material.dart';

class AppTourTooltip extends StatelessWidget {
  final String message;
  final Widget child;
  final VoidCallback? onDismiss;
  final bool show;

  const AppTourTooltip({
    super.key,
    required this.message,
    required this.child,
    this.onDismiss,
    this.show = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) return child;

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        Positioned(
          top: -40,
          left: 0,
          right: 0,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  if (onDismiss != null)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 16),
                      onPressed: onDismiss,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
