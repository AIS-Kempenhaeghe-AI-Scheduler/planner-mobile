@echo off
setlocal enabledelayedexpansion

REM Version Bump Script for Flutter App (Windows)
REM Usage: scripts\bump_version.bat [patch|minor|major]

REM Default to patch if no argument provided
if "%1"=="" (
    set BUMP_TYPE=patch
) else (
    set BUMP_TYPE=%1
)

REM Validate bump type
if not "%BUMP_TYPE%"=="patch" if not "%BUMP_TYPE%"=="minor" if not "%BUMP_TYPE%"=="major" (
    echo ❌ Error: Invalid bump type. Use 'patch', 'minor', or 'major'
    exit /b 1
)

REM Check if we're in a git repository
git rev-parse --git-dir >nul 2>&1
if errorlevel 1 (
    echo ❌ Error: Not in a git repository
    exit /b 1
)

REM Check for uncommitted changes
git diff-index --quiet HEAD -- >nul 2>&1
if errorlevel 1 (
    echo ❌ Error: You have uncommitted changes. Please commit them first.
    exit /b 1
)

REM Get current version from pubspec.yaml
if not exist "pubspec.yaml" (
    echo ❌ Error: pubspec.yaml not found
    exit /b 1
)

for /f "tokens=2" %%i in ('findstr "^version:" pubspec.yaml') do set CURRENT_VERSION=%%i

for /f "tokens=1 delims=+" %%i in ("%CURRENT_VERSION%") do set VERSION_NAME=%%i
for /f "tokens=2 delims=+" %%i in ("%CURRENT_VERSION%") do set BUILD_NUMBER=%%i

echo 📋 Current version: %CURRENT_VERSION%
echo 📋 Version name: %VERSION_NAME%
echo 📋 Build number: %BUILD_NUMBER%
echo 📋 Bump type: %BUMP_TYPE%

REM Parse version components
for /f "tokens=1,2,3 delims=." %%a in ("%VERSION_NAME%") do (
    set MAJOR=%%a
    set MINOR=%%b
    set PATCH=%%c
)

REM Bump version based on type
if "%BUMP_TYPE%"=="major" (
    set /a MAJOR+=1
    set MINOR=0
    set PATCH=0
) else if "%BUMP_TYPE%"=="minor" (
    set /a MINOR+=1
    set PATCH=0
) else (
    set /a PATCH+=1
)

REM Increment build number
set /a NEW_BUILD=BUILD_NUMBER+1
set NEW_VERSION_NAME=%MAJOR%.%MINOR%.%PATCH%
set NEW_VERSION=%NEW_VERSION_NAME%+%NEW_BUILD%

echo 🚀 New version: %NEW_VERSION%
echo 🚀 New version name: %NEW_VERSION_NAME%
echo 🚀 New build number: %NEW_BUILD%

REM Ask for confirmation
set /p CONFIRM="❓ Do you want to proceed with this version bump? (y/N): "
if /i not "%CONFIRM%"=="y" (
    echo ❌ Version bump cancelled
    exit /b 1
)

REM Update pubspec.yaml
echo 📝 Updating pubspec.yaml...
powershell -Command "(Get-Content pubspec.yaml) -replace '^version: .*', 'version: %NEW_VERSION%' | Set-Content pubspec.yaml"

REM Verify the change
findstr "^version: %NEW_VERSION%" pubspec.yaml >nul
if errorlevel 1 (
    echo ❌ Error: Failed to update version in pubspec.yaml
    exit /b 1
)

echo ✅ Successfully updated version in pubspec.yaml

REM Create git commit
echo 📝 Creating git commit...
git add pubspec.yaml
git commit -m "chore: bump version to %NEW_VERSION%

- Version: %NEW_VERSION_NAME%
- Build: %NEW_BUILD%
- Type: %BUMP_TYPE% bump"

REM Create git tag
echo 🏷️ Creating git tag...
git tag -a "v%NEW_VERSION_NAME%" -m "Release v%NEW_VERSION_NAME%

Version: %NEW_VERSION_NAME%
Build: %NEW_BUILD%"

echo ✅ Version bump completed successfully!
echo.
echo 📋 Summary:
echo   Old version: %CURRENT_VERSION%
echo   New version: %NEW_VERSION%
echo   Git tag: v%NEW_VERSION_NAME%
echo.
echo 📤 Next steps:
echo   1. Push changes: git push origin main
echo   2. Push tags: git push origin --tags
echo   3. Or push both: git push origin main --follow-tags
echo.
echo 🚀 The GitHub Actions workflow will automatically build and deploy when you push to main branch.

pause
