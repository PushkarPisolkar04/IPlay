import 'package:flutter/material.dart';
import 'drawing_controller.dart';

/// Tool palette widget for selecting drawing tools
class DrawingToolsPalette extends StatelessWidget {
  final DrawingController controller;
  final Axis direction;

  const DrawingToolsPalette({
    super.key,
    required this.controller,
    this.direction = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final tools = [
          _ToolItem(
            tool: DrawingTool.pencil,
            icon: Icons.edit,
            label: 'Pencil',
          ),
          _ToolItem(
            tool: DrawingTool.brush,
            icon: Icons.brush,
            label: 'Brush',
          ),
          _ToolItem(
            tool: DrawingTool.eraser,
            icon: Icons.auto_fix_high,
            label: 'Eraser',
          ),
          _ToolItem(
            tool: DrawingTool.rectangle,
            icon: Icons.rectangle_outlined,
            label: 'Rectangle',
          ),
          _ToolItem(
            tool: DrawingTool.circle,
            icon: Icons.circle_outlined,
            label: 'Circle',
          ),
          _ToolItem(
            tool: DrawingTool.line,
            icon: Icons.horizontal_rule,
            label: 'Line',
          ),
          _ToolItem(
            tool: DrawingTool.polygon,
            icon: Icons.pentagon_outlined,
            label: 'Polygon',
          ),
        ];

        if (direction == Axis.vertical) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: tools.map((item) => _buildToolButton(item)).toList(),
          );
        } else {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: tools.map((item) => _buildToolButton(item)).toList(),
          );
        }
      },
    );
  }

  Widget _buildToolButton(_ToolItem item) {
    final isSelected = controller.currentTool == item.tool;

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Tooltip(
        message: item.label,
        child: InkWell(
          onTap: () => controller.setTool(item.tool),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected ? Colors.teal : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.teal : Colors.grey[300]!,
                width: 2,
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
            child: Icon(
              item.icon,
              color: isSelected ? Colors.white : Colors.grey[700],
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolItem {
  final DrawingTool tool;
  final IconData icon;
  final String label;

  _ToolItem({
    required this.tool,
    required this.icon,
    required this.label,
  });
}

/// Stroke width adjustment slider
class StrokeWidthSlider extends StatelessWidget {
  final DrawingController controller;
  final double min;
  final double max;

  const StrokeWidthSlider({
    super.key,
    required this.controller,
    this.min = 1,
    this.max = 20,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Stroke Width',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${controller.strokeWidth.toInt()}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
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
                value: controller.strokeWidth,
                min: min,
                max: max,
                divisions: (max - min).toInt(),
                onChanged: (value) => controller.setStrokeWidth(value),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Opacity control slider
class OpacitySlider extends StatelessWidget {
  final DrawingController controller;

  const OpacitySlider({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Opacity',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${(controller.opacity * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
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
                value: controller.opacity,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                onChanged: (value) => controller.setOpacity(value),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Fill toggle for shapes
class FillToggle extends StatelessWidget {
  final DrawingController controller;

  const FillToggle({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        // Only show for shape tools
        final isShapeTool = controller.currentTool == DrawingTool.rectangle ||
            controller.currentTool == DrawingTool.circle ||
            controller.currentTool == DrawingTool.polygon;

        if (!isShapeTool) {
          return const SizedBox.shrink();
        }

        return Row(
          children: [
            const Text(
              'Fill Shape',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Switch(
              value: controller.filled,
              onChanged: (value) => controller.setFilled(value),
              activeColor: Colors.teal,
            ),
          ],
        );
      },
    );
  }
}
