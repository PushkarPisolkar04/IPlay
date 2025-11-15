# Game Data Models

This directory contains all the data models for the seven educational games in the iPlay application.

## Overview

All game models follow a consistent architecture with:
- Base `GameModel` class providing common properties
- Game-specific models extending the base class
- JSON serialization/deserialization support
- Validation logic for data integrity
- Helper methods for game logic

## Models Created

### 1. Base Models (`game_model.dart`)
- **GameModel**: Base class for all games with common properties (id, name, description, color, difficulty, xpReward, etc.)
- **GameRewards**: Reward configuration (completion, perfectScore, firstTime, highScore)
- **LeaderboardConfig**: Leaderboard settings (enabled, scope)

### 2. Quiz Master (`quiz_master_model.dart`)
- **QuizQuestion**: Individual quiz question with options, correct answer, explanation, difficulty, realm, points, and optional hint/image
- **QuizMasterGame**: Extends GameModel with question pool management and random selection logic

Key Features:
- Random selection of 10 questions from 50+ question pool
- Questions categorized by difficulty (easy, medium, hard) and realm (copyright, trademark, patent, etc.)
- Support for hints and images in questions

### 3. Trademark Match (`trademark_match_model.dart`)
- **TrademarkPair**: Logo-company pair with image URL, hint, difficulty, category, and region
- **TrademarkMatchGame**: Extends GameModel with pair selection and shuffling logic

Key Features:
- 30+ trademark pairs (international and Indian brands)
- Random selection and shuffling for matching gameplay
- Filtering by difficulty, category, and region

### 4. IP Defender (`ip_defender_model.dart`)
- **Coordinate**: Position data for game elements
- **Tower**: Tower defense tower with stats, upgrades, and special effects
- **TowerUpgrade**: Upgrade levels for towers
- **Enemy**: Enemy types with health, speed, and abilities
- **Wave**: Wave configuration with enemy spawns
- **WaveEnemy**: Enemy configuration within a wave
- **TowerDefenseLevel**: Complete level data with waves, path, and starting resources
- **IPDefenderGame**: Extends GameModel with tower defense game data

Key Features:
- 4 tower types (Copyright Shield, Patent Cannon, Trademark Barrier, Trade Secret Vault)
- 4 enemy types with different characteristics
- 10 levels with increasing difficulty
- Tower upgrade system
- Path-based enemy movement

### 5. Spot the Original (`spot_the_original_model.dart`)
- **ProductImage**: Image data with original/counterfeit flag and differences list
- **EducationalInfo**: Brand history, trademark info, and identification tips
- **ProductSet**: Set of 4 images (1 original, 3 counterfeits) with educational content
- **SpotTheOriginalGame**: Extends GameModel with product set selection

Key Features:
- 25+ product sets with visual variations
- Educational information about brands and trademarks
- Difference highlighting for counterfeits
- Categories: beverages, food products, electronics, fashion

### 6. GI Mapper (`gi_mapper_model.dart`)
- **GeoCoordinates**: Latitude/longitude for product locations
- **GIProduct**: Geographical Indication product with state, coordinates, and characteristics
- **StateData**: India map state data with SVG paths and colors
- **IndiaMapData**: Complete India map with all states
- **GIMapperGame**: Extends GameModel with GI product mapping

Key Features:
- 40+ GI products covering all major Indian states
- Interactive map with state boundaries
- Product categories: beverages, food, textiles, handicrafts
- Filtering by state, category, and difficulty

### 7. Patent Detective (`patent_detective_model.dart`)
- **PatentInfo**: Patent details (number, inventor, year, title, innovation)
- **DetectiveCase**: Case with progressive clues, suspects, and patent information
- **PatentDetectiveGame**: Extends GameModel with case selection

Key Features:
- 50+ detective cases covering diverse invention categories
- 5 progressive clues per case (general to specific)
- 4 suspect options per case
- Bonus scoring for solving with fewer clues
- Text-based gameplay (no custom images required)

### 8. Innovation Lab (`innovation_lab_model.dart`)
- **DrawingTool**: Tool configuration (pencil, brush, shapes, text, etc.)
- **ColorPaletteItem**: Color with name and hex value
- **DrawingLayer**: Layer management for multi-layer designs
- **TemplateGuide**: Guide lines and shapes for templates
- **TemplateData**: Complete template configuration
- **DesignTemplate**: Pre-made design templates
- **EducationalContent**: Educational information for IP questions
- **IPQuestion**: IP filing questions with educational content
- **InnovationLabGame**: Extends GameModel with drawing tools, templates, and IP quiz

Key Features:
- 8 drawing tools (pencil, brush, eraser, shapes, text)
- 21-color palette
- 10 design templates (product blueprint, logo, packaging, etc.)
- 20+ IP filing questions
- Layer management system
- Template-based design workflow

## Usage Example

```dart
// Load Quiz Master game from JSON
final json = await loadJsonFromAssets('content/games/quiz_master.json');
final quizGame = QuizMasterGame.fromJson(json);

// Select random questions
final questions = quizGame.selectRandomQuestions();

// Get questions by difficulty
final hardQuestions = quizGame.getQuestionsByDifficulty('hard');

// Get questions by realm
final copyrightQuestions = quizGame.getQuestionsByRealm('copyright');
```

## Validation

All models include validation logic to ensure:
- Required fields are not empty
- Numeric values are within valid ranges
- Collections have minimum required items
- Indexes are within bounds
- Data relationships are consistent

## JSON Serialization

All models support:
- `fromJson()` factory constructor for deserialization
- `toJson()` method for serialization
- Proper handling of optional fields
- Type-safe conversions

## Next Steps

These models are ready to be used with:
1. Game CMS loading service (Task 9)
2. Individual game screen implementations (Tasks 10-16)
3. UI components and animations (Task 17)
4. Integration with XP and progress systems (Task 18)
