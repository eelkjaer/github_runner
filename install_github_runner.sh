#!/bin/bash

set -e  # Stop script on error

echo "🚀 Starting GitHub Actions Runner Setup..."

### ✅ CONFIGURABLE VARIABLES (CHANGE THESE AS NEEDED)
USERNAME="GithubRunner"
USER_PASSWORD="runnerpassword"
RUNNER_LABELS="ios-android"
RUNNER_DIR="/Users/$USERNAME/actions-runner"
HOMEDIR="/Users/$USERNAME"
GITHUB_REPO_URL="https://github.com/YOUR-ORG/YOUR-REPO"

### ✅ Step 1: Ask for GitHub Tokens
echo "🔑 Each GitHub Actions Runner requires a unique token."
read -p "Enter GitHub Actions Token for Runner 1: " GITHUB_TOKEN_1
read -p "Enter GitHub Actions Token for Runner 2: " GITHUB_TOKEN_2

### ✅ Step 2: Create the `GithubRunner` User
if id "$USERNAME" &>/dev/null; then
    echo "✅ User '$USERNAME' already exists."
else
    echo "👤 Creating user '$USERNAME'..."
    sudo sysadminctl -addUser $USERNAME -fullName "GitHub Runner" -password "$USER_PASSWORD" -admin
    sudo mkdir -p $HOMEDIR
    sudo chown -R $USERNAME:staff $HOMEDIR
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" | sudo tee "/etc/sudoers.d/$USERNAME"
fi

### ✅ Step 3: Install Required Tools (Under `GithubRunner`)
echo "🛠 Installing development tools..."
sudo -u $USERNAME /bin/bash << EOF
    # Install Homebrew
    if ! command -v brew &>/dev/null; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    # Update Homebrew & Install Packages
    brew update && brew upgrade
    brew install git gh node python openjdk@17 ruby watchman cocoapods dotnet
    brew install --cask dotnet-sdk yarn nvm cloudflare/cloudflare/cloudflared
    brew install gradle kotlin cmake fastlane bundler

    # Configure Java (OpenJDK 17)
    echo 'export PATH="/usr/local/opt/openjdk@17/bin:$PATH"' >> ~/.zshrc
    echo 'export JAVA_HOME=$(/usr/libexec/java_home -v 17)' >> ~/.zshrc
    source ~/.zshrc

    # Install .NET MAUI workloads
    dotnet workload install maui maui-android maui-ios dotnet-android dotnet-ios

    # Install Android Studio & SDK
    brew install --cask android-studio
    yes | sdkmanager --licenses
    sdkmanager --install "platform-tools" "platforms;android-33" "build-tools;33.0.2" "cmdline-tools;latest" "ndk;25.2.9519653" "extras;google;market_apk_expansion" "extras;google;market_licensing"

    # Configure Android SDK Paths
    echo 'export ANDROID_HOME=$HOME/Library/Android/sdk' >> ~/.zshrc
    echo 'export PATH=$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$PATH' >> ~/.zshrc
    source ~/.zshrc

    # Install Xcode & CLI Tools
    brew install --cask xcode
    xcode-select --install
    sudo xcodebuild -license accept
EOF

### ✅ Step 4: Set Up Two GitHub Actions Runners (Each with Its Own Token)
echo "🐙 Setting up GitHub Actions Runners..."
mkdir -p $RUNNER_DIR/runner-1 $RUNNER_DIR/runner-2
chown -R $USERNAME:staff $RUNNER_DIR

for i in 1 2; do
    TOKEN_VAR="GITHUB_TOKEN_$i"
    TOKEN=${!TOKEN_VAR}

    sudo -u $USERNAME /bin/bash << EOF
        cd $RUNNER_DIR/runner-$i
        curl -o actions-runner-osx.tar.gz -L https://github.com/actions/runner/releases/latest/download/actions-runner-osx-x64.tar.gz
        tar xzf ./actions-runner-osx.tar.gz
        ./config.sh --url $GITHUB_REPO_URL --token $TOKEN --name runner-$i --unattended --labels $RUNNER_LABELS
        ./svc.sh install
        ./svc.sh start
EOF
done

echo "✅ GitHub Runners Installed!"

### ✅ Step 5: Configure Cloudflare Tunnel for Remote Access
echo "🌍 Setting up Cloudflare Tunnel for remote SSH..."
sudo -u $USERNAME cloudflared tunnel login
sudo -u $USERNAME cloudflared tunnel create github-mac-mini
echo "✅ Cloudflare Tunnel configured. Add a public hostname in Cloudflare dashboard to connect via SSH."

### ✅ Step 6: Install Apple Certificates & Provisioning Profiles (Manual Step)
echo "🍏 Installing Apple Developer Certificates..."
mkdir -p $HOMEDIR/Library/MobileDevice/Provisioning\ Profiles
chown -R $USERNAME:staff $HOMEDIR/Library/MobileDevice

echo "🔹 Copy your distribution certificates & provisioning profiles to:"
echo "   $HOMEDIR/Library/MobileDevice/Provisioning Profiles/"
echo "🔹 Import certificates with:"
echo "   sudo -u $USERNAME security import distribution.p12 -k ~/Library/Keychains/login.keychain-db -P 'your_password' -T /usr/bin/codesign"

### ✅ Step 7: Create Update Script (`update-tools.sh`)
cat << 'EOF' > $HOMEDIR/update-tools.sh
#!/bin/bash
echo "🚀 Updating all tools..."
brew update && brew upgrade
brew upgrade gh node python openjdk@17 ruby watchman cocoapods dotnet gradle kotlin cmake fastlane bundler
dotnet workload update
yes | sdkmanager --licenses
sdkmanager --update
softwareupdate --install --all
sudo xcodebuild -license accept
EOF
chmod +x $HOMEDIR/update-tools.sh
echo "alias update-tools='$HOMEDIR/update-tools.sh'" >> $HOMEDIR/.zshrc

### ✅ Finalize
echo "✅ Installation Complete!"
echo "🔹 Add Apple Certificates & Provisioning Profiles"
echo "🔹 To update tools, run: update-tools"
echo "🔹 To restart GitHub Actions runners:"
echo "   cd $RUNNER_DIR/runner-1 && ./run.sh"
echo "   cd $RUNNER_DIR/runner-2 && ./run.sh"

exit 0
