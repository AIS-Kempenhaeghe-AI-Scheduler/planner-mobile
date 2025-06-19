# GitHub Actions Workflows

This directory contains automated workflows for building and deploying the AI Scheduling App.

## 📁 Workflows

### `deploy.yml` - Main Deployment Workflow
- **Purpose**: Automatic APK deployment with version bumping
- **Triggers**: 
  - Push to `main` or `develop` branches
  - Manual trigger via GitHub Actions UI
  - Pull requests to `main` (test only)
- **Features**:
  - Automatic version bumping based on commit messages
  - APK and AAB generation
  - GitHub releases creation
  - Secure keystore handling

## 🚀 Quick Start

1. **Automatic Deployment**: Push to `main` or `develop` branch
2. **Manual Deployment**: Use GitHub Actions UI to trigger workflow
3. **Version Control**: Use provided scripts in `/scripts` folder

## 📖 Documentation

See [DEPLOYMENT.md](../../docs/DEPLOYMENT.md) for detailed setup and usage instructions.

## 🔧 Configuration

Required repository secrets for production builds:
- `KEYSTORE_BASE64`
- `KEY_ALIAS` 
- `STORE_PASSWORD`
- `KEY_PASSWORD`

If not provided, debug signing will be used automatically.
