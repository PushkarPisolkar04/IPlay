@echo off
REM Script to clean Firebase data for fresh start
REM WARNING: This will DELETE ALL DATA in your Firestore database

echo.
echo ====================================
echo   Firebase Data Cleanup Script
echo ====================================
echo.
echo WARNING: This will DELETE ALL DATA in Firebase!
echo Project: iplay-246b9
echo.
set /p confirmation="Are you ABSOLUTELY sure? Type 'YES' to continue: "

if not "%confirmation%"=="YES" (
    echo Cancelled. No data was deleted.
    exit /b 0
)

echo.
echo Starting cleanup...
echo.

REM Delete all collections
echo Deleting all Firestore collections...
firebase firestore:delete --all-collections --project iplay-246b9 -f

echo.
echo Cleanup complete!
echo.
echo Next steps:
echo 1. Run: flutter run lib/core/utils/populate_badges.dart
echo 2. Create content JSON files (38 files needed)
echo 3. Create test user accounts
echo.
echo See FIREBASE_SETUP_GUIDE.md for detailed instructions.
echo.
pause
