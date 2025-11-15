import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:async';

/// Represents a drawing element (stroke or shape)
abstract class DrawingElement {
  final Paint paint;
  final String id;

  DrawingElement({required this.paint, required this.id});

  void draw(Canvas canvas);
}

/// Free-form stroke path
class StrokeElement extends DrawingElement {
  final List<Offset> points;

  StrokeElement({
    required this.points,
    required super.paint,
    required super.id,
  });

  @override
  void draw(Canvas canvas) {
    if (points.length < 2) return;

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }
}

/// Rectangle shape
class RectangleElement extends DrawingElement {
  final Offset start;
  final Offset end;
  final bool filled;

  RectangleElement({
    required this.start,
    required this.end,
    required this.filled,
    required super.paint,
    required super.id,
  });

  @override
  void draw(Canvas canvas) {
    final rect = Rect.fromPoints(start, end);
    if (filled) {
      canvas.drawRect(rect, paint..style = PaintingStyle.fill);
    } else {
      canvas.drawRect(rect, paint..style = PaintingStyle.stroke);
    }
  }
}

/// Circle shape
class CircleElement extends DrawingElement {
  final Offset center;
  final double radius;
  final bool filled;

  CircleElement({
    required this.center,
    required this.radius,
    required this.filled,
    required super.paint,
    required super.id,
  });

  @override
  void draw(Canvas canvas) {
    if (filled) {
      canvas.drawCircle(center, radius, paint..style = PaintingStyle.fill);
    } else {
      canvas.drawCircle(center, radius, paint..style = PaintingStyle.stroke);
    }
  }
}

/// Line shape
class LineElement extends DrawingElement {
  final Offset start;
  final Offset end;

  LineElement({
    required this.start,
    required this.end,
    required super.paint,
    required super.id,
  });

  @override
  void draw(Canvas canvas) {
    canvas.drawLine(start, end, paint);
  }
}

/// Polygon shape
class PolygonElement extends DrawingElement {
  final List<Offset> vertices;
  final bool filled;

  PolygonElement({
    required this.vertices,
    required this.filled,
    required super.paint,
    required super.id,
  });

  @override
  void draw(Canvas canvas) {
    if (vertices.length < 3) return;

    final path = Path();
    path.moveTo(vertices[0].dx, vertices[0].dy);

    for (int i = 1; i < vertices.length; i++) {
      path.lineTo(vertices[i].dx, vertices[i].dy);
    }
    path.close();

    if (filled) {
      canvas.drawPath(path, paint..style = PaintingStyle.fill);
    } else {
      canvas.drawPath(path, paint..style = PaintingStyle.stroke);
    }
  }
}

/// Drawing tool types
enum DrawingTool {
  pencil,
  brush,
  eraser,
  rectangle,
  circle,
  line,
  polygon,
}

/// Controller for managing drawing state
class DrawingController extends ChangeNotifier {
  // Drawing elements organized by layers
  final Map<String, List<DrawingElement>> _layers = {};
  String _currentLayerId = 'layer_0';
  
  // Undo/redo stacks (max 20 actions)
  final List<Map<String, List<DrawingElement>>> _undoStack = [];
  final List<Map<String, List<DrawingElement>>> _redoStack = [];
  static const int maxHistorySize = 20;

  // Current drawing state
  DrawingTool _currentTool = DrawingTool.pencil;
  Color _currentColor = Colors.black;
  double _strokeWidth = 3.0;
  double _opacity = 1.0;
  bool _filled = false;

  // Temporary drawing element (for shapes being drawn)
  DrawingElement? _tempElement;
  List<Offset> _tempPoints = [];

  DrawingController() {
    // Initialize with one layer
    _layers[_currentLayerId] = [];
  }

  // Getters
  DrawingTool get currentTool => _currentTool;
  Color get currentColor => _currentColor;
  double get strokeWidth => _strokeWidth;
  double get opacity => _opacity;
  bool get filled => _filled;
  String get currentLayerId => _currentLayerId;
  Map<String, List<DrawingElement>> get layers => Map.unmodifiable(_layers);
  DrawingElement? get tempElement => _tempElement;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  // Setters
  void setTool(DrawingTool tool) {
    _currentTool = tool;
    notifyListeners();
  }

  void setColor(Color color) {
    _currentColor = color;
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    _strokeWidth = width;
    notifyListeners();
  }

  void setOpacity(double opacity) {
    _opacity = opacity.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setFilled(bool filled) {
    _filled = filled;
    notifyListeners();
  }

  void setCurrentLayer(String layerId) {
    if (_layers.containsKey(layerId)) {
      _currentLayerId = layerId;
      notifyListeners();
    }
  }

  // Layer management
  void addLayer(String layerId) {
    if (!_layers.containsKey(layerId)) {
      _saveState();
      _layers[layerId] = [];
      notifyListeners();
    }
  }

  void removeLayer(String layerId) {
    if (_layers.containsKey(layerId) && _layers.length > 1) {
      _saveState();
      _layers.remove(layerId);
      if (_currentLayerId == layerId) {
        _currentLayerId = _layers.keys.first;
      }
      notifyListeners();
    }
  }

  void clearLayer(String layerId) {
    if (_layers.containsKey(layerId)) {
      _saveState();
      _layers[layerId]!.clear();
      notifyListeners();
    }
  }

  void clearAllLayers() {
    _saveState();
    for (var layer in _layers.values) {
      layer.clear();
    }
    notifyListeners();
  }

  // Drawing operations
  void startDrawing(Offset point) {
    _tempPoints = [point];

    if (_currentTool == DrawingTool.pencil ||
        _currentTool == DrawingTool.brush ||
        _currentTool == DrawingTool.eraser) {
      // For free-form tools, start collecting points
      _tempPoints = [point];
    } else {
      // For shapes, store the starting point
      _tempPoints = [point];
    }
  }

  void updateDrawing(Offset point) {
    if (_tempPoints.isEmpty) return;

    final paint = _createPaint();
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    switch (_currentTool) {
      case DrawingTool.pencil:
      case DrawingTool.brush:
        _tempPoints.add(point);
        _tempElement = StrokeElement(
          points: List.from(_tempPoints),
          paint: paint,
          id: id,
        );
        break;

      case DrawingTool.eraser:
        _tempPoints.add(point);
        final eraserPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = _strokeWidth * 2
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        _tempElement = StrokeElement(
          points: List.from(_tempPoints),
          paint: eraserPaint,
          id: id,
        );
        break;

      case DrawingTool.rectangle:
        _tempElement = RectangleElement(
          start: _tempPoints[0],
          end: point,
          filled: _filled,
          paint: paint,
          id: id,
        );
        break;

      case DrawingTool.circle:
        final radius = (point - _tempPoints[0]).distance;
        _tempElement = CircleElement(
          center: _tempPoints[0],
          radius: radius,
          filled: _filled,
          paint: paint,
          id: id,
        );
        break;

      case DrawingTool.line:
        _tempElement = LineElement(
          start: _tempPoints[0],
          end: point,
          paint: paint,
          id: id,
        );
        break;

      case DrawingTool.polygon:
        // For polygon, collect multiple points
        // This is a simplified version - could be enhanced
        break;
    }

    notifyListeners();
  }

  void endDrawing() {
    if (_tempElement != null) {
      _saveState();
      _layers[_currentLayerId]!.add(_tempElement!);
      _tempElement = null;
      _tempPoints = [];
      notifyListeners();
    }
  }

  void cancelDrawing() {
    _tempElement = null;
    _tempPoints = [];
    notifyListeners();
  }

  // Undo/Redo
  void undo() {
    if (_undoStack.isEmpty) return;

    // Save current state to redo stack
    _redoStack.add(_copyLayers());
    if (_redoStack.length > maxHistorySize) {
      _redoStack.removeAt(0);
    }

    // Restore previous state
    final previousState = _undoStack.removeLast();
    _layers.clear();
    _layers.addAll(previousState);

    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;

    // Save current state to undo stack
    _undoStack.add(_copyLayers());
    if (_undoStack.length > maxHistorySize) {
      _undoStack.removeAt(0);
    }

    // Restore next state
    final nextState = _redoStack.removeLast();
    _layers.clear();
    _layers.addAll(nextState);

    notifyListeners();
  }

  // Export to image
  Future<Uint8List?> exportToImage({
    required double width,
    required double height,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw white background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, height),
      Paint()..color = Colors.white,
    );

    // Draw all layers
    for (var layer in _layers.values) {
      for (var element in layer) {
        element.draw(canvas);
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData?.buffer.asUint8List();
  }

  // Private helpers
  Paint _createPaint() {
    return Paint()
      ..color = _currentColor.withValues(alpha: _opacity)
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
  }

  void _saveState() {
    _undoStack.add(_copyLayers());
    if (_undoStack.length > maxHistorySize) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  Map<String, List<DrawingElement>> _copyLayers() {
    final copy = <String, List<DrawingElement>>{};
    for (var entry in _layers.entries) {
      copy[entry.key] = List.from(entry.value);
    }
    return copy;
  }

  @override
  void dispose() {
    _layers.clear();
    _undoStack.clear();
    _redoStack.clear();
    super.dispose();
  }
}
