# Enemy Sprites

This directory contains sprite images for the four enemy types in IP Defender.

## Enemy Types

### 1. Counterfeiter (counterfeiter.png)
- **Color Theme**: Red (#F44336)
- **Design**: Sneaky character with fake goods/bag
- **Size**: 32x32 pixels
- **Stats**: Moderate health (100), moderate speed (1.0)
- **Style**: Basic infringer appearance

### 2. Pirate (pirate.png)
- **Color Theme**: Purple (#673AB7)
- **Design**: Pirate character with copyright violation theme
- **Size**: 32x32 pixels
- **Stats**: Low health (60), high speed (1.8)
- **Style**: Fast-moving, copyright violator

### 3. Infringer (infringer.png)
- **Color Theme**: Brown (#795548)
- **Design**: Heavily armored character with shield
- **Size**: 40x40 pixels (larger due to tank role)
- **Stats**: High health (200), low speed (0.6)
- **Style**: Tank, heavily armored patent violator

### 4. Copycat (copycat.png)
- **Color Theme**: Orange-Red (#FF5722)
- **Design**: Cat-like character or mimic with copying theme
- **Size**: 32x32 pixels
- **Stats**: Medium health (120), medium speed (1.2)
- **Style**: Sneaky design thief

## Sprite Requirements

- **Format**: PNG with transparency
- **Resolution**: 32x32 pixels (standard), 40x40 pixels (Infringer)
- **Color Depth**: 32-bit RGBA
- **Animation**: Consider 2-4 frame walk cycles for movement
- **Style**: Cartoon/stylized characters that are clearly distinguishable
- **Direction**: Sprites should face right (movement direction)

## Visual Distinction

Each enemy type should be easily distinguishable by:
1. **Color**: Unique color scheme per type
2. **Size**: Infringer is larger (40x40) vs others (32x32)
3. **Shape**: Different silhouettes
4. **Theme**: Visual elements matching their IP violation type

## Asset Optimization

Follow the IMAGE_OPTIMIZATION_GUIDE.md in the assets root directory:
- Use PNG format for sprites with transparency
- Keep file sizes under 30KB per sprite
- Ensure clear silhouettes at small sizes
- Use distinct colors for easy identification during gameplay

## Placeholder Sprites

Temporary placeholder SVG files are provided for development. Replace with final PNG sprites before production.
