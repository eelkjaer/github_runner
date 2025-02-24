# 🚀 GitHub Actions Runner Setup for macOS

This repository contains an **automated setup script** to configure a **self-hosted GitHub Actions runner** on a **Mac Mini** for **iOS & Android builds**.

## 📌 Features

- **Creates a new user** (`GithubRunner`)
- **Disables password prompts & GUI interactions**
- **Installs all necessary tools** (Xcode, Android SDK, .NET, Fastlane, Gradle, Kotlin, CocoaPods, etc.)
- **Configures two GitHub Actions runners**
- **Sets up Cloudflare Tunnel for remote SSH access**
- **Provides an easy `update-tools` command**

## 📥 Installation

### 1. Run the Installation Script
From the **admin user** on your Mac Mini, run:

```sh
curl -fsSL https://raw.githubusercontent.com/YOUR-ORG/YOUR-REPO/main/install_github_runner.sh | sudo bash
```

_Replace `YOUR-ORG/YOUR-REPO` with the actual repository path._

### 2. Provide the Required Inputs
- **GitHub Actions Runner Tokens** (one for each runner)
- **GitHub Repository URL** (e.g., `https://github.com/YOUR-ORG/YOUR-REPO`)

## 🔧 How to Use

### Check the GitHub Runners
After installation, verify that your runners are online by navigating to:
**GitHub → Repo → Settings → Actions → Self-Hosted Runners**

You should see **two runners (`runner-1` and `runner-2`) online**.

### Updating Installed Tools
To update all tools, run the following command as the `GithubRunner` user:

```sh
update-tools
```

This command updates:
- Homebrew & all dependencies
- Node.js, Python, .NET, OpenJDK, Gradle, Kotlin, CocoaPods, etc.
- Android SDK, Xcode, Fastlane, and GitHub Actions Runner

### Restart GitHub Runners
If necessary, restart the runners manually:

```sh
cd /Users/GithubRunner/actions-runner/runner-1 && ./run.sh
cd /Users/GithubRunner/actions-runner/runner-2 && ./run.sh
```

## 🔒 Remote Access via Cloudflare Tunnel
The installation script automatically configures a **Cloudflare Tunnel** for remote SSH access.

1. Log in to Cloudflare and set up a public hostname for the tunnel.
2. Connect via SSH:

```sh
ssh GithubRunner@your-tunnel-hostname
```

## 📜 Apple Certificates & Provisioning Profiles
For iOS builds, you must manually install your Apple certificates and provisioning profiles:

1. Copy your `.p12` certificate and provisioning profiles to:
   ```
   /Users/GithubRunner/Library/MobileDevice/Provisioning Profiles/
   ```
2. Import the certificate into the keychain:

```sh
sudo -u GithubRunner security import distribution.p12 -k ~/Library/Keychains/login.keychain-db -P "your_password" -T /usr/bin/codesign
```

## 📌 Installed Software

| **Category**       | **Installed Tools**                                                                               |
|--------------------|---------------------------------------------------------------------------------------------------|
| **General**        | Homebrew, GitHub Actions Runner, Cloudflare Tunnel                                                |
| **Base Dev Tools** | Git, GitHub CLI, Node.js, NVM, Python, OpenJDK 17, Ruby, Watchman, CocoaPods, .NET                  |
| **Android Tools**  | Android Studio, Android SDK, NDK, Gradle, Kotlin, CMake, Google Play Licensing Libraries            |
| **iOS Tools**      | Xcode, Xcode CLI Tools, Fastlane, Bundler                                                           |

## ❓ FAQ

### What macOS versions are supported?
macOS Monterey (12.x) and newer are supported. Older versions may work but are untested.

### Can I run more than two GitHub Actions runners?
Yes. To add more runners, create additional runner directories and configure them similarly to the two provided.

### How do I uninstall everything?
To remove all installed components, run:

```sh
sudo sysadminctl -deleteUser GithubRunner
sudo rm -rf /Users/GithubRunner
```

## 👨‍💻 Contributing
Feel free to open an issue or submit a pull request for improvements.

## 🔗 Resources
- [GitHub Actions Self-Hosted Runners Documentation](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Apple Developer Certificates & Provisioning Profiles](https://developer.apple.com/account/resources)
