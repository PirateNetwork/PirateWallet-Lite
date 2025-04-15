#!/usr/bin/env bash

export APP_VERSION="1.0.12"
export PREV_VERSION="1.0.11"

ROOTFOLDER=$(pwd)

set -eu -o pipefail

# Allow user overrides to $MAKE. Typical usage for users who need it:
if [[ -z "${MAKE-}" ]]; then
    MAKE=make
fi

# Allow overrides to $BUILD and $HOST for porters. Most users will not need it.
if [[ -z "${BUILD-}" ]]; then
    BUILD="$(./depends/config.guess)"
fi
if [[ -z "${HOST-}" ]]; then
    HOST="$BUILD"
fi

if [ -z $APP_VERSION ]; then echo "APP_VERSION is not set"; exit 1; fi
if [ -z $PREV_VERSION ]; then echo "PREV_VERSION is not set"; exit 1; fi

printf "Version files..........\n"
# Replace the version number in the .pro file so it gets picked up everywhere
sed -i "s/${PREV_VERSION}/${APP_VERSION}/g" piratewallet-lite.pro > /dev/null

# Also update it in the README.md
sed -i "s/${PREV_VERSION}/${APP_VERSION}/g" README.md > /dev/null
printf "[OK]\n"

printf "Cleaning...............\n"
rm -rf bin/*
rm -rf artifacts/*
rm -rf src/*.o
rm -rf src/*.a
rm -rf src/*.so
rm -rf src/*.d
rm -rf src/*.dSYM
rm -rf src/*.a
printf "[OK]\n"





PREFIX="$(pwd)/depends/$BUILD/"
export PREFIX=$PREFIX
printf "Building depends for $BUILD to $PREFIX\n"

printf "Building Qt and Libsodium Library...............\n"
HOST="$HOST" BUILD="$BUILD" "$MAKE" "$@" -C ./depends/ V=1
printf "[OK]\n\n"

export QT_STATIC="$ROOTFOLDER"/depends/"$HOST"

printf "Building Rust Library...............\n"
cd "$ROOTFOLDER"/res
rm -rf ./libs
mkdir -p ./libs
cd "$ROOTFOLDER"/res/libzecwalletlite
SODIUM_LIB_DIR="$ROOTFOLDER"/depends/"$HOST"/lib/
cargo build --lib --release 
cp "$ROOTFOLDER"/res/libzecwalletlite/target/release/libpiratewalletlite.a "$ROOTFOLDER"/res/libs/libpiratewalletlite.a
cd "$ROOTFOLDER"
printf "[OK]\n\n"

printf "Running Translations............\n"
QT_STATIC=$QT_STATIC bash utils/dotranslations.sh >/dev/null
printf "[OK]\n\n"

printf "Building QT Wallet..............."
"$QT_STATIC"/bin/qmake piratewallet-lite.pro CONFIG+=release > /dev/null
make -j4 > /dev/null
printf "[OK]\n\n"