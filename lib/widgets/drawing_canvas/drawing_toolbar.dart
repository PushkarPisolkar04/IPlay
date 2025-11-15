import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'drawing_controller.dart';

/// Top toolbar with undo/redo and save functionality
class DrawingToolbar extends StatelessWidget {
  final DrawingController controller;
  final VoidCallback? onSave;
  final VoidCallback? onExport;
  final VoidCallback? onClear;

  const DrawingToolbar({
    super.key,
    required this.controller,
    this.onSave,
    this.onExport,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
          ),
          child: Row(
            children: [
              // Undo button
              IconButton(
                icon: const Icon(Icons.undo),
                onPressed: controller.canUndo ? () => controller.undo() : null,
                tooltip: 'Undo',
                color: controller.canUndo ? Colors.teal : Colors.grey,
              ),

              // Redo button
              IconButton(
                icon: const Icon(Icons.redo),
                onPressed: controller.canRedo ? () => controller.redo() : null,
                tooltip: 'Redo',
                color: controller.canRedo ? Colors.teal : Colors.grey,
              ),

              const VerticalDivider(),

              // Clear button
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _showClearConfirmation(context),
                tooltip: 'Clear All',
                color: Colors.red,
              ),

              const Spacer(),

              // Save button
              if (onSave != null)
                TextButton.icon(
                  icon: const Icon(Icons.save, size: 20),
                  label: const Text('Save'),
                  onPressed: onSave,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.teal,
                  ),
                ),

              const SizedBox(width: 8),

              // Export button
              if (onExport != null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.download, size: 20),
                  label: const Text('Export'),
                  onPressed: onExport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Canvas'),
        content: const Text('Are you sure you want to clear all layers? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.clearAllLayers();
              Navigator.pop(context);
              if (onClear != null) onClear!();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

/// Service for saving and loading drawings
class DrawingStorageService {
  static const String _storageKey = 'saved_drawings';
  static const String _drawingsDir = 'drawings';

  /// Save drawing to local storage
  Future<bool> saveDrawing({
    required String name,
    required DrawingController controller,
    required double width,
    required double height,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing drawings
      final drawingsJson = prefs.getString(_storageKey);
      final drawings = drawingsJson != null
          ? List<Map<String, dynamic>>.from(json.decode(drawingsJson))
          : <Map<String, dynamic>>[];

      // Create drawing metadata
      final drawingData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': name,
        'createdAt': DateTime.now().toIso8601String(),
        'width': width,
        'height': height,
      };

      drawings.add(drawingData);

      // Save to preferences
      await prefs.setString(_storageKey, json.encode(drawings));

      // Export image
      final imageData = await controller.exportToImage(
        width: width,
        height: height,
      );

      if (imageData != null) {
        await _saveImageToFile(drawingData['id']! as String, imageData);
      }

      return true;
    } catch (e) {
      // print('Error saving drawing: $e');
      return false;
    }
  }

  /// Load all saved drawings
  Future<List<SavedDrawing>> loadDrawings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final drawingsJson = prefs.getString(_storageKey);

      if (drawingsJson == null) return [];

      final drawingsList = List<Map<String, dynamic>>.from(json.decode(drawingsJson));

      return drawingsList.map((data) {
        return SavedDrawing(
          id: data['id'] as String,
          name: data['name'] as String,
          createdAt: DateTime.parse(data['createdAt'] as String),
          width: (data['width'] as num).toDouble(),
          height: (data['height'] as num).toDouble(),
        );
      }).toList();
    } catch (e) {
      // print('Error loading drawings: $e');
      return [];
    }
  }

  /// Delete a saved drawing
  Future<bool> deleteDrawing(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final drawingsJson = prefs.getString(_storageKey);

      if (drawingsJson == null) return false;

      final drawings = List<Map<String, dynamic>>.from(json.decode(drawingsJson));
      drawings.removeWhere((d) => d['id'] == id);

      await prefs.setString(_storageKey, json.encode(drawings));

      // Delete image file
      await _deleteImageFile(id);

      return true;
    } catch (e) {
      // print('Error deleting drawing: $e');
      return false;
    }
  }

  /// Export drawing as PNG image
  Future<String?> exportDrawing({
    required String name,
    required DrawingController controller,
    required double width,
    required double height,
  }) async {
    try {
      final imageData = await controller.exportToImage(
        width: width,
        height: height,
      );

      if (imageData == null) return null;

      // Get documents directory
      final directory = await getApplicationDocumentsDirectory();
      final exportsDir = Directory('${directory.path}/exports');

      if (!await exportsDir.exists()) {
        await exportsDir.create(recursive: true);
      }

      // Create file with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${name.replaceAll(' ', '_')}_$timestamp.png';
      final file = File('${exportsDir.path}/$fileName');

      await file.writeAsBytes(imageData);

      return file.path;
    } catch (e) {
      // print('Error exporting drawing: $e');
      return null;
    }
  }

  /// Get image file for a saved drawing
  Future<File?> getDrawingImage(String id) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_drawingsDir/$id.png');

      if (await file.exists()) {
        return file;
      }

      return null;
    } catch (e) {
      // print('Error getting drawing image: $e');
      return null;
    }
  }

  // Private helpers
  Future<void> _saveImageToFile(String id, Uint8List imageData) async {
    final directory = await getApplicationDocumentsDirectory();
    final drawingsDir = Directory('${directory.path}/$_drawingsDir');

    if (!await drawingsDir.exists()) {
      await drawingsDir.create(recursive: true);
    }

    final file = File('${drawingsDir.path}/$id.png');
    await file.writeAsBytes(imageData);
  }

  Future<void> _deleteImageFile(String id) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_drawingsDir/$id.png');

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // print('Error deleting image file: $e');
    }
  }
}

/// Saved drawing model
class SavedDrawing {
  final String id;
  final String name;
  final DateTime createdAt;
  final double width;
  final double height;

  SavedDrawing({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.width,
    required this.height,
  });
}

/// Dialog for saving drawing
class SaveDrawingDialog extends StatefulWidget {
  final DrawingController controller;
  final double canvasWidth;
  final double canvasHeight;

  const SaveDrawingDialog({
    super.key,
    required this.controller,
    required this.canvasWidth,
    required this.canvasHeight,
  });

  @override
  State<SaveDrawingDialog> createState() => _SaveDrawingDialogState();
}

class _SaveDrawingDialogState extends State<SaveDrawingDialog> {
  final _nameController = TextEditingController();
  final _storageService = DrawingStorageService();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name for your drawing')),
      );
      return;
    }

    setState(() => _saving = true);

    final success = await _storageService.saveDrawing(
      name: _nameController.text,
      controller: widget.controller,
      width: widget.canvasWidth,
      height: widget.canvasHeight,
    );

    if (mounted) {
      setState(() => _saving = false);

      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Drawing saved successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save drawing')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save Drawing'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Drawing Name',
              hintText: 'My Awesome Design',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            enabled: !_saving,
          ),
          if (_saving) ...[
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Dialog for exporting drawing
class ExportDrawingDialog extends StatefulWidget {
  final DrawingController controller;
  final double canvasWidth;
  final double canvasHeight;

  const ExportDrawingDialog({
    super.key,
    required this.controller,
    required this.canvasWidth,
    required this.canvasHeight,
  });

  @override
  State<ExportDrawingDialog> createState() => _ExportDrawingDialogState();
}

class _ExportDrawingDialogState extends State<ExportDrawingDialog> {
  final _nameController = TextEditingController(text: 'drawing');
  final _storageService = DrawingStorageService();
  bool _exporting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a file name')),
      );
      return;
    }

    setState(() => _exporting = true);

    final filePath = await _storageService.exportDrawing(
      name: _nameController.text,
      controller: widget.controller,
      width: widget.canvasWidth,
      height: widget.canvasHeight,
    );

    if (mounted) {
      setState(() => _exporting = false);

      if (filePath != null) {
        Navigator.pop(context, filePath);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported to: $filePath')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to export drawing')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Drawing'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'File Name',
              hintText: 'drawing',
              suffix: Text('.png'),
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            enabled: !_exporting,
          ),
          const SizedBox(height: 12),
          Text(
            'Image will be exported as PNG format',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          if (_exporting) ...[
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _exporting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _exporting ? null : _export,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
          child: const Text('Export'),
        ),
      ],
    );
  }
}
