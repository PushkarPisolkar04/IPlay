import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/gi_mapper_model.dart';
import '../core/design/app_design_system.dart';

/// Interactive India map widget with SVG rendering and touch detection
class IndiaMapWidget extends StatefulWidget {
  final IndiaMapData mapData;
  final Map<String, GIProduct?> statePlacements;
  final Function(String stateCode, GIProduct product) onProductPlaced;
  final bool showResults;
  final Color highlightColor;
  final String? hoveredState;
  final Function(String? stateCode)? onStateHover;

  const IndiaMapWidget({
    super.key,
    required this.mapData,
    required this.statePlacements,
    required this.onProductPlaced,
    this.showResults = false,
    this.highlightColor = AppDesignSystem.primaryAmber,
    this.hoveredState,
    this.onStateHover,
  });

  @override
  State<IndiaMapWidget> createState() => _IndiaMapWidgetState();
}

class _IndiaMapWidgetState extends State<IndiaMapWidget> {
  String? _hoveredStateCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppDesignSystem.backgroundGrey),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // SVG Map
            SvgPicture.asset(
              'assets/maps/india_map.svg',
              fit: BoxFit.contain,
            ),
            
            // Interactive overlay for each state
            ...widget.mapData.states.map((state) {
              return _buildStateOverlay(state);
            }),
            
            // Product pins on placed states
            ...widget.statePlacements.entries
                .where((entry) => entry.value != null)
                .map((entry) {
              final stateCode = entry.key;
              final product = entry.value!;
              final state = widget.mapData.getStateByCode(stateCode);
              
              if (state == null) return const SizedBox.shrink();
              
              return _buildProductPin(state, product);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStateOverlay(StateData state) {
    final hasProduct = widget.statePlacements[state.code] != null;
    final product = widget.statePlacements[state.code];
    final isHovered = _hoveredStateCode == state.code;
    
    Color? overlayColor;
    if (widget.showResults && hasProduct && product != null) {
      // Show correct/incorrect feedback
      overlayColor = product.stateCode == state.code
          ? AppDesignSystem.success.withValues(alpha: 0.3)
          : Colors.red.withValues(alpha: 0.3);
    } else if (isHovered) {
      overlayColor = widget.highlightColor.withValues(alpha: 0.2);
    }

    return Positioned.fill(
      child: DragTarget<GIProduct>(
        onAcceptWithDetails: (details) {
          widget.onProductPlaced(state.code, details.data);
          // HapticFeedbackUtil.lightImpact();
        },
        onWillAcceptWithDetails: (details) {
          setState(() {
            _hoveredStateCode = state.code;
          });
          widget.onStateHover?.call(state.code);
          return true;
        },
        onLeave: (data) {
          setState(() {
            _hoveredStateCode = null;
          });
          widget.onStateHover?.call(null);
        },
        builder: (context, candidateData, rejectedData) {
          return MouseRegion(
            onEnter: (_) {
              setState(() {
                _hoveredStateCode = state.code;
              });
              widget.onStateHover?.call(state.code);
            },
            onExit: (_) {
              setState(() {
                _hoveredStateCode = null;
              });
              widget.onStateHover?.call(null);
            },
            child: overlayColor != null
                ? Container(
                    color: overlayColor,
                  )
                : const SizedBox.shrink(),
          );
        },
      ),
    );
  }

  Widget _buildProductPin(StateData state, GIProduct product) {
    final isCorrect = product.stateCode == state.code;
    
    return Positioned(
      left: 100, // This would need proper positioning based on state coordinates
      top: 100,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on,
              color: widget.showResults
                  ? (isCorrect ? AppDesignSystem.success : Colors.red)
                  : widget.highlightColor,
              size: 24,
            ),
            if (widget.showResults)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isCorrect ? AppDesignSystem.success : Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  product.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
