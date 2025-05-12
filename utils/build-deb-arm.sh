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

HOST=aarch64-linux-gnu

if [ -z $APP_VERSION ]; then echo "APP_VERSION is not set"; exit 1; fi
if [ -z $PREV_VERSION ]; then echo "PREV_VERSION is not set"; exit 1; fi

printf "Version files..........\n"
# Replace the version number in the .pro file so it gets picked up everywhere
sed -i "s/${PREV_VERSION}/${APP_VERSION}/g" piratewallet-lite.pro > /dev/null

# Also update it in the README.md
sed -i "s/${PREV_VERSION}/${APP_VERSION}/g" README.md > /dev/null
printf "[OK]\n"

printf "Cleaning...............\n"
rm -rf "$ROOTFOLDER"/bin/*
rm -rf "$ROOTFOLDER"/artifacts
rm -rf "$ROOTFOLDER"/src/*.o
rm -rf "$ROOTFOLDER"/src/*.a
rm -rf "$ROOTFOLDER"/src/*.so
rm -rf "$ROOTFOLDER"/src/*.d
rm -rf "$ROOTFOLDER"/src/*.dSYM
rm -rf "$ROOTFOLDER"/src/*.a
printf "[OK]\n"





PREFIX="$(pwd)/depends/$HOST/"
export PREFIX=$PREFIX
printf "Building depends for $HOST to $PREFIX\n"

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
rustup target add aarch64-unknown-linux-gnu
cargo build --lib --release --target aarch64-unknown-linux-gnu
cp "$ROOTFOLDER"/res/libzecwalletlite/target/aarch64-unknown-linux-gnu/release/libpiratewalletlite.a "$ROOTFOLDER"/res/libs/libpiratewalletlite.a
cd "$ROOTFOLDER"
printf "[OK]\n\n"

printf "Running Translations............\n"
QT_STATIC=$QT_STATIC bash utils/dotranslations.sh >/dev/null
printf "[OK]\n\n"

printf "Building QT Wallet..............."
"$QT_STATIC"/bin/qmake piratewallet-lite.pro CONFIG+=release > /dev/null
make -j4 > /dev/null 2>&1
printf "[OK]\n\n"




printf "Packaging..............\n"
mkdir "$ROOTFOLDER"/bin/piratewallet-lite-v$APP_VERSION > /dev/null
aarch64-linux-gnu-strip piratewallet-lite

cp piratewallet-lite              "$ROOTFOLDER"/bin/piratewallet-lite-v$APP_VERSION > /dev/null
cp README.md                      "$ROOTFOLDER"/bin/piratewallet-lite-v$APP_VERSION > /dev/null
cp LICENSE                        "$ROOTFOLDER"/bin/piratewallet-lite-v$APP_VERSION > /dev/null

cd "$ROOTFOLDER"/bin
tar czf linux-piratewallet-lite-v$APP_VERSION.tar.gz piratewallet-lite-v$APP_VERSION/
cd "$ROOTFOLDER"

mkdir "$ROOTFOLDER"/artifacts 
cp "$ROOTFOLDER"/bin/linux-piratewallet-lite-v$APP_VERSION.tar.gz "$ROOTFOLDER"/artifacts/aarch64-linux-binaries-piratewallet-lite-v$APP_VERSION.tar.gz
printf  "[OK]\n\n"


if [ -f "$ROOTFOLDER"/artifacts/aarch64-linux-binaries-piratewallet-lite-v$APP_VERSION.tar.gz ] ; then
    printf "Package contents.......\n"
    # Test if the package is built OK
    if tar tf "$ROOTFOLDER/artifacts/aarch64-linux-binaries-piratewallet-lite-v$APP_VERSION.tar.gz" | wc -l | grep -q "4"; then
        printf "[OK]\n\n"
    else
        printf "[ERROR]\n\n"
        exit 1
    fi
else
    printf "[ERROR - artifacts/aarch64-linux-binaries-piratewallet-lite-v$APP_VERSION.tar.gz not found]\n\n"
    exit 1
fi

echo -n "Building deb..........."
debdir=bin/deb/piratewallet-lite-v$APP_VERSION
mkdir -p $debdir > /dev/null
mkdir    $debdir/DEBIAN
mkdir -p $debdir/usr/local/bin

cat utils/deb/control_aarch64 | sed "s/RELEASE_VERSION/$APP_VERSION/g" > $debdir/DEBIAN/control

cp piratewallet-lite                   $debdir/usr/local/bin/

mkdir -p $debdir/usr/share/pixmaps/
cp res/piratewallet-lite.xpm           $debdir/usr/share/pixmaps/

mkdir -p $debdir/usr/share/applications
cp src/scripts/desktopentry    $debdir/usr/share/applications/piratewallet-lite.desktop

dpkg-deb --build $debdir >/dev/null
cp $debdir.deb                 artifacts/aarch64-linux-deb-piratewallet-lite-v$APP_VERSION.deb
echo "[OK]"

