#!/usr/bin/env bash

HOST=x86_64-w64-mingw32
CXX=x86_64-w64-mingw32-g++-posix
CC=x86_64-w64-mingw32-gcc-posix
PREFIX="$(pwd)/depends/$HOST"
ROOTFOLDER=$(pwd)

set -eu -o pipefail


export PREFIX=$PREFIX

printf "Building Qt and Libsodium Library...............\n"
HOST="$HOST" make "$@" -C ./depends/ V=0
printf "[OK]\n"


printf "Building Rust Library...............\n"
cd "$ROOTFOLDER"/res
rm -rf ./libs
mkdir -p ./libs
cd "$ROOTFOLDER"/res/libzecwalletlite
cargo build --lib --release --target x86_64-pc-windows-gnu
cp "$ROOTFOLDER"/res/libzecwalletlite/target/x86_64-pc-windows-gnu/release/libpiratewalletlite.a "$ROOTFOLDER"/res/libs/libpiratewalletlite.a
cd "$ROOTFOLDER"
printf "[OK]\n"


printf "Building QT Wallet..............."
# Build the lib first
# cd lib && make winrelease && cd ..
"$ROOTFOLDER"/depends/"$HOST"/native/bin/qmake piratewallet-lite-mingw.pro CONFIG+=release > /dev/null
make -j4 > /dev/null
echo "[OK]"
