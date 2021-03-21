#!/bin/bash

#cd /tmp

FILE=openssl-1.1.1e.tar.gz
if [ -f "$FILE" ]; then
    echo "$FILE exists"
else
    wget https://www.openssl.org/source/old/1.1.1/openssl-1.1.1e.tar.gz
    tar xvf openssl-1.1.1e.tar.gz
fi

cd openssl-1.1.1e/

rm -rf release
mkdir release

make clean
make distclean

./config --prefix=/$PWD/openssl-1.1.1e/release
make -j$(nproc)
make -j$(nproc) install

make clean
make distclean
