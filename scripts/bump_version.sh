#!/bin/bash

# Version Bump Script for Flutter App
# Usage: ./scripts/bump_version.sh [patch|minor|major]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Default to patch if no argument provided
BUMP_TYPE=${1:-patch}

# Validate bump type
if [[ ! "$BUMP_TYPE" =~ ^(patch|minor|major)$ ]]; then
    echo "❌ Error: Invalid bump type. Use 'patch', 'minor', or 'major'"
    exit 1
fi

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Error: Not in a git repository"
    exit 1
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo "❌ Error: You have uncommitted changes. Please commit them first."
    exit 1
fi

# Get current version from pubspec.yaml
PUBSPEC_FILE="$PROJECT_DIR/pubspec.yaml"
if [[ ! -f "$PUBSPEC_FILE" ]]; then
    echo "❌ Error: pubspec.yaml not found at $PUBSPEC_FILE"
    exit 1
fi

CURRENT_VERSION=$(grep '^version:' "$PUBSPEC_FILE" | cut -d' ' -f2 | tr -d '\r')
VERSION_NAME=$(echo "$CURRENT_VERSION" | cut -d'+' -f1)
BUILD_NUMBER=$(echo "$CURRENT_VERSION" | cut -d'+' -f2)

echo "📋 Current version: $CURRENT_VERSION"
echo "📋 Version name: $VERSION_NAME"
echo "📋 Build number: $BUILD_NUMBER"

# Parse version components
IFS='.' read -ra VERSION_PARTS <<< "$VERSION_NAME"
MAJOR=${VERSION_PARTS[0]}
MINOR=${VERSION_PARTS[1]}
PATCH=${VERSION_PARTS[2]}

echo "📋 Bump type: $BUMP_TYPE"

# Bump version based on type
case $BUMP_TYPE in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
esac

# Increment build number
NEW_BUILD=$((BUILD_NUMBER + 1))
NEW_VERSION_NAME="$MAJOR.$MINOR.$PATCH"
NEW_VERSION="$NEW_VERSION_NAME+$NEW_BUILD"

echo "🚀 New version: $NEW_VERSION"
echo "🚀 New version name: $NEW_VERSION_NAME"
echo "🚀 New build number: $NEW_BUILD"

# Ask for confirmation
read -p "❓ Do you want to proceed with this version bump? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Version bump cancelled"
    exit 1
fi

# Update pubspec.yaml
echo "📝 Updating pubspec.yaml..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/^version: .*/version: $NEW_VERSION/" "$PUBSPEC_FILE"
else
    # Linux
    sed -i "s/^version: .*/version: $NEW_VERSION/" "$PUBSPEC_FILE"
fi

# Verify the change
if grep -q "^version: $NEW_VERSION" "$PUBSPEC_FILE"; then
    echo "✅ Successfully updated version in pubspec.yaml"
else
    echo "❌ Error: Failed to update version in pubspec.yaml"
    exit 1
fi

# Create git commit
echo "📝 Creating git commit..."
git add "$PUBSPEC_FILE"
git commit -m "chore: bump version to $NEW_VERSION

- Version: $NEW_VERSION_NAME
- Build: $NEW_BUILD
- Type: $BUMP_TYPE bump"

# Create git tag
echo "🏷️ Creating git tag..."
git tag -a "v$NEW_VERSION_NAME" -m "Release v$NEW_VERSION_NAME

Version: $NEW_VERSION_NAME
Build: $NEW_BUILD"

echo "✅ Version bump completed successfully!"
echo ""
echo "📋 Summary:"
echo "  Old version: $CURRENT_VERSION"
echo "  New version: $NEW_VERSION"
echo "  Git tag: v$NEW_VERSION_NAME"
echo ""
echo "📤 Next steps:"
echo "  1. Push changes: git push origin main"
echo "  2. Push tags: git push origin --tags"
echo "  3. Or push both: git push origin main --follow-tags"
echo ""
echo "🚀 The GitHub Actions workflow will automatically build and deploy when you push to main branch."
