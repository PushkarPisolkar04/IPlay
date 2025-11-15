import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'drawing_controller.dart';

/// Layer information model
class LayerInfo {
  final String id;
  String name;
  bool visible;
  bool locked;
  double opacity;

  LayerInfo({
    required this.id,
    required this.name,
    this.visible = true,
    this.locked = false,
    this.opacity = 1.0,
  });
}

/// Enhanced drawing controller with layer metadata
class LayerManager extends ChangeNotifier {
  final DrawingController drawingController;
  final Map<String, LayerInfo> _layerInfo = {};
  int _layerCounter = 0;

  LayerManager({required this.drawingController}) {
    // Initialize with default layer
    _layerInfo['layer_0'] = LayerInfo(
      id: 'layer_0',
      name: 'Layer 1',
    );
  }

  Map<String, LayerInfo> get layerInfo => Map.unmodifiable(_layerInfo);
  List<String> get layerIds => _layerInfo.keys.toList();

  void addLayer() {
    _layerCounter++;
    final layerId = 'layer_$_layerCounter';
    final layerName = 'Layer ${_layerCounter + 1}';

    _layerInfo[layerId] = LayerInfo(
      id: layerId,
      name: layerName,
    );

    drawingController.addLayer(layerId);
    notifyListeners();
  }

  void removeLayer(String layerId) {
    if (_layerInfo.length > 1 && _layerInfo.containsKey(layerId)) {
      _layerInfo.remove(layerId);
      drawingController.removeLayer(layerId);
      notifyListeners();
    }
  }

  void renameLayer(String layerId, String newName) {
    if (_layerInfo.containsKey(layerId)) {
      _layerInfo[layerId]!.name = newName;
      notifyListeners();
    }
  }

  void toggleLayerVisibility(String layerId) {
    if (_layerInfo.containsKey(layerId)) {
      _layerInfo[layerId]!.visible = !_layerInfo[layerId]!.visible;
      notifyListeners();
    }
  }

  void toggleLayerLock(String layerId) {
    if (_layerInfo.containsKey(layerId)) {
      _layerInfo[layerId]!.locked = !_layerInfo[layerId]!.locked;
      notifyListeners();
    }
  }

  void setLayerOpacity(String layerId, double opacity) {
    if (_layerInfo.containsKey(layerId)) {
      _layerInfo[layerId]!.opacity = opacity.clamp(0.0, 1.0);
      notifyListeners();
    }
  }

  void reorderLayers(int oldIndex, int newIndex) {
    final keys = layerIds;
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final item = keys.removeAt(oldIndex);
    keys.insert(newIndex, item);

    // Rebuild layer info map in new order
    final newLayerInfo = <String, LayerInfo>{};
    for (var key in keys) {
      newLayerInfo[key] = _layerInfo[key]!;
    }

    _layerInfo.clear();
    _layerInfo.addAll(newLayerInfo);
    notifyListeners();
  }

  bool isLayerVisible(String layerId) {
    return _layerInfo[layerId]?.visible ?? true;
  }

  bool isLayerLocked(String layerId) {
    return _layerInfo[layerId]?.locked ?? false;
  }
}

/// Layer panel widget showing all layers with controls
class LayerPanel extends StatefulWidget {
  final LayerManager layerManager;
  final DrawingController drawingController;

  const LayerPanel({
    super.key,
    required this.layerManager,
    required this.drawingController,
  });

  @override
  State<LayerPanel> createState() => _LayerPanelState();
}

class _LayerPanelState extends State<LayerPanel> {
  @override
  void initState() {
    super.initState();
    widget.layerManager.addListener(_onLayerUpdate);
    widget.drawingController.addListener(_onLayerUpdate);
  }

  @override
  void dispose() {
    widget.layerManager.removeListener(_onLayerUpdate);
    widget.drawingController.removeListener(_onLayerUpdate);
    super.dispose();
  }

  void _onLayerUpdate() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final layerIds = widget.layerManager.layerIds.reversed.toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Layers',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () => widget.layerManager.addLayer(),
                  tooltip: 'Add Layer',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Layer list
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ReorderableListView.builder(
              shrinkWrap: true,
              itemCount: layerIds.length,
              onReorder: (oldIndex, newIndex) {
                widget.layerManager.reorderLayers(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final layerId = layerIds[index];
                final layerInfo = widget.layerManager.layerInfo[layerId]!;
                final isCurrentLayer =
                    widget.drawingController.currentLayerId == layerId;

                return _buildLayerItem(
                  key: ValueKey(layerId),
                  layerId: layerId,
                  layerInfo: layerInfo,
                  isCurrentLayer: isCurrentLayer,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayerItem({
    required Key key,
    required String layerId,
    required LayerInfo layerInfo,
    required bool isCurrentLayer,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrentLayer ? Colors.teal.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isCurrentLayer ? Colors.teal : Colors.grey[300]!,
          width: isCurrentLayer ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (!layerInfo.locked) {
            widget.drawingController.setCurrentLayer(layerId);
          }
        },
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              // Drag handle
              const Icon(
                Icons.drag_indicator,
                size: 20,
                color: Colors.grey,
              ),

              const SizedBox(width: 8),

              // Layer thumbnail (simplified)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Icon(
                  Icons.layers,
                  size: 20,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(width: 12),

              // Layer name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      layerInfo.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isCurrentLayer ? FontWeight.w600 : FontWeight.normal,
                        color: layerInfo.locked ? Colors.grey : Colors.black,
                      ),
                    ),
                    if (layerInfo.opacity < 1.0)
                      Text(
                        '${(layerInfo.opacity * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),

              // Visibility toggle
              IconButton(
                icon: Icon(
                  layerInfo.visible ? Icons.visibility : Icons.visibility_off,
                  size: 20,
                ),
                onPressed: () => widget.layerManager.toggleLayerVisibility(layerId),
                tooltip: layerInfo.visible ? 'Hide Layer' : 'Show Layer',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),

              const SizedBox(width: 8),

              // Lock toggle
              IconButton(
                icon: Icon(
                  layerInfo.locked ? Icons.lock : Icons.lock_open,
                  size: 20,
                ),
                onPressed: () => widget.layerManager.toggleLayerLock(layerId),
                tooltip: layerInfo.locked ? 'Unlock Layer' : 'Lock Layer',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),

              const SizedBox(width: 8),

              // More options
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                padding: EdgeInsets.zero,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Rename'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.content_copy, size: 18),
                        SizedBox(width: 8),
                        Text('Duplicate'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        Icon(Icons.clear, size: 18),
                        SizedBox(width: 8),
                        Text('Clear'),
                      ],
                    ),
                  ),
                  if (widget.layerManager.layerIds.length > 1)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                ],
                onSelected: (value) => _handleLayerAction(value, layerId, layerInfo),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLayerAction(String action, String layerId, LayerInfo layerInfo) {
    switch (action) {
      case 'rename':
        _showRenameDialog(layerId, layerInfo.name);
        break;
      case 'duplicate':
        // TODO: Implement layer duplication
        break;
      case 'clear':
        widget.drawingController.clearLayer(layerId);
        break;
      case 'delete':
        widget.layerManager.removeLayer(layerId);
        break;
    }
  }

  void _showRenameDialog(String layerId, String currentName) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Layer'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Layer Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                widget.layerManager.renameLayer(layerId, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }
}

/// Compact layer thumbnails view (horizontal)
class LayerThumbnailsView extends StatelessWidget {
  final LayerManager layerManager;
  final DrawingController drawingController;

  const LayerThumbnailsView({
    super.key,
    required this.layerManager,
    required this.drawingController,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([layerManager, drawingController]),
      builder: (context, _) {
        final layerIds = layerManager.layerIds.reversed.toList();

        return SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: layerIds.length + 1,
            itemBuilder: (context, index) {
              if (index == layerIds.length) {
                // Add layer button
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: InkWell(
                    onTap: () => layerManager.addLayer(),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[400]!, width: 2, style: BorderStyle.solid),
                      ),
                      child: const Icon(Icons.add, size: 30, color: Colors.grey),
                    ),
                  ),
                );
              }

              final layerId = layerIds[index];
              final layerInfo = layerManager.layerInfo[layerId]!;
              final isCurrentLayer = drawingController.currentLayerId == layerId;

              return Padding(
                padding: const EdgeInsets.all(8),
                child: InkWell(
                  onTap: () {
                    if (!layerInfo.locked) {
                      drawingController.setCurrentLayer(layerId);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 60,
                    decoration: BoxDecoration(
                      color: isCurrentLayer
                          ? Colors.teal.withValues(alpha: 0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCurrentLayer ? Colors.teal : Colors.grey[300]!,
                        width: isCurrentLayer ? 3 : 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          layerInfo.visible ? Icons.layers : Icons.layers_clear,
                          size: 24,
                          color: layerInfo.locked ? Colors.grey : Colors.teal,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          layerInfo.name,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isCurrentLayer ? FontWeight.w600 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
