@echo off
echo 🚀 Setting up Automatic APK Deployment with GitHub Actions
echo ==========================================================

REM Check if we're in a git repository
git rev-parse --git-dir >nul 2>&1
if errorlevel 1 (
    echo ❌ Error: Not in a git repository. Please initialize git first:
    echo    git init
    echo    git add .
    echo    git commit -m "Initial commit"
    echo    git branch -M main
    echo    git remote add origin ^<your-repo-url^>
    echo    git push -u origin main
    pause
    exit /b 1
)

echo.
echo 📋 Current Setup Status:
echo ------------------------

REM Check current version
if exist "pubspec.yaml" (
    for /f "tokens=2" %%i in ('findstr "^version:" pubspec.yaml') do set CURRENT_VERSION=%%i
    echo ✅ Current version: !CURRENT_VERSION!
) else (
    echo ❌ pubspec.yaml not found
)

REM Check workflow file
if exist ".github\workflows\deploy.yml" (
    echo ✅ GitHub Actions workflow configured
) else (
    echo ❌ GitHub Actions workflow not found
)

REM Check if remote repository exists
git remote get-url origin >nul 2>&1
if not errorlevel 1 (
    for /f %%i in ('git remote get-url origin') do set REPO_URL=%%i
    echo ✅ Git remote configured: !REPO_URL!
) else (
    echo ❌ Git remote not configured
)

echo.
echo 🔐 Required GitHub Secrets (for production signing):
echo ---------------------------------------------------
echo Go to your repository on GitHub:
echo Settings → Secrets and variables → Actions → New repository secret
echo.
echo Add these secrets (optional - debug signing used if not provided):
echo • KEYSTORE_BASE64 - Base64 encoded keystore file
echo • KEY_ALIAS - Keystore key alias
echo • STORE_PASSWORD - Keystore store password
echo • KEY_PASSWORD - Keystore key password

echo.
echo 📝 To create KEYSTORE_BASE64:
echo -----------------------------
echo [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes("your-keystore.jks")) ^| clip

echo.
echo 🎯 Next Steps:
echo -------------
echo 1. Add GitHub secrets (if you have a production keystore)
echo 2. Commit and push your changes:
echo    git add .
echo    git commit -m "feat: add automatic APK deployment"
echo    git push origin main
echo.
echo 3. Your app will be automatically built and released!
echo.
echo 4. For manual version bumps, use:
echo    scripts\bump_version.bat [patch^|minor^|major]
echo.
echo 5. Or trigger manually from GitHub Actions UI

echo.
echo 📖 Documentation:
echo ----------------
echo • Deployment Guide: docs\DEPLOYMENT.md
echo • Workflows Info: .github\workflows\README.md

echo.
echo ✅ Setup complete! Your repository is ready for automatic APK deployment.
pause
