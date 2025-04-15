#!/bin/bash
MXE_COMMIT="5ea86ee8d6c2819be7e4973ab0b7a2a5166116d2"

if [ -d res/mxe ]; then
    rm -rf res/mxe
fi

echo "Downloading MXE..."
echo "https://github.com/mxe/mxe/archive/$MXE_COMMIT.tar.gz"

cd ./res
git clone https://github.com/mxe/mxe.git
cd mxe
git checkout $MXE_COMMIT

make -j4 MXE_TARGETS='x86_64-w64-mingw32.static' qt5 cc libsodium
