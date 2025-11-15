# Image Optimization Guide

## Quick Reference

**Goal:** Keep each image under 50 KB while maintaining quality

## Online Tools (Easiest)

### 1. TinyPNG (Recommended)
- **URL:** https://tinypng.com
- **How to use:**
  1. Drag and drop images
  2. Download compressed versions
  3. Replace original files
- **Results:** 50-70% size reduction, no visible quality loss
- **Limit:** 20 images at a time (free)

### 2. Squoosh (Google)
- **URL:** https://squoosh.app
- **How to use:**
  1. Upload image
  2. Adjust quality slider (80-85% is good)
  3. Compare before/after
  4. Download
- **Results:** Fine-tuned control, WebP support
- **Limit:** One image at a time

### 3. ImageOptim (Mac Only)
- **URL:** https://imageoptim.com
- **How to use:**
  1. Download and install
  2. Drag images to app
  3. Automatically optimized
- **Results:** Lossless compression
- **Limit:** None (batch processing)

## Command Line Tools (For Batch Processing)

### Install Tools

**Mac (Homebrew):**
```bash
brew install pngquant optipng webp
```

**Windows (Chocolatey):**
```bash
choco install pngquant optipng webp
```

**Linux (apt):**
```bash
sudo apt install pngquant optipng webp
```

### Optimize PNG Images

**Single file:**
```bash
pngquant --quality=80-90 --ext .png --force image.png
```

**All PNG files in directory:**
```bash
# Badges
pngquant --quality=80-90 --ext .png --force assets/badges/*.png

# Trademarks
pngquant --quality=80-90 --ext .png --force assets/trademarks/*.png
```

### Convert to WebP (Better Compression)

**Single file:**
```bash
cwebp -q 85 input.png -o output.webp
```

**Batch convert:**
```bash
# Convert all PNG to WebP
for file in assets/badges/*.png; do
  cwebp -q 85 "$file" -o "${file%.png}.webp"
done
```

## Size Targets

### Badges (128x128 to 256x256)
- **Target:** 10-20 KB per image
- **Format:** PNG or WebP
- **Quality:** 80-85%

### Trademark Logos (200x200 to 300x300)
- **Target:** 20-40 KB per image
- **Format:** PNG or WebP
- **Quality:** 85-90%

### Game Icons (512x512)
- **Target:** 30-60 KB per image
- **Format:** PNG or WebP
- **Quality:** 85-90%

## Optimization Checklist

- [ ] Resize images to appropriate dimensions (don't use 2000x2000 for a 200x200 display)
- [ ] Compress with TinyPNG or similar tool
- [ ] Check file size (should be under 50 KB)
- [ ] Test in app (verify quality is acceptable)
- [ ] Consider WebP for even better compression
- [ ] Remove metadata (EXIF data) to save space

## Before/After Example

### Unoptimized Badge
- Size: 2048x2048 pixels
- File size: 250 KB
- Format: PNG (32-bit)

### Optimized Badge
- Size: 256x256 pixels (resized)
- File size: 15 KB (compressed)
- Format: PNG (24-bit) or WebP
- **Savings: 94%** 🎉

## WebP vs PNG

### PNG
- ✅ Universal support
- ✅ Lossless compression
- ✅ Transparency support
- ❌ Larger file sizes

### WebP
- ✅ 25-35% smaller than PNG
- ✅ Lossless or lossy compression
- ✅ Transparency support
- ✅ Fully supported in Flutter
- ❌ Not supported in very old browsers (not relevant for Flutter apps)

**Recommendation:** Use WebP for 30-40% size savings!

## Automated Optimization Script

Create a script to optimize all images at once:

**optimize_images.sh:**
```bash
#!/bin/bash

echo "Optimizing badges..."
for file in assets/badges/*.png; do
  pngquant --quality=80-90 --ext .png --force "$file"
  echo "Optimized: $file"
done

echo "Optimizing trademarks..."
for file in assets/trademarks/*.png; do
  pngquant --quality=85-90 --ext .png --force "$file"
  echo "Optimized: $file"
done

echo "Done! All images optimized."
```

**Usage:**
```bash
chmod +x optimize_images.sh
./optimize_images.sh
```

## Verification

After optimization, check the results:

```bash
# Check file sizes
du -sh assets/badges/*
du -sh assets/trademarks/*

# Count total size
du -sh assets/badges/
du -sh assets/trademarks/
```

**Expected Results:**
- Badges folder: ~750 KB (50 images × 15 KB)
- Trademarks folder: ~900 KB (30 images × 30 KB)
- **Total: ~1.65 MB** (down from ~4-6 MB)

## Tips

1. **Don't over-optimize:** 80-85% quality is usually perfect
2. **Test on device:** Always check how images look on actual phones
3. **Keep originals:** Save uncompressed versions in a separate folder
4. **Batch process:** Use scripts to optimize many images at once
5. **Use WebP:** For maximum compression with great quality

## Resources

- TinyPNG: https://tinypng.com
- Squoosh: https://squoosh.app
- ImageOptim: https://imageoptim.com
- WebP Converter: https://developers.google.com/speed/webp
- pngquant: https://pngquant.org
