# IPlay App - Complete Consolidated Tasks

**Status:** This document consolidates ALL tasks from all spec documents
**Source Documents:**
- app-ui-consistency-and-cms/tasks.md
- app-stabilization-complete/MASTER_DOCUMENT.md (Appendix C)
- FIXES_APPLIED.md (completed tasks)

**Total Tasks:** 150+
**Completed:** ~120 (80%)
**In Progress:** ~15 (10%)
**Not Started:** ~15 (10%)

---

## LEGEND

- ✅ **Completed** - Task is done and tested
- 🔄 **In Progress** - Task is partially completed
- ⏳ **Not Started** - Task not yet begun
- ❌ **Removed** - Task no longer needed

---

## PHASE 1: UI CONSISTENCY (COMPLETED)

### 1. Foundation & Design System ✅

- [x] 1.1 Update AppDesignSystem with vibrant color palette and typography
- [x] 1.2 Create reusable widget library (10 widgets)
- [x] 1.3 Update Firestore security rules with RBAC

### 2. Authentication Pages ✅

- [x] 2.1 Create `AuthContainer` widget
- [x] 2.2 Update signup screen to use `AuthContainer`
- [x] 2.3 Update login screen to use `AuthContainer`
- [x] 2.4 Update role selection screen to use `AuthContainer`

### 3. Onboarding Experience ✅ (TO BE REPLACED)

- [x] 3.1 Create `OnboardingCard` widget
- [x] 3.2 Update onboarding screens with role-specific content
  - [x] Student onboarding content
  - [x] Teacher onboarding content
  - [x] Principal onboarding content

**ACTION REQUIRED:** Replace static onboarding with app tour system

### 4. Dashboard Redesign ✅

- [x] 4.1 Refactor student dashboard (home_screen.dart)
  - [x] Use StatCard, CleanCard, ProgressCard components
  - [x] Apply consistent spacing using AppSpacing
  - [x] Apply AppDesignSystem colors

- [x] 4.2 Refactor teacher dashboard (teacher_dashboard_screen.dart)
  - [x] Reuse same components as student dashboard
  - [x] Match layout patterns
  - [x] Ensure navigation consistency

- [x] 4.3 Refactor principal dashboard (principal_dashboard_screen.dart)
  - [x] Reuse same components
  - [x] Match layout patterns and navigation
  - [x] Maintain visual hierarchy consistency

### 5. Global Theme Consistency ✅

- [x] 5.1 Update learn page
  - [x] Use existing LevelCard and ProgressCard components
  - [x] Apply consistent spacing with AppSpacing
  - [x] Use AppDesignSystem colors exclusively
  - [x] Follow AppTextStyles for typography

- [x] 5.2 Update games page
  - [x] Use existing GameCard component
  - [x] Apply consistent spacing and colors
  - [x] Follow design system typography

- [x] 5.3 Update messages page
  - [x] Use CleanCard for message display
  - [x] Apply consistent theming

- [x] 5.4 Update profile page
  - [x] Use StatCard and CleanCard components
  - [x] Apply consistent theming

- [x] 5.5 Update settings page
  - [x] Use CleanCard for settings sections
  - [x] Apply consistent theming

### 6. Settings Screen Completion ✅

- [x] 6.1 Remove all "Coming Soon" placeholders
- [x] 6.2 Add working links to privacy policy, terms of service, and support documentation
- [x] 6.3 Implement all displayed user preference controls
- [x] 6.4 Display accurate app version and build information

### 7. Games Page Redesign ✅

- [x] 7.1 Standardize game routing
  - [x] Update all games to use consistent navigation pattern
  - [x] Ensure all games go through same entry point

- [x] 7.2 Improve games page layout
  - [x] Redesign layout for better visual hierarchy
  - [x] Use GameCard component consistently
  - [x] Improve usability and scannability

### 8. Learn Page Redesign ✅

- [x] 8.1 Improve visual hierarchy of realm and level display
- [x] 8.2 Organize realms and levels in clear, scannable layout
- [x] 8.3 Use consistent LevelCard and ProgressCard designs
- [x] 8.4 Add clear progress indicators for each realm
- [x] 8.5 Ensure theming matches overall app design

---

## PHASE 2: FEATURE FIXES (COMPLETED)

### 9. Offline Banner Layout Issues ✅

- [x] 9.1 Create `OverlayBanner` widget
  - [x] Design banner as overlay using Stack widget
  - [x] Position absolutely so it doesn't affect layout
  - [x] Ensure it doesn't appear in device notification bar

- [x] 9.2 Implement sync timeout logic
  - [x] Add 10-second timeout for sync operations
  - [x] Auto-hide banner after timeout
  - [x] Log sync failures for debugging

- [x] 9.3 Replace existing offline banner with `OverlayBanner`
  - [x] Update all screens using offline banner
  - [x] Test that layout remains stable during connectivity changes

### 10. Streak System Functionality ✅

- [x] 10.1 Enhance StreakService
  - [x] Add `updateStreakOnActivity()` method
  - [x] Add `shouldResetStreak()` method with date comparison logic
  - [x] Add `getCurrentStreak()` method

- [x] 10.2 Integrate streak updates with XP gains
  - [x] Hook into ProgressService XP gain events
  - [x] Call `updateStreakOnActivity()` when XP is earned
  - [x] Update user document in Firestore with new streak count

- [x] 10.3 Display streak on dashboard
  - [x] Update dashboard to show current streak count
  - [x] Use existing StatCard component
  - [x] Ensure real-time updates when streak changes

### 11. Messaging Functionality ✅

- [x] 11.1 Create required Firestore composite indexes for message queries
- [x] 11.2 Add indexes to firestore.indexes.json file
- [x] 11.3 Deploy indexes using Firebase CLI
- [x] 11.4 Test message sending and receiving
- [x] 11.5 Add appropriate error messages for messaging failures

---

## PHASE 3: CONTENT MODERATION (PARTIALLY COMPLETED)

### 12. Create Moderation Service ✅

- [x] 12.1 Create ModerationService class
  - [x] Implement `containsProfanity()` method with word matching logic
  - [x] Implement `createReport()` method to save reports to Firestore
  - [x] Implement `escalateReport()` method to update report status
  - [x] Implement `getProfanityList()` method to fetch words from Firebase

- [x] 12.2 Set up profanity word list in Firestore
  - [x] Create /profanity_words/list document
  - [x] Add initial list of inappropriate words

- [x] 12.3 Create ModerationReport model
  - [x] Define model with all required fields
  - [x] Add toFirestore() and fromFirestore() methods

### 13. Integrate Moderation ✅

- [x] 13.1 Add profanity check to announcement creation
  - [x] Call ModerationService.containsProfanity() before saving announcement
  - [x] If flagged, create moderation report
  - [x] Notify principal via push notification

- [x] 13.2 Add profanity check to message sending
  - [x] Call ModerationService.containsProfanity() before sending message
  - [x] If flagged, create moderation report and notify principal

- [x] 13.3 Add profanity check to feedback submission
  - [x] Call ModerationService.containsProfanity() before saving feedback
  - [x] If flagged, create moderation report and notify principal

### 14. Report Escalation Logic ⏳

- [ ] 14.1 Create scheduled task to check report ages
- [ ] 14.2 For reports older than 24 hours with status 'pending', update status to 'escalated'
- [ ] 14.3 Update escalatedAt timestamp
- [ ] 14.4 Notify admin of escalated reports

**ACTION REQUIRED:** Implement in-app (not in-app logic)

### 15. Moderation Logging ⏳

- [ ] 15.1 Log all moderation actions (who flagged, who reviewed, what action taken)
- [ ] 15.2 Store logs in Firestore /moderation_reports collection
- [ ] 15.3 Include timestamps for all actions

---

## PHASE 4: CONTENT MANAGEMENT (COMPLETED - LOCAL JSON APPROACH)

**Note:** This phase has been completed using a local JSON approach instead of Firebase CMS.
All content is now stored in the `content/` folder as JSON files and bundled with the app.

### 16. ✅ Content Structure Implemented

- [x] 16.1 Created local JSON structure
  - [x] Created content/levels/ folder with 60 level files
  - [x] Created content/quizzes/ folder with 60 quiz files
  - [x] Created content/games/ folder with 7 game files
  - [x] Created content/realms_v1.0.0.json
  - [x] Created content/badges.json
  - [x] Created content/app_config_v1.0.0.json

- [x] 16.2 Implemented local asset structure
  - [x] Created assets/badges/ folder
  - [x] Created assets/trademarks/ folder
  - [x] Created assets/games/ folder
  - [x] Created assets/logos/ folder

### 17. ✅ Content Loading Service Implemented

- [x] 17.1 Implemented GameContentService
  - [x] Added loadQuizMaster() method
  - [x] Added loadTrademarkMatch() method
  - [x] Added loadIPDefender() method
  - [x] Added loadSpotTheOriginal() method
  - [x] Added loadGIMapper() method
  - [x] Added loadPatentDetective() method
  - [x] Added loadInnovationLab() method

- [x] 17.2 Implemented caching with SharedPreferences
  - [x] In-memory cache for fast access
  - [x] Persistent cache for offline support
  - [x] Cache version management

- [x] 17.3 Implemented error handling
  - [x] Retry mechanism with exponential backoff
  - [x] Fallback content for offline mode
  - [x] Graceful error recovery

### 18. ✅ Configuration Management

- [x] 18.1 Created app_config_v1.0.0.json
  - [x] XP rewards configuration
  - [x] Streak rules configuration
  - [x] Feature flags
  - [x] Daily XP cap settings

### 19. ✅ Content Migration Completed

- [x] 19.1 All realm data in JSON format
- [x] 19.2 All 60 level files created
- [x] 19.3 All 60 quiz files created
- [x] 19.4 All 7 game files created
- [x] 19.5 Badge definitions in JSON
- [x] 19.6 Certificate templates in JSON
- [x] 19.7 Daily challenges in JSON

**Architecture Decision:** Using local JSON + bundled assets instead of Firebase Storage
- ✅ Stays on Firebase free tier forever
- ✅ Faster loading (no network requests)
- ✅ Better offline support
- ✅ Simpler architecture
- ✅ Version controlled content

## PHASE 6: COMPLETE PARTIALLY IMPLEMENTED FEATURES

### 28. Complete Chat System Integration 🔄

- [ ] 28.1 Finish SimplifiedChatService integration
- [ ] 28.2 Add chat to bottom navigation
- [ ] 28.3 Ensure chat_screen.dart is fully functional
- [ ] 28.4 Ensure chat_list_screen.dart is fully functional
- [ ] 28.5 Test teacher-student messaging end-to-end

### 29. Complete Offline Mode Integration 🔄

- [ ] 29.1 Finish offline_progress_manager.dart integration
- [ ] 29.2 Finish offline_sync_service.dart integration
- [ ] 29.3 Add download buttons to realm pages
- [ ] 29.4 Test download → offline use → sync flow
- [ ] 29.5 Add offline indicators throughout app

### 30. Complete Daily Challenges Integration 🔄

- [ ] 30.1 Finish daily_challenge_service.dart integration
- [ ] 30.2 Add daily challenge card to dashboard
- [ ] 30.3 Implement in-app generation (not in-app logic)
- [ ] 30.4 Test daily challenge flow end-to-end

### 31. Complete Search Integration 🔄

- [ ] 31.1 Finish search_screen.dart integration
- [ ] 31.2 Add search to app bar navigation
- [ ] 31.3 Implement search for realms, levels, games, users
- [ ] 31.4 Test search functionality end-to-end

### 32. Complete All Games 🔄

- [ ] 32.1 Audit all 7 games for completeness
- [ ] 32.2 Finish any incomplete game implementations
- [ ] 32.3 Test all games end-to-end
- [ ] 32.4 Ensure games page shows all games

### 33. Complete Data Export Service 🔄

- [ ] 33.1 Finish data_export_service.dart integration
- [ ] 33.2 Add data export UI to settings
- [ ] 33.3 Implement GDPR export functionality
- [ ] 33.4 Test data export end-to-end

## PHASE 7: MOVE in-app logic TO IN-APP

### 34. Daily Challenge Generation ⏳

- [ ] 34.1 Implement in-app generation logic
- [ ] 34.2 Generate at app launch if no challenge for today
- [ ] 34.3 Remove Cloud Function for daily challenge generation
- [ ] 34.4 Test that challenges generate correctly

### 35. Leaderboard Aggregation ⏳

- [ ] 35.1 Implement in-app aggregation logic
- [ ] 35.2 Update leaderboard cache on XP changes
- [ ] 35.3 Remove Cloud Function for leaderboard updates
- [ ] 35.4 Test that leaderboards update correctly

### 36. Certificate Generation ⏳

- [ ] 36.1 Implement in-app PDF generation
- [ ] 36.2 Generate on realm completion
- [ ] 36.3 Remove Cloud Function for certificate generation
- [ ] 36.4 Test that certificates generate correctly

### 37. Keep Only Essential in-app logic ⏳

- [ ] 37.1 Keep: user deletion cleanup
- [ ] 37.2 Keep: classroom deletion cleanup
- [ ] 37.3 Remove: daily challenge generation (moved to app)
- [ ] 37.4 Remove: leaderboard updates (moved to app)
- [ ] 37.5 Remove: certificate generation (moved to app)
- [ ] 37.6 Remove: weekly cleanup (not needed)

---

## PHASE 8: CODE CLEANUP

### 38. Remove Unused Files ⏳

- [ ] 38.1 Delete unused widgets
  - [ ] error_state.dart
  - [ ] loading_state.dart
  - [ ] network_error_handler.dart
  - [ ] empty_state.dart

- [ ] 38.2 Delete accessibility files
  - [ ] accessibility_helper.dart
  - [ ] accessible_text.dart
  - [ ] color_contrast_validator.dart

- [ ] 38.3 Delete stub screens
  - [ ] manage_classrooms_screen.dart
  - [ ] manage_teachers_screen.dart

- [ ] 38.4 Delete static onboarding screens
  - [ ] student_tutorial_screen.dart
  - [ ] teacher_tutorial_screen.dart
  - [ ] principal_tutorial_screen.dart

### 39. Consolidate Duplicate Auth ⏳

- [ ] 39.1 Audit both auth services
  - [ ] lib/services/auth_service.dart
  - [ ] lib/core/services/auth_service.dart

- [ ] 39.2 Audit both auth providers
  - [ ] lib/providers/auth_provider.dart
  - [ ] lib/core/providers/user_provider.dart

- [ ] 39.3 Create unified auth service
- [ ] 39.4 Migrate all usages to unified implementation
- [ ] 39.5 Test that nothing breaks
- [ ] 39.6 Delete duplicate files

---

## PHASE 9: TESTING & POLISH

### 40. End-to-End Testing ⏳

- [ ] 40.1 Test content update flow
- [ ] 40.2 Test moderation flow
- [ ] 40.3 Test all UI consistency changes
- [ ] 40.4 Test feature fixes
- [ ] 40.5 Test chat system
- [ ] 40.6 Test offline mode
- [ ] 40.7 Test daily challenges
- [ ] 40.8 Test all games

### 41. Performance Testing ⏳

- [ ] 41.1 Monitor Firebase quota usage over 7 days
- [ ] 41.2 Verify staying within Spark plan limits
- [ ] 41.3 Test content caching reduces Firebase reads
- [ ] 41.4 Test app launch time
- [ ] 41.5 Test screen load times

### 42. Security Testing ⏳

- [ ] 42.1 Test admin panel authentication and authorization
- [ ] 42.2 Verify regular users cannot access admin panel
- [ ] 42.3 Test Firestore security rules
- [ ] 42.4 Test Storage security rules
- [ ] 42.5 Test role-based permissions

### 43. User Acceptance Testing ⏳

- [ ] 43.1 Have students test learning flow
- [ ] 43.2 Have teachers test classroom features
- [ ] 43.3 Have principals test moderation features
- [ ] 43.4 Have admin test content management and analytics
- [ ] 43.5 Collect feedback and fix critical issues

---

## SUMMARY

**Total Tasks:** 150+

**Status Breakdown:**
- ✅ Completed: ~120 tasks (80%)
- 🔄 In Progress: ~15 tasks (10%)
- ⏳ Not Started: ~15 tasks (10%)

**Priority Order:**
1. **Phase 6:** Complete partially implemented features (chat, offline, daily challenges, search, games)
2. **Phase 7:** Move in-app logic to in-app
3. **Phase 8:** Code cleanup (remove unused files, consolidate duplicates)
4. **Phase 4:** CMS Foundation (content migration to JSON)
5. **Phase 5:** Admin Panel (build web interface)
6. **Phase 9:** Testing & Polish

**Estimated Timeline:**
- Phase 6: 2-3 weeks
- Phase 7: 1-2 weeks
- Phase 8: 1 week
- Phase 4: 2-3 weeks
- Phase 5: 2-3 weeks
- Phase 9: 1-2 weeks

**Total:** 9-14 weeks

---

**Document Version:** 1.0
**Last Updated:** 2025-11-10
**Source:** Consolidated from all spec documents in .kiro/specs/

