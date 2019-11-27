#!/usr/bin/env bash

# Only setup virtualenv if we intend on localizing the app.
function setup_virtualenv {
  # Install Python tooling for localizations scripts
  echo password | sudo easy_install pip
  echo password | sudo -S pip install --upgrade pip
  echo password | sudo -S pip install virtualenv
}

#
# Install Node.js dependencies and build user scripts
#

npm install
npm run build

#
# Add a badge for FirefoxBeta
#

if [ "$BUDDYBUILD_SCHEME" = "FirefoxBeta" ]; then
  brew install imagemagick
  brew install ruby
  export PATH=/usr/local/opt/ruby/bin:$PATH
  export PATH=`gem env gemdir`/bin:$PATH
  echo password | sudo -S gem install badge
  CF_BUNDLE_SHORT_VERSION_STRING=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Client/Info.plist)
  badge --no_badge --shield_no_resize --shield "$CF_BUNDLE_SHORT_VERSION_STRING-Build%20$BUDDYBUILD_BUILD_NUMBER-blue"
fi

#
# Import only the shipping locales (from shipping_locales.txt) on Release
# builds. Import all locales on Beta and Fennec_Enterprise, except for pull
# requests.
#

git clone https://github.com/mozilla-mobile/ios-l10n-scripts.git || exit 1

if [ "$BUDDYBUILD_SCHEME" = "Firefox" ]; then
  setup_virtualenv
  ./ios-l10n-scripts/import-locales-firefox.sh --release
fi

if [ "$BUDDYBUILD_SCHEME" = "FirefoxBeta" ]; then
  setup_virtualenv
  ./ios-l10n-scripts/import-locales-firefox.sh
fi

if [ "$BUDDYBUILD_SCHEME" = "Fennec_Enterprise" ] && [ "$BUDDYBUILD_PULL_REQUEST" = "" ]; then
  setup_virtualenv
  ./ios-l10n-scripts/import-locales-firefox.sh
fi

# workaround, earlgrey needs to have dependencies downloaded before setup
# https://github.com/google/EarlGrey/issues/732
carthage checkout
./Carthage/Checkouts/EarlGrey/Scripts/setup-earlgrey.sh

cd content-blocker-lib-ios
./build-disconnect.py block
./build-disconnect.py block-cookies
cd ..

