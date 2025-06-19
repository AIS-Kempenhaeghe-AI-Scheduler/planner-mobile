# Automatic APK Deployment with Version Management

This repository includes automated APK deployment with automatic version bumping using GitHub Actions.

## 🚀 Features

- **Automatic Version Bumping**: Intelligently bumps version based on commit messages or manual input
- **APK & AAB Generation**: Builds both APK (for direct installation) and AAB (for Google Play Store)
- **GitHub Releases**: Automatically creates releases with downloadable assets
- **Secure Signing**: Supports both production and debug keystores
- **Cross-Platform**: Works on Windows, Linux, and macOS
- **Manual Override**: Allows manual version bumping via workflow dispatch

## 📋 Setup Instructions

### 1. Repository Secrets

Add the following secrets to your GitHub repository (Settings → Secrets and variables → Actions):

#### Required for Production Signing (Optional)
- `KEYSTORE_BASE64`: Base64 encoded keystore file
- `KEY_ALIAS`: Keystore key alias
- `STORE_PASSWORD`: Keystore store password  
- `KEY_PASSWORD`: Keystore key password

If these secrets are not provided, the workflow will use debug signing.

#### To Create Base64 Keystore:
```bash
# On Linux/macOS
base64 -i your-keystore.jks | pbcopy

# On Windows (PowerShell)
[System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes("your-keystore.jks")) | clip
```

### 2. Workflow Triggers

The deployment workflow (`deploy.yml`) is triggered by:

- **Push to main**: Automatically bumps version and deploys
- **Push to develop**: Automatically bumps version and deploys
- **Pull Request to main**: Runs tests only (no deployment)
- **Manual Trigger**: Allows you to choose version bump type (patch/minor/major)

### 3. Version Bumping Logic

#### Automatic (on push):
- **Major**: Commit message contains "breaking" or "major"
- **Minor**: Commit message contains "feat", "feature", or "minor"  
- **Patch**: All other commits (default)

#### Manual (workflow dispatch):
- Choose from: `patch`, `minor`, `major`

## 🛠️ Manual Version Bumping

### Option 1: Using Scripts

#### On Windows:
```cmd
# Patch version (1.0.0 → 1.0.1)
scripts\bump_version.bat patch

# Minor version (1.0.0 → 1.1.0)
scripts\bump_version.bat minor

# Major version (1.0.0 → 2.0.0)
scripts\bump_version.bat major
```

#### On Linux/macOS:
```bash
# Make script executable (first time only)
chmod +x scripts/bump_version.sh

# Patch version (1.0.0 → 1.0.1)
./scripts/bump_version.sh patch

# Minor version (1.0.0 → 1.1.0)
./scripts/bump_version.sh minor

# Major version (1.0.0 → 2.0.0)
./scripts/bump_version.sh major
```

### Option 2: Manual Edit

1. Edit `pubspec.yaml`
2. Update the `version:` field (format: `X.Y.Z+build`)
3. Commit and push

### Option 3: GitHub Actions UI

1. Go to Actions tab in GitHub
2. Select "Auto Deploy with Version Bump"
3. Click "Run workflow"
4. Choose branch and version bump type
5. Click "Run workflow"

## 📦 Build Outputs

Each successful deployment creates:

1. **GitHub Release** with:
   - APK file (`ai-scheduling-app-vX.Y.Z.apk`)
   - AAB file (`ai-scheduling-app-vX.Y.Z.aab`)
   - Release notes

2. **Artifacts** (downloadable from Actions page):
   - Build artifacts with version in filename
   - Retained for 30 days

## 🔄 Workflow Details

### Jobs Overview

1. **version-bump**: Updates version in `pubspec.yaml` and creates commit
2. **build-and-deploy**: Builds APK/AAB and creates GitHub release
3. **test-only**: Runs tests for pull requests (no deployment)

### Build Process

1. ✅ Checkout code and pull latest changes
2. ☕ Setup Java 17 with Temurin distribution
3. 🐦 Setup Flutter 3.19.3 (stable channel)
4. 📦 Install Flutter dependencies (`flutter pub get`)
5. 🧪 Run tests (`flutter test`)
6. 🔑 Setup keystore (production or debug)
7. 🏗️ Build release APK and AAB
8. 📤 Upload artifacts and create GitHub release

## 🐛 Troubleshooting

### Common Issues

#### 1. Build Failures
- Check that all dependencies are up to date
- Ensure Android SDK is properly configured
- Verify keystore secrets are correctly set

#### 2. Version Conflicts
- Make sure you pull latest changes before manual version bumps
- Check for merge conflicts in `pubspec.yaml`

#### 3. Keystore Issues
- Verify base64 encoding is correct
- Ensure all keystore secrets are set
- Check keystore password and alias

### Debug Information

The workflow includes verbose logging. Check the GitHub Actions logs for detailed information about each step.

## 📱 Installation

### From GitHub Releases

1. Go to the [Releases page](../../releases)
2. Download the latest APK file
3. Enable "Install from unknown sources" on your Android device
4. Install the APK

### From Actions Artifacts

1. Go to [Actions](../../actions)
2. Click on a successful workflow run
3. Download the artifacts
4. Extract and install the APK

## 🔐 Security Notes

- Production builds are signed with your keystore
- Debug builds use Android debug keystore
- Keystore secrets are stored securely in GitHub Secrets
- APK files include signature verification

## 🤝 Contributing

When contributing:

1. Use conventional commit messages for automatic version bumping
2. Test your changes locally before pushing
3. Create pull requests to `main` branch
4. Version bumps happen automatically on merge

## 📚 References

- [Flutter Build Documentation](https://docs.flutter.dev/deployment/android)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
