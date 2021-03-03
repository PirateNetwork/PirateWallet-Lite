#!/bin/bash

# First thing to do is see if libsodium.a exists in the res folder. If it does, then there's nothing to do
if [ -f res/libsodium.a ]; then
    rm res/libsodium.a
fi

echo "Building libsodium"

# Go into the lib sodium directory
cd res/libsodium
if [ ! -f libsodium-1.0.18.tar.gz ]; then
    wget https://download.libsodium.org/libsodium/releases/libsodium-1.0.18.tar.gz
fi

if [ ! -d win ]; then
    mkdir win
    tar -C ./win -xf libsodium-1.0.18.tar.gz
else
    rm -r win/libsodium-1.0.18
    tar -C ./win -xf libsodium-1.0.18.tar.gz
fi

# Now build it
cd ./win/libsodium-1.0.18

export HOST=x86_64-w64-mingw32
CXX=x86_64-w64-mingw32-g++-posix
CC=x86_64-w64-mingw32-gcc-posix
PREFIX="$(pwd)/depends/$HOST"

#LIBS="" ./configure --prefix="${PREFIX}" --host=x86_64-w64-mingw32 --enable-static CC="${CC} -g " CXX="${CXX} -g " > /dev/null
LIBS="" ./configure --host=x86_64-w64-mingw32 --enable-static CC="${CC} -g " CXX="${CXX} -g " > /dev/null

make clean > /dev/null 2>&1
make > /dev/null 2>&1

cd ..
cd ..

# copy the library to the parents's res/ folder
cp win/libsodium-1.0.18/src/libsodium/.libs/libsodium.a ../
