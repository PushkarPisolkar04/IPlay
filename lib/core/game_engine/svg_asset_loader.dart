import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Service to load and cache SVG assets for the tower defense game
class SvgAssetLoader {
  static final SvgAssetLoader _instance = SvgAssetLoader._internal();
  factory SvgAssetLoader() => _instance;
  SvgAssetLoader._internal();

  final Map<String, ui.Picture> _cache = {};
  final Map<String, Future<ui.Picture>> _loading = {};

  /// Load an SVG asset and return it as a Picture
  Future<ui.Picture> loadSvg(String assetPath, {double? width, double? height}) async {
    // Check cache first
    if (_cache.containsKey(assetPath)) {
      return _cache[assetPath]!;
    }

    // Check if already loading
    if (_loading.containsKey(assetPath)) {
      return _loading[assetPath]!;
    }

    // Start loading
    final loadingFuture = _loadSvgInternal(assetPath, width: width, height: height);
    _loading[assetPath] = loadingFuture;

    try {
      final picture = await loadingFuture;
      _cache[assetPath] = picture;
      _loading.remove(assetPath);
      return picture;
    } catch (e) {
      _loading.remove(assetPath);
      rethrow;
    }
  }

  Future<ui.Picture> _loadSvgInternal(String assetPath, {double? width, double? height}) async {
    final pictureInfo = await vg.loadPicture(
      SvgAssetLoader(assetPath),
      null,
    );
    return pictureInfo.picture;
  }

  /// Preload multiple SVG assets
  Future<void> preloadAssets(List<String> assetPaths) async {
    await Future.wait(
      assetPaths.map((path) => loadSvg(path)),
    );
  }

  /// Clear the cache
  void clearCache() {
    for (final picture in _cache.values) {
      picture.dispose();
    }
    _cache.clear();
  }

  /// Check if an asset is loaded
  bool isLoaded(String assetPath) {
    return _cache.containsKey(assetPath);
  }

  /// Get a cached picture
  ui.Picture? getCached(String assetPath) {
    return _cache[assetPath];
  }
}

/// Custom asset loader for vg.loadPicture
class SvgAssetLoader extends vg.AssetBundle {
  final String assetPath;

  SvgAssetLoader(this.assetPath);

  @override
  Future<ByteData> load(String key) async {
    return await rootBundle.load(assetPath);
  }
}
