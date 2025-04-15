#!/usr/bin/env bash

export APP_VERSION="1.0.12"
export PREV_VERSION="1.0.11"

HOST=x86_64-w64-mingw32
ROOTFOLDER=$(pwd)

set -eu -o pipefail

# Allow user overrides to $MAKE. Typical usage for users who need it:
if [[ -z "${MAKE-}" ]]; then
    MAKE=make
fi

if [ -z $APP_VERSION ]; then echo "APP_VERSION is not set"; exit 1; fi
if [ -z $PREV_VERSION ]; then echo "PREV_VERSION is not set"; exit 1; fi

printf "Version files..........\n"
# Replace the version number in the .pro file so it gets picked up everywhere
sed -i "s/${PREV_VERSION}/${APP_VERSION}/g" piratewallet-lite.pro > /dev/null

# Also update it in the README.md
sed -i "s/${PREV_VERSION}/${APP_VERSION}/g" README.md > /dev/null
printf "[OK]\n\n"



printf "BUILD MXE Toolchain Library...............\n"
"$ROOTFOLDER"/src/scripts/buildmxe.sh
export PATH="$ROOTFOLDER"/res/mxe/usr/bin:"$PATH"
export QT_STATIC="$ROOTFOLDER"/res/mxe/usr/x86_64-w64-mingw32.static/qt5
printf "[OK]\n\n"

printf "Building Rust Library...............\n"
cd "$ROOTFOLDER"/res
rm -rf ./libs
mkdir -p ./libs
cd "$ROOTFOLDER"/res/libzecwalletlite

SODIUM_LIB_DIR="$ROOTFOLDER"/res/mxe/usr/x86_64-w64-mingw32.static/lib/
cargo build --lib --release --target x86_64-pc-windows-gnu > /dev/null 2>&1
cp "$ROOTFOLDER"/res/libzecwalletlite/target/x86_64-pc-windows-gnu/release/libpiratewalletlite.a "$ROOTFOLDER"/res/libs/libpiratewalletlite.a
cd "$ROOTFOLDER"
printf "[OK]\n\n"

printf "Running Translations............\n"
QT_STATIC=$QT_STATIC bash utils/dotranslations-win.sh >/dev/null
printf "[OK]\n\n"

printf "Configuring QT Wallet...............\n"
# Build the lib first
x86_64-w64-mingw32.static-qmake-qt5 piratewallet-lite-mingw.pro CONFIG+=release > /dev/null
printf "[OK]\n\n"

printf "Cleaning...............\n"
rm -rf bin/*
rm -rf artifacts/*
make clean > /dev/null 2>&1
printf "[OK]\n\n"

printf "Building QT Wallet...............\n"
make -j4 > /dev/null 2>&1
echo "[OK]\n\n"
