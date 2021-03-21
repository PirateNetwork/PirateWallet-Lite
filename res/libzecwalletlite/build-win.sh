#!/bin/bash

# First thing to do is see if libsodium.a exists in the res folder. If it does, then there's nothing to do
if [ -f res/libzecwalletlite.a ]; then
    rm res/libzecwalletlite.a
fi

if [ -f res/zecwalletlite.lib ]; then
    rm res/zecwalletlite.lib
fi

echo "Building libzecwalletlite"

# Now build it
cd res/libzecwalletlite
# ./buildopenssl-win.sh
# export OPENSSL_DIR=$(pwd)/openssl-1.1.1e/openssl-1.1.1e/x86_64-pc-windows-gnu
# make winrelease
cargo build --lib --release --target x86_64-pc-windows-gnu

# copy the library to the parents's res/ folder
cp target/x86_64-pc-windows-gnu/release/zecwalletlite.lib ../
