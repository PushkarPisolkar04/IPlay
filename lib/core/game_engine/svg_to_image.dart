import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Helper class to convert SVG assets to ui.Image for canvas rendering
class SvgToImage {
  /// Convert an SVG asset to a ui.Image
  static Future<ui.Image> loadSvgAsImage(
    String assetPath, {
    double width = 100,
    double height = 100,
  }) async {
    // Load the SVG string
    final svgString = await rootBundle.loadString(assetPath);
    
    // Parse the SVG
    final pictureInfo = await vg.loadPicture(
      SvgStringLoader(svgString),
      null,
    );
    
    // Convert to image
    final image = await pictureInfo.picture.toImage(
      width.toInt(),
      height.toInt(),
    );
    
    pictureInfo.picture.dispose();
    
    return image;
  }

  /// Load multiple SVG assets as images
  static Future<Map<String, ui.Image>> loadMultipleSvgs(
    Map<String, String> assetPaths, {
    double width = 100,
    double height = 100,
  }) async {
    final Map<String, ui.Image> images = {};
    
    for (final entry in assetPaths.entries) {
      try {
        images[entry.key] = await loadSvgAsImage(
          entry.value,
          width: width,
          height: height,
        );
      } catch (e) {
        // Skip if SVG fails to load
        print('Failed to load SVG ${entry.value}: $e');
      }
    }
    
    return images;
  }
}
