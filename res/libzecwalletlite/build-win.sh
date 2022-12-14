#!/bin/bash

echo "Building libpiratewalletlite"

# Now build it
cd res/libzecwalletlite
# ./buildopenssl-win.sh
# export OPENSSL_DIR=$(pwd)/openssl-1.1.1e/openssl-1.1.1e/x86_64-pc-windows-gnu
# make winrelease
cargo build --lib --release --target x86_64-pc-windows-gnu

# copy the library to the parents's res/ folder
cp target/x86_64-pc-windows-gnu/release/libpiratewalletlite.a ../win32libs/libpiratewalletlite.a
