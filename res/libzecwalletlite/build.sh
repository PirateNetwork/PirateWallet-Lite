#!/bin/bash

echo "Building libpiratewalletlite"

# Now build it
cd res/libzecwalletlite
./buildopenssl.sh
export OPENSSL_DIR=$(pwd)/openssl-1.1.1e/openssl-1.1.1e/release
cargo build --lib --release


# copy the library to the parents's res/ folder
cp target/release/libpiratewalletlite.a ../unixlibs/libpiratewalletlite.a
