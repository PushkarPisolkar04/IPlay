# GI Mapper - Implementation Guide

## Overview
The GI Mapper game has been fully populated with 40 Indian Geographical Indication (GI) products covering all major states and categories. This document provides a complete guide to the implementation.

## CMS Content Summary

### Total Products: 40

#### By Category:
- **Beverages:** 6 products (Tea, Coffee, Feni)
- **Food Products:** 12 products (Rice, Mangoes, Sweets, Fruits)
- **Textiles:** 11 products (Silk, Shawls, Embroidery, Fabrics)
- **Handicrafts:** 7 products (Toys, Pottery, Instruments, Art)
- **Spices:** 4 products (Pepper, Cardamom, Chilli, Bay Leaf)

#### By Difficulty:
- **Easy:** 10 products (10 points each)
- **Medium:** 18 products (15 points each)
- **Hard:** 12 products (20 points each)

#### By Region:
- **North:** 11 products (Punjab, Haryana, UP, Rajasthan, HP, UK, J&K, Delhi)
- **South:** 12 products (Karnataka, Kerala, Tamil Nadu, Andhra Pradesh, Telangana)
- **East:** 4 products (West Bengal, Bihar, Odisha)
- **West:** 5 products (Maharashtra, Gujarat, Goa)
- **Central:** 2 products (Madhya Pradesh, Chhattisgarh)
- **Northeast:** 6 products (Assam, Sikkim, Meghalaya, Mizoram, Manipur, Arunachal Pradesh)

## Featured Products

### Famous GI Products Included:
1. **Darjeeling Tea** (WB) - First Indian GI product (2003)
2. **Basmati Rice** (Punjab) - World-famous aromatic rice
3. **Alphonso Mango** (Maharashtra) - King of Mangoes
4. **Kashmir Pashmina** (J&K) - Luxurious wool
5. **Kanchipuram Silk** (TN) - Traditional silk sarees
6. **Mysore Silk** (Karnataka) - Royal silk
7. **Channapatna Toys** (Karnataka) - Colorful wooden toys
8. **Banaras Brocades** (UP) - Gold thread silk
9. **Tirupati Laddu** (AP) - Sacred temple sweet
10. **Madhubani Painting** (Bihar) - Traditional folk art

### Lesser-Known GI Products:
1. **Aranmula Kannadi** (Kerala) - Unique metal mirror
2. **Pochampally Ikat** (Telangana) - Tie-dye textile
3. **Bhavani Jamakkalam** (TN) - Traditional floor mat
4. **Sikkim Large Cardamom** - Himalayan spice
5. **Manipur Black Rice** - Nutritious black rice
6. **Mizo Chilli** - Extremely hot variety
7. **Uttarakhand Tejpat** - Aromatic bay leaf
8. **Chhattisgarh Kosa Silk** - Golden tussar silk

## Data Structure

Each GI product includes:
- **id:** Unique identifier (gi_001 to gi_040)
- **name:** Product name
- **state:** Full state name
- **stateCode:** Two-letter state code
- **coordinates:** Latitude and longitude
- **category:** beverage, food, textile, handicraft, spice, art
- **imageUrl:** Path to product image (assets/gi/)
- **description:** Detailed product description
- **registrationYear:** Year of GI registration
- **uniqueCharacteristics:** Array of distinctive features
- **hint:** Helpful clue for players
- **difficulty:** easy, medium, or hard
- **points:** Score value (10, 15, or 20)

## Map Data

### India Map SVG
- **Location:** `assets/maps/india_map.svg`
- **Dimensions:** 800x1000 pixels
- **Features:**
  - All 29 states and Delhi
  - Interactive state paths with hover effects
  - Color-coded by region
  - State labels with codes
  - Responsive design
  - Touch-friendly for mobile

### State Colors by Region:
- **North:** Yellow/Blue tones (Punjab, Haryana, UP, etc.)
- **South:** Pink/Orange tones (Karnataka, Kerala, TN, AP, TG)
- **East:** Green/Orange tones (West Bengal, Bihar, Odisha)
- **West:** Purple/Yellow tones (Maharashtra, Gujarat, Goa)
- **Central:** Pink/Green tones (MP, Chhattisgarh)
- **Northeast:** Blue/Cyan tones (Assam, Sikkim, etc.)

## Assets Required

### Product Images (40 total)
All images should be placed in `assets/gi/` directory:
- Format: PNG with transparent/white background
- Size: 300x300 pixels
- File size: Under 100KB each
- Naming: snake_case (e.g., darjeeling_tea.png)

**Status:** Placeholder documentation created. Actual images need to be sourced.

### Map Assets
- ✅ `assets/maps/india_map.svg` - Created (simplified version)
- ✅ `assets/maps/README.md` - Documentation created

## Game Mechanics

### Gameplay Flow:
1. Player sees interactive India map
2. GI product cards appear at bottom (8 random products per game)
3. Player drags product cards to correct states
4. Immediate feedback on correct/incorrect placement
5. Score calculated based on correct mappings
6. Educational info shown for each product

### Scoring System:
- Easy products: 10 points
- Medium products: 15 points
- Hard products: 20 points
- Perfect game bonus: 2x multiplier
- Time bonus: Additional points for quick completion

### Educational Features:
- Product descriptions and history
- Registration year information
- Unique characteristics
- Hints for difficult products
- Post-game educational mode showing all products

## Implementation Checklist

### ✅ Completed:
1. Created comprehensive CMS file with 40 GI products
2. Added detailed product information (name, state, coordinates, etc.)
3. Included registration years and unique characteristics
4. Created India map SVG with all states
5. Added color-coded regions to map
6. Created asset directory structure (assets/gi/)
7. Updated pubspec.yaml with new asset paths
8. Created documentation files (README.md, guides)
9. Added map data with state codes and colors

### ⏳ Pending:
1. Source and add 40 product images (PNG format)
2. Optimize images for mobile performance
3. Test map SVG rendering in Flutter
4. Implement game screen UI (Phase 7 of tasks)
5. Add drag-and-drop functionality
6. Implement scoring and validation logic
7. Create educational mode display

## Testing Recommendations

### Content Testing:
- Verify all 40 products have correct state mappings
- Check registration years for accuracy
- Validate coordinates for each product
- Ensure descriptions are educational and accurate

### Visual Testing:
- Test map rendering on various screen sizes
- Verify state colors are distinguishable
- Check touch targets for mobile devices
- Test image loading and fallbacks

### Gameplay Testing:
- Test drag-and-drop on touch devices
- Verify scoring calculations
- Check hint system functionality
- Test educational mode display

## Educational Value

### Learning Objectives:
1. **Geography:** Learn Indian states and their locations
2. **Cultural Heritage:** Discover regional specialties
3. **IP Awareness:** Understand GI protection importance
4. **Product Knowledge:** Learn about traditional products
5. **Regional Diversity:** Appreciate India's cultural richness

### Age Appropriateness:
- Target age: 10-18 years
- Difficulty levels accommodate different knowledge levels
- Hints available for challenging products
- Educational content suitable for school curriculum

## Future Enhancements

### Potential Additions:
1. Add more GI products (India has 400+ registered GIs)
2. Include union territories with their GI products
3. Add audio pronunciations for product names
4. Include video clips showing product creation
5. Add quiz mode about GI facts
6. Implement multiplayer competition mode
7. Create seasonal challenges with specific categories
8. Add AR mode to visualize products in 3D

### Content Updates:
1. Regular updates with newly registered GI products
2. Add more detailed product histories
3. Include artisan interviews and stories
4. Add recipes or usage information
5. Link to official GI registry for verification

## Resources

### Official Sources:
- **GI Registry:** https://ipindia.gov.in/registered-gls.htm
- **WIPO Database:** https://www.wipo.int/gis/en/
- **Ministry of Commerce:** https://commerce.gov.in/

### Educational Resources:
- GI product catalogs
- State tourism websites
- Cultural heritage documentation
- Traditional craft associations

## Notes for Developers

### Performance Considerations:
- Lazy load product images
- Cache map SVG for quick rendering
- Optimize touch detection on map
- Use efficient state management for drag-and-drop

### Accessibility:
- Add screen reader support for product names
- Ensure sufficient color contrast
- Provide keyboard navigation alternative
- Add haptic feedback for interactions

### Localization:
- Product names in regional languages
- Descriptions in Hindi and English
- State names in local scripts
- Audio support for multiple languages

## Conclusion

The GI Mapper CMS is now fully populated with 40 diverse Indian GI products covering all major states and categories. The content is educational, engaging, and ready for implementation in the game UI. The next phase involves sourcing product images and implementing the interactive game mechanics as outlined in the design document.

---

**Last Updated:** November 12, 2025
**Version:** 1.0.0
**Status:** CMS Content Complete, Assets Pending
