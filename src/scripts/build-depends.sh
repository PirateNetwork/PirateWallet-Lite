#!/usr/bin/env bash

set -eu -o pipefail

# Allow user overrides to $MAKE. Typical usage for users who need it:
#   MAKE=gmake ./zcutil/build.sh -j$(nproc)
if [[ -z "${MAKE-}" ]]; then
    MAKE=make
fi

# Allow overrides to $BUILD and $HOST for porters. Most users will not need it.
#   BUILD=i686-pc-linux-gnu ./zcutil/build.sh
if [[ -z "${BUILD-}" ]]; then
    BUILD="$(./depends/config.guess)"
fi
if [[ -z "${HOST-}" ]]; then
    HOST="$BUILD"
fi


ROOTFOLDER=$(pwd)
PREFIX="$(pwd)/depends/$BUILD/"
export PREFIX=$PREFIX
printf "Building depends for $BUILD to $PREFIX\n"

printf "Building Qt and Libsodium Library...............\n"
HOST="$HOST" BUILD="$BUILD" "$MAKE" "$@" -C ./depends/ V=1
printf "[OK]\n"

printf "Building Rust Library...............\n"
cd "$ROOTFOLDER"/res
rm -rf ./libs
mkdir -p ./libs
cd "$ROOTFOLDER"/res/libzecwalletlite
cargo build --lib --release 
cp "$ROOTFOLDER"/res/libzecwalletlite/target/release/libpiratewalletlite.a "$ROOTFOLDER"/res/libs/libpiratewalletlite.a
cd "$ROOTFOLDER"
printf "[OK]\n"

printf "Building QT Wallet..............."
# Build the lib first
# cd lib && make winrelease && cd ..
"$ROOTFOLDER"/depends/"$HOST"/native/bin/qmake piratewallet-lite.pro CONFIG+=release > /dev/null
make -j4 > /dev/null
echo "[OK]"