#!/bin/sh

# Fail this script if any subcommand fails.
set -e

# The default execution directory of this script is the ci_scripts directory.
# Navigate to the root of the repository.
cd "$CI_PRIMARY_REPOSITORY_PATH"

# 1. Clone the Flutter SDK repository (stable branch)
git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"

# 2. Precache iOS engine artifacts
flutter precache --ios

# 3. Fetch Flutter dependencies
flutter pub get

# 4. Install CocoaPods via Homebrew
HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods

# 5. Generate Flutter iOS configuration files and install CocoaPods pods
flutter build ios --config-only --no-codesign

exit 0
