# Projectile and Effect Sprites

This directory contains sprite images for tower projectiles and visual effects in IP Defender.

## Projectile Types

### 1. Shield Wave (shield_wave.png)
- **Tower**: Copyright Shield
- **Color Theme**: Blue (#2196F3)
- **Design**: Wave/pulse effect emanating from shield
- **Size**: 24x24 pixels
- **Animation**: Expanding wave or energy pulse
- **Style**: Defensive energy wave

### 2. Patent Bolt (patent_bolt.png)
- **Tower**: Patent Cannon
- **Color Theme**: Purple (#9C27B0)
- **Design**: Energy bolt or gear-shaped projectile
- **Size**: 16x16 pixels
- **Animation**: Rotating or pulsing energy
- **Style**: High-damage projectile

### 3. Trademark Field (trademark_field.png)
- **Tower**: Trademark Barrier
- **Color Theme**: Orange (#FF9800)
- **Design**: Area effect field or barrier waves
- **Size**: 32x32 pixels (area effect)
- **Animation**: Pulsing field or barrier lines
- **Style**: Slowing area effect

### 4. Secret Pulse (secret_pulse.png)
- **Tower**: Trade Secret Vault
- **Color Theme**: Green (#4CAF50)
- **Design**: Radial pulse or lock symbols
- **Size**: 28x28 pixels
- **Animation**: Expanding pulse waves
- **Style**: Area damage with income generation theme

## Effect Sprites

### Hit Effects
- **explosion_small.png**: Small impact effect (16x16)
- **explosion_medium.png**: Medium impact effect (24x24)
- **explosion_large.png**: Large impact effect (32x32)

### Status Effects
- **slow_effect.png**: Visual indicator for slowed enemies (16x16)
- **damage_indicator.png**: Damage number popup effect

## Sprite Requirements

- **Format**: PNG with transparency
- **Resolution**: Varies by type (16x16 to 32x32)
- **Color Depth**: 32-bit RGBA
- **Animation**: 2-4 frame sprite sheets for animated effects
- **Style**: Glowing, energy-based effects with clear visibility
- **Blending**: Design for additive or screen blending modes

## Visual Design Guidelines

1. **Visibility**: Projectiles must be clearly visible against game backgrounds
2. **Color Coding**: Match tower color themes for instant recognition
3. **Size**: Proportional to damage/effect area
4. **Trail Effects**: Consider motion blur or particle trails for fast projectiles
5. **Impact**: Clear visual feedback when hitting enemies

## Asset Optimization

Follow the IMAGE_OPTIMIZATION_GUIDE.md in the assets root directory:
- Use PNG format with transparency
- Keep file sizes under 20KB per sprite
- Use bright, saturated colors for visibility
- Consider sprite sheets for animated effects (more efficient)

## Placeholder Sprites

Temporary placeholder SVG files are provided for development. Replace with final PNG sprites before production.
