# IPlay Learning Content

This directory contains JSON files for all learning content in the IPlay app.

## Content Structure

Each realm has multiple levels, with content stored in individual JSON files following the naming convention: `{realm_id}_level_{number}.json`

### Realms and Levels

1. **Copyright Realm** (8 levels)
   - Level 1: What is Copyright? ✅
   - Level 2: Types of Copyright ✅
   - Level 3: Ownership (TODO)
   - Level 4: Duration (TODO)
   - Level 5: Fair Use & Exceptions (TODO)
   - Level 6: Infringement (TODO)
   - Level 7: Registration (TODO)
   - Level 8: Enforcement (TODO)

2. **Trademark Realm** (8 levels)
   - Level 1: Introduction to Trademarks ✅
   - Level 2: Types of Trademarks (TODO)
   - Level 3: Registration Process (TODO)
   - Level 4: Trademark Search (TODO)
   - Level 5: Trademark Infringement (TODO)
   - Level 6: Well-Known Marks (TODO)
   - Level 7: International Protection (TODO)
   - Level 8: Trademark Maintenance (TODO)

3. **Patent Realm** (9 levels)
   - Level 1: Understanding Patents ✅
   - Level 2: Types of Patents (TODO)
   - Level 3: Patentability Criteria (TODO)
   - Level 4: Patent Search (TODO)
   - Level 5: Patent Application (TODO)
   - Level 6: Patent Examination (TODO)
   - Level 7: Patent Infringement (TODO)
   - Level 8: Patent Licensing (TODO)
   - Level 9: International Patents (TODO)

4. **Industrial Design Realm** (7 levels)
   - Level 1: Introduction to Industrial Designs ✅
   - Level 2: Design Registration (TODO)
   - Level 3: Design vs Patent (TODO)
   - Level 4: Design Infringement (TODO)
   - Level 5: International Design Protection (TODO)
   - Level 6: Design Portfolio Management (TODO)
   - Level 7: Design Licensing (TODO)

5. **Geographical Indications Realm** (6 levels)
   - Level 1: Introduction to GI ✅
   - Level 2: Famous Indian GIs (TODO)
   - Level 3: GI Registration Process (TODO)
   - Level 4: GI Protection & Enforcement (TODO)
   - Level 5: International GI Systems (TODO)
   - Level 6: GI and Rural Development (TODO)

6. **Trade Secrets Realm** (6 levels)
   - Level 1: Understanding Trade Secrets ✅
   - Level 2: Protecting Trade Secrets (TODO)
   - Level 3: NDAs and Confidentiality (TODO)
   - Level 4: Trade Secret vs Patent (TODO)
   - Level 5: Trade Secret Misappropriation (TODO)
   - Level 6: International Trade Secret Protection (TODO)

**Total: 44 levels** (6 completed, 38 TODO)

## JSON Schema

All content files follow the schema defined in `schema.json`. Key fields include:

- `levelId`: Unique identifier (e.g., "copyright_level_1")
- `realmId`: Realm identifier (e.g., "copyright")
- `levelNumber`: Sequential number within realm
- `name`: Display name of the level
- `difficulty`: "Basic", "Intermediate", or "Advanced"
- `xpReward`: XP awarded for completion (50-500)
- `estimatedMinutes`: Time to complete (5-60 minutes)
- `videoUrl`: YouTube video ID or URL
- `videoDuration`: Video length in seconds
- `contentBlocks`: Array of content sections
- `keyTakeaways`: 3-7 key learning points
- `quizQuestions`: 5-8 multiple choice questions
- `passingScore`: Minimum percentage to pass (typically 60)
- `version`: Semantic version (e.g., "1.0.0")
- `updatedAt`: ISO 8601 timestamp

## Content Block Types

- `text`: Regular text content
- `image`: Image with optional caption
- `video`: Embedded video
- `example`: Real-world example with title
- `case_study`: Detailed case study with title
- `summary`: Summary section

## Quiz Questions

Each quiz question includes:
- `question`: The question text
- `options`: Array of 4 answer choices
- `correctIndex`: Index of correct answer (0-3)
- `explanation`: Explanation of the correct answer

## Adding New Content

1. Create a new JSON file following the naming convention
2. Follow the schema defined in `schema.json`
3. Include 5-8 quiz questions with explanations
4. Set appropriate difficulty level and XP reward
5. Update this README with the new level

## Content Guidelines

- Keep content concise and engaging
- Use real-world examples from India
- Include case studies where relevant
- Ensure quiz questions test understanding, not memorization
- Provide clear explanations for quiz answers
- Use appropriate difficulty progression (Basic → Intermediate → Advanced)
- Estimate time realistically (including video and quiz)

## Version Control

- Increment patch version (x.x.1) for minor content fixes
- Increment minor version (x.1.0) for content additions
- Increment major version (1.0.0) for major content restructuring
- Update `updatedAt` timestamp when making changes
