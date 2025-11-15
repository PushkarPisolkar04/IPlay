import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'drawing_controller.dart';

/// HSV Color Picker Widget
class ColorPickerWidget extends StatefulWidget {
  final DrawingController controller;
  final List<Color>? presetColors;

  const ColorPickerWidget({
    super.key,
    required this.controller,
    this.presetColors,
  });

  @override
  State<ColorPickerWidget> createState() => _ColorPickerWidgetState();
}

class _ColorPickerWidgetState extends State<ColorPickerWidget> {
  late HSVColor _currentHSV;
  final List<Color> _recentColors = [];

  @override
  void initState() {
    super.initState();
    _currentHSV = HSVColor.fromColor(widget.controller.currentColor);
  }

  void _updateColor(Color color) {
    widget.controller.setColor(color);
    _currentHSV = HSVColor.fromColor(color);
    
    // Add to recent colors
    if (!_recentColors.contains(color)) {
      _recentColors.insert(0, color);
      if (_recentColors.length > 8) {
        _recentColors.removeLast();
      }
    }
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Color',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // Current color display
        Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: widget.controller.currentColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!, width: 2),
          ),
        ),

        const SizedBox(height: 16),

        // Preset colors
        if (widget.presetColors != null && widget.presetColors!.isNotEmpty) ...[
          const Text(
            'Preset Colors',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.presetColors!.map((color) {
              return _buildColorCircle(color, 36);
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Recent colors
        if (_recentColors.isNotEmpty) ...[
          const Text(
            'Recent Colors',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentColors.map((color) {
              return _buildColorCircle(color, 32);
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // HSV Color Wheel
        const Text(
          'Color Wheel',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: GestureDetector(
            onPanDown: _handleColorWheelInteraction,
            onPanUpdate: _handleColorWheelInteraction,
            child: CustomPaint(
              painter: ColorWheelPainter(currentHSV: _currentHSV),
              size: const Size(200, 200),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Saturation slider
        const Text(
          'Saturation',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Colors.teal,
            inactiveTrackColor: Colors.grey[300],
            thumbColor: Colors.teal,
            overlayColor: Colors.teal.withValues(alpha: 0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: _currentHSV.saturation,
            onChanged: (value) {
              _updateColor(_currentHSV.withSaturation(value).toColor());
            },
          ),
        ),

        const SizedBox(height: 8),

        // Value (brightness) slider
        const Text(
          'Brightness',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Colors.teal,
            inactiveTrackColor: Colors.grey[300],
            thumbColor: Colors.teal,
            overlayColor: Colors.teal.withValues(alpha: 0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: _currentHSV.value,
            onChanged: (value) {
              _updateColor(_currentHSV.withValue(value).toColor());
            },
          ),
        ),
      ],
    );
  }

  Widget _buildColorCircle(Color color, double size) {
    final isSelected = widget.controller.currentColor == color;

    return GestureDetector(
      onTap: () => _updateColor(color),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.teal : Colors.grey[300]!,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.teal.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
      ),
    );
  }

  void _handleColorWheelInteraction(dynamic details) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    // Find the color wheel widget position
    // This is a simplified version - adjust based on actual layout
    final center = Offset(
      renderBox.size.width / 2,
      localPosition.dy,
    );

    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final radius = 100.0; // Half of color wheel size

    if (distance <= radius) {
      final angle = math.atan2(dy, dx);
      final hue = (angle * 180 / math.pi + 360) % 360;

      _updateColor(_currentHSV.withHue(hue).toColor());
    }
  }
}

/// Custom painter for HSV color wheel
class ColorWheelPainter extends CustomPainter {
  final HSVColor currentHSV;

  ColorWheelPainter({required this.currentHSV});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw color wheel
    for (double i = 0; i < 360; i += 1) {
      final hue = i;
      final color = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      final startAngle = (i - 90) * math.pi / 180;
      final sweepAngle = 1 * math.pi / 180;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }

    // Draw inner white circle for saturation/value
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.7, innerPaint);

    // Draw current color indicator
    final angle = (currentHSV.hue - 90) * math.pi / 180;
    final indicatorX = center.dx + radius * math.cos(angle);
    final indicatorY = center.dy + radius * math.sin(angle);

    final indicatorPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final indicatorBorderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(Offset(indicatorX, indicatorY), 8, indicatorPaint);
    canvas.drawCircle(Offset(indicatorX, indicatorY), 8, indicatorBorderPaint);
  }

  @override
  bool shouldRepaint(ColorWheelPainter oldDelegate) {
    return oldDelegate.currentHSV != currentHSV;
  }
}

/// Simple color grid picker (alternative to wheel)
class ColorGridPicker extends StatelessWidget {
  final DrawingController controller;
  final List<Color> colors;

  const ColorGridPicker({
    super.key,
    required this.controller,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((color) {
            final isSelected = controller.currentColor == color;

            return GestureDetector(
              onTap: () => controller.setColor(color),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.teal : Colors.grey[300]!,
                    width: isSelected ? 3 : 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.teal.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
