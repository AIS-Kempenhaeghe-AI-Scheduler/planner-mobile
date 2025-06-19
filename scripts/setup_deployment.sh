#!/bin/bash

# Setup script for GitHub Actions deployment
# This script prepares your repository for automatic APK deployment

set -e

echo "🚀 Setting up Automatic APK Deployment with GitHub Actions"
echo "=========================================================="

# Make scripts executable
if [ -f "scripts/bump_version.sh" ]; then
    chmod +x scripts/bump_version.sh
    echo "✅ Made bump_version.sh executable"
fi

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Error: Not in a git repository. Please initialize git first:"
    echo "   git init"
    echo "   git add ."
    echo "   git commit -m 'Initial commit'"
    echo "   git branch -M main"
    echo "   git remote add origin <your-repo-url>"
    echo "   git push -u origin main"
    exit 1
fi

echo ""
echo "📋 Current Setup Status:"
echo "------------------------"

# Check current version
if [ -f "pubspec.yaml" ]; then
    CURRENT_VERSION=$(grep '^version:' pubspec.yaml | cut -d' ' -f2 | tr -d '\r')
    echo "✅ Current version: $CURRENT_VERSION"
else
    echo "❌ pubspec.yaml not found"
fi

# Check workflow file
if [ -f ".github/workflows/deploy.yml" ]; then
    echo "✅ GitHub Actions workflow configured"
else
    echo "❌ GitHub Actions workflow not found"
fi

# Check if remote repository exists
if git remote get-url origin >/dev/null 2>&1; then
    REPO_URL=$(git remote get-url origin)
    echo "✅ Git remote configured: $REPO_URL"
else
    echo "❌ Git remote not configured"
fi

echo ""
echo "🔐 Required GitHub Secrets (for production signing):"
echo "---------------------------------------------------"
echo "Go to your repository on GitHub:"
echo "Settings → Secrets and variables → Actions → New repository secret"
echo ""
echo "Add these secrets (optional - debug signing used if not provided):"
echo "• KEYSTORE_BASE64 - Base64 encoded keystore file"
echo "• KEY_ALIAS - Keystore key alias"
echo "• STORE_PASSWORD - Keystore store password"
echo "• KEY_PASSWORD - Keystore key password"

echo ""
echo "📝 To create KEYSTORE_BASE64:"
echo "-----------------------------"
echo "base64 -i your-keystore.jks | pbcopy     # macOS"
echo "base64 -i your-keystore.jks              # Linux"
echo ""
echo "# Windows PowerShell:"
echo '[System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes("your-keystore.jks")) | clip'

echo ""
echo "🎯 Next Steps:"
echo "-------------"
echo "1. Add GitHub secrets (if you have a production keystore)"
echo "2. Commit and push your changes:"
echo "   git add ."
echo "   git commit -m 'feat: add automatic APK deployment'"
echo "   git push origin main"
echo ""
echo "3. Your app will be automatically built and released!"
echo ""
echo "4. For manual version bumps, use:"
echo "   ./scripts/bump_version.sh [patch|minor|major]"
echo "   scripts\\bump_version.bat [patch|minor|major]  (Windows)"
echo ""
echo "5. Or trigger manually from GitHub Actions UI"

echo ""
echo "📖 Documentation:"
echo "----------------"
echo "• Deployment Guide: docs/DEPLOYMENT.md"
echo "• Workflows Info: .github/workflows/README.md"

echo ""
echo "✅ Setup complete! Your repository is ready for automatic APK deployment."
