import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'td_game_engine.dart';
import '../../models/ip_defender_model.dart';

/// Custom painter for rendering the tower defense game with SVG assets
class TDGamePainter extends CustomPainter {
  final TDGameEngine engine;
  final PlacedTower? selectedTower;
  final Coordinate? hoverGridPos;
  final Tower? towerToPlace;
  final Map<String, ui.Image>? svgImages;

  TDGamePainter({
    required this.engine,
    this.selectedTower,
    this.hoverGridPos,
    this.towerToPlace,
    this.svgImages,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw game map background if available
    final mapImage = svgImages?['assets/maps/game_map.svg'];
    if (mapImage != null) {
      final srcRect = Rect.fromLTWH(0, 0, mapImage.width.toDouble(), mapImage.height.toDouble());
      final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
      canvas.drawImageRect(mapImage, srcRect, dstRect, Paint()..filterQuality = FilterQuality.high);
    }
    
    // Draw grid
    _drawGrid(canvas, size);
    
    // Draw path
    _drawPath(canvas);
    
    // Draw tower placement preview
    if (hoverGridPos != null && towerToPlace != null) {
      _drawTowerPlacementPreview(canvas, hoverGridPos!, towerToPlace!);
    }
    
    // Draw towers
    for (final tower in engine.placedTowers) {
      _drawTower(canvas, tower);
      
      // Draw range indicator for selected tower
      if (selectedTower == tower) {
        _drawTowerRange(canvas, tower);
      }
    }
    
    // Draw enemies
    for (final enemy in engine.activeEnemies) {
      _drawEnemy(canvas, enemy);
    }
    
    // Draw projectiles
    for (final projectile in engine.activeProjectiles) {
      _drawProjectile(canvas, projectile);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw vertical lines
    for (int x = 0; x <= TDGameEngine.gridWidth; x++) {
      final xPos = x * TDGameEngine.tileSize;
      canvas.drawLine(
        Offset(xPos, 0),
        Offset(xPos, TDGameEngine.gridHeight * TDGameEngine.tileSize),
        paint,
      );
    }

    // Draw horizontal lines
    for (int y = 0; y <= TDGameEngine.gridHeight; y++) {
      final yPos = y * TDGameEngine.tileSize;
      canvas.drawLine(
        Offset(0, yPos),
        Offset(TDGameEngine.gridWidth * TDGameEngine.tileSize, yPos),
        paint,
      );
    }
  }

  void _drawPath(Canvas canvas) {
    if (engine.path.isEmpty) return;

    final paint = Paint()
      ..color = Colors.brown.withValues(alpha: 0.3)
      ..strokeWidth = TDGameEngine.tileSize * 0.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(engine.path.first.x, engine.path.first.y);
    
    for (int i = 1; i < engine.path.length; i++) {
      path.lineTo(engine.path[i].x, engine.path[i].y);
    }

    canvas.drawPath(path, paint);
  }

  void _drawTower(Canvas canvas, PlacedTower tower) {
    final pos = engine.gridToWorld(tower.gridPosition);
    final tileSize = TDGameEngine.tileSize;

    // Try to use SVG image if available
    final svgImage = svgImages?[tower.towerData.spriteUrl];
    
    if (svgImage != null) {
      // Draw SVG image
      final imageSize = tileSize * 0.8;
      final srcRect = Rect.fromLTWH(0, 0, svgImage.width.toDouble(), svgImage.height.toDouble());
      final dstRect = Rect.fromCenter(
        center: Offset(pos.x, pos.y),
        width: imageSize,
        height: imageSize,
      );
      
      canvas.drawImageRect(svgImage, srcRect, dstRect, Paint());
    } else {
      // Fallback to programmatic rendering
      // Draw tower base
      final basePaint = Paint()
        ..color = tower.towerData.color.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(pos.x, pos.y),
        tileSize * 0.4,
        basePaint,
      );

      // Draw tower body
      final bodyPaint = Paint()
        ..color = tower.towerData.color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(pos.x, pos.y),
        tileSize * 0.3,
        bodyPaint,
      );

      // Draw tower icon based on type
      _drawTowerIcon(canvas, tower, pos);
    }

    // Draw level indicator
    if (tower.level > 1) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${tower.level}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(pos.x - textPainter.width / 2, pos.y + tileSize * 0.25),
      );
    }
  }

  void _drawTowerIcon(Canvas canvas, PlacedTower tower, Coordinate pos) {
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final size = TDGameEngine.tileSize * 0.2;

    // Draw different shapes based on tower type
    if (tower.towerData.id == 'copyright_shield') {
      // Draw shield shape
      final path = Path()
        ..moveTo(pos.x, pos.y - size)
        ..lineTo(pos.x + size, pos.y)
        ..lineTo(pos.x, pos.y + size)
        ..lineTo(pos.x - size, pos.y)
        ..close();
      canvas.drawPath(path, iconPaint);
    } else if (tower.towerData.id == 'patent_cannon') {
      // Draw cannon shape (rectangle)
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(pos.x, pos.y),
          width: size * 1.5,
          height: size,
        ),
        iconPaint,
      );
    } else if (tower.towerData.id == 'trademark_barrier') {
      // Draw barrier shape (triangle)
      final path = Path()
        ..moveTo(pos.x, pos.y - size)
        ..lineTo(pos.x + size, pos.y + size)
        ..lineTo(pos.x - size, pos.y + size)
        ..close();
      canvas.drawPath(path, iconPaint);
    } else if (tower.towerData.id == 'trade_secret_vault') {
      // Draw vault shape (square)
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(pos.x, pos.y),
          width: size * 1.2,
          height: size * 1.2,
        ),
        iconPaint,
      );
    }
  }

  void _drawTowerRange(Canvas canvas, PlacedTower tower) {
    final pos = engine.gridToWorld(tower.gridPosition);
    final rangePaint = Paint()
      ..color = tower.towerData.color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(pos.x, pos.y),
      tower.range * TDGameEngine.tileSize,
      rangePaint,
    );
  }

  void _drawTowerPlacementPreview(Canvas canvas, Coordinate gridPos, Tower tower) {
    final pos = engine.gridToWorld(gridPos);
    final isValid = engine.isValidTowerPosition(gridPos);

    // Draw placement circle
    final paint = Paint()
      ..color = (isValid ? Colors.green : Colors.red).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(pos.x, pos.y),
      TDGameEngine.tileSize * 0.4,
      paint,
    );

    // Draw range preview
    final rangePaint = Paint()
      ..color = tower.color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(pos.x, pos.y),
      tower.range * TDGameEngine.tileSize,
      rangePaint,
    );
  }

  void _drawEnemy(Canvas canvas, GameEnemy enemy) {
    final pos = engine.getEnemyPosition(enemy);
    final size = TDGameEngine.tileSize * 0.3;

    // Try to use SVG image if available
    final svgImage = svgImages?[enemy.enemyData.spriteUrl];
    
    if (svgImage != null) {
      // Draw SVG image
      final imageSize = size * 2;
      final srcRect = Rect.fromLTWH(0, 0, svgImage.width.toDouble(), svgImage.height.toDouble());
      final dstRect = Rect.fromCenter(
        center: Offset(pos.x, pos.y),
        width: imageSize,
        height: imageSize,
      );
      
      canvas.drawImageRect(svgImage, srcRect, dstRect, Paint());
    } else {
      // Fallback to programmatic rendering
      final bodyPaint = Paint()
        ..color = enemy.enemyData.color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(pos.x, pos.y),
        size,
        bodyPaint,
      );
    }

    // Draw health bar
    _drawHealthBar(canvas, pos, enemy.currentHealth, enemy.enemyData.baseHealth, size);
  }

  void _drawHealthBar(Canvas canvas, Coordinate pos, int current, int max, double enemySize) {
    final barWidth = enemySize * 2;
    final barHeight = 4.0;
    final barY = pos.y - enemySize - 8;

    // Background
    final bgPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(pos.x - barWidth / 2, barY, barWidth, barHeight),
      bgPaint,
    );

    // Health
    final healthPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    final healthWidth = barWidth * (current / max);
    canvas.drawRect(
      Rect.fromLTWH(pos.x - barWidth / 2, barY, healthWidth, barHeight),
      healthPaint,
    );
  }

  void _drawProjectile(Canvas canvas, Projectile projectile) {
    // Try to use SVG image if available
    final svgImage = svgImages?[projectile.tower.towerData.projectileUrl];
    
    if (svgImage != null) {
      // Draw SVG image
      final imageSize = 12.0;
      final srcRect = Rect.fromLTWH(0, 0, svgImage.width.toDouble(), svgImage.height.toDouble());
      final dstRect = Rect.fromCenter(
        center: Offset(projectile.position.x, projectile.position.y),
        width: imageSize,
        height: imageSize,
      );
      
      canvas.drawImageRect(svgImage, srcRect, dstRect, Paint());
    } else {
      // Fallback to programmatic rendering
      final paint = Paint()
        ..color = projectile.tower.towerData.color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(projectile.position.x, projectile.position.y),
        4.0,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(TDGamePainter oldDelegate) => true;
}
