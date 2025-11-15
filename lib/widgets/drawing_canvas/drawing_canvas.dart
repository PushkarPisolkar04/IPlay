import 'package:flutter/material.dart';
import 'drawing_controller.dart';

/// Custom painter for rendering drawing elements
class DrawingCanvasPainter extends CustomPainter {
  final DrawingController controller;
  final bool showGrid;
  final int gridSize;
  final Color gridColor;

  DrawingCanvasPainter({
    required this.controller,
    this.showGrid = false,
    this.gridSize = 20,
    this.gridColor = Colors.grey,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw grid if enabled
    if (showGrid) {
      _drawGrid(canvas, size);
    }

    // Draw all layers
    for (var layer in controller.layers.values) {
      for (var element in layer) {
        element.draw(canvas);
      }
    }

    // Draw temporary element (shape being drawn)
    if (controller.tempElement != null) {
      controller.tempElement!.draw(canvas);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    // Vertical lines
    for (double x = 0; x <= size.width; x += gridSize.toDouble()) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Horizontal lines
    for (double y = 0; y <= size.height; y += gridSize.toDouble()) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(DrawingCanvasPainter oldDelegate) => true;
}

/// Interactive drawing canvas widget
class DrawingCanvas extends StatefulWidget {
  final DrawingController controller;
  final double width;
  final double height;
  final Color backgroundColor;
  final bool showGrid;
  final int gridSize;
  final Color gridColor;

  const DrawingCanvas({
    super.key,
    required this.controller,
    this.width = double.infinity,
    this.height = 400,
    this.backgroundColor = Colors.white,
    this.showGrid = false,
    this.gridSize = 20,
    this.gridColor = Colors.grey,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        border: Border.all(color: Colors.grey[300]!, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: GestureDetector(
          onPanStart: (details) {
            widget.controller.startDrawing(details.localPosition);
          },
          onPanUpdate: (details) {
            widget.controller.updateDrawing(details.localPosition);
          },
          onPanEnd: (details) {
            widget.controller.endDrawing();
          },
          onTapDown: (details) {
            // For single tap tools
            widget.controller.startDrawing(details.localPosition);
          },
          onTapUp: (details) {
            widget.controller.endDrawing();
          },
          child: CustomPaint(
            painter: DrawingCanvasPainter(
              controller: widget.controller,
              showGrid: widget.showGrid,
              gridSize: widget.gridSize,
              gridColor: widget.gridColor,
            ),
            size: Size(widget.width, widget.height),
          ),
        ),
      ),
    );
  }
}
