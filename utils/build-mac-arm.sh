#!/bin/bash

export APP_VERSION="1.0.12"
export PREV_VERSION="1.0.11"
export PATH=$PATH:/usr/local/bin
export MACOSX_DEPLOYMENT_TARGET=11.0

ROOTFOLDER=$(pwd)

# Accept the variables as command line arguments as well
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -q|--qt_path)
    QT_PATH="$2"
    shift # past argument
    shift # past value
    ;;
    -c|--certificate)
    CERTIFICATE="$2"
    shift # past argument
    shift # past value
    ;;
    -u|--username)
    APPLE_USERNAME="$2"
    shift # past argument
    shift # past value
    ;;
    -p|--password)
    APPLE_PASSWORD="$2"
    shift # past argument
    shift # past value
    ;;
    -v|--version)
    APP_VERSION="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters



# Allow overrides to $BUILD and $HOST for porters. Most users will not need it.
if [[ -z "${BUILD-}" ]]; then
    BUILD="$(./depends/config.guess)"
fi

HOST=aarch64-apple-darwin

if [ -z $APP_VERSION ]; then echo "APP_VERSION is not set"; exit 1; fi
if [ -z $PREV_VERSION ]; then echo "PREV_VERSION is not set"; exit 1; fi

#Clean
printf "Cleaning...............\n"
rm -rf bin/*
rm -rf artifacts/*
rm -rf src/*.o
rm -rf src/*.a
rm -rf src/*.so
rm -rf src/*.d
rm -rf src/*.dSYM
rm -rf src/*.a
rm .qmake.stash
printf "[OK]\n"

PREFIX="$(pwd)/depends/$HOST"
export PREFIX=$PREFIX
printf "Building depends for $HOST to $PREFIX\n"

printf "Building Qt and Libsodium Library...............\n"
HOST="$HOST" BUILD="$BUILD" make "$@" -C ./depends/ V=1
printf "[OK]\n\n"

export QT_STATIC="$ROOTFOLDER"/depends/"$HOST"

printf "Building Rust Library...............\n"
cd "$ROOTFOLDER"/res
rm -rf ./libs
mkdir -p ./libs
cd "$ROOTFOLDER"/res/libzecwalletlite
SODIUM_LIB_DIR="$ROOTFOLDER"/depends/"$HOST"/lib/
rustup target add aarch64-apple-darwin
cargo build --lib --release --target aarch64-apple-darwin
cp "$ROOTFOLDER"/res/libzecwalletlite/target/aarch64-apple-darwin/release/libpiratewalletlite.a "$ROOTFOLDER"/res/libs/libpiratewalletlite.a
cd "$ROOTFOLDER"
printf "[OK]\n\n"

printf "Running Translations............\n"
QT_STATIC=$QT_STATIC bash utils/dotranslations.sh >/dev/null
printf "[OK]\n\n"

printf "Building QT Wallet..............."
"$QT_STATIC"/bin/qmake piratewallet-lite.pro CONFIG+=release > /dev/null
make -j4
printf "[OK]\n\n"

#Qt deploy
echo -n "Deploying.............."
mkdir "$ROOTFOLDER"/artifacts >/dev/null 2>&1
rm -f "$ROOTFOLDER"/artifcats/piratewallet-lite.dmg >/dev/null 2>&1
rm -f "$ROOTFOLDER"/artifacts/rw* >/dev/null 2>&1
#$QT_STATIC/bin/macdeployqt piratewallet-lite.app
echo "[OK]"


# Code Signing Note:
# On MacOS, you still need to run these 3 commands:
# xcrun altool --notarize-app -t osx -f macOS-zecwallet-lite-v1.0.0.dmg --primary-bundle-id="com.yourcompany.zecwallet-lite" -u "apple developer id@email.com" -p "one time password"
# xcrun altool --notarization-info <output from pervious command> -u "apple developer id@email.com" -p "one time password"
#...wait for the notarization to finish...
# xcrun stapler staple macOS-zerwallet-lite-v1.0.0.dmg

echo -n "Building dmg..........."
mv piratewallet-lite.app PirateWallet-Lite.app
create-dmg --volname "PirateWallet-Lite-v$APP_VERSION" --volicon "res/logo.icns" --window-pos 200 120 --icon "PirateWallet-Lite.app" 200 190  --app-drop-link 600 185 --hide-extension "PirateWallet-Lite.app"  --window-size 800 400 --hdiutil-quiet --background res/dmgbg.png  artifacts/aarch64-MacOS-piratewallet-lite-v$APP_VERSION.dmg PirateWallet-Lite.app >/dev/null 2>&1

if [ ! -f artifacts/aarch64-MacOS-piratewallet-lite-v$APP_VERSION.dmg ]; then
    echo "[ERROR]"
    exit 1
fi
echo  "[OK]"

# Submit to Apple for notarization
#echo -n "Apple notarization....."
#xcrun altool --notarize-app -t osx -f artifacts/macOS-zecwallet-lite-v$APP_VERSION.dmg --primary-bundle-id="com.yourcompany.zecwallet-lite" -u "$APPLE_USERNAME" -p "$APPLE_PASSWORD"
#echo  "[OK]"
