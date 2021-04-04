#!/bin/bash
echo "Building libsodium"

# First thing to do is see if libsodium.a exists in the res folder. If it does, then there's nothing to do
if [ ! -f res/unixlibs/libsodium.a ]; then

# Go into the lib sodium directory
cd res/libsodium
if [ ! -f libsodium-1.0.18.tar.gz ]; then
    wget https://download.libsodium.org/libsodium/releases/libsodium-1.0.18.tar.gz
fi

if [ ! -d libsodium-1.0.18 ]; then
    tar xf libsodium-1.0.18.tar.gz
fi

# Now build it
cd libsodium-1.0.18
LIBS="" ./configure > /dev/null
make clean > /dev/null 2>&1
if [[ "$OSTYPE" == "darwin"* ]]; then
    make CFLAGS="-mmacosx-version-min=10.11" CPPFLAGS="-mmacosx-version-min=10.11" > /dev/null 2>&1
else
    make > /dev/null 2>&1
fi

#move up to res folder
cd ..
cd ..

#check if the destiation folder exists
if [ ! -d unixlibs ]; then
    mkdir unixlibs
fi

# copy the library to the destination
cp ./libsodium/libsodium-1.0.18/src/libsodium/.libs/libsodium.a ./unixlibs/libsodium.a

else
  echo "Skipping libsodium already built"
fi
