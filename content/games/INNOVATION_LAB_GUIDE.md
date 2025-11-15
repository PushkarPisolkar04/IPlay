# Innovation Lab CMS Guide

## Overview
The Innovation Lab game provides a creative canvas for students to design products, logos, and packaging while learning about intellectual property protection. After creating designs, students answer questions about IP filing to understand what can be patented, copyrighted, or trademarked.

## Game Structure

### Game Flow
1. **Template Selection**: Students choose from 10 design templates
2. **Creative Design**: Use drawing tools to create their design
3. **IP Quiz**: Answer 5 random questions about IP protection
4. **Learning**: Receive educational content based on their answers

### Key Features
- **Drawing Tools**: 8 different tools (pencil, brush, eraser, shapes, text)
- **Color Palette**: 21 predefined colors
- **Templates**: 10 professional templates across various categories
- **IP Questions**: 20 educational questions about IP protection
- **Layer System**: Support for multiple layers with visibility control
- **Grid System**: Optional grid for precise design work

## Content Structure

### 1. Drawing Tools (8 tools)

Each tool has the following properties:
- **id**: Unique identifier
- **name**: Display name
- **icon**: Material icon name
- **type**: Tool type (freehand, eraser, shape, text)
- **strokeWidthRange**: Min and max stroke width
- **defaultStrokeWidth**: Default width setting
- **supportsOpacity**: Whether opacity can be adjusted
- **supportsColor**: Whether color can be changed
- **supportsFill**: Whether shapes can be filled (shapes only)

#### Available Tools:
1. **Pencil** - Fine drawing (1-5px)
2. **Brush** - Thick painting (5-30px)
3. **Eraser** - Remove strokes (10-50px)
4. **Line** - Straight lines
5. **Rectangle** - Rectangular shapes
6. **Circle** - Circular shapes
7. **Polygon** - Multi-sided shapes (3-8 sides)
8. **Text** - Text labels (12-72pt)

### 2. Color Palette (21 colors)

Predefined Material Design colors including:
- Basic: Black, White, Grey
- Primary: Red, Blue, Green, Yellow
- Extended: Pink, Purple, Indigo, Cyan, Teal, Orange, Brown, etc.

### 3. Design Templates (10 templates)

Templates are organized by category and difficulty:

#### Easy Templates (3):
1. **Logo Design** - Branding category
   - Circular and square guides
   - 2 layers (guides + logo)
   - No grid

2. **App Icon Design** - Digital category
   - Rounded square guide
   - Grid enabled (10px)
   - 2 layers

3. **Business Card** - Branding category
   - Standard dimensions
   - Grid enabled (5px)
   - 3 layers (front, logo, info)

#### Medium Templates (4):
4. **Product Blueprint** - Product design category
   - Technical grid (20px)
   - Center guides
   - 2 layers

5. **Poster Design** - Marketing category
   - Large grid (25px)
   - Horizontal guides
   - 3 layers (background, content, text)

6. **T-Shirt Design** - Fashion category
   - T-shirt outline
   - Print area guide
   - 3 layers

7. **Product Label** - Packaging category
   - Grid enabled (10px)
   - Horizontal guides
   - 3 layers (border, brand, info)

#### Hard Templates (3):
8. **Packaging Design** - Packaging category
   - Box template with fold lines
   - Grid enabled (15px)
   - 3 layers

9. **Infographic Layout** - Information category
   - Large grid (30px)
   - Multiple section guides
   - 4 layers

10. **Patent Diagram** - Technical category
    - Technical grid (15px)
    - Center guides
    - 4 layers (grid, drawing, callouts, labels)

### 4. IP Filing Questions (20 questions)

Questions are categorized by difficulty:

#### Easy Questions (5 questions - 15 points each):
- Logo trademark protection
- Copyright for creative works
- Product/business name protection
- Character copyright
- Basic IP concepts

#### Medium Questions (9 questions - 20 points each):
- Utility vs design patents
- Trade secrets
- Design patent applications
- Software/app protection
- Improvement patents
- Copyright duration
- Photography copyright
- Trademark vs trade name
- Aesthetic design protection

#### Hard Questions (6 questions - 25 points each):
- Mathematical formulas in India
- Layered IP protection
- Non-traditional trademarks (colors)
- New use patents
- Non-obviousness requirement
- Business methods in India
- Dual patent protection

## Educational Content

Each question includes:
1. **Question**: The main question text
2. **Context**: Background information
3. **Options**: 4 multiple choice answers
4. **Correct Answer**: Index of correct option
5. **Explanation**: Why the answer is correct
6. **Educational Content**:
   - Title
   - Detailed explanation
   - Real-world examples

### Topics Covered:
- Patents (utility, design, improvement, new use)
- Trademarks (logos, colors, trade dress, trade names)
- Copyright (automatic protection, duration, limitations)
- Trade Secrets (recipes, formulas, confidential info)
- Indian IP Law specifics
- Layered IP protection strategies
- What cannot be patented in India

## Implementation Notes

### Template Data Structure
Each template includes:
- **gridEnabled**: Boolean for grid visibility
- **gridSize**: Grid spacing in pixels (optional)
- **gridColor**: Hex color for grid lines (optional)
- **backgroundColor**: Canvas background color
- **layers**: Array of layer objects
  - id, name, visible, locked, opacity
- **guides**: Array of guide objects (optional)
  - type, position/coordinates

### Layer System
Layers support:
- Visibility toggle
- Lock/unlock for editing
- Opacity adjustment
- Reordering (drag to reorder)
- Up to 4 layers per template

### Grid System
- Optional blueprint-style grid
- Configurable size (5-30px)
- Configurable color
- Toggle on/off during design

### Undo/Redo
- 20 action history
- Supports all drawing operations
- Clear undo stack on template change

### Export
- Save designs to local storage
- Export to PNG format
- Include all visible layers
- Maintain aspect ratio

## Game Mechanics

### Scoring
- 5 questions per game (randomly selected)
- Points based on difficulty:
  - Easy: 15 points
  - Medium: 20 points
  - Hard: 25 points
- Maximum score: 125 points (5 hard questions)
- Minimum score: 75 points (5 easy questions)

### XP Rewards
- Completion: 100 XP
- Perfect Score: 200 XP (bonus)
- First Time: 120 XP
- High Score: 250 XP

### Leaderboards
- Classroom scope
- School scope
- Global scope

## Content Guidelines

### Adding New Templates
1. Choose appropriate category
2. Set difficulty level
3. Define layer structure (2-4 layers)
4. Configure grid settings if needed
5. Add helpful guides
6. Create thumbnail image

### Adding New Questions
1. Write clear question and context
2. Create 4 plausible options
3. Provide detailed explanation
4. Add educational content with examples
5. Set appropriate difficulty
6. Assign point value (15/20/25)
7. Ensure accuracy of legal information

### Question Writing Tips
- Use real-world scenarios
- Focus on practical applications
- Include Indian IP law specifics
- Provide concrete examples
- Explain common misconceptions
- Use clear, simple language
- Avoid legal jargon when possible

## Asset Requirements

### Template Thumbnails
- Location: `assets/templates/`
- Format: PNG
- Size: 200x200px recommended
- Naming: `{template_id}_thumb.png`

### Icons
- Use Material Design icons
- Specified by icon name (e.g., "edit", "brush")
- Flutter will render from icon font

## Testing Checklist

- [ ] All 8 drawing tools work correctly
- [ ] Color picker displays all 21 colors
- [ ] All 10 templates load properly
- [ ] Grid system toggles correctly
- [ ] Layer visibility and locking work
- [ ] Undo/redo functions properly (20 actions)
- [ ] All 20 questions display correctly
- [ ] Educational content shows after answers
- [ ] Scoring calculates correctly
- [ ] XP rewards are granted
- [ ] Designs can be saved and exported
- [ ] JSON structure is valid

## Future Enhancements

Potential additions:
- More templates (web design, book cover, etc.)
- Additional drawing tools (gradient, pattern fill)
- Import images as reference
- Collaborative design mode
- Template customization
- More IP questions (target: 50+)
- Video tutorials for each template
- AI-powered design suggestions
- Export to multiple formats (SVG, PDF)

## References

- Indian Patents Act, 1970
- Indian Copyright Act, 1957
- Trade Marks Act, 1999
- Design Act, 2000
- Material Design Icons: https://fonts.google.com/icons
