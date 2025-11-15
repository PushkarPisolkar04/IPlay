import 'package:flutter/material.dart';
import '../../models/innovation_lab_model.dart';

/// Template gallery widget for selecting design templates
class TemplateGallery extends StatefulWidget {
  final List<DesignTemplate> templates;
  final Function(DesignTemplate) onTemplateSelected;

  const TemplateGallery({
    super.key,
    required this.templates,
    required this.onTemplateSelected,
  });

  @override
  State<TemplateGallery> createState() => _TemplateGalleryState();
}

class _TemplateGalleryState extends State<TemplateGallery> {
  String _selectedCategory = 'all';
  
  List<String> get _categories {
    final categories = <String>{'all'};
    for (var template in widget.templates) {
      categories.add(template.category);
    }
    return categories.toList();
  }

  List<DesignTemplate> get _filteredTemplates {
    if (_selectedCategory == 'all') {
      return widget.templates;
    }
    return widget.templates
        .where((t) => t.category == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category filter
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categories.map((category) {
              final isSelected = _selectedCategory == category;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    category == 'all' ? 'All' : _formatCategory(category),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  selectedColor: Colors.teal,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // Template grid
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: _filteredTemplates.length,
            itemBuilder: (context, index) {
              final template = _filteredTemplates[index];
              return _buildTemplateCard(template);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateCard(DesignTemplate template) {
    return InkWell(
      onTap: () => widget.onTemplateSelected(template),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Template thumbnail
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _parseColor(template.templateData.backgroundColor),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: _buildTemplateThumbnail(template),
                ),
              ),
            ),

            // Template info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    template.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildDifficultyBadge(template.difficulty),
                      const Spacer(),
                      if (template.templateData.gridEnabled)
                        const Icon(
                          Icons.grid_on,
                          size: 16,
                          color: Colors.grey,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateThumbnail(DesignTemplate template) {
    // Show template icon based on category
    IconData icon;
    Color iconColor;

    switch (template.category) {
      case 'product_design':
        icon = Icons.inventory_2_outlined;
        iconColor = Colors.blue;
        break;
      case 'logo_design':
        icon = Icons.branding_watermark;
        iconColor = Colors.purple;
        break;
      case 'packaging':
        icon = Icons.shopping_bag_outlined;
        iconColor = Colors.orange;
        break;
      case 'blueprint':
        icon = Icons.architecture;
        iconColor = Colors.cyan;
        break;
      case 'ui_design':
        icon = Icons.phone_android;
        iconColor = Colors.green;
        break;
      default:
        icon = Icons.design_services;
        iconColor = Colors.teal;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 48,
          color: iconColor,
        ),
        if (template.templateData.gridEnabled) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.grid_on, size: 12, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Grid',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color color;
    switch (difficulty.toLowerCase()) {
      case 'easy':
        color = Colors.green;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      case 'hard':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        difficulty,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatCategory(String category) {
    return category
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Color _parseColor(String colorString) {
    try {
      final hexColor = colorString.replaceAll('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (e) {
      return Colors.white;
    }
  }
}

/// Template selection dialog
class TemplateSelectionDialog extends StatelessWidget {
  final List<DesignTemplate> templates;

  const TemplateSelectionDialog({
    super.key,
    required this.templates,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Text(
                  'Choose a Template',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Template gallery
            Expanded(
              child: TemplateGallery(
                templates: templates,
                onTemplateSelected: (template) {
                  Navigator.pop(context, template);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid toggle widget
class GridToggle extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final int? gridSize;
  final ValueChanged<int>? onGridSizeChanged;

  const GridToggle({
    super.key,
    required this.enabled,
    required this.onChanged,
    this.gridSize,
    this.onGridSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.grid_on, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Show Grid',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Switch(
              value: enabled,
              onChanged: onChanged,
              activeColor: Colors.teal,
            ),
          ],
        ),

        if (enabled && gridSize != null && onGridSizeChanged != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Grid Size',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Slider(
                  value: gridSize!.toDouble(),
                  min: 10,
                  max: 50,
                  divisions: 8,
                  label: '$gridSize px',
                  onChanged: (value) => onGridSizeChanged!(value.toInt()),
                  activeColor: Colors.teal,
                ),
              ),
              Text(
                '$gridSize',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Template preview widget
class TemplatePreview extends StatelessWidget {
  final DesignTemplate template;
  final VoidCallback? onUse;

  const TemplatePreview({
    super.key,
    required this.template,
    this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Template name
          Text(
            template.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // Description
          Text(
            template.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(height: 16),

          // Template details
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildDetailChip(
                Icons.category,
                _formatCategory(template.category),
              ),
              _buildDetailChip(
                Icons.layers,
                '${template.templateData.layers.length} layers',
              ),
              if (template.templateData.gridEnabled)
                _buildDetailChip(
                  Icons.grid_on,
                  'Grid: ${template.templateData.gridSize ?? 20}px',
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Use template button
          if (onUse != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Use This Template'),
                onPressed: onUse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCategory(String category) {
    return category
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
